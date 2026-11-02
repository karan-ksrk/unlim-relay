import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/repositories/settings_repository.dart';

void main() {
  test(
    'v1 database upgrades to the current schema and keeps the role',
    () async {
      // Schema shipped in Milestone 1 builds.
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(
              'CREATE TABLE "app_settings" ("name" TEXT NOT NULL, '
              '"value" TEXT NOT NULL, PRIMARY KEY ("name"));',
            );
            raw.execute(
              "INSERT INTO app_settings VALUES ('device_role', 'sender');",
            );
            raw.execute('PRAGMA user_version = 1;');
          },
        ),
      );
      addTearDown(db.close);

      expect(
        await DriftSettingsRepository(db).readDeviceRole(),
        DeviceRole.sender,
      );
      expect(await db.select(db.mediaItems).get(), isEmpty);
      expect(await db.select(db.pairedDevices).get(), isEmpty);
      expect(await db.select(db.scheduleSettingsTable).get(), isEmpty);
      expect(await db.select(db.transferLocks).get(), isEmpty);

      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name = 'media_items' AND name LIKE 'media_items_%'",
          )
          .map((row) => row.read<String>('name'))
          .get();
      expect(
        indexes,
        unorderedEquals(['media_items_status', 'media_items_source_media_id']),
      );

      final version = await db
          .customSelect('PRAGMA user_version')
          .map((row) => row.read<int>('user_version'))
          .getSingle();
      expect(version, db.schemaVersion);
    },
  );

  test('v2 database gains paired_devices and keeps its inventory', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE "app_settings" ("name" TEXT NOT NULL, '
            '"value" TEXT NOT NULL, PRIMARY KEY ("name"));',
          );
          raw.execute(
            'CREATE TABLE "media_items" ("id" INTEGER NOT NULL PRIMARY KEY '
            'AUTOINCREMENT, "source_media_id" TEXT NOT NULL, "display_name" '
            'TEXT NOT NULL, "mime_type" TEXT NOT NULL, "size_bytes" INTEGER '
            'NOT NULL, "date_taken_millis" INTEGER NULL, '
            '"date_modified_millis" INTEGER NOT NULL, "relative_path" TEXT '
            'NULL, "kind" TEXT NOT NULL, "sha256" TEXT NULL, "status" TEXT '
            'NOT NULL, "first_seen_at" INTEGER NOT NULL, "transferred_at" '
            'INTEGER NULL, "receiver_acknowledgement_id" TEXT NULL, '
            '"last_error" TEXT NULL, "removed_from_library_at" INTEGER NULL);',
          );
          raw.execute(
            "INSERT INTO media_items (source_media_id, display_name, "
            "mime_type, size_bytes, date_modified_millis, kind, status, "
            "first_seen_at) VALUES ('1', 'IMG_1.jpg', 'image/jpeg', 10, 0, "
            "'image', 'pending', 0);",
          );
          raw.execute('PRAGMA user_version = 2;');
        },
      ),
    );
    addTearDown(db.close);

    expect(await db.select(db.mediaItems).get(), hasLength(1));
    expect(await db.select(db.pairedDevices).get(), isEmpty);
    expect(await db.select(db.receivedFiles).get(), isEmpty);
  });
}
