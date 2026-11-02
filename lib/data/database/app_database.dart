import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/device_role.dart';
import '../models/media_enums.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AppSettings,
    MediaItems,
    PairedDevices,
    ReceivedFiles,
    ScheduleSettingsTable,
    TransferLocks,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens a database on [executor]; tests pass an in-memory executor.
  AppDatabase(super.executor);

  /// Opens the on-device database file.
  ///
  /// The scheduled transfer runs in a second Flutter engine with its own
  /// connection to this file, so WAL lets readers continue during writes
  /// and the busy timeout waits out the other engine's write lock.
  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'lumasync',
          native: DriftNativeOptions(
            setup: (db) {
              db.execute('PRAGMA journal_mode = WAL;');
              db.execute('PRAGMA busy_timeout = 10000;');
            },
          ),
        ),
      );

  /// v1: app_settings. v2: media_items. v3: paired_devices.
  /// v4: received_files. v5: schedule_settings, transfer_locks.
  /// v6: media_items.deleted_at.
  @override
  int get schemaVersion => 6;

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
      if (from < 5) {
        await m.createTable(scheduleSettingsTable);
        await m.createTable(transferLocks);
      }
      // A v1 database got media_items with every column in step 2.
      if (from >= 2 && from < 6) {
        await m.addColumn(mediaItems, mediaItems.deletedAt);
      }
    },
  );
}
