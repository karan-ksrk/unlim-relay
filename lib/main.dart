import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/logging/app_logger.dart';
import 'data/database/app_database.dart';
import 'data/models/local_device.dart';
import 'data/plugin_adapters/device_info.dart';
import 'data/providers.dart';
import 'data/repositories/settings_repository.dart';

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
