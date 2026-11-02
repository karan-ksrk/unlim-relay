import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/local_device.dart';
import 'package:lumasync/data/plugin_adapters/receiver_keep_alive.dart';
import 'package:lumasync/data/plugin_adapters/screen_wake_lock.dart';
import 'package:lumasync/data/plugin_adapters/service_discovery.dart';
import 'package:lumasync/data/providers.dart';
import 'package:lumasync/data/plugin_adapters/launch_sound.dart';
import 'package:lumasync/features/launch/launch_intro.dart';
import 'package:lumasync/features/schedule/schedule_controller.dart';

import 'fake_schedule_plugins.dart';
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

class FakeReceiverKeepAlive implements ReceiverKeepAlive {
  FakeReceiverKeepAlive({this.available = true});

  /// Whether Android lets the service start.
  bool available;
  bool running = false;

  @override
  Future<bool> start() async => running = available;

  @override
  Future<void> stop() async => running = false;
}

class FakeLaunchSound implements LaunchSound {
  int plays = 0;

  @override
  Future<void> play() async => plays++;
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
  FakeBackgroundScheduler? scheduler,
  FakeTransferNotifications? notifications,
  FakeReceiverKeepAlive? keepAlive,
  FakeScreenWakeLock? wakeLock,
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
  screenWakeLockProvider.overrideWithValue(wakeLock ?? FakeScreenWakeLock()),
  receiverKeepAliveProvider.overrideWithValue(
    keepAlive ?? FakeReceiverKeepAlive(),
  ),
  backgroundSchedulerProvider.overrideWithValue(
    scheduler ?? FakeBackgroundScheduler(),
  ),
  transferNotificationsProvider.overrideWithValue(
    notifications ?? FakeTransferNotifications(),
  ),
  batteryOptimizationProvider.overrideWithValue(FakeBatteryOptimization()),
  backgroundPollIntervalProvider.overrideWithValue(null),
  launchIntroEnabledProvider.overrideWithValue(false),
  launchSoundProvider.overrideWithValue(FakeLaunchSound()),
  stagingDirectoryProvider.overrideWith(
    (ref) async => Directory.systemTemp.createTemp('lumasync_staging_'),
  ),
];
