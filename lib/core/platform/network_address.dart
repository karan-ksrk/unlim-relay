import 'dart:io';

/// This phone's IPv4 address on the local Wi-Fi (or hotspot), or `null`
/// when it has none. Mobile-data interfaces are skipped: the peer can't
/// reach them.
Future<String?> localNetworkAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );
  final candidates =
      interfaces.where((i) => !_isMobileData(i.name)).toList()
        ..sort((a, b) => _rank(a.name).compareTo(_rank(b.name)));
  for (final interface in candidates) {
    for (final address in interface.addresses) {
      if (!address.isLoopback && !address.isLinkLocal) return address.address;
    }
  }
  return null;
}

bool _isMobileData(String name) =>
    name.startsWith('rmnet') ||
    name.startsWith('ccmni') ||
    name.startsWith('dummy') ||
    name.startsWith('tun');

/// Wi-Fi first, then hotspot, then anything else.
int _rank(String name) {
  if (name.startsWith('wlan')) return 0;
  if (name.startsWith('ap') || name.startsWith('swlan')) return 1;
  return 2;
}
