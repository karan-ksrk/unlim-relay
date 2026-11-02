import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on during a manual transfer, and on the receiver when
/// its foreground service can't start, so Android doesn't suspend the app.
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
