import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../app/app_info.dart';

/// Keeps the receiver running while the app is in the background or the
/// screen is off, using an Android foreground service with a notification.
abstract interface class ReceiverKeepAlive {
  /// Starts the service. Returns whether it is running.
  Future<bool> start();

  Future<void> stop();
}

/// [ReceiverKeepAlive] backed by `package:flutter_foreground_task`.
///
/// No task callback is registered, so no second engine starts: the service
/// only keeps this process (and the receiver server in the app's isolate)
/// alive, holding a CPU wake lock and a Wi-Fi lock. Swiping the app away
/// from recents destroys the app's engine, so the service stops with it
/// (android:stopWithTask in the manifest) rather than showing a
/// notification for a receiver that is gone.
class ForegroundTaskReceiverKeepAlive implements ReceiverKeepAlive {
  const ForegroundTaskReceiverKeepAlive();

  static const _serviceId = 7003;

  /// Only sets the plugin's options, so calling it on every start is fine.
  static void _init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'receiver_ready',
        channelName: 'Ready to receive',
        channelDescription:
            'Shown while this phone is listening for the '
            'sender.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
        allowAutoRestart: false,
        // Left unset on purpose: the plugin's `stopWithTask: true` stops the
        // service as soon as the app is paused (Home, screen off). The
        // manifest's android:stopWithTask stops it only when the app is
        // swiped away.
      ),
    );
  }

  @override
  Future<bool> start() async {
    _init();
    if (await FlutterForegroundTask.isRunningService) return true;
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: [ForegroundServiceTypes.connectedDevice],
      notificationTitle: 'Ready to receive',
      notificationText:
          '$appName is listening for the sender. Keep it in '
          'recent apps.',
    );
    return result is ServiceRequestSuccess;
  }

  @override
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
