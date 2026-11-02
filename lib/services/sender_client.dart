import 'dart:io';
import 'dart:math';

import '../core/utils/secrets.dart';
import '../core/utils/streaming_sha256.dart';
import '../data/database/app_database.dart';
import '../data/models/device_role.dart';
import 'pairing_invite.dart';
import 'protocol/frame_codec.dart';
import 'protocol/luma_connection.dart';
import 'protocol/messages.dart';
import 'tls_identity.dart';

/// The receiver turned the pairing down or the code was invalid.
class PairingRejectedException implements Exception {
  const PairingRejectedException(this.reason);

  final String reason;

  @override
  String toString() => reason;
}

class ConnectionTestResult {
  const ConnectionTestResult({
    required this.receiverName,
    required this.host,
    required this.port,
    required this.roundTrip,
    required this.acknowledgedFiles,
    required this.acknowledgedBytes,
  });

  final String receiverName;
  final String host;
  final int port;
  final Duration roundTrip;
  final int acknowledgedFiles;
  final int acknowledgedBytes;
}

/// The user cancelled while a file was streaming.
class TransferCancelledException implements Exception {
  const TransferCancelledException();
}

sealed class FileOutcome {
  const FileOutcome();
}

/// The receiver verified and published the file (or already had it).
class FileDelivered extends FileOutcome {
  const FileDelivered({
    required this.sha256,
    required this.acknowledgementId,
    required this.alreadyPresent,
    this.savedAs,
  });

  final String sha256;
  final String acknowledgementId;
  final bool alreadyPresent;
  final String? savedAs;
}

class FileNotDelivered extends FileOutcome {
  const FileNotDelivered(this.reason);

  final String reason;
}

/// An authenticated session for sending files one at a time.
class SenderSession {
  SenderSession._(this._connection, this.receiverName);

  /// Flush to the OS every this many bytes so at most about this much file
  /// data is buffered in memory.
  static const flushEveryBytes = 1024 * 1024;

  /// The receiver re-hashes the published copy before acknowledging, which
  /// takes a while for large videos on a slow phone.
  static const ackTimeout = Duration(minutes: 5);

  final LumaConnection _connection;
  final String receiverName;

  Future<ManifestAck> sendManifest(Manifest manifest) async {
    _connection.send(manifest);
    return _connection.expect<ManifestAck>();
  }

  /// Offers [offer] and, if accepted, streams [source] while hashing it.
  ///
  /// [onBytes] reports bytes sent for this file; [onVerifying] fires once
  /// all bytes are out and the receiver is verifying and publishing.
  Future<FileOutcome> sendFile(
    FileOffer offer,
    Stream<List<int>> Function() source, {
    void Function(int sentBytes)? onBytes,
    void Function()? onVerifying,
    bool Function()? isCancelled,
  }) async {
    _connection.send(offer);
    switch (await _connection.next()) {
      case FileAccept():
        break;
      case FileAlreadyPresent(:final sha256, :final acknowledgementId):
        return FileDelivered(
          sha256: sha256,
          acknowledgementId: acknowledgementId,
          alreadyPresent: true,
        );
      case FileRejected(:final reason):
        return FileNotDelivered(reason);
      case final ErrorMessage error:
        throw RemoteErrorException(error);
      case null:
        throw const SocketException('Receiver closed the connection');
      case final other:
        throw ProtocolException('Unexpected ${other.type}');
    }

    final hasher = StreamingSha256();
    var sent = 0;
    var unflushed = 0;
    await for (final chunk in source()) {
      if (isCancelled?.call() ?? false) throw const TransferCancelledException();
      hasher.add(chunk);
      _connection.sendData(chunk);
      sent += chunk.length;
      unflushed += chunk.length;
      if (unflushed >= flushEveryBytes) {
        await _connection.flush();
        unflushed = 0;
        onBytes?.call(sent);
      }
    }
    await _connection.flush();
    onBytes?.call(sent);

    final sha = hasher.close();
    _connection.send(FileComplete(transferId: offer.transferId, sha256: sha));
    onVerifying?.call();

    switch (await _connection.next(timeout: ackTimeout)) {
      case FileAck(:final sha256, :final acknowledgementId, :final savedAs):
        if (sha256 != sha) {
          throw const ProtocolException('Acknowledged hash does not match');
        }
        return FileDelivered(
          sha256: sha,
          acknowledgementId: acknowledgementId,
          alreadyPresent: false,
          savedAs: savedAs,
        );
      case FileRejected(:final reason):
        return FileNotDelivered(reason);
      case final ErrorMessage error:
        throw RemoteErrorException(error);
      case null:
        throw const SocketException('Receiver closed the connection');
      case final other:
        throw ProtocolException('Unexpected ${other.type}');
    }
  }

  Future<void> close() => _connection.close();
}

/// Sender side of the protocol. Every connection pins the receiver's
/// certificate fingerprint; no certificate authority is trusted.
class SenderClient {
  SenderClient({
    required this.deviceId,
    required this.displayName,
    this.connectTimeout = const Duration(seconds: 6),
  });

  /// Covers the time the receiver's user takes to approve.
  static const approvalWait = Duration(seconds: 90);

  final String deviceId;
  final String displayName;
  final Duration connectTimeout;

  /// Pairs using a scanned [invite]. [onConnected] fires once the pinned TLS
  /// connection is up and the receiver is being asked to approve.
  Future<({PairedDevice receiver, String authToken})> pair(
    PairingInvite invite, {
    required DateTime now,
    void Function()? onConnected,
  }) async {
    final connection = await _connect(
      invite.host,
      invite.port,
      invite.fingerprint,
    );
    try {
      connection.send(
        PairRequest(
          pairingSecret: invite.secret,
          senderId: deviceId,
          senderName: displayName,
        ),
      );
      onConnected?.call();
      final reply = await connection.next(timeout: approvalWait);
      switch (reply) {
        case PairAccepted(:final receiverId, :final receiverName, :final authToken):
          if (receiverId != invite.receiverId) {
            throw const ProtocolException('Receiver identity changed');
          }
          return (
            receiver: PairedDevice(
              deviceId: receiverId,
              displayName: receiverName,
              peerRole: DeviceRole.receiver,
              certificateFingerprint: invite.fingerprint,
              lastKnownHost: invite.host,
              lastKnownPort: invite.port,
              pairedAt: now,
              lastSeenAt: now,
            ),
            authToken: authToken,
          );
        case PairRejected(:final reason):
          throw PairingRejectedException(reason);
        case ErrorMessage():
          throw RemoteErrorException(reply);
        case null:
          throw const SocketException('Receiver closed the connection');
        case final other:
          throw ProtocolException('Unexpected ${other.type}');
      }
    } finally {
      await connection.close();
    }
  }

  /// Connects with the pinned certificate and authenticates.
  Future<SenderSession> openSession({
    required PairedDevice receiver,
    required String host,
    required int port,
    required String authToken,
  }) async {
    final fingerprint = receiver.certificateFingerprint;
    if (fingerprint == null) throw StateError('Receiver has no pinned certificate');
    final connection = await _connect(host, port, fingerprint);
    try {
      connection.send(Hello(senderId: deviceId, authToken: authToken));
      final accepted = await connection.expect<HelloAccepted>();
      if (accepted.receiverId != receiver.deviceId) {
        throw const ProtocolException('Receiver identity changed');
      }
      return SenderSession._(connection, accepted.receiverName);
    } on Object {
      await connection.close();
      rethrow;
    }
  }

  /// Authenticates, measures one ping and sends [manifest], which the
  /// receiver must acknowledge with matching totals.
  Future<ConnectionTestResult> testConnection({
    required PairedDevice receiver,
    required String host,
    required int port,
    required String authToken,
    required Manifest manifest,
  }) async {
    final fingerprint = receiver.certificateFingerprint;
    if (fingerprint == null) throw StateError('Receiver has no pinned certificate');
    final connection = await _connect(host, port, fingerprint);
    try {
      connection.send(Hello(senderId: deviceId, authToken: authToken));
      final accepted = await connection.expect<HelloAccepted>();
      if (accepted.receiverId != receiver.deviceId) {
        throw const ProtocolException('Receiver identity changed');
      }

      final nonce = Random.secure().nextInt(1 << 32);
      final stopwatch = Stopwatch()..start();
      connection.send(Ping(nonce));
      final pong = await connection.expect<Pong>();
      final roundTrip = stopwatch.elapsed;
      if (pong.nonce != nonce) throw const ProtocolException('Ping mismatch');

      connection.send(manifest);
      final ack = await connection.expect<ManifestAck>();
      final expectedBytes = manifest.files.fold(0, (s, f) => s + f.sizeBytes);
      if (ack.sessionId != manifest.sessionId ||
          ack.fileCount != manifest.files.length ||
          ack.totalBytes != expectedBytes) {
        throw const ProtocolException('Manifest acknowledgement mismatch');
      }

      return ConnectionTestResult(
        receiverName: accepted.receiverName,
        host: host,
        port: port,
        roundTrip: roundTrip,
        acknowledgedFiles: ack.fileCount,
        acknowledgedBytes: ack.totalBytes,
      );
    } finally {
      await connection.close();
    }
  }

  Future<LumaConnection> _connect(String host, int port, String fingerprint) async {
    final socket = await SecureSocket.connect(
      host,
      port,
      context: SecurityContext(withTrustedRoots: false),
      onBadCertificate: (certificate) => constantTimeEquals(
        certificateFingerprint(certificate.der),
        fingerprint,
      ),
      timeout: connectTimeout,
    );
    return LumaConnection(socket);
  }
}
