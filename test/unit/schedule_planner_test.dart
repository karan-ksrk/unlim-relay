import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/models/schedule.dart';
import 'package:lumasync/services/schedule_planner.dart';

void main() {
  // Monday 2 November 2026.
  DateTime at(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 11, day, hour, minute);

  final daily = ScheduleSettings(enabled: true, enabledAt: at(1, 8));

  ScheduleStatus attempted(DateTime when, ScheduleOutcome outcome) =>
      ScheduleStatus(lastAttemptAt: when, lastOutcome: outcome);

  group('slots', () {
    test('next slot is later today when the time has not passed', () {
      expect(nextSlotAfter(daily, at(2, 12)), at(2, 21));
    });

    test('next slot is tomorrow once the time has passed', () {
      expect(nextSlotAfter(daily, at(2, 21)), at(3, 21));
    });

    test('weekdays skip to the next enabled day', () {
      // Monday only; from Monday night the next run is next Monday.
      final mondays = daily.copyWith(weekdays: {1});
      expect(nextSlotAfter(mondays, at(2, 22)), at(9, 21));
      expect(latestSlot(mondays, at(8, 12)), at(2, 21));
    });

    test('crosses month ends', () {
      expect(
        nextSlotAfter(daily, DateTime(2026, 11, 30, 22)),
        DateTime(2026, 12, 1, 21),
      );
    });
  });

  group('planNextRun', () {
    test('is null when the schedule is off or has no days', () {
      expect(
        planNextRun(const ScheduleSettings(), ScheduleStatus.none, at(2, 12)),
        isNull,
      );
      expect(
        planNextRun(
          daily.copyWith(weekdays: {}),
          ScheduleStatus.none,
          at(2, 12),
        ),
        isNull,
      );
    });

    test('waits for today\'s time', () {
      final status = attempted(at(1, 21), ScheduleOutcome.completed);
      expect(planNextRun(daily, status, at(2, 12)), at(2, 21));
    });

    test('a missed time is due right away', () {
      final status = attempted(at(1, 21), ScheduleOutcome.completed);
      final now = at(2, 23);
      expect(planNextRun(daily, status, now), now);
      expect(isRunDue(daily, status, now), isTrue);
    });

    test('a missed time is still caught up the next morning', () {
      final status = attempted(at(1, 21), ScheduleOutcome.completed);
      final now = at(3, 7);
      expect(planNextRun(daily, status, now), now);
    });

    test('turning it on after today\'s time waits for tomorrow', () {
      final settings = daily.copyWith(enabledAt: at(2, 22));
      expect(
        planNextRun(settings, ScheduleStatus.none, at(2, 22, 5)),
        at(3, 21),
      );
      expect(isRunDue(settings, ScheduleStatus.none, at(2, 22, 5)), isFalse);
    });

    test('a finished run waits for the next day', () {
      for (final outcome in [
        ScheduleOutcome.completed,
        ScheduleOutcome.nothingToSend,
        ScheduleOutcome.limitReached,
      ]) {
        final status = attempted(at(2, 21, 2), outcome);
        expect(
          planNextRun(daily, status, at(2, 21, 10)),
          at(3, 21),
          reason: outcome.name,
        );
      }
    });

    test('a deferred run retries every 30 minutes', () {
      final status = attempted(at(2, 21, 2), ScheduleOutcome.deferred);
      expect(planNextRun(daily, status, at(2, 21, 3)), at(2, 21, 32));
      expect(isRunDue(daily, status, at(2, 21, 3)), isFalse);
      expect(isRunDue(daily, status, at(2, 21, 32)), isTrue);
    });

    test('retries stop after the retry window', () {
      // Window is 3 hours after 9 PM; a retry at 00:10 would be past it.
      final status = attempted(at(2, 23, 40), ScheduleOutcome.failed);
      expect(planNextRun(daily, status, at(2, 23, 41)), at(3, 21));
    });

    test('no retries when the window is 0', () {
      final settings = daily.copyWith(retryHours: 0);
      final status = attempted(at(2, 21, 2), ScheduleOutcome.deferred);
      expect(planNextRun(settings, status, at(2, 21, 3)), at(3, 21));
    });

    test('a retry that is overdue runs now', () {
      final status = attempted(at(2, 21, 2), ScheduleOutcome.deferred);
      final now = at(2, 22, 30);
      expect(planNextRun(daily, status, now), now);
    });

    test('a killed run counts as retryable', () {
      final status = attempted(at(2, 21, 2), ScheduleOutcome.running);
      expect(planNextRun(daily, status, at(2, 21, 20)), at(2, 21, 32));
    });

    test('a run out of time continues a minute later, past the window', () {
      final settings = daily.copyWith(retryHours: 0);
      final status = attempted(at(2, 21, 9), ScheduleOutcome.partial);
      expect(planNextRun(settings, status, at(2, 21, 9)), at(2, 21, 10));
    });

    test('a continuation never goes past the next scheduled time', () {
      // A run for the 2 Nov slot still going just before the 3 Nov slot.
      final status = attempted(
        DateTime(2026, 11, 3, 20, 59, 30),
        ScheduleOutcome.partial,
      );
      expect(
        planNextRun(daily, status, DateTime(2026, 11, 3, 20, 59, 31)),
        at(3, 21),
      );
    });
  });
}
