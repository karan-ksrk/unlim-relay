import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a transfer or "Ready to receive" is active, so
/// Android doesn't suspend the app mid-transfer (plan §2.3 MVP: both apps
/// open).
abstract interface class ScreenWakeLock {
  Future<void> enable();

  Future<void> disable();
}

class WakelockPlusScreenWakeLock implements ScreenWakeLock {
  const WakelockPlusScreenWakeLock();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}
