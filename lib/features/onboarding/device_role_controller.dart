import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/models/device_role.dart';
import '../../data/providers.dart';

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
  }

  Future<void> reset() async {
    await ref.read(settingsRepositoryProvider).clearDeviceRole();
    _log.info('Device role cleared');
    state = null;
  }
}
