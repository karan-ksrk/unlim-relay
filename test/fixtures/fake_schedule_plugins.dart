import 'package:lumasync/data/models/schedule.dart';
import 'package:lumasync/data/plugin_adapters/background_scheduler.dart';
import 'package:lumasync/data/plugin_adapters/battery_optimization.dart';
import 'package:lumasync/data/plugin_adapters/transfer_notifications.dart';

class FakeBackgroundScheduler implements BackgroundScheduler {
  /// The time of the registered daily run; `null` when cancelled.
  DateTime? scheduledAt;
  ScheduleSettings? scheduledWith;
  int runNowCalls = 0;
  void Function(Map<String, dynamic>)? progressListener;

  @override
  Future<void> scheduleAt(
    DateTime at,
    ScheduleSettings settings, {
    required DateTime now,
  }) async {
    scheduledAt = at;
    scheduledWith = settings;
  }

  @override
  Future<void> cancel() async {
    scheduledAt = null;
    scheduledWith = null;
  }

  @override
  Future<void> runNow(ScheduleSettings settings) async => runNowCalls++;

  @override
  Future<void> listenForProgress(
    void Function(Map<String, dynamic>) listener,
  ) async => progressListener = listener;
}

class FakeTransferNotifications implements TransferNotifications {
  bool enabled = true;
  int permissionRequests = 0;
  final shown = <(String, String)>[];

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return enabled;
  }

  @override
  Future<void> showScheduleStatus(String title, String body) async =>
      shown.add((title, body));
}

class FakeBatteryOptimization implements BatteryOptimization {
  bool exempt = false;

  @override
  Future<bool> isExempt() async => exempt;

  @override
  Future<bool> requestExemption() async => exempt = true;
}
