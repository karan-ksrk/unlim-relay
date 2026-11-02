import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/local_device.dart';
import 'package:lumasync/data/plugin_adapters/screen_wake_lock.dart';
import 'package:lumasync/data/plugin_adapters/service_discovery.dart';
import 'package:lumasync/data/providers.dart';

import 'fake_secure_store.dart';
import 'fake_settings_repository.dart';
import 'media_fixtures.dart';

class FakeScreenWakeLock implements ScreenWakeLock {
  bool enabled = false;

  @override
  Future<void> enable() async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;
}

class FakeServiceDiscovery implements ServiceDiscovery {
  DiscoveredReceiver? receiver;
  int advertised = 0;

  @override
  Future<void> advertise({
    required String deviceId,
    required String name,
    required int port,
  }) async => advertised++;

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<DiscoveredReceiver?> find(
    String deviceId, {
    Duration timeout = const Duration(seconds: 6),
  }) async => receiver;
}

/// Provider overrides for pumping the whole app in widget tests.
List<Override> appOverrides({
  required AppDatabase db,
  required FakeSettingsRepository settings,
  FakeMediaLibrary? library,
}) => [
  appDatabaseProvider.overrideWithValue(db),
  settingsRepositoryProvider.overrideWithValue(settings),
  initialDeviceRoleProvider.overrideWithValue(settings.role),
  localDeviceProvider.overrideWithValue(
    const LocalDevice(id: 'test-device-id', displayName: 'Test Phone'),
  ),
  mediaLibraryProvider.overrideWithValue(library ?? FakeMediaLibrary()),
  secureStoreProvider.overrideWithValue(FakeSecureStore()),
  serviceDiscoveryProvider.overrideWithValue(FakeServiceDiscovery()),
  screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
  stagingDirectoryProvider.overrideWith(
    (ref) async => Directory.systemTemp.createTemp('lumasync_staging_'),
  ),
];
