import '../data/models/schedule.dart';

/// Gap between retries of a deferred or failed run.
const scheduleRetryInterval = Duration(minutes: 30);

/// Earliest restart after the start of a run that stopped at its time
/// budget; in practice that run ended later, so it continues straight away.
const scheduleContinuationDelay = Duration(minutes: 1);

/// Background work may start slightly before the planned instant.
const _dueTolerance = Duration(minutes: 1);

/// The most recent scheduled time at or before [now], on an enabled weekday.
DateTime? latestSlot(ScheduleSettings settings, DateTime now) {
  for (var back = 0; back <= 7; back++) {
    final slot = _slotOn(settings, now.year, now.month, now.day - back);
    if (!slot.isAfter(now) && settings.weekdays.contains(slot.weekday)) {
      return slot;
    }
  }
  return null;
}

/// The first scheduled time strictly after [now], on an enabled weekday.
DateTime? nextSlotAfter(ScheduleSettings settings, DateTime now) {
  for (var ahead = 0; ahead <= 7; ahead++) {
    final slot = _slotOn(settings, now.year, now.month, now.day + ahead);
    if (slot.isAfter(now) && settings.weekdays.contains(slot.weekday)) {
      return slot;
    }
  }
  return null;
}

/// When the next scheduled run should start, or `null` when the schedule is
/// off. Returns [now] when a run is due.
///
/// - Each scheduled time gets one run. If the phone misses it (off, Doze),
///   the run happens as soon as Android allows, until the next scheduled
///   time.
/// - A deferred, failed or killed run is retried every 30 minutes for
///   `retryHours` after the scheduled time.
/// - A run that stopped at its time budget continues straight away.
DateTime? planNextRun(
  ScheduleSettings settings,
  ScheduleStatus status,
  DateTime now,
) {
  if (!settings.enabled || settings.weekdays.isEmpty) return null;
  var next = nextSlotAfter(settings, now);
  final attemptAt = status.lastAttemptAt;
  if (next != null &&
      attemptAt != null &&
      !attemptAt.isBefore(next) &&
      status.lastOutcome?.isRetryable == false) {
    // A run that started a moment early already finished this slot.
    next = nextSlotAfter(settings, next);
  }
  final slot = latestSlot(settings, now);
  final enabledAt = settings.enabledAt;
  if (slot == null || (enabledAt != null && slot.isBefore(enabledAt))) {
    return next;
  }

  final attempt = status.lastAttemptAt;
  if (attempt == null || attempt.isBefore(slot)) return now;

  final outcome = status.lastOutcome;
  if (outcome == null || !outcome.isRetryable) return next;

  final DateTime retryAt;
  if (outcome == ScheduleOutcome.partial) {
    retryAt = attempt.add(scheduleContinuationDelay);
  } else {
    retryAt = attempt.add(scheduleRetryInterval);
    final deadline = slot.add(Duration(hours: settings.retryHours));
    if (retryAt.isAfter(deadline)) return next;
  }
  if (next != null && !retryAt.isBefore(next)) return next;
  return retryAt.isAfter(now) ? retryAt : now;
}

/// Whether a run should start now.
bool isRunDue(ScheduleSettings settings, ScheduleStatus status, DateTime now) {
  final at = planNextRun(settings, status, now);
  return at != null && !at.isAfter(now.add(_dueTolerance));
}

DateTime _slotOn(ScheduleSettings settings, int year, int month, int day) =>
    DateTime(year, month, day, settings.hour, settings.minute);
