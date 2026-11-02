import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database/app_database.dart';
import 'models/device_role.dart';
import 'models/local_device.dart';
import 'plugin_adapters/media_library.dart';
import 'plugin_adapters/media_publisher.dart';
import 'plugin_adapters/photo_manager_media_library.dart';
import 'plugin_adapters/screen_wake_lock.dart';
import 'plugin_adapters/secure_store.dart';
import 'plugin_adapters/service_discovery.dart';
import 'repositories/media_inventory_repository.dart';
import 'repositories/pairing_repository.dart';
import 'repositories/received_files_repository.dart';
import 'repositories/settings_repository.dart';

/// Opened in `main` and injected through `ProviderScope.overrides`.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Role read from storage before the first frame, so the router can pick
/// the start screen without a loading flash.
final initialDeviceRoleProvider = Provider<DeviceRole?>((ref) => null);

final mediaLibraryProvider = Provider<MediaLibrary>(
  (ref) => PhotoManagerMediaLibrary(),
);

final mediaInventoryRepositoryProvider = Provider<MediaInventoryRepository>(
  (ref) => DriftMediaInventoryRepository(ref.watch(appDatabaseProvider)),
);

/// Resolved in `main` before the first frame.
final localDeviceProvider = Provider<LocalDevice>(
  (ref) => throw UnimplementedError('localDeviceProvider must be overridden'),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => const FlutterSecureStore(),
);

final serviceDiscoveryProvider = Provider<ServiceDiscovery>(
  (ref) => BonsoirServiceDiscovery(),
);

final pairingRepositoryProvider = Provider<PairingRepository>(
  (ref) => DriftPairingRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(secureStoreProvider),
  ),
);

final pairedDeviceProvider = StreamProvider<PairedDevice?>(
  (ref) => ref.watch(pairingRepositoryProvider).watchPairedDevice(),
);

final mediaPublisherProvider = Provider<MediaPublisher>(
  (ref) => const PhotoManagerMediaPublisher(),
);

final receivedFilesRepositoryProvider = Provider<ReceivedFilesRepository>(
  (ref) => DriftReceivedFilesRepository(ref.watch(appDatabaseProvider)),
);

final receivedStatsProvider = StreamProvider<ReceivedStats>(
  (ref) => ref.watch(receivedFilesRepositoryProvider).watchStats(),
);

final screenWakeLockProvider = Provider<ScreenWakeLock>(
  (ref) => const WakelockPlusScreenWakeLock(),
);

/// Private staging for incoming files; never visible to the gallery.
final stagingDirectoryProvider = FutureProvider<Directory>((ref) async {
  final support = await getApplicationSupportDirectory();
  return Directory(p.join(support.path, 'incoming'));
});
