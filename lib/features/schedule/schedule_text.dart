import 'package:material_ui/material_ui.dart';

import '../../data/models/schedule.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Every day", "Weekdays", "Weekends" or "Mon, Wed, Fri".
String describeWeekdays(Set<int> weekdays) {
  if (weekdays.length == 7) return 'Every day';
  if (weekdays.isEmpty) return 'No days';
  if (weekdays.length == 5 && weekdays.containsAll({1, 2, 3, 4, 5})) {
    return 'Weekdays';
  }
  if (weekdays.length == 2 && weekdays.containsAll({6, 7})) return 'Weekends';
  return [
    for (var day = 1; day <= 7; day++)
      if (weekdays.contains(day)) _dayNames[day - 1],
  ].join(', ');
}

String dayLetter(int isoWeekday) => _dayNames[isoWeekday - 1].substring(0, 1);

String dayName(int isoWeekday) => _dayNames[isoWeekday - 1];

String formatClock(BuildContext context, DateTime at) =>
    TimeOfDay.fromDateTime(at).format(context);

/// "Today", "Tomorrow", "Yesterday" or "Mon 3 Nov".
String relativeDay(DateTime at, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final days = day.difference(today).inHours ~/ 24;
  return switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    _ => '${dayName(at.weekday)} ${at.day} ${_monthNames[at.month - 1]}',
  };
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// One line for the home tile: "Off" or "Every day, around 9:00 PM".
String describeSchedule(BuildContext context, ScheduleSettings settings) {
  if (!settings.enabled) return 'Off';
  final time = TimeOfDay(hour: settings.hour, minute: settings.minute);
  return '${describeWeekdays(settings.weekdays)}, around '
      '${time.format(context)}';
}

/// "Today around 9:00 PM", or "Waiting for Android" once the time passed.
String describeNextRun(BuildContext context, DateTime at, DateTime now) {
  if (!at.isAfter(now.add(const Duration(minutes: 1)))) {
    return 'Due now; starts when Android allows';
  }
  return '${relativeDay(at, now)} around ${formatClock(context, at)}';
}

String describeOutcome(ScheduleOutcome outcome) => switch (outcome) {
  ScheduleOutcome.running => 'Running or interrupted',
  ScheduleOutcome.completed => 'Sent',
  ScheduleOutcome.nothingToSend => 'Nothing to send',
  ScheduleOutcome.limitReached => 'Daily limit reached',
  ScheduleOutcome.partial => 'Continuing',
  ScheduleOutcome.deferred => 'Deferred',
  ScheduleOutcome.failed => 'Stopped',
};

String describeRetry(int hours) => hours == 0
    ? "Don't retry; wait for the next day"
    : 'Every 30 min for up to ${hours == 1 ? '1 hour' : '$hours hours'}';
