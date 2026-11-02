/// Daily transfer schedule (plan §9). Runs are best-effort: Android
/// WorkManager starts them at or after the chosen time.
class ScheduleSettings {
  const ScheduleSettings({
    this.enabled = false,
    this.hour = 21,
    this.minute = 0,
    this.weekdays = everyDay,
    this.wifiOnly = true,
    this.chargingOnly = false,
    this.retryHours = defaultRetryHours,
    this.enabledAt,
  });

  static const everyDay = {1, 2, 3, 4, 5, 6, 7};
  static const defaultRetryHours = 3;
  static const retryHourChoices = [0, 1, 3, 6];

  final bool enabled;
  final int hour;
  final int minute;

  /// ISO weekdays, 1 = Monday … 7 = Sunday.
  final Set<int> weekdays;
  final bool wifiOnly;
  final bool chargingOnly;

  /// How long after the scheduled time a deferred or failed run is retried
  /// (every 30 minutes). 0 means wait for the next scheduled day.
  final int retryHours;

  /// When the schedule was last turned on or changed. Slots before this are
  /// never caught up, so turning it on at 10 PM for 9 PM doesn't start a run
  /// right away.
  final DateTime? enabledAt;

  ScheduleSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    Set<int>? weekdays,
    bool? wifiOnly,
    bool? chargingOnly,
    int? retryHours,
    DateTime? enabledAt,
  }) => ScheduleSettings(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdays: weekdays ?? this.weekdays,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    chargingOnly: chargingOnly ?? this.chargingOnly,
    retryHours: retryHours ?? this.retryHours,
    enabledAt: enabledAt ?? this.enabledAt,
  );

  @override
  bool operator ==(Object other) =>
      other is ScheduleSettings &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays) &&
      other.wifiOnly == wifiOnly &&
      other.chargingOnly == chargingOnly &&
      other.retryHours == retryHours &&
      other.enabledAt == enabledAt;

  @override
  int get hashCode => Object.hash(
    enabled,
    hour,
    minute,
    Object.hashAllUnordered(weekdays),
    wifiOnly,
    chargingOnly,
    retryHours,
    enabledAt,
  );
}

enum ScheduleOutcome {
  /// Recorded when a run starts; still there afterwards means the run was
  /// killed.
  running,

  /// Files were sent.
  completed,
  nothingToSend,

  /// Today's limit was already used up.
  limitReached,

  /// Stopped at the time budget with files left; continues shortly.
  partial,

  /// Preconditions not met (receiver unreachable, not paired, no photo
  /// access, another transfer running). Nothing was sent.
  deferred,

  /// The session broke off.
  failed;

  /// Whether the planner should try again before the next scheduled day.
  bool get isRetryable => switch (this) {
    running || partial || deferred || failed => true,
    completed || nothingToSend || limitReached => false,
  };

  static ScheduleOutcome? tryParse(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// What happened on the most recent scheduled run.
class ScheduleStatus {
  const ScheduleStatus({
    this.lastAttemptAt,
    this.lastOutcome,
    this.lastMessage,
    this.lastSuccessAt,
    this.nextRunEstimate,
  });

  static const none = ScheduleStatus();

  final DateTime? lastAttemptAt;
  final ScheduleOutcome? lastOutcome;

  /// One line for the user, e.g. why the run was deferred.
  final String? lastMessage;

  /// Last run that finished without errors, including "nothing to send".
  final DateTime? lastSuccessAt;

  /// When background work was last registered to start; Android may start
  /// it later.
  final DateTime? nextRunEstimate;
}
