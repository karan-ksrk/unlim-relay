import 'dart:io';

import 'package:logging/logging.dart';

import '../data/database/app_database.dart';
import '../data/plugin_adapters/service_discovery.dart';
import '../data/repositories/pairing_repository.dart';

class ReceiverLink {
  const ReceiverLink({
    required this.receiver,
    required this.authToken,
    required this.host,
    required this.port,
  });

  final PairedDevice receiver;
  final String authToken;
  final String host;
  final int port;
}

class NotPairedException implements Exception {
  const NotPairedException();

  @override
  String toString() => 'Not paired with a receiver. Pair the phones first.';
}

/// Finds the paired receiver: mDNS first (its IP may have changed), then
/// the last address that worked.
class ReceiverLocator {
  ReceiverLocator(this._pairing, this._discovery);

  static final _log = Logger('ReceiverLocator');

  final PairingRepository _pairing;
  final ServiceDiscovery _discovery;

  Future<ReceiverLink> locate() async {
    final receiver = await _pairing.pairedDevice();
    final token = receiver == null
        ? null
        : await _pairing.authToken(receiver.deviceId);
    if (receiver == null || token == null) throw const NotPairedException();

    final found = await _discovery.find(receiver.deviceId);
    final host = found?.host ?? receiver.lastKnownHost;
    final port = found?.port ?? receiver.lastKnownPort;
    if (host == null || port == null) {
      throw const SocketException('Receiver address unknown');
    }
    _log.info(
      found != null
          ? 'Receiver found via mDNS at $host:$port'
          : 'Receiver not found via mDNS; using last known $host:$port',
    );
    return ReceiverLink(
      receiver: receiver,
      authToken: token,
      host: host,
      port: port,
    );
  }

  Future<void> recordSuccess(ReceiverLink link) => _pairing.recordSeen(
    link.receiver.deviceId,
    at: DateTime.now(),
    host: link.host,
    port: link.port,
  );
}
