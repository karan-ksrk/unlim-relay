import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'background/background_entry.dart';
import 'core/logging/app_logger.dart';
import 'data/database/app_database.dart';
import 'data/models/local_device.dart';
import 'data/plugin_adapters/background_scheduler.dart';
import 'data/plugin_adapters/device_info.dart';
import 'data/providers.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/transfer_lock_repository.dart';
import 'services/scheduled_transfer_job.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();

  final database = AppDatabase.defaults();
  final settings = DriftSettingsRepository(database);
  final initialRole = await settings.readDeviceRole();
  final localDevice = LocalDevice(
    id: await settings.deviceId(),
    displayName: await const DeviceInfoPlusSource().displayName(),
  );

  await WorkmanagerBackgroundScheduler.initialize(callbackDispatcher);
  // Re-register the daily run on every start (plan §9), e.g. after an app
  // update or a force-stop cleared it.
  unawaited(
    ScheduleCoordinator(
      schedule: DriftScheduleRepository(database),
      scheduler: const WorkmanagerBackgroundScheduler(),
      locks: DriftTransferLockRepository(database),
      settings: settings,
    ).sync().then<void>(
      (_) {},
      onError: (Object e) =>
          Logger('main').warning('Schedule sync on start failed: $e'),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        initialDeviceRoleProvider.overrideWithValue(initialRole),
        localDeviceProvider.overrideWithValue(localDevice),
      ],
      child: const LumaSyncApp(),
    ),
  );
}
