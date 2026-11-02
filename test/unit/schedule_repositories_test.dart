import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/schedule.dart';
import 'package:lumasync/data/repositories/schedule_repository.dart';
import 'package:lumasync/data/repositories/transfer_lock_repository.dart';

import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  group('DriftScheduleRepository', () {
    test('defaults to off at 9 PM every day', () async {
      final settings = await DriftScheduleRepository(db).readSettings();

      expect(settings, const ScheduleSettings());
      expect(settings.enabled, isFalse);
      expect(settings.weekdays, ScheduleSettings.everyDay);
    });

    test('round-trips settings', () async {
      final repository = DriftScheduleRepository(db);
      final saved = ScheduleSettings(
        enabled: true,
        hour: 6,
        minute: 45,
        weekdays: {1, 3, 5},
        wifiOnly: false,
        chargingOnly: true,
        retryHours: 6,
        enabledAt: DateTime(2026, 11, 2, 10),
      );

      await repository.saveSettings(saved);

      expect(await repository.readSettings(), saved);
    });

    test('records attempts and outcomes without touching settings', () async {
      final repository = DriftScheduleRepository(db);
      await repository.saveSettings(const ScheduleSettings(enabled: true));
      final started = DateTime(2026, 11, 2, 21, 1);

      await repository.recordAttempt(started);
      expect(
        (await repository.readStatus()).lastOutcome,
        ScheduleOutcome.running,
      );

      await repository.recordOutcome(
        ScheduleOutcome.completed,
        message: 'All caught up.',
        successAt: started,
      );
      await repository.recordNextRunEstimate(DateTime(2026, 11, 3, 21));
      // A later failure keeps the last success.
      await repository.recordAttempt(started.add(const Duration(days: 1)));
      await repository.recordOutcome(ScheduleOutcome.deferred, message: 'x');

      final status = await repository.readStatus();
      expect(status.lastOutcome, ScheduleOutcome.deferred);
      expect(status.lastMessage, 'x');
      expect(status.lastSuccessAt, started);
      expect(status.nextRunEstimate, DateTime(2026, 11, 3, 21));
      expect((await repository.readSettings()).enabled, isTrue);
    });

    test('watch emits changes', () async {
      final repository = DriftScheduleRepository(db);
      final emitted = repository.watch().map((e) => e.$1.enabled).distinct();

      expect(emitted, emitsInOrder([false, true]));
      await Future<void>.delayed(Duration.zero);
      await repository.saveSettings(const ScheduleSettings(enabled: true));
    });
  });

  group('DriftTransferLockRepository', () {
    final now = DateTime(2026, 11, 2, 21);

    test('only one holder at a time', () async {
      final locks = DriftTransferLockRepository(db);

      expect(
        await locks.tryAcquire(TransferLockOwner.schedule, now: now),
        isTrue,
      );
      expect(await locks.tryAcquire(TransferLockOwner.app, now: now), isFalse);
      expect(await locks.holder(now: now), TransferLockOwner.schedule);

      await locks.release(TransferLockOwner.app);
      expect(
        await locks.holder(now: now),
        TransferLockOwner.schedule,
        reason: 'only the holder can release',
      );

      await locks.release(TransferLockOwner.schedule);
      expect(await locks.tryAcquire(TransferLockOwner.app, now: now), isTrue);
    });

    test('an expired lease can be taken over; renewal keeps it', () async {
      final locks = DriftTransferLockRepository(db);
      await locks.tryAcquire(TransferLockOwner.schedule, now: now);

      final later = now.add(const Duration(minutes: 1));
      await locks.renew(TransferLockOwner.schedule, now: later);
      final beforeExpiry = later.add(const Duration(minutes: 1, seconds: 59));
      expect(
        await locks.tryAcquire(TransferLockOwner.app, now: beforeExpiry),
        isFalse,
      );

      final afterExpiry = later.add(DriftTransferLockRepository.ttl);
      expect(await locks.holder(now: afterExpiry), isNull);
      expect(
        await locks.tryAcquire(TransferLockOwner.app, now: afterExpiry),
        isTrue,
      );
    });

    test('whileHolding releases after errors and reports the holder', () async {
      final locks = DriftTransferLockRepository(db);

      await expectLater(
        locks.whileHolding(
          TransferLockOwner.app,
          () async => throw StateError('boom'),
        ),
        throwsStateError,
      );
      expect(await locks.holder(now: DateTime.now()), isNull);

      await locks.tryAcquire(TransferLockOwner.schedule, now: DateTime.now());
      await expectLater(
        locks.whileHolding(TransferLockOwner.app, () async => 1),
        throwsA(
          isA<TransferBusyException>().having(
            (e) => e.holder,
            'holder',
            TransferLockOwner.schedule,
          ),
        ),
      );
    });
  });
}
