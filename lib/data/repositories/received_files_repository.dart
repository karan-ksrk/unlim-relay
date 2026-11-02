import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ReceivedStats {
  const ReceivedStats({
    this.count = 0,
    this.totalBytes = 0,
    this.lastReceivedAt,
  });

  final int count;
  final int totalBytes;
  final DateTime? lastReceivedAt;
}

/// Receiver-side record of verified, published files.
abstract interface class ReceivedFilesRepository {
  /// The record for a retransmit of the same source file version.
  Future<ReceivedFile?> findByTransfer({
    required String senderDeviceId,
    required String transferId,
    required int sizeBytes,
    required int sourceModifiedMillis,
  });

  Future<ReceivedFile?> findBySha256(String sha256);

  Future<void> add(ReceivedFilesCompanion file);

  Stream<ReceivedStats> watchStats();
}

class DriftReceivedFilesRepository implements ReceivedFilesRepository {
  DriftReceivedFilesRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ReceivedFile?> findByTransfer({
    required String senderDeviceId,
    required String transferId,
    required int sizeBytes,
    required int sourceModifiedMillis,
  }) {
    final query = _db.select(_db.receivedFiles)
      ..where(
        (t) =>
            t.senderDeviceId.equals(senderDeviceId) &
            t.transferId.equals(transferId) &
            t.sizeBytes.equals(sizeBytes) &
            t.sourceModifiedMillis.equals(sourceModifiedMillis),
      )
      ..limit(1);
    return query.getSingleOrNull();
  }

  @override
  Future<ReceivedFile?> findBySha256(String sha256) =>
      (_db.select(_db.receivedFiles)
            ..where((t) => t.sha256.equals(sha256))
            ..limit(1))
          .getSingleOrNull();

  @override
  Future<void> add(ReceivedFilesCompanion file) =>
      _db.into(_db.receivedFiles).insert(file);

  @override
  Stream<ReceivedStats> watchStats() {
    final t = _db.receivedFiles;
    final count = t.id.count();
    final bytes = t.sizeBytes.sum();
    final last = t.receivedAt.max();
    final query = _db.selectOnly(t)..addColumns([count, bytes, last]);
    return query.watchSingle().map(
      (row) => ReceivedStats(
        count: row.read(count) ?? 0,
        totalBytes: row.read(bytes) ?? 0,
        lastReceivedAt: row.read(last),
      ),
    );
  }
}
