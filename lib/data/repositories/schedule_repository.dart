/// Daily transfer schedule (plan §9). Runs are best-effort: Android
/// WorkManager starts them at or after the chosen time.
class ScheduleSettings {
  const ScheduleSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.wifiOnly = true,
    this.chargingOnly = false,
    this.lastAttemptAt,
    this.lastSuccessAt,
  });

  final bool enabled;
  final int hour;
  final int minute;

  /// ISO weekdays, 1 = Monday … 7 = Sunday.
  final Set<int> weekdays;
  final bool wifiOnly;
  final bool chargingOnly;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
}

/// Persists the schedule and registers background work.
///
/// Implemented in Milestone 5.
abstract interface class ScheduleRepository {
  Future<ScheduleSettings> read();

  /// Saves [settings] and re-registers the unique background job.
  Future<void> save(ScheduleSettings settings);
}
