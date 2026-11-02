import 'package:device_info_plus/device_info_plus.dart';

/// Human-readable name for this phone, shown to the peer during pairing.
abstract interface class DeviceInfoSource {
  Future<String> displayName();
}

class DeviceInfoPlusSource implements DeviceInfoSource {
  const DeviceInfoPlusSource();

  @override
  Future<String> displayName() async {
    final info = await DeviceInfoPlugin().androidInfo;
    // The user-set device name, unless it's just the model code.
    if (info.name.isNotEmpty && info.name != info.model) return info.name;
    final brand = info.brand;
    if (info.model.toLowerCase().startsWith(brand.toLowerCase())) {
      return info.model;
    }
    return '$brand ${info.model}';
  }
}
