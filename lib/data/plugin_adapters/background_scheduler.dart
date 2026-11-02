import 'package:workmanager/workmanager.dart';

import '../models/schedule.dart';

/// Registers the scheduled transfer with the OS. Background work is
/// inexact: Android starts it at or after the requested time.
abstract interface class BackgroundScheduler {
  /// Replaces any pending scheduled run with one at or after [at].
  Future<void> scheduleAt(
    DateTime at,
    ScheduleSettings settings, {
    required DateTime now,
  });

  Future<void> cancel();

  /// Starts a scheduled-style run right away, separate from the daily one.
  Future<void> runNow(ScheduleSettings settings);

  /// Delivers progress maps reported by a running background task.
  Future<void> listenForProgress(void Function(Map<String, dynamic>) listener);
}

/// [BackgroundScheduler] backed by `package:workmanager` (Android
/// WorkManager). [initialize] must run in `main` before any other call.
class WorkmanagerBackgroundScheduler implements BackgroundScheduler {
  const WorkmanagerBackgroundScheduler();

  static const dailyTaskName = 'dailyTransfer';
  static const dailyWork = 'daily-transfer';
  static const runNowWork = 'daily-transfer-now';

  /// Set in the run-now task's input so it skips the "is it time?" check.
  static const forceKey = 'force';

  static Future<void> initialize(Function callbackDispatcher) =>
      Workmanager().initialize(callbackDispatcher);

  @override
  Future<void> scheduleAt(
    DateTime at,
    ScheduleSettings settings, {
    required DateTime now,
  }) {
    final delay = at.difference(now);
    return Workmanager().registerOneOffTask(
      dailyWork,
      dailyTaskName,
      initialDelay: delay.isNegative ? Duration.zero : delay,
      constraints: _constraints(settings),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      foregroundServiceConfig: _foreground,
    );
  }

  @override
  Future<void> cancel() => Workmanager().cancelByUniqueName(dailyWork);

  @override
  Future<void> runNow(ScheduleSettings settings) =>
      Workmanager().registerOneOffTask(
        runNowWork,
        dailyTaskName,
        inputData: {forceKey: true},
        constraints: _constraints(settings),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        foregroundServiceConfig: _foreground,
      );

  @override
  Future<void> listenForProgress(
    void Function(Map<String, dynamic>) listener,
  ) => Workmanager().setProgressListener((_, progress) => listener(progress));

  /// Battery and network conditions are left to WorkManager, which waits
  /// until they hold instead of starting and giving up.
  static Constraints _constraints(ScheduleSettings settings) => Constraints(
    networkType: settings.wifiOnly
        ? NetworkType.unmetered
        : NetworkType.connected,
    requiresCharging: settings.chargingOnly,
    requiresBatteryNotLow: true,
  );

  /// Runs as a data-sync foreground service so OEM battery managers don't
  /// kill a transfer halfway. Android may refuse this from the background;
  /// the task then runs as ordinary background work.
  static final _foreground = ForegroundServiceConfig(
    notificationTitle: 'Daily transfer',
    notificationText: 'Sending new photos and videos…',
    notificationChannelId: 'daily_transfer_running',
    notificationChannelName: 'Daily transfer in progress',
    notificationId: 7001,
    foregroundServiceType: ForegroundServiceType.dataSync,
  );
}
