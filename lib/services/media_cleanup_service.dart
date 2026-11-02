import 'package:logging/logging.dart';

import '../data/database/app_database.dart';
import '../data/models/media_enums.dart';
import '../data/plugin_adapters/media_library.dart';
import '../data/repositories/media_inventory_repository.dart';

/// What a deletion request would do, before anything is deleted.
class CleanupReview {
  const CleanupReview({required this.deletable, required this.held});

  /// Verified on the receiver and unchanged since.
  final List<MediaItem> deletable;

  /// Selected but kept, with the reason.
  final List<(MediaItem, String)> held;

  int get bytes => deletable.fold(0, (sum, item) => sum + item.sizeBytes);
}

class CleanupResult {
  const CleanupResult({
    required this.deleted,
    required this.bytes,
    required this.declined,
  });

  final int deleted;
  final int bytes;

  /// Android's confirmation was declined, so nothing was deleted.
  final bool declined;
}

/// Manual deletion of originals after a verified transfer (plan §10).
///
/// Only ever deletes what the user selected and confirmed, through Android's
/// own confirmation, and only files the receiver verified that haven't
/// changed since. Never runs automatically.
class MediaCleanupService {
  MediaCleanupService({
    required this._inventory,
    required this._library,
    this._clock = DateTime.now,
  });

  static final _log = Logger('MediaCleanupService');

  final MediaInventoryRepository _inventory;
  final MediaLibrary _library;
  final DateTime Function() _clock;

  /// Checks each selected item again against the database and the library.
  Future<CleanupReview> review(Set<int> ids) async {
    final deletable = <MediaItem>[];
    final held = <(MediaItem, String)>[];
    for (final item in await _inventory.itemsByIds(ids)) {
      final reason = await _holdReason(item);
      reason == null ? deletable.add(item) : held.add((item, reason));
    }
    return CleanupReview(deletable: deletable, held: held);
  }

  Future<String?> _holdReason(MediaItem item) async {
    if (item.status != TransferStatus.transferred ||
        item.sha256 == null ||
        item.receiverAcknowledgementId == null) {
      return 'Not verified by the receiver yet.';
    }
    if (item.deletedAt != null || item.removedFromLibraryAt != null) {
      return 'Already gone from this phone.';
    }
    final current = await _library.describe(item.sourceMediaId);
    if (current == null) return 'No longer on this phone.';
    if (current.sizeBytes != item.sizeBytes ||
        current.dateModified.millisecondsSinceEpoch !=
            item.dateModifiedMillis) {
      return 'Changed since it was transferred; transfer it again first.';
    }
    return null;
  }

  /// Deletes [review]'s deletable items. Android asks the user first.
  Future<CleanupResult> delete(CleanupReview review) async {
    if (review.deletable.isEmpty) {
      return const CleanupResult(deleted: 0, bytes: 0, declined: false);
    }
    final deletedIds = (await _library.delete([
      for (final item in review.deletable) item.sourceMediaId,
    ])).toSet();
    final deleted = [
      for (final item in review.deletable)
        if (deletedIds.contains(item.sourceMediaId)) item,
    ];
    await _inventory.markDeleted({
      for (final item in deleted) item.id,
    }, _clock());
    final bytes = deleted.fold(0, (sum, item) => sum + item.sizeBytes);
    _log.info(
      'Deleted ${deleted.length} of ${review.deletable.length} originals '
      '($bytes bytes)',
    );
    return CleanupResult(
      deleted: deleted.length,
      bytes: bytes,
      declined: deleted.isEmpty,
    );
  }
}
