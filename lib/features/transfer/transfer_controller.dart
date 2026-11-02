import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/models/transfer_limits.dart';
import '../../data/providers.dart';
import '../../data/repositories/transfer_lock_repository.dart';
import '../../services/daily_limits.dart';
import '../../services/transfer_errors.dart';
import '../../services/transfer_orchestrator.dart';
import '../pairing/sender_link_controller.dart';

enum TransferPhase { idle, running, done, failed }

class TransferState {
  const TransferState({
    this.phase = TransferPhase.idle,
    this.progress,
    this.summary,
    this.error,
    this.cancelling = false,
  });

  final TransferPhase phase;
  final TransferProgress? progress;
  final TransferSummary? summary;
  final String? error;
  final bool cancelling;

  bool get isRunning => phase == TransferPhase.running;
}

final transferOrchestratorProvider = Provider<TransferOrchestrator>(
  (ref) => TransferOrchestrator(
    inventory: ref.watch(mediaInventoryRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    library: ref.watch(mediaLibraryProvider),
    locator: ref.watch(receiverLocatorProvider),
    client: ref.watch(senderClientProvider),
  ),
);

final transferLimitsProvider = FutureProvider<TransferLimits>(
  (ref) => ref.watch(settingsRepositoryProvider).readTransferLimits(),
);

/// Photos and videos transferred since local midnight.
final transferredTodayProvider = StreamProvider<({int photos, int videos})>(
  (ref) => ref
      .watch(mediaInventoryRepositoryProvider)
      .watchTransferredSince(startOfDay(DateTime.now())),
);

final transferControllerProvider =
    NotifierProvider<TransferController, TransferState>(TransferController.new);

class TransferController extends Notifier<TransferState> {
  static final _log = Logger('TransferController');

  bool _cancelRequested = false;

  @override
  TransferState build() => const TransferState();

  /// Sends pending and failed files, or only [itemIds], within today's
  /// limits. [extraBatch] sends one more daily-sized batch even though
  /// today's limit is used up.
  Future<void> start({Set<int>? itemIds, bool extraBatch = false}) async {
    if (state.isRunning) return;
    _cancelRequested = false;
    state = const TransferState(phase: TransferPhase.running);
    final wakeLock = ref.read(screenWakeLockProvider);
    await _quietly(wakeLock.enable);
    try {
      // The lock keeps this from overlapping a scheduled run in the
      // background engine.
      final summary = await ref
          .read(transferLockRepositoryProvider)
          .whileHolding(
            TransferLockOwner.app,
            () => ref
                .read(transferOrchestratorProvider)
                .run(
                  itemIds: itemIds,
                  extraBatch: extraBatch,
                  onProgress: (progress) => state = TransferState(
                    phase: TransferPhase.running,
                    progress: progress,
                    cancelling: _cancelRequested,
                  ),
                  isCancelled: () => _cancelRequested,
                ),
          );
      state = TransferState(
        phase: TransferPhase.done,
        progress: state.progress,
        summary: summary,
      );
    } on Object catch (error, stackTrace) {
      _log.warning('Transfer failed to start', error, stackTrace);
      state = TransferState(
        phase: TransferPhase.failed,
        error: describeTransferError(error),
      );
    } finally {
      await _quietly(wakeLock.disable);
    }
  }

  void cancel() {
    if (!state.isRunning) return;
    _cancelRequested = true;
    state = TransferState(
      phase: TransferPhase.running,
      progress: state.progress,
      cancelling: true,
    );
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      _log.warning('Wake lock: $error');
    }
  }
}
