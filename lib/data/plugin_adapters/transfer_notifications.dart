import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Status notifications for scheduled transfers.
abstract interface class TransferNotifications {
  /// Whether the user allows notifications (Android 13+ asks at runtime).
  Future<bool> areEnabled();

  /// Shows the Android 13+ permission prompt. Returns whether allowed.
  Future<bool> requestPermission();

  Future<void> showScheduleStatus(String title, String body);
}

/// [TransferNotifications] backed by `package:flutter_local_notifications`.
class LocalTransferNotifications implements TransferNotifications {
  LocalTransferNotifications();

  static const _statusId = 7002;

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialized;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_transfer_status',
      'Daily transfer results',
      channelDescription:
          'When a scheduled transfer finishes, is deferred '
          'or fails.',
    ),
  );

  Future<void> _ensureInitialized() => _initialized ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> areEnabled() async {
    await _ensureInitialized();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> showScheduleStatus(String title, String body) async {
    await _ensureInitialized();
    await _plugin.show(
      id: _statusId,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }
}
