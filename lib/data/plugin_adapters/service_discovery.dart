import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:logging/logging.dart';

class DiscoveredReceiver {
  const DiscoveredReceiver({
    required this.deviceId,
    required this.name,
    required this.host,
    required this.port,
  });

  final String deviceId;
  final String name;
  final String host;
  final int port;
}

/// Local-network service discovery (mDNS / DNS-SD).
abstract interface class ServiceDiscovery {
  /// Advertises this receiver; replaces any previous advertisement.
  Future<void> advertise({
    required String deviceId,
    required String name,
    required int port,
  });

  Future<void> stopAdvertising();

  /// Finds the receiver with [deviceId], or `null` after [timeout].
  Future<DiscoveredReceiver?> find(
    String deviceId, {
    Duration timeout = const Duration(seconds: 6),
  });
}

/// [ServiceDiscovery] backed by `package:bonsoir` (Android NsdManager).
class BonsoirServiceDiscovery implements ServiceDiscovery {
  static final _log = Logger('BonsoirServiceDiscovery');
  static const _type = '_lumasync._tcp';

  BonsoirBroadcast? _broadcast;

  @override
  Future<void> advertise({
    required String deviceId,
    required String name,
    required int port,
  }) async {
    await stopAdvertising();
    final broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: name,
        type: _type,
        port: port,
        attributes: {'id': deviceId, 'v': '1'},
      ),
    );
    await broadcast.initialize();
    await broadcast.start();
    _broadcast = broadcast;
    _log.info('Advertising $_type on port $port');
  }

  @override
  Future<void> stopAdvertising() async {
    final broadcast = _broadcast;
    _broadcast = null;
    if (broadcast != null) await broadcast.stop();
  }

  @override
  Future<DiscoveredReceiver?> find(
    String deviceId, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final discovery = BonsoirDiscovery(type: _type);
    await discovery.initialize();
    final result = Completer<DiscoveredReceiver?>();
    final subscription = discovery.eventStream!.listen((event) {
      switch (event) {
        case BonsoirDiscoveryServiceFoundEvent(:final service):
          // Android only delivers TXT attributes (our device id) after
          // resolution, so every LumaSync service is resolved and matched
          // below.
          discovery.serviceResolver.resolveService(service);
        case BonsoirDiscoveryServiceResolvedEvent(:final service):
          final host = service.hostAddresses
              .where((a) => InternetAddress.tryParse(a)?.type ==
                  InternetAddressType.IPv4)
              .firstOrNull;
          if (service.attributes['id'] == deviceId &&
              host != null &&
              !result.isCompleted) {
            result.complete(
              DiscoveredReceiver(
                deviceId: deviceId,
                name: service.name,
                host: host,
                port: service.port,
              ),
            );
          }
        default:
          break;
      }
    });
    try {
      await discovery.start();
      return await result.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await subscription.cancel();
      await discovery.stop();
    }
  }
}
