import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/features/pairing/receiver_controller.dart';
import 'package:lumasync/services/transfer_errors.dart';

import '../fixtures/app_overrides.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<ReceiverState> waitForSettled(ProviderContainer container) async {
    for (var i = 0; i < 200; i++) {
      final state = container.read(receiverControllerProvider);
      if (state.phase == ReceiverPhase.ready ||
          state.phase == ReceiverPhase.failed) {
        return state;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return container.read(receiverControllerProvider);
  }

  test('Ready to receive resumes after an app restart', () async {
    final settings = FakeSettingsRepository(DeviceRole.receiver)
      ..receiverReady = true;
    final container = ProviderContainer.test(
      overrides: appOverrides(db: db, settings: settings),
    );

    container.read(receiverControllerProvider);
    final state = await waitForSettled(container);

    expect(state.phase, ReceiverPhase.ready);
    await container.read(receiverControllerProvider.notifier).setReady(false);
    expect(settings.receiverReady, isFalse);
  });

  test('stays off when it was off', () async {
    final container = ProviderContainer.test(
      overrides: appOverrides(
        db: db,
        settings: FakeSettingsRepository(DeviceRole.receiver),
      ),
    );

    container.read(receiverControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(container.read(receiverControllerProvider).phase, ReceiverPhase.off);
  });

  test('turning it on is remembered', () async {
    final settings = FakeSettingsRepository(DeviceRole.receiver);
    final container = ProviderContainer.test(
      overrides: appOverrides(db: db, settings: settings),
    );

    await container.read(receiverControllerProvider.notifier).setReady(true);

    expect(settings.receiverReady, isTrue);
    expect(
      container.read(receiverControllerProvider).phase,
      ReceiverPhase.ready,
    );
    await container.read(receiverControllerProvider.notifier).setReady(false);
  });

  test(
    'Ready to receive runs as a foreground service, not screen-on',
    () async {
      final keepAlive = FakeReceiverKeepAlive();
      final wakeLock = FakeScreenWakeLock();
      final container = ProviderContainer.test(
        overrides: appOverrides(
          db: db,
          settings: FakeSettingsRepository(DeviceRole.receiver),
          keepAlive: keepAlive,
          wakeLock: wakeLock,
        ),
      );
      final controller = container.read(receiverControllerProvider.notifier);

      await controller.setReady(true);

      expect(
        container.read(receiverControllerProvider).runsInBackground,
        isTrue,
      );
      expect(keepAlive.running, isTrue);
      expect(wakeLock.enabled, isFalse);

      await controller.setReady(false);
      expect(keepAlive.running, isFalse);
    },
  );

  test('keeps the screen on when the service cannot start', () async {
    final wakeLock = FakeScreenWakeLock();
    final container = ProviderContainer.test(
      overrides: appOverrides(
        db: db,
        settings: FakeSettingsRepository(DeviceRole.receiver),
        keepAlive: FakeReceiverKeepAlive(available: false),
        wakeLock: wakeLock,
      ),
    );
    final controller = container.read(receiverControllerProvider.notifier);

    await controller.setReady(true);

    final state = container.read(receiverControllerProvider);
    expect(state.phase, ReceiverPhase.ready);
    expect(state.runsInBackground, isFalse);
    expect(wakeLock.enabled, isTrue);

    await controller.setReady(false);
    expect(wakeLock.enabled, isFalse);
  });

  test('a refused connection says to turn on Ready to receive', () async {
    // Bind and release a port so nothing is listening on it.
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();

    Object? error;
    try {
      await Socket.connect(InternetAddress.loopbackIPv4, port);
    } on Object catch (e) {
      error = e;
    }

    expect(
      describeTransferError(error!, host: '192.168.1.20'),
      contains('turn on Ready to receive'),
    );
  });
}
