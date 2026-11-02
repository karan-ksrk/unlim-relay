import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/models/schedule.dart';
import 'package:lumasync/data/plugin_adapters/media_library.dart';
import 'package:lumasync/data/repositories/media_inventory_repository.dart';
import 'package:lumasync/data/repositories/pairing_repository.dart';
import 'package:lumasync/data/repositories/schedule_repository.dart';
import 'package:lumasync/data/repositories/transfer_lock_repository.dart';
import 'package:lumasync/services/media_scan_service.dart';
import 'package:lumasync/services/scheduled_transfer_job.dart';
import 'package:lumasync/services/transfer_orchestrator.dart';

import '../fixtures/fake_schedule_plugins.dart';
import '../fixtures/fake_secure_store.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

typedef RunScript = Future<TransferSummary> Function(
  void Function(TransferProgress)? onProgress,
  bool Function()? isCancelled,
);

class FakeOrchestrator implements TransferOrchestrator {
  RunScript script = (_, _) async => const TransferSummary(delivered: 3);
  final triggers = <TransferTrigger>[];

  @override
  Future<TransferSummary> run({
    TransferTrigger trigger = TransferTrigger.manual,
    Set<int>? itemIds,
    bool extraBatch = false,
    void Function(TransferProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) {
    triggers.add(trigger);
    return script(onProgress, isCancelled);
  }
}

void main() {
  // Monday 2 November 2026; the schedule is 9 PM every day.
  DateTime at(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 11, day, hour, minute);

  late AppDatabase db;
  late DriftScheduleRepository schedule;
  late DriftTransferLockRepository locks;
  late FakeSettingsRepository settings;
  late DriftPairingRepository pairing;
  late FakeMediaLibrary library;
  late FakeOrchestrator orchestrator;
  late FakeBackgroundScheduler scheduler;
  late FakeTransferNotifications notifications;
  late List<Map<String, dynamic>> progress;
  late DateTime now;
  late ScheduledTransferJob job;

  Future<void> pair() => pairing.savePairing(
    PairedDevice(
      deviceId: 'r1',
      displayName: 'Redmi Note 7 Pro',
      peerRole: DeviceRole.receiver,
      certificateFingerprint: 'ab' * 32,
      pairedAt: at(1, 12),
    ),
    authToken: 'token',
  );

  setUp(() async {
    db = memoryDatabase();
    schedule = DriftScheduleRepository(db);
    locks = DriftTransferLockRepository(db);
    settings = FakeSettingsRepository(DeviceRole.sender);
    pairing = DriftPairingRepository(db, FakeSecureStore());
    library = FakeMediaLibrary(media: [scanned('1'), scanned('2')]);
    orchestrator = FakeOrchestrator();
    scheduler = FakeBackgroundScheduler();
    notifications = FakeTransferNotifications();
    progress = [];
    now = at(2, 21, 1);
    DateTime clock() => now;

    final coordinator = ScheduleCoordinator(
      schedule: schedule,
      scheduler: scheduler,
      locks: locks,
      settings: settings,
      clock: clock,
    );
    job = ScheduledTransferJob(
      schedule: schedule,
      coordinator: coordinator,
      locks: locks,
      settings: settings,
      pairing: pairing,
      library: library,
      scanner: MediaScanService(
        library: library,
        inventory: DriftMediaInventoryRepository(db),
        settings: settings,
        clock: clock,
      ),
      orchestrator: orchestrator,
      notifications: notifications,
      reportProgress: progress.add,
      clock: clock,
    );

    // Turned on this morning, so yesterday's 9 PM is not caught up.
    await schedule.saveSettings(
      ScheduleSettings(enabled: true, enabledAt: at(2, 8)),
    );
    await pair();
  });

  tearDown(() => db.close());

  test('a due run scans, sends, records success and plans tomorrow', () async {
    orchestrator.script = (onProgress, _) async {
      onProgress?.call(
        const TransferProgress(
          totalFiles: 3,
          totalBytes: 3000,
          fileIndex: 0,
          delivered: 0,
          alreadyPresent: 0,
          failed: 0,
          sentBytes: 500,
          bytesPerSecond: 0,
          currentFileName: 'IMG_1.jpg',
        ),
      );
      return const TransferSummary(delivered: 3, deferredPhotos: 2);
    };

    final outcome = await job.run();

    expect(outcome, ScheduleOutcome.completed);
    expect(library.listCalls, 1, reason: 'rescans before sending');
    expect(orchestrator.triggers, [TransferTrigger.scheduled]);
    expect(progress.single[ScheduledProgress.fileName], 'IMG_1.jpg');

    final status = await schedule.readStatus();
    expect(status.lastAttemptAt, now);
    expect(status.lastOutcome, ScheduleOutcome.completed);
    expect(status.lastSuccessAt, now);
    expect(status.lastMessage, contains('2 files wait'));
    expect(status.nextRunEstimate, at(3, 21));
    expect(scheduler.scheduledAt, at(3, 21));

    expect(notifications.shown.single.$1, 'Sent 3 files to Redmi Note 7 Pro');
    expect(await locks.holder(now: now), isNull, reason: 'lock released');
  });

  test('a run started a moment early counts for its slot', () async {
    now = DateTime(2026, 11, 2, 20, 59, 59);

    expect(await job.run(), ScheduleOutcome.completed);

    expect((await schedule.readStatus()).lastAttemptAt, at(2, 21));
    expect(scheduler.scheduledAt, at(3, 21), reason: 'not repeated at 9 PM');
  });

  test('before the scheduled time it only re-registers', () async {
    now = at(2, 15);

    expect(await job.run(), isNull);

    expect(orchestrator.triggers, isEmpty);
    expect((await schedule.readStatus()).lastAttemptAt, isNull);
    expect(scheduler.scheduledAt, at(2, 21));
    expect(notifications.shown, isEmpty);
  });

  test('Run now ignores the time', () async {
    now = at(2, 15);

    expect(await job.run(force: true), ScheduleOutcome.completed);
    // The 9 PM run still happens: it was attempted before that slot.
    expect(scheduler.scheduledAt, at(2, 21));
  });

  test('an unreachable receiver defers and retries in 30 minutes', () async {
    orchestrator.script = (_, _) async =>
        throw const SocketException('No route to host');

    final outcome = await job.run();

    expect(outcome, ScheduleOutcome.deferred);
    final status = await schedule.readStatus();
    expect(status.lastMessage, contains('Could not reach the receiver'));
    expect(status.lastSuccessAt, isNull);
    expect(scheduler.scheduledAt, at(2, 21, 31));
    expect(notifications.shown.single.$1, 'Daily transfer deferred');
    expect(
      notifications.shown.single.$2,
      contains('Trying again around 9:31 PM'),
    );
  });

  test('without a pairing nothing is attempted', () async {
    await pairing.revokePairing();

    expect(await job.run(), ScheduleOutcome.deferred);
    expect(orchestrator.triggers, isEmpty);
    expect(
      (await schedule.readStatus()).lastMessage,
      'Not paired with a receiver.',
    );
  });

  test('without photo access nothing is attempted', () async {
    library.access = MediaAccess.denied;

    expect(await job.run(), ScheduleOutcome.deferred);
    expect(orchestrator.triggers, isEmpty);
  });

  test('a manual transfer in progress defers the run', () async {
    await locks.tryAcquire(TransferLockOwner.app, now: now);

    expect(await job.run(), ScheduleOutcome.deferred);
    expect(orchestrator.triggers, isEmpty);
    expect(
      await locks.holder(now: now),
      TransferLockOwner.app,
      reason: "the app's lock is left alone",
    );
  });

  test(
    'a run out of time continues a minute later without a notification',
    () async {
      orchestrator.script = (_, isCancelled) async {
        now = now.add(ScheduledTransferJob.defaultBudget);
        expect(isCancelled!(), isTrue);
        return const TransferSummary(delivered: 40, cancelled: true);
      };

      expect(await job.run(), ScheduleOutcome.partial);
      expect(scheduler.scheduledAt, now);
      expect(notifications.shown, isEmpty);
    },
  );

  test('a used-up limit finishes for the day', () async {
    orchestrator.script = (_, _) async =>
        const TransferSummary(deferredPhotos: 12, deferredVideos: 1);

    expect(await job.run(), ScheduleOutcome.limitReached);
    expect(scheduler.scheduledAt, at(3, 21));
    expect(
      (await schedule.readStatus()).lastMessage,
      contains('13 files waiting'),
    );
  });

  test('a dropped connection is recorded as stopped and retried', () async {
    orchestrator.script = (_, _) async => const TransferSummary(
      delivered: 2,
      failed: 1,
      error: 'Could not reach the receiver.',
    );

    expect(await job.run(), ScheduleOutcome.failed);
    expect(
      (await schedule.readStatus()).lastMessage,
      'Sent 2 files, then: Could not reach the receiver.',
    );
    expect(scheduler.scheduledAt, at(2, 21, 31));
  });

  group('ScheduleCoordinator', () {
    late ScheduleCoordinator coordinator;

    setUp(() {
      coordinator = ScheduleCoordinator(
        schedule: schedule,
        scheduler: scheduler,
        locks: locks,
        settings: settings,
        clock: () => now,
      );
      now = at(2, 12);
    });

    test('registers the next run and records the estimate', () async {
      expect(await coordinator.sync(), at(2, 21));
      expect(scheduler.scheduledAt, at(2, 21));
      expect(scheduler.scheduledWith?.wifiOnly, isTrue);
    });

    test('cancels when turned off or on the receiver', () async {
      await coordinator.sync();
      await schedule.saveSettings(const ScheduleSettings());
      expect(await coordinator.sync(), isNull);
      expect(scheduler.scheduledAt, isNull);

      await schedule.saveSettings(
        ScheduleSettings(enabled: true, enabledAt: at(1, 8)),
      );
      settings.role = DeviceRole.receiver;
      expect(await coordinator.sync(), isNull);
      expect(scheduler.scheduledAt, isNull);
    });

    test('leaves a running scheduled run alone', () async {
      await schedule.recordNextRunEstimate(at(2, 11));
      await locks.tryAcquire(TransferLockOwner.schedule, now: now);

      expect(await coordinator.sync(), at(2, 11));
      expect(scheduler.scheduledAt, isNull, reason: 'nothing replaced');
    });
  });
}
