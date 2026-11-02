import 'package:drift/drift.dart';

import '../data/database/app_database.dart';
import '../data/models/media_enums.dart';
import '../data/plugin_adapters/media_library.dart';
import '../data/repositories/media_inventory_repository.dart';

/// Compares a fresh library scan with the stored inventory (plan §5).
///
/// - New files are inserted as pending.
/// - Files whose size or modification time changed lose their hash and
///   transfer verification and go back to pending.
/// - Files that left the library are marked removed but kept as history.
/// - A file whose MediaStore id changed (restore, re-index) is matched by
///   name, size and capture time so its status is kept.
InventoryChanges reconcileInventory({
  required List<MediaItem> existing,
  required List<ScannedMedia> scanned,
  required DateTime now,
}) {
  final byId = <String, MediaItem>{};
  for (final item in existing) {
    final current = byId[item.sourceMediaId];
    // Prefer the live row if an old removed row shares the id.
    if (current == null || current.removedFromLibraryAt != null) {
      byId[item.sourceMediaId] = item;
    }
  }

  final scannedIds = {for (final media in scanned) media.sourceMediaId};
  final orphansByFingerprint = <String, MediaItem>{};
  for (final item in existing) {
    if (scannedIds.contains(item.sourceMediaId)) continue;
    orphansByFingerprint.putIfAbsent(
      _fingerprint(item.displayName, item.sizeBytes, item.dateTakenMillis),
      () => item,
    );
  }

  final inserts = <MediaItemsCompanion>[];
  final updates = <int, MediaItemsCompanion>{};
  final matched = <int>{};
  var changed = 0;
  var restored = 0;

  for (final media in scanned) {
    final item =
        byId[media.sourceMediaId] ??
        orphansByFingerprint.remove(
          _fingerprint(
            media.displayName,
            media.sizeBytes,
            media.dateTaken?.millisecondsSinceEpoch,
          ),
        );
    if (item == null) {
      inserts.add(_newItem(media, now));
      continue;
    }

    matched.add(item.id);
    final contentChanged =
        item.sizeBytes != media.sizeBytes ||
        item.dateModifiedMillis != media.dateModified.millisecondsSinceEpoch;
    final metadataChanged =
        item.sourceMediaId != media.sourceMediaId ||
        item.displayName != media.displayName ||
        item.mimeType != media.mimeType ||
        item.dateTakenMillis != media.dateTaken?.millisecondsSinceEpoch ||
        item.relativePath != media.relativePath ||
        item.kind != media.kind;
    final wasRemoved = item.removedFromLibraryAt != null;
    if (!contentChanged && !metadataChanged && !wasRemoved) continue;

    if (contentChanged) changed++;
    if (wasRemoved) restored++;
    updates[item.id] = _metadata(media).copyWith(
      removedFromLibraryAt: const Value(null),
      status: contentChanged ? const Value(TransferStatus.pending) : null,
      sha256: contentChanged ? const Value(null) : null,
      transferredAt: contentChanged ? const Value(null) : null,
      receiverAcknowledgementId: contentChanged ? const Value(null) : null,
      lastError: contentChanged ? const Value(null) : null,
    );
  }

  var removed = 0;
  for (final item in existing) {
    if (matched.contains(item.id) || item.removedFromLibraryAt != null) {
      continue;
    }
    updates[item.id] = MediaItemsCompanion(removedFromLibraryAt: Value(now));
    removed++;
  }

  return InventoryChanges(
    inserts: inserts,
    updates: updates,
    added: inserts.length,
    changed: changed,
    removed: removed,
    restored: restored,
  );
}

String _fingerprint(String name, int size, int? dateTakenMillis) =>
    '$name|$size|$dateTakenMillis';

MediaItemsCompanion _metadata(ScannedMedia media) => MediaItemsCompanion(
  sourceMediaId: Value(media.sourceMediaId),
  displayName: Value(media.displayName),
  mimeType: Value(media.mimeType),
  sizeBytes: Value(media.sizeBytes),
  dateTakenMillis: Value(media.dateTaken?.millisecondsSinceEpoch),
  dateModifiedMillis: Value(media.dateModified.millisecondsSinceEpoch),
  relativePath: Value(media.relativePath),
  kind: Value(media.kind),
);

MediaItemsCompanion _newItem(ScannedMedia media, DateTime now) =>
    _metadata(media).copyWith(
      status: const Value(TransferStatus.pending),
      firstSeenAt: Value(now),
    );
