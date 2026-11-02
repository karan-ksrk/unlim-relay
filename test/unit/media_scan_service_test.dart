import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/media_enums.dart';
import 'package:lumasync/data/repositories/media_inventory_repository.dart';
import 'package:lumasync/services/media_scan_service.dart';

import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;
  late DriftMediaInventoryRepository inventory;
  late FakeMediaLibrary library;
  late FakeSettingsRepository settings;
  late MediaScanService service;
  final now = DateTime(2026, 11, 2, 12);

  setUp(() {
    db = memoryDatabase();
    inventory = DriftMediaInventoryRepository(db);
    library = FakeMediaLibrary(
      media: [
        scanned('1', size: 100),
        scanned('2', size: 200),
        scanned('3', size: 300, kind: MediaKind.video),
      ],
    );
    settings = FakeSettingsRepository();
    service = MediaScanService(
      library: library,
      inventory: inventory,
      settings: settings,
      clock: () => now,
    );
  });

  tearDown(() => db.close());

  test('first scan adds every file as pending', () async {
    final summary = await service.scan();

    expect(summary.scanned, 3);
    expect(summary.added, 3);
    expect(settings.lastScanAt, now);

    final stats = await inventory.watchStats().first;
    expect(stats.photos, 2);
    expect(stats.videos, 1);
    expect(stats.countFor(LibraryTab.pending), 3);
    expect(stats.bytesFor(LibraryTab.pending), 600);
  });

  test('repeated scans do not duplicate rows', () async {
    await service.scan();
    final second = await service.scan();

    expect(second.added, 0);
    expect(second.changed, 0);
    expect(await inventory.allItems(), hasLength(3));
  });

  test('later scans pick up new and deleted files', () async {
    await service.scan();
    library.media = [library.media[0], library.media[1], scanned('4')];

    final summary = await service.scan();

    expect(summary.added, 1);
    expect(summary.removed, 1);
    expect(await inventory.allItems(), hasLength(4));
    final pending = await inventory.watchTab(LibraryTab.pending).first;
    expect(
      pending.map((i) => i.sourceMediaId),
      unorderedEquals(['1', '2', '4']),
    );
  });

  test('progress is reported', () async {
    final progress = <(int, int)>[];
    await service.scan(
      onProgress: (done, total) => progress.add((done, total)),
    );

    expect(progress.last, (3, 3));
  });
}
