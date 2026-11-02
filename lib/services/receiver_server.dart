import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../core/utils/secrets.dart';
import '../data/database/app_database.dart';
import '../data/models/device_role.dart';
import '../data/repositories/pairing_repository.dart';
import 'pairing_invite.dart';
import 'protocol/frame_codec.dart';
import 'protocol/luma_connection.dart';
import 'protocol/messages.dart';
import 'receiver_storage_service.dart';
import 'tls_identity.dart';
import '../app/app_info.dart';

class PairingRequestInfo {
  const PairingRequestInfo({
    required this.senderId,
    required this.senderName,
    required this.remoteAddress,
  });

  final String senderId;
  final String senderName;
  final String remoteAddress;
}

/// Asks the user whether to trust a sender. Resolves `false` to decline.
typedef PairingApprover = Future<bool> Function(PairingRequestInfo request);

sealed class ReceiverEvent {
  const ReceiverEvent();
}

class SenderPaired extends ReceiverEvent {
  const SenderPaired(this.senderName);

  final String senderName;
}

class ManifestReceived extends ReceiverEvent {
  const ManifestReceived({
    required this.senderName,
    required this.fileCount,
    required this.totalBytes,
    required this.at,
  });

  final String senderName;
  final int fileCount;
  final int totalBytes;
  final DateTime at;
}

class FileReceiving extends ReceiverEvent {
  const FileReceiving({required this.name, required this.sizeBytes});

  final String name;
  final int sizeBytes;
}

class FileSaved extends ReceiverEvent {
  const FileSaved({required this.name, required this.alreadyPresent});

  final String name;
  final bool alreadyPresent;
}

class FileFailed extends ReceiverEvent {
  const FileFailed({required this.name, required this.reason});

  final String name;
  final String reason;
}

class SessionEnded extends ReceiverEvent {
  const SessionEnded();
}

/// TLS server on the receiver: handles pairing and authenticated sessions.
class ReceiverServer {
  ReceiverServer({
    required this.identity,
    required this.deviceId,
    required this.displayName,
    required this._pairing,
    required this._approvePairing,
    this._storage,
    this._clock = DateTime.now,
  });

  static final _log = Logger('ReceiverServer');

  /// Tried first so the address stays stable across restarts; any free port
  /// is used if it's taken.
  static const preferredPort = 47863;
  static const inviteLifetime = Duration(minutes: 5);
  static const approvalTimeout = Duration(seconds: 60);
  static const idleTimeout = Duration(seconds: 60);

  final TlsIdentity identity;
  final String deviceId;
  final String displayName;
  final PairingRepository _pairing;
  final PairingApprover _approvePairing;

  /// Handles incoming files; `null` refuses them (pairing-only server).
  final ReceiverStorageService? _storage;
  final DateTime Function() _clock;
  final _events = StreamController<ReceiverEvent>.broadcast();

  SecureServerSocket? _server;
  ({String secret, DateTime expiresAt})? _invite;

  Stream<ReceiverEvent> get events => _events.stream;

  int? get port => _server?.port;

  DateTime? get inviteExpiresAt => _invite?.expiresAt;

  Future<int> start({InternetAddress? address, int port = preferredPort}) async {
    final existing = _server;
    if (existing != null) return existing.port;
    final context = identity.toServerContext();
    final bindAddress = address ?? InternetAddress.anyIPv4;
    SecureServerSocket server;
    try {
      server = await SecureServerSocket.bind(bindAddress, port, context);
    } on SocketException {
      server = await SecureServerSocket.bind(bindAddress, 0, context);
    }
    server.listen(
      _handle,
      // Failed TLS handshakes (e.g. a sender rejecting our certificate).
      onError: (Object error) => _log.warning('Incoming connection: $error'),
    );
    _server = server;
    _log.info('Listening on port ${server.port}');
    return server.port;
  }

  Future<void> stop() async {
    _invite = null;
    final server = _server;
    _server = null;
    await server?.close();
  }

  /// Creates a one-time invite for the QR code, replacing any earlier one.
  PairingInvite createInvite(String host) {
    final port = _server?.port;
    if (port == null) throw StateError('Server is not running');
    final secret = randomToken(24);
    _invite = (secret: secret, expiresAt: _clock().add(inviteLifetime));
    return PairingInvite(
      receiverId: deviceId,
      receiverName: displayName,
      host: host,
      port: port,
      fingerprint: identity.fingerprint,
      secret: secret,
    );
  }

  void cancelInvite() => _invite = null;

  Future<void> _handle(SecureSocket socket) async {
    final connection = LumaConnection(socket);
    try {
      switch (await connection.next()) {
        case final PairRequest request:
          await _pair(connection, request);
        case final Hello hello:
          await _session(connection, hello);
        case null:
          break;
        case final other:
          connection.send(
            ErrorMessage(
              code: ErrorMessage.unexpectedMessage,
              message: 'Expected pairRequest or hello, got ${other.type}',
            ),
          );
      }
    } on Object catch (error) {
      _log.warning('Connection from ${connection.remoteAddress}: $error');
    } finally {
      await connection.close();
    }
  }

  Future<void> _pair(LumaConnection connection, PairRequest request) async {
    if (request.protocolVersion != currentProtocolVersion) {
      connection.send(
        const ErrorMessage(
          code: ErrorMessage.unsupportedVersion,
          message: 'Update $appName on both phones to the same version.',
        ),
      );
      return;
    }
    final invite = _invite;
    if (invite == null ||
        _clock().isAfter(invite.expiresAt) ||
        !constantTimeEquals(request.pairingSecret, invite.secret)) {
      connection.send(
        const PairRejected(
          reason:
              'This pairing code is no longer valid. Show a new code on the '
              'receiver and scan it again.',
        ),
      );
      return;
    }
    // One use only, whatever the user decides.
    _invite = null;

    final approved = await _approvePairing(
      PairingRequestInfo(
        senderId: request.senderId,
        senderName: request.senderName,
        remoteAddress: connection.remoteAddress,
      ),
    ).timeout(approvalTimeout, onTimeout: () => false);
    if (!approved) {
      connection.send(
        const PairRejected(reason: 'Pairing was declined on the receiver.'),
      );
      return;
    }

    final token = randomToken();
    final now = _clock();
    await _pairing.savePairing(
      PairedDevice(
        deviceId: request.senderId,
        displayName: request.senderName,
        peerRole: DeviceRole.sender,
        authTokenHash: sha256Hex(token),
        lastKnownHost: connection.remoteAddress,
        pairedAt: now,
        lastSeenAt: now,
      ),
    );
    connection.send(
      PairAccepted(
        receiverId: deviceId,
        receiverName: displayName,
        authToken: token,
      ),
    );
    _log.info('Paired with ${request.senderName}');
    _events.add(SenderPaired(request.senderName));
  }

  Future<void> _session(LumaConnection connection, Hello hello) async {
    final device = await _pairing.pairedDevice();
    final tokenHash = device?.authTokenHash;
    final authorized =
        hello.protocolVersion == currentProtocolVersion &&
        device != null &&
        device.peerRole == DeviceRole.sender &&
        device.deviceId == hello.senderId &&
        tokenHash != null &&
        constantTimeEquals(sha256Hex(hello.authToken), tokenHash);
    if (!authorized) {
      _log.warning('Rejected unpaired sender from ${connection.remoteAddress}');
      connection.send(
        const ErrorMessage(
          code: ErrorMessage.unauthorized,
          message: 'This phone is not paired with the receiver. Pair again.',
        ),
      );
      return;
    }

    await _pairing.recordSeen(
      device.deviceId,
      at: _clock(),
      host: connection.remoteAddress,
    );
    connection.send(
      HelloAccepted(receiverId: deviceId, receiverName: displayName),
    );

    try {
      await _sessionLoop(connection, device);
    } finally {
      _events.add(const SessionEnded());
    }
  }

  Future<void> _sessionLoop(
    LumaConnection connection,
    PairedDevice device,
  ) async {
    while (true) {
      switch (await connection.next(timeout: idleTimeout)) {
        case null:
          return;
        case final FileOffer offer:
          await _receiveFile(connection, offer, device);
        case Ping(:final nonce):
          connection.send(Pong(nonce));
        case final Manifest manifest:
          final totalBytes = manifest.files.fold(
            0,
            (sum, file) => sum + file.sizeBytes,
          );
          connection.send(
            ManifestAck(
              sessionId: manifest.sessionId,
              fileCount: manifest.files.length,
              totalBytes: totalBytes,
            ),
          );
          _log.info(
            'Manifest ${manifest.sessionId}: ${manifest.files.length} files',
          );
          _events.add(
            ManifestReceived(
              senderName: device.displayName,
              fileCount: manifest.files.length,
              totalBytes: totalBytes,
              at: _clock(),
            ),
          );
        case final other:
          connection.send(
            ErrorMessage(
              code: ErrorMessage.unexpectedMessage,
              message: 'Unexpected ${other.type}',
            ),
          );
          return;
      }
    }
  }

  /// Receives one offered file: dedupe, stage, verify, publish, then the
  /// final acknowledgement (plan §7).
  Future<void> _receiveFile(
    LumaConnection connection,
    FileOffer offer,
    PairedDevice device,
  ) async {
    final storage = _storage;
    if (storage == null) {
      connection.send(
        FileRejected(
          transferId: offer.transferId,
          reason: 'This receiver is not accepting files.',
          retryable: true,
        ),
      );
      return;
    }

    final existing = await storage.alreadyReceived(offer, device.deviceId);
    if (existing != null) {
      connection.send(
        FileAlreadyPresent(
          transferId: offer.transferId,
          sha256: existing.sha256,
          acknowledgementId: existing.acknowledgementId,
        ),
      );
      _events.add(FileSaved(name: existing.publishedName, alreadyPresent: true));
      return;
    }

    final incoming = await storage.begin(offer, device.deviceId);
    connection.send(FileAccept(transferId: offer.transferId));
    _events.add(FileReceiving(name: offer.name, sizeBytes: offer.sizeBytes));
    try {
      while (true) {
        switch (await connection.nextAny(timeout: idleTimeout)) {
          case IncomingData(:final bytes):
            await incoming.write(bytes);
          case IncomingMessage(message: final FileComplete complete)
              when complete.transferId == offer.transferId:
            final result = await storage.finish(incoming, complete.sha256);
            switch (result) {
              case ReceiveSaved():
                connection.send(
                  FileAck(
                    transferId: offer.transferId,
                    sha256: result.sha256,
                    acknowledgementId: result.acknowledgementId,
                    savedAs: result.savedAs,
                  ),
                );
                _events.add(
                  FileSaved(name: result.savedAs, alreadyPresent: result.duplicate),
                );
              case ReceiveRejected(:final reason, :final retryable):
                connection.send(
                  FileRejected(
                    transferId: offer.transferId,
                    reason: reason,
                    retryable: retryable,
                  ),
                );
                _events.add(FileFailed(name: offer.name, reason: reason));
            }
            return;
          case null:
            throw const SocketException('Sender disconnected mid-file');
          case IncomingMessage(:final message):
            throw ProtocolException('Unexpected ${message.type} mid-file');
        }
      }
    } on Object catch (error) {
      await storage.abort(incoming);
      _events.add(FileFailed(name: offer.name, reason: '$error'));
      rethrow;
    }
  }
}
