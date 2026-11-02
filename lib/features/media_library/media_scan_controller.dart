import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/plugin_adapters/media_library.dart';
import '../../data/providers.dart';
import '../../services/media_scan_service.dart';
import 'media_library_providers.dart';

enum ScanPhase { idle, requestingAccess, scanning, done, accessDenied, failed }

class MediaScanState {
  const MediaScanState({
    this.phase = ScanPhase.idle,
    this.scanned = 0,
    this.total = 0,
    this.summary,
    this.error,
  });

  final ScanPhase phase;
  final int scanned;
  final int total;
  final ScanSummary? summary;
  final String? error;

  bool get isBusy =>
      phase == ScanPhase.requestingAccess || phase == ScanPhase.scanning;
}

final mediaScanControllerProvider =
    NotifierProvider<MediaScanController, MediaScanState>(
      MediaScanController.new,
    );

/// Requests media access when the user starts a scan, then runs it.
class MediaScanController extends Notifier<MediaScanState> {
  static final _log = Logger('MediaScanController');

  @override
  MediaScanState build() => const MediaScanState();

  Future<void> scan() async {
    if (state.isBusy) return;
    state = const MediaScanState(phase: ScanPhase.requestingAccess);
    try {
      final access = await ref.read(mediaLibraryProvider).requestAccess();
      ref.invalidate(mediaAccessProvider);
      if (access == MediaAccess.denied) {
        state = const MediaScanState(phase: ScanPhase.accessDenied);
        return;
      }

      state = const MediaScanState(phase: ScanPhase.scanning);
      final summary = await ref
          .read(mediaScanServiceProvider)
          .scan(
            onProgress: (scanned, total) => state = MediaScanState(
              phase: ScanPhase.scanning,
              scanned: scanned,
              total: total,
            ),
          );
      state = MediaScanState(phase: ScanPhase.done, summary: summary);
      ref.invalidate(lastScanAtProvider);
    } catch (error, stackTrace) {
      _log.severe('Camera scan failed', error, stackTrace);
      state = MediaScanState(phase: ScanPhase.failed, error: '$error');
    }
  }
}
