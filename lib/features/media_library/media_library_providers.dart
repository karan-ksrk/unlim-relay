import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/models/media_enums.dart';
import '../../data/plugin_adapters/media_library.dart';
import '../../data/providers.dart';
import '../../data/repositories/media_inventory_repository.dart';
import '../../services/media_scan_service.dart';

final mediaScanServiceProvider = Provider<MediaScanService>(
  (ref) => MediaScanService(
    library: ref.watch(mediaLibraryProvider),
    inventory: ref.watch(mediaInventoryRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

final inventoryStatsProvider = StreamProvider<InventoryStats>(
  (ref) => ref.watch(mediaInventoryRepositoryProvider).watchStats(),
);

final libraryTabItemsProvider =
    StreamProvider.family<List<MediaItem>, LibraryTab>(
      (ref, tab) => ref.watch(mediaInventoryRepositoryProvider).watchTab(tab),
    );

final lastScanAtProvider = FutureProvider<DateTime?>(
  (ref) => ref.watch(settingsRepositoryProvider).readLastScanAt(),
);

/// Current photo/video access, re-read when the app resumes.
final mediaAccessProvider = FutureProvider<MediaAccess>(
  (ref) => ref.watch(mediaLibraryProvider).currentAccess(),
);

/// Thumbnails load lazily per grid cell and are dropped when off screen.
final thumbnailProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, sourceMediaId) =>
      ref.watch(mediaLibraryProvider).thumbnail(sourceMediaId),
  retry: (retryCount, error) => null,
);
