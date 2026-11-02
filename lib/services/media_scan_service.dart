import 'package:logging/logging.dart';

import '../data/plugin_adapters/media_library.dart';
import '../data/repositories/media_inventory_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'inventory_reconciler.dart';

class ScanSummary {
  const ScanSummary({
    required this.scanned,
    required this.added,
    required this.changed,
    required this.removed,
    required this.restored,
    required this.duration,
  });

  final int scanned;
  final int added;
  final int changed;
  final int removed;
  final int restored;
  final Duration duration;
}

/// Runs an incremental camera-library scan and persists the result.
class MediaScanService {
  MediaScanService({
    required this._library,
    required this._inventory,
    required this._settings,
    this._clock = DateTime.now,
  });

  static final _log = Logger('MediaScanService');

  final MediaLibrary _library;
  final MediaInventoryRepository _inventory;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  /// Caller must have obtained media access first.
  Future<ScanSummary> scan({ScanProgressCallback? onProgress}) async {
    final stopwatch = Stopwatch()..start();
    final scanned = await _library.listCameraMedia(onProgress: onProgress);
    final listedIn = stopwatch.elapsed;

    final now = _clock();
    final changes = reconcileInventory(
      existing: await _inventory.allItems(),
      scanned: scanned,
      now: now,
    );
    await _inventory.apply(changes);
    await _settings.saveLastScanAt(now);

    final summary = ScanSummary(
      scanned: scanned.length,
      added: changes.added,
      changed: changes.changed,
      removed: changes.removed,
      restored: changes.restored,
      duration: stopwatch.elapsed,
    );
    _log.info(
      'Scan: ${summary.scanned} files, +${summary.added} new, '
      '${summary.changed} changed, ${summary.removed} removed, '
      '${summary.restored} restored; listed in ${listedIn.inMilliseconds} ms, '
      'total ${summary.duration.inMilliseconds} ms',
    );
    return summary;
  }
}
