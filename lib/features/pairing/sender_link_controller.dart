import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../core/utils/secrets.dart';
import '../../data/providers.dart';
import '../../services/pairing_invite.dart';
import '../../services/protocol/messages.dart';
import '../../services/receiver_locator.dart';
import '../../services/sender_client.dart';
import '../../services/transfer_errors.dart';

enum SenderLinkPhase {
  idle,
  connecting,
  waitingForApproval,
  paired,
  testing,
  tested,
  failed,
}

class SenderLinkState {
  const SenderLinkState({
    this.phase = SenderLinkPhase.idle,
    this.testResult,
    this.error,
  });

  final SenderLinkPhase phase;
  final ConnectionTestResult? testResult;
  final String? error;

  bool get isBusy =>
      phase == SenderLinkPhase.connecting ||
      phase == SenderLinkPhase.waitingForApproval ||
      phase == SenderLinkPhase.testing;
}

final senderClientProvider = Provider<SenderClient>((ref) {
  final local = ref.watch(localDeviceProvider);
  return SenderClient(deviceId: local.id, displayName: local.displayName);
});

final receiverLocatorProvider = Provider<ReceiverLocator>(
  (ref) => ReceiverLocator(
    ref.watch(pairingRepositoryProvider),
    ref.watch(serviceDiscoveryProvider),
  ),
);

final senderLinkControllerProvider =
    NotifierProvider<SenderLinkController, SenderLinkState>(
      SenderLinkController.new,
    );

/// Sender-side pairing and the connection test.
class SenderLinkController extends Notifier<SenderLinkState> {
  static final _log = Logger('SenderLinkController');

  /// Pending items sent in the test manifest.
  static const testManifestLimit = 100;

  @override
  SenderLinkState build() => const SenderLinkState();

  Future<void> pair(PairingInvite invite) async {
    if (state.isBusy) return;
    state = const SenderLinkState(phase: SenderLinkPhase.connecting);
    try {
      final result = await ref
          .read(senderClientProvider)
          .pair(
            invite,
            now: DateTime.now(),
            onConnected: () => state = const SenderLinkState(
              phase: SenderLinkPhase.waitingForApproval,
            ),
          );
      await ref
          .read(pairingRepositoryProvider)
          .savePairing(result.receiver, authToken: result.authToken);
      _log.info('Paired with ${result.receiver.displayName}');
      state = const SenderLinkState(phase: SenderLinkPhase.paired);
    } on Object catch (error, stackTrace) {
      _log.warning('Pairing failed', error, stackTrace);
      state = SenderLinkState(
        phase: SenderLinkPhase.failed,
        error: describeTransferError(error, host: invite.host),
      );
    }
  }

  Future<void> testConnection() async {
    if (state.isBusy) return;
    state = const SenderLinkState(phase: SenderLinkPhase.testing);
    final locator = ref.read(receiverLocatorProvider);
    ReceiverLink? link;
    try {
      link = await locator.locate();
      final local = ref.read(localDeviceProvider);
      final pending = await ref
          .read(mediaInventoryRepositoryProvider)
          .pendingItems(limit: testManifestLimit);
      final manifest = Manifest(
        sessionId: randomToken(12),
        senderDeviceId: local.id,
        files: [
          for (final item in pending)
            ManifestFile(
              transferId: '${local.id}:${item.id}',
              name: item.displayName,
              mimeType: item.mimeType,
              sizeBytes: item.sizeBytes,
              dateTakenMillis: item.dateTakenMillis,
            ),
        ],
      );

      final result = await ref
          .read(senderClientProvider)
          .testConnection(
            receiver: link.receiver,
            host: link.host,
            port: link.port,
            authToken: link.authToken,
            manifest: manifest,
          );
      await locator.recordSuccess(link);
      _log.info(
        'Connection test OK: ${result.roundTrip.inMilliseconds} ms, '
        'manifest of ${result.acknowledgedFiles} files acknowledged',
      );
      state = SenderLinkState(
        phase: SenderLinkPhase.tested,
        testResult: result,
      );
    } on Object catch (error, stackTrace) {
      _log.warning('Connection test failed', error, stackTrace);
      state = SenderLinkState(
        phase: SenderLinkPhase.failed,
        error: describeTransferError(error, host: link?.host),
      );
    }
  }

  Future<void> unpair() async {
    await ref.read(pairingRepositoryProvider).revokePairing();
    state = const SenderLinkState();
  }
}
