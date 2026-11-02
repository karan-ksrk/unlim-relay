import 'dart:async';

import 'package:logging/logging.dart';

import '../core/utils/secrets.dart';
import '../data/database/app_database.dart';
import '../data/models/media_enums.dart';
import '../data/plugin_adapters/media_library.dart';
import '../data/repositories/media_inventory_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'daily_limits.dart';
import 'protocol/messages.dart';
import 'receiver_locator.dart';
import 'sender_client.dart';
import 'transfer_errors.dart';

enum TransferTrigger { manual, scheduled }

class TransferProgress {
  const TransferProgress({
    required this.totalFiles,
    required this.totalBytes,
    required this.fileIndex,
    required this.delivered,
    required this.alreadyPresent,
    required this.failed,
    required this.sentBytes,
    required this.bytesPerSecond,
    this.currentFileName,
    this.verifying = false,
  });

  final int totalFiles;
  final int totalBytes;

  /// 0-based index of the current file.
  final int fileIndex;
  final int delivered;
  final int alreadyPresent;
  final int failed;

  /// Bytes sent so far across the batch, including the current file.
  final int sentBytes;
  final double bytesPerSecond;
  final String? currentFileName;

  /// The current file is sent and the receiver is verifying and saving it.
  final bool verifying;

  int get finished => delivered + alreadyPresent + failed;
}

class TransferSummary {
  const TransferSummary({
    this.delivered = 0,
    this.alreadyPresent = 0,
    this.failed = 0,
    this.deferredPhotos = 0,
    this.deferredVideos = 0,
    this.cancelled = false,
    this.error,
  });

  final int delivered;
  final int alreadyPresent;
  final int failed;

  /// Held back by today's limits.
  final int deferredPhotos;
  final int deferredVideos;
  final bool cancelled;

  /// Set when the session stopped early, e.g. the connection dropped.
  final String? error;

  bool get nothingToSend =>
      delivered + alreadyPresent + failed == 0 && !cancelled && error == null;
}

/// Sends pending files one at a time (plan §7). A file becomes transferred
/// only after the receiver's final acknowledgement; source files are never
/// modified or deleted.
class TransferOrchestrator {
  TransferOrchestrator({
    required this._inventory,
    required this._settings,
    required this._library,
    required this._locator,
    required this._client,
    this._clock = DateTime.now,
  });

  static final _log = Logger('TransferOrchestrator');

  final MediaInventoryRepository _inventory;
  final SettingsRepository _settings;
  final MediaLibrary _library;
  final ReceiverLocator _locator;
  final SenderClient _client;
  final DateTime Function() _clock;

  /// Sends pending and failed items (or only [itemIds]) within today's
  /// limits, newest first. Connection setup errors are thrown; errors
  /// mid-batch end the session and are reported in the summary.
  ///
  /// [extraBatch] is the user's explicit "Run next batch": one more batch of
  /// the daily size, ignoring what was already sent today.
  Future<TransferSummary> run({
    TransferTrigger trigger = TransferTrigger.manual,
    Set<int>? itemIds,
    bool extraBatch = false,
    void Function(TransferProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    await _inventory.resetInterrupted();
    final limits = await _settings.readTransferLimits();
    final sentToday = extraBatch
        ? (photos: 0, videos: 0)
        : await _inventory.watchTransferredSince(startOfDay(_clock())).first;
    final allowance = applyDailyLimits(
      await _inventory.transferCandidates(ids: itemIds),
      limits,
      photosSentToday: sentToday.photos,
      videosSentToday: sentToday.videos,
    );
    final batch = allowance.selected;
    if (batch.isEmpty) {
      return TransferSummary(
        deferredPhotos: allowance.deferredPhotos,
        deferredVideos: allowance.deferredVideos,
      );
    }

    final link = await _locator.locate();
    final session = await _client.openSession(
      receiver: link.receiver,
      host: link.host,
      port: link.port,
      authToken: link.authToken,
    );
    _log.info(
      '${trigger.name}${extraBatch ? ' extra-batch' : ''} transfer of '
      '${batch.length} files to '
      '${session.receiverName}; ${allowance.deferred} deferred by limits',
    );

    final totalBytes = batch.fold(0, (sum, item) => sum + item.sizeBytes);
    final stopwatch = Stopwatch()..start();
    var delivered = 0, alreadyPresent = 0, failed = 0, doneBytes = 0;
    var cancelled = false;
    String? error;

    void report(int index, MediaItem item, int sent, {bool verifying = false}) {
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      onProgress?.call(
        TransferProgress(
          totalFiles: batch.length,
          totalBytes: totalBytes,
          fileIndex: index,
          delivered: delivered,
          alreadyPresent: alreadyPresent,
          failed: failed,
          sentBytes: doneBytes + sent,
          bytesPerSecond: seconds > 0 ? (doneBytes + sent) / seconds : 0,
          currentFileName: item.displayName,
          verifying: verifying,
        ),
      );
    }

    try {
      await session.sendManifest(
        Manifest(
          sessionId: randomToken(12),
          senderDeviceId: _client.deviceId,
          files: [for (final item in batch) _manifestFile(item)],
        ),
      );
      await _locator.recordSuccess(link);

      for (var i = 0; i < batch.length; i++) {
        if (isCancelled?.call() ?? false) {
          cancelled = true;
          break;
        }
        final item = batch[i];
        report(i, item, 0);

        final file = await _library.originalFile(item.sourceMediaId);
        if (file == null || !await file.exists()) {
          await _inventory.setStatus(
            item.id,
            TransferStatus.failed,
            error: 'The file is no longer on this phone.',
          );
          failed++;
          doneBytes += item.sizeBytes;
          continue;
        }

        await _inventory.setStatus(item.id, TransferStatus.transferring);
        try {
          final outcome = await session.sendFile(
            FileOffer(
              transferId: _transferId(item),
              name: item.displayName,
              mimeType: item.mimeType,
              sizeBytes: await file.length(),
              dateTakenMillis: item.dateTakenMillis,
              sourceModifiedMillis: item.dateModifiedMillis,
            ),
            file.openRead,
            onBytes: (sent) => report(i, item, sent),
            onVerifying: () {
              unawaited(
                _inventory.setStatus(item.id, TransferStatus.verifying),
              );
              report(i, item, item.sizeBytes, verifying: true);
            },
            isCancelled: isCancelled,
          );
          switch (outcome) {
            case FileDelivered():
              await _inventory.markTransferred(
                item.id,
                sha256: outcome.sha256,
                acknowledgementId: outcome.acknowledgementId,
                at: _clock(),
              );
              outcome.alreadyPresent ? alreadyPresent++ : delivered++;
            case FileNotDelivered(:final reason):
              await _inventory.setStatus(
                item.id,
                TransferStatus.failed,
                error: reason,
              );
              failed++;
          }
        } on TransferCancelledException {
          await _inventory.setStatus(item.id, TransferStatus.pending);
          cancelled = true;
          break;
        } on Object catch (e) {
          // The connection is unusable after a mid-file error; stop here
          // and leave the rest pending.
          error = describeTransferError(e, host: link.host);
          await _inventory.setStatus(
            item.id,
            TransferStatus.failed,
            error: error,
          );
          failed++;
          _log.warning('Transfer of ${item.displayName} failed', e);
          break;
        }
        doneBytes += item.sizeBytes;
      }
    } finally {
      await session.close();
    }

    _log.info(
      'Transfer finished: $delivered sent, $alreadyPresent already on '
      'receiver, $failed failed${cancelled ? ', cancelled' : ''} in '
      '${stopwatch.elapsed.inSeconds}s',
    );
    return TransferSummary(
      delivered: delivered,
      alreadyPresent: alreadyPresent,
      failed: failed,
      deferredPhotos: allowance.deferredPhotos,
      deferredVideos: allowance.deferredVideos,
      cancelled: cancelled,
      error: error,
    );
  }

  /// Stable per inventory row, so retransmits are recognised.
  String _transferId(MediaItem item) => '${_client.deviceId}:${item.id}';

  ManifestFile _manifestFile(MediaItem item) => ManifestFile(
    transferId: _transferId(item),
    name: item.displayName,
    mimeType: item.mimeType,
    sizeBytes: item.sizeBytes,
    dateTakenMillis: item.dateTakenMillis,
  );
}
