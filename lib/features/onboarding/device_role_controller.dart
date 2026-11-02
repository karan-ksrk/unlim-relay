import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/models/device_role.dart';
import '../../data/providers.dart';
import '../schedule/schedule_controller.dart';

final deviceRoleProvider = NotifierProvider<DeviceRoleController, DeviceRole?>(
  DeviceRoleController.new,
);

/// Holds the selected role; `null` means onboarding is not finished.
class DeviceRoleController extends Notifier<DeviceRole?> {
  static final _log = Logger('DeviceRoleController');

  @override
  DeviceRole? build() => ref.watch(initialDeviceRoleProvider);

  Future<void> select(DeviceRole role) async {
    await ref.read(settingsRepositoryProvider).saveDeviceRole(role);
    _log.info('Device role set to ${role.name}');
    state = role;
    _syncSchedule();
  }

  Future<void> reset() async {
    await ref.read(settingsRepositoryProvider).clearDeviceRole();
    _log.info('Device role cleared');
    state = null;
    _syncSchedule();
  }

  /// Only the sender runs the daily transfer.
  void _syncSchedule() => unawaited(
    Future(() => ref.read(scheduleCoordinatorProvider).sync()).then<void>(
      (_) {},
      onError: (Object e) => _log.warning('Schedule sync failed: $e'),
    ),
  );
}
