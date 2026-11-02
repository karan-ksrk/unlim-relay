import 'package:permission_handler/permission_handler.dart';

/// Android battery optimization ("Doze") exemption for this app.
abstract interface class BatteryOptimization {
  /// Whether the app is exempt, so scheduled runs are less likely to be
  /// delayed or killed.
  Future<bool> isExempt();

  /// Shows the system prompt to exempt the app. Returns whether exempt.
  Future<bool> requestExemption();
}

/// [BatteryOptimization] backed by `package:permission_handler`.
class PermissionHandlerBatteryOptimization implements BatteryOptimization {
  const PermissionHandlerBatteryOptimization();

  @override
  Future<bool> isExempt() => Permission.ignoreBatteryOptimizations.isGranted;

  @override
  Future<bool> requestExemption() async =>
      (await Permission.ignoreBatteryOptimizations.request()).isGranted;
}
