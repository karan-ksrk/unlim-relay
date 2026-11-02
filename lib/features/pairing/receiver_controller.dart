import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../core/platform/network_address.dart';
import '../../data/models/device_role.dart';
import '../../data/plugin_adapters/receiver_keep_alive.dart';
import '../../data/plugin_adapters/screen_wake_lock.dart';
import '../../data/plugin_adapters/service_discovery.dart';
import '../../data/providers.dart';
import '../onboarding/device_role_controller.dart';
import '../../services/pairing_invite.dart';
import '../../services/receiver_server.dart';
import '../../services/receiver_storage_service.dart';
import '../../services/tls_identity_store.dart';

enum ReceiverPhase { off, starting, ready, failed }

/// A sender waiting for the user to allow or decline pairing.
class PendingApproval {
  PendingApproval(this.request) : _completer = Completer<bool>();

  final PairingRequestInfo request;
  final Completer<bool> _completer;
}

class ReceiverState {
  const ReceiverState({
    this.phase = ReceiverPhase.off,
    this.port,
    this.invite,
    this.inviteExpiresAt,
    this.pendingApproval,
    this.lastManifest,
    this.receivingName,
    this.savedThisSession = 0,
    this.failedThisSession = 0,
    this.lastFailure,
    this.message,
    this.error,
    this.runsInBackground = false,
  });

  final ReceiverPhase phase;
  final int? port;
  final PairingInvite? invite;
  final DateTime? inviteExpiresAt;
  final PendingApproval? pendingApproval;
  final ManifestReceived? lastManifest;

  /// File currently being received, if any.
  final String? receivingName;
  final int savedThisSession;
  final int failedThisSession;
  final String? lastFailure;

  /// Latest notable outcome, e.g. "Paired with iQOO I2304".
  final String? message;
  final String? error;

  /// The foreground service is keeping the receiver alive with the screen
  /// off. When false the screen is kept on instead.
  final bool runsInBackground;

  bool get isReady => phase == ReceiverPhase.ready;

  ReceiverState copyWith({
    ReceiverPhase? phase,
    int? port,
    Object? invite = _keep,
    Object? inviteExpiresAt = _keep,
    Object? pendingApproval = _keep,
    ManifestReceived? lastManifest,
    Object? receivingName = _keep,
    int? savedThisSession,
    int? failedThisSession,
    String? lastFailure,
    Object? message = _keep,
    Object? error = _keep,
    bool? runsInBackground,
  }) => ReceiverState(
    phase: phase ?? this.phase,
    port: port ?? this.port,
    invite: invite == _keep ? this.invite : invite as PairingInvite?,
    inviteExpiresAt: inviteExpiresAt == _keep
        ? this.inviteExpiresAt
        : inviteExpiresAt as DateTime?,
    pendingApproval: pendingApproval == _keep
        ? this.pendingApproval
        : pendingApproval as PendingApproval?,
    lastManifest: lastManifest ?? this.lastManifest,
    receivingName: receivingName == _keep
        ? this.receivingName
        : receivingName as String?,
    savedThisSession: savedThisSession ?? this.savedThisSession,
    failedThisSession: failedThisSession ?? this.failedThisSession,
    lastFailure: lastFailure ?? this.lastFailure,
    message: message == _keep ? this.message : message as String?,
    error: error == _keep ? this.error : error as String?,
    runsInBackground: runsInBackground ?? this.runsInBackground,
  );
}

const _keep = Object();

final tlsIdentityStoreProvider = Provider<TlsIdentityStore>(
  (ref) => TlsIdentityStore(ref.watch(secureStoreProvider)),
);

final receiverControllerProvider =
    NotifierProvider<ReceiverController, ReceiverState>(ReceiverController.new);

/// Runs the receiver server while "Ready to receive" is on. A foreground
/// service keeps it running with the screen off or the app in the
/// background (plan §2.3); if Android refuses the service, the screen is
/// kept on instead.
class ReceiverController extends Notifier<ReceiverState> {
  static final _log = Logger('ReceiverController');

  ReceiverServer? _server;
  Future<void>? _starting;
  StreamSubscription<ReceiverEvent>? _events;
  late ReceiverKeepAlive _keepAliveService;
  late ScreenWakeLock _screenWakeLock;
  late ServiceDiscovery _discovery;

  @override
  ReceiverState build() {
    // Read now: providers can't be read from onDispose, where _shutdown
    // also runs.
    _keepAliveService = ref.read(receiverKeepAliveProvider);
    _screenWakeLock = ref.read(screenWakeLockProvider);
    _discovery = ref.read(serviceDiscoveryProvider);
    ref.onDispose(_shutdown);
    Future.microtask(_resumeIfWasReady);
    return const ReceiverState();
  }

  /// "Ready to receive" survives app restarts: if it was on, start again.
  Future<void> _resumeIfWasReady() async {
    if (!ref.mounted || ref.read(deviceRoleProvider) != DeviceRole.receiver) {
      return;
    }
    if (await ref.read(settingsRepositoryProvider).readReceiverReady()) {
      _log.info('Resuming Ready to receive');
      await _start();
    }
  }

  Future<void> setReady(bool ready) async {
    await ref.read(settingsRepositoryProvider).saveReceiverReady(ready);
    if (ready) {
      // Android 13+ hides the service notification without it; the
      // service itself runs either way.
      try {
        await ref.read(transferNotificationsProvider).requestPermission();
      } on Object catch (error) {
        _log.warning('Notification permission request failed: $error');
      }
    }
    await (ready ? _start() : _stop());
  }

  /// Starts the server if needed and shows a fresh pairing code.
  Future<void> showPairingCode() async {
    await _start();
    final server = _server;
    if (server == null) return;
    final host = await localNetworkAddress();
    if (host == null) {
      state = state.copyWith(
        error: 'Connect this phone to Wi-Fi to show a pairing code.',
      );
      return;
    }
    final invite = server.createInvite(host);
    state = state.copyWith(
      invite: invite,
      inviteExpiresAt: server.inviteExpiresAt,
      message: null,
      error: null,
    );
  }

  void cancelPairingCode() {
    _server?.cancelInvite();
    state = state.copyWith(invite: null, inviteExpiresAt: null);
  }

  void respondToPairing({required bool allow}) {
    final pending = state.pendingApproval;
    if (pending != null && !pending._completer.isCompleted) {
      pending._completer.complete(allow);
    }
  }

  /// Callers that overlap (auto-resume and the switch) share one start.
  Future<void> _start() {
    if (_server != null) return Future.value();
    return _starting ??= _doStart().whenComplete(() => _starting = null);
  }

  Future<void> _doStart() async {
    state = state.copyWith(phase: ReceiverPhase.starting, error: null);
    try {
      final local = ref.read(localDeviceProvider);
      final identity = await ref
          .read(tlsIdentityStoreProvider)
          .loadOrCreate('LumaSync ${local.displayName}');
      final storage = ReceiverStorageService(
        stagingDirectory: await ref.read(stagingDirectoryProvider.future),
        publisher: ref.read(mediaPublisherProvider),
        received: ref.read(receivedFilesRepositoryProvider),
      );
      await storage.cleanStaging();
      final server = ReceiverServer(
        identity: identity,
        deviceId: local.id,
        displayName: local.displayName,
        pairing: ref.read(pairingRepositoryProvider),
        approvePairing: _askUser,
        storage: storage,
      );
      final port = await server.start();
      _server = server;
      _events = server.events.listen(_onEvent);
      final background = await _keepAlive(start: true);
      if (!background) await _wakeLock(enable: true);
      state = state.copyWith(
        phase: ReceiverPhase.ready,
        port: port,
        runsInBackground: background,
      );

      // Discovery helps the sender find a new IP later; pairing works
      // without it, so a failure here is not fatal.
      try {
        await ref
            .read(serviceDiscoveryProvider)
            .advertise(deviceId: local.id, name: local.displayName, port: port);
      } on Object catch (error) {
        _log.warning('mDNS advertising failed: $error');
      }
    } on Object catch (error, stackTrace) {
      _log.severe('Receiver failed to start', error, stackTrace);
      state = state.copyWith(
        phase: ReceiverPhase.failed,
        error: 'Could not start receiving: $error',
      );
    }
  }

  Future<void> _stop() async {
    await _shutdown();
    state = const ReceiverState();
  }

  Future<void> _shutdown() async {
    await _keepAlive(start: false);
    await _wakeLock(enable: false);
    await _events?.cancel();
    _events = null;
    final server = _server;
    _server = null;
    await server?.stop();
    try {
      await _discovery.stopAdvertising();
    } on Object catch (error) {
      _log.warning('Stopping mDNS failed: $error');
    }
  }

  Future<bool> _askUser(PairingRequestInfo request) {
    final pending = PendingApproval(request);
    state = state.copyWith(pendingApproval: pending);
    return pending._completer.future
        .timeout(ReceiverServer.approvalTimeout, onTimeout: () => false)
        .whenComplete(() {
          if (identical(state.pendingApproval, pending)) {
            state = state.copyWith(
              pendingApproval: null,
              invite: null,
              inviteExpiresAt: null,
            );
          }
        });
  }

  Future<bool> _keepAlive({required bool start}) async {
    final keepAlive = _keepAliveService;
    try {
      if (start) return await keepAlive.start();
      await keepAlive.stop();
    } on Object catch (error) {
      _log.warning('Receiver foreground service: $error');
    }
    return false;
  }

  Future<void> _wakeLock({required bool enable}) async {
    try {
      final lock = _screenWakeLock;
      await (enable ? lock.enable() : lock.disable());
    } on Object catch (error) {
      _log.warning('Wake lock: $error');
    }
  }

  void _onEvent(ReceiverEvent event) {
    switch (event) {
      case SenderPaired(:final senderName):
        state = state.copyWith(message: 'Paired with $senderName');
      case final ManifestReceived manifest:
        state = state.copyWith(lastManifest: manifest);
      case FileReceiving(:final name):
        state = state.copyWith(receivingName: name);
      case FileSaved():
        state = state.copyWith(
          receivingName: null,
          savedThisSession: state.savedThisSession + 1,
        );
      case FileFailed(:final name, :final reason):
        state = state.copyWith(
          receivingName: null,
          failedThisSession: state.failedThisSession + 1,
          lastFailure: '$name: $reason',
        );
      case SessionEnded():
        state = state.copyWith(receivingName: null);
    }
  }
}
