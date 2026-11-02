import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/media_enums.dart';
import 'package:lumasync/data/plugin_adapters/media_library.dart';
import 'package:lumasync/data/repositories/media_inventory_repository.dart';
import 'package:lumasync/services/inventory_reconciler.dart';

import '../fixtures/media_fixtures.dart';

void main() {
  late AppDatabase db;
  late DriftMediaInventoryRepository repo;
  final now = DateTime(2026, 11, 2, 12);

  setUp(() {
    db = memoryDatabase();
    repo = DriftMediaInventoryRepository(db);
  });

  tearDown(() => db.close());

  Future<void> insert(List<ScannedMedia> media) => repo.apply(
    reconcileInventory(existing: const [], scanned: media, now: now),
  );

  test('tabs list matching statuses, newest capture first', () async {
    await insert([
      scanned('old', takenMillis: 1000),
      scanned('new', takenMillis: 3000),
      scanned('failed', takenMillis: 2000),
    ]);
    final failedId = (await repo.allItems())
        .firstWhere((i) => i.sourceMediaId == 'failed')
        .id;
    await repo.apply(
      InventoryChanges(
        updates: {
          failedId: const MediaItemsCompanion(
            status: Value(TransferStatus.failed),
            lastError: Value('Receiver unavailable'),
          ),
        },
      ),
    );

    final pending = await repo.watchTab(LibraryTab.pending).first;
    final failed = await repo.watchTab(LibraryTab.failed).first;
    final transferred = await repo.watchTab(LibraryTab.transferred).first;

    expect(pending.map((i) => i.sourceMediaId), ['new', 'old']);
    expect(failed.single.lastError, 'Receiver unavailable');
    expect(transferred, isEmpty);
  });

  test('removed items are hidden from tabs and stats but kept', () async {
    await insert([scanned('1', size: 10), scanned('2', size: 20)]);
    final items = await repo.allItems();

    await repo.apply(
      reconcileInventory(
        existing: items,
        scanned: [scanned('1', size: 10)],
        now: now,
      ),
    );

    final pending = await repo.watchTab(LibraryTab.pending).first;
    final stats = await repo.watchStats().first;
    expect(pending.single.sourceMediaId, '1');
    expect(stats.totalCount, 1);
    expect(stats.totalBytes, 10);
    expect(await repo.allItems(), hasLength(2));
  });

  test('stats stream updates after changes', () async {
    final emitted = <int>[];
    final sub = repo.watchStats().listen((s) => emitted.add(s.totalCount));
    await pumpEventQueue();

    await insert([scanned('1')]);
    await pumpEventQueue();
    await sub.cancel();

    expect(emitted, [0, 1]);
  });
}
