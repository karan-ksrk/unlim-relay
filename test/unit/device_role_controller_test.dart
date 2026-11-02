import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/providers.dart';
import 'package:lumasync/features/onboarding/device_role_controller.dart';

import '../fixtures/fake_settings_repository.dart';

void main() {
  ProviderContainer createContainer(FakeSettingsRepository repo) =>
      ProviderContainer.test(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          initialDeviceRoleProvider.overrideWithValue(repo.role),
        ],
      );

  test('starts with no role on a fresh install', () {
    final container = createContainer(FakeSettingsRepository());

    expect(container.read(deviceRoleProvider), isNull);
  });

  test('starts with the stored role', () {
    final container = createContainer(
      FakeSettingsRepository(DeviceRole.receiver),
    );

    expect(container.read(deviceRoleProvider), DeviceRole.receiver);
  });

  test('select persists the role and updates state', () async {
    final repo = FakeSettingsRepository();
    final container = createContainer(repo);

    await container.read(deviceRoleProvider.notifier).select(DeviceRole.sender);

    expect(container.read(deviceRoleProvider), DeviceRole.sender);
    expect(repo.role, DeviceRole.sender);
  });

  test('reset clears the stored role', () async {
    final repo = FakeSettingsRepository(DeviceRole.sender);
    final container = createContainer(repo);

    await container.read(deviceRoleProvider.notifier).reset();

    expect(container.read(deviceRoleProvider), isNull);
    expect(repo.role, isNull);
  });

  test('DeviceRole.tryParse ignores unknown values', () {
    expect(DeviceRole.tryParse('sender'), DeviceRole.sender);
    expect(DeviceRole.tryParse('receiver'), DeviceRole.receiver);
    expect(DeviceRole.tryParse('bogus'), isNull);
    expect(DeviceRole.tryParse(null), isNull);
  });
}
