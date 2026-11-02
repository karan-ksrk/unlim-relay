import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/media_enums.dart';

/// Inserts and updates produced by reconciling a scan with the inventory.
class InventoryChanges {
  const InventoryChanges({
    this.inserts = const [],
    this.updates = const {},
    this.added = 0,
    this.changed = 0,
    this.removed = 0,
    this.restored = 0,
  });

  final List<MediaItemsCompanion> inserts;

  /// Partial updates keyed by [MediaItem.id].
  final Map<int, MediaItemsCompanion> updates;

  final int added;

  /// Items whose content changed and went back to pending.
  final int changed;

  /// Items no longer in the media library.
  final int removed;

  /// Previously removed items that reappeared.
  final int restored;

  bool get isEmpty => inserts.isEmpty && updates.isEmpty;
}

/// Live inventory totals, excluding items removed from the library.
class InventoryStats {
  const InventoryStats({
    this.counts = const {},
    this.bytes = const {},
    this.photos = 0,
    this.videos = 0,
  });

  static const empty = InventoryStats();

  final Map<TransferStatus, int> counts;
  final Map<TransferStatus, int> bytes;
  final int photos;
  final int videos;

  int get totalCount => photos + videos;

  int get totalBytes => bytes.values.fold(0, (sum, b) => sum + b);

  int countFor(LibraryTab tab) =>
      tab.statuses.fold(0, (sum, s) => sum + (counts[s] ?? 0));

  int bytesFor(LibraryTab tab) =>
      tab.statuses.fold(0, (sum, s) => sum + (bytes[s] ?? 0));
}

/// Persistent sender inventory (plan §5 and §11).
abstract interface class MediaInventoryRepository {
  /// Every row, including items removed from the library.
  Future<List<MediaItem>> allItems();

  /// Applies [changes] atomically.
  Future<void> apply(InventoryChanges changes);

  /// Items listed in [tab], newest capture first.
  Stream<List<MediaItem>> watchTab(LibraryTab tab);

  /// Pending items still in the library, oldest capture first.
  Future<List<MediaItem>> pendingItems({int? limit});

  /// Pending and failed items still in the library, newest capture first,
  /// optionally restricted to [ids].
  Future<List<MediaItem>> transferCandidates({Set<int>? ids});

  /// Items left mid-transfer by a killed app go back to pending.
  Future<int> resetInterrupted();

  Future<void> setStatus(int id, TransferStatus status, {String? error});

  /// Only called after the receiver's final acknowledgement (plan §7).
  Future<void> markTransferred(
    int id, {
    required String sha256,
    required String acknowledgementId,
    required DateTime at,
  });

  /// Photos and videos marked transferred at or after [since].
  Stream<({int photos, int videos})> watchTransferredSince(DateTime since);

  Stream<InventoryStats> watchStats();

  Future<List<MediaItem>> itemsByIds(Set<int> ids);

  /// Records that the user deleted these originals from this phone. The
  /// rows stay as tombstones (plan §10).
  Future<void> markDeleted(Set<int> ids, DateTime at);

  /// Originals deleted from this phone after transfer, and their size.
  Stream<({int files, int bytes})> watchDeleted();
}

class DriftMediaInventoryRepository implements MediaInventoryRepository {
  DriftMediaInventoryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<MediaItem>> allItems() => _db.select(_db.mediaItems).get();

  @override
  Future<void> apply(InventoryChanges changes) async {
    if (changes.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.mediaItems, changes.inserts);
      for (final MapEntry(key: id, value: update) in changes.updates.entries) {
        batch.update(_db.mediaItems, update, where: (t) => t.id.equals(id));
      }
    });
  }

  @override
  Stream<List<MediaItem>> watchTab(LibraryTab tab) {
    final query = _db.select(_db.mediaItems)
      ..where(
        (t) =>
            t.status.isInValues(tab.statuses) & t.removedFromLibraryAt.isNull(),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.dateTakenMillis),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  @override
  Future<List<MediaItem>> pendingItems({int? limit}) {
    final query = _db.select(_db.mediaItems)
      ..where(
        (t) =>
            t.status.equalsValue(TransferStatus.pending) &
            t.removedFromLibraryAt.isNull(),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.dateTakenMillis),
        (t) => OrderingTerm.asc(t.id),
      ]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  static const _inFlight = {
    TransferStatus.queued,
    TransferStatus.transferring,
    TransferStatus.verifying,
    TransferStatus.publishing,
  };

  @override
  Future<List<MediaItem>> transferCandidates({Set<int>? ids}) {
    final query = _db.select(_db.mediaItems)
      ..where((t) {
        var condition =
            t.status.isInValues(const [
              TransferStatus.pending,
              TransferStatus.failed,
            ]) &
            t.removedFromLibraryAt.isNull();
        if (ids != null) condition = condition & t.id.isIn(ids);
        return condition;
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.dateTakenMillis),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.get();
  }

  @override
  Future<int> resetInterrupted() =>
      (_db.update(
        _db.mediaItems,
      )..where((t) => t.status.isInValues(_inFlight))).write(
        const MediaItemsCompanion(status: Value(TransferStatus.pending)),
      );

  @override
  Future<void> setStatus(int id, TransferStatus status, {String? error}) async {
    assert(status != TransferStatus.transferred, 'Use markTransferred');
    await (_db.update(_db.mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(status: Value(status), lastError: Value(error)),
    );
  }

  @override
  Future<void> markTransferred(
    int id, {
    required String sha256,
    required String acknowledgementId,
    required DateTime at,
  }) async {
    await (_db.update(_db.mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(
        status: const Value(TransferStatus.transferred),
        sha256: Value(sha256),
        receiverAcknowledgementId: Value(acknowledgementId),
        transferredAt: Value(at),
        lastError: const Value(null),
      ),
    );
  }

  @override
  Stream<({int photos, int videos})> watchTransferredSince(DateTime since) {
    final t = _db.mediaItems;
    final count = t.id.count();
    final query = _db.selectOnly(t)
      ..addColumns([t.kind, count])
      ..where(
        t.status.equalsValue(TransferStatus.transferred) &
            t.transferredAt.isBiggerOrEqualValue(since),
      )
      ..groupBy([t.kind]);
    return query.watch().map((rows) {
      var photos = 0;
      var videos = 0;
      for (final row in rows) {
        final n = row.read(count) ?? 0;
        if (row.readWithConverter<MediaKind, String>(t.kind) ==
            MediaKind.video) {
          videos += n;
        } else {
          photos += n;
        }
      }
      return (photos: photos, videos: videos);
    });
  }

  @override
  Future<List<MediaItem>> itemsByIds(Set<int> ids) =>
      (_db.select(_db.mediaItems)..where((t) => t.id.isIn(ids))).get();

  @override
  Future<void> markDeleted(Set<int> ids, DateTime at) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.mediaItems)..where((t) => t.id.isIn(ids))).write(
      MediaItemsCompanion(
        deletedAt: Value(at),
        removedFromLibraryAt: Value(at),
      ),
    );
  }

  @override
  Stream<({int files, int bytes})> watchDeleted() {
    final t = _db.mediaItems;
    final count = t.id.count();
    final bytes = t.sizeBytes.sum();
    final query = _db.selectOnly(t)
      ..addColumns([count, bytes])
      ..where(t.deletedAt.isNotNull());
    return query.watchSingle().map(
      (row) => (files: row.read(count) ?? 0, bytes: row.read(bytes) ?? 0),
    );
  }

  @override
  Stream<InventoryStats> watchStats() {
    final t = _db.mediaItems;
    final count = t.id.count();
    final bytes = t.sizeBytes.sum();
    final query = _db.selectOnly(t)
      ..addColumns([t.status, t.kind, count, bytes])
      ..where(t.removedFromLibraryAt.isNull())
      ..groupBy([t.status, t.kind]);

    return query.watch().map((rows) {
      final counts = <TransferStatus, int>{};
      final sizes = <TransferStatus, int>{};
      var photos = 0;
      var videos = 0;
      for (final row in rows) {
        final status = row.readWithConverter<TransferStatus, String>(t.status)!;
        final kind = row.readWithConverter<MediaKind, String>(t.kind)!;
        final n = row.read(count) ?? 0;
        counts[status] = (counts[status] ?? 0) + n;
        sizes[status] = (sizes[status] ?? 0) + (row.read(bytes) ?? 0);
        if (kind == MediaKind.video) {
          videos += n;
        } else {
          photos += n;
        }
      }
      return InventoryStats(
        counts: counts,
        bytes: sizes,
        photos: photos,
        videos: videos,
      );
    });
  }
}
