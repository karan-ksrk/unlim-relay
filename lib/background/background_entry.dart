import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';

import '../core/logging/app_logger.dart';
import '../data/database/app_database.dart';
import '../data/models/local_device.dart';
import '../data/plugin_adapters/background_scheduler.dart';
import '../data/plugin_adapters/device_info.dart';
import '../data/plugin_adapters/photo_manager_media_library.dart';
import '../data/providers.dart';
import '../data/repositories/settings_repository.dart';
import '../features/schedule/schedule_controller.dart';

final _log = Logger('BackgroundEntry');

/// Set when Android stops the task early; the transfer winds down.
bool _stopRequested = false;
Future<void>? _running;

/// Entry point of the WorkManager engine, a separate Flutter engine with its
/// own isolate and database connection.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(_runTask, onTaskStopped: _onTaskStopped);
}

Future<bool> _runTask(String taskName, Map<String, dynamic>? inputData) async {
  configureLogging();
  final force = inputData?[WorkmanagerBackgroundScheduler.forceKey] == true;
  _stopRequested = false;
  final done = Completer<void>();
  _running = done.future;
  final database = AppDatabase.defaults();
  try {
    final settings = DriftSettingsRepository(database);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        mediaLibraryProvider.overrideWithValue(
          PhotoManagerMediaLibrary(inBackground: true),
        ),
        localDeviceProvider.overrideWithValue(
          LocalDevice(
            id: await settings.deviceId(),
            displayName: await const DeviceInfoPlusSource().displayName(),
          ),
        ),
        scheduledProgressReporterProvider.overrideWithValue(
          (progress) => unawaited(Workmanager().reportProgress(progress)),
        ),
      ],
    );
    try {
      await container
          .read(scheduledTransferJobProvider)
          .run(force: force, stopRequested: () => _stopRequested);
    } finally {
      container.dispose();
    }
  } on Object catch (error, stackTrace) {
    _log.severe('Background task $taskName failed', error, stackTrace);
  } finally {
    await database.close();
    done.complete();
  }
  // Retries are planned by the schedule itself; WorkManager's own retry
  // would start a duplicate run.
  return true;
}

/// Lets the current file finish being cancelled before the engine is torn
/// down; the item goes back to pending.
Future<void> _onTaskStopped(String taskName, StopReason reason) async {
  _log.warning('Background task $taskName stopped by Android: ${reason.name}');
  _stopRequested = true;
  await _running?.timeout(const Duration(seconds: 5), onTimeout: () {});
}
