import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/device_role.dart';
import '../models/media_enums.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [AppSettings, MediaItems, PairedDevices, ReceivedFiles])
class AppDatabase extends _$AppDatabase {
  /// Opens a database on [executor]; tests pass an in-memory executor.
  AppDatabase(super.executor);

  /// Opens the on-device database file.
  AppDatabase.defaults() : super(driftDatabase(name: 'lumasync'));

  /// v1: app_settings. v2: media_items. v3: paired_devices.
  /// v4: received_files.
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(mediaItems);
        await m.createIndex(mediaItemsStatus);
        await m.createIndex(mediaItemsSourceMediaId);
      }
      if (from < 3) {
        await m.createTable(pairedDevices);
      }
      if (from < 4) {
        await m.createTable(receivedFiles);
        await m.createIndex(receivedFilesTransferId);
        await m.createIndex(receivedFilesSha256);
      }
    },
  );
}
