import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/media_enums.dart';
import 'package:lumasync/data/repositories/media_inventory_repository.dart';
import 'package:lumasync/services/inventory_reconciler.dart';
import 'package:lumasync/services/media_cleanup_service.dart';

import '../fixtures/media_fixtures.dart';

void main() {
  final now = DateTime(2026, 11, 3, 10);
  late AppDatabase db;
  late DriftMediaInventoryRepository inventory;
  late FakeMediaLibrary library;
  late MediaCleanupService service;

  /// Scans [library] into the inventory and returns row ids by media id.
  Future<Map<String, int>> scanIn() async {
    await inventory.apply(
      reconcileInventory(
        existing: await inventory.allItems(),
        scanned: library.media,
        now: now,
      ),
    );
    return {
      for (final item in await inventory.allItems())
        item.sourceMediaId: item.id,
    };
  }

  setUp(() {
    db = memoryDatabase();
    inventory = DriftMediaInventoryRepository(db);
    library = FakeMediaLibrary(
      media: [scanned('1', size: 100), scanned('2', size: 200), scanned('3')],
    );
    service = MediaCleanupService(
      inventory: inventory,
      library: library,
      clock: () => now,
    );
  });

  tearDown(() => db.close());

  test('only verified, unchanged files are deletable', () async {
    final ids = await scanIn();
    await inventory.markTransferred(
      ids['1']!,
      sha256: 'a',
      acknowledgementId: 'ack-1',
      at: now,
    );
    await inventory.markTransferred(
      ids['2']!,
      sha256: 'b',
      acknowledgementId: 'ack-2',
      at: now,
    );
    // File 2 was edited after its transfer; file 3 was never sent.
    library.media[1] = scanned('2', size: 999, modifiedMillis: 2000000);

    final review = await service.review(ids.values.toSet());

    expect(review.deletable.map((i) => i.sourceMediaId), ['1']);
    expect(review.bytes, 100);
    expect(
      {for (final (item, reason) in review.held) item.sourceMediaId: reason},
      {'2': contains('Changed since'), '3': contains('Not verified')},
    );
  });

  test(
    'deleting leaves tombstones that a lagging scan cannot revive',
    () async {
      final ids = await scanIn();
      await inventory.markTransferred(
        ids['1']!,
        sha256: 'a',
        acknowledgementId: 'ack-1',
        at: now,
      );

      final result = await service.delete(await service.review({ids['1']!}));

      expect(result.deleted, 1);
      expect(result.bytes, 100);
      expect(library.deleted, ['1']);
      final row = (await inventory.itemsByIds({ids['1']!})).single;
      expect(row.deletedAt, now);
      expect(row.status, TransferStatus.transferred);
      expect(await inventory.watchDeleted().first, (files: 1, bytes: 100));

      // The media index still lists the deleted file for a while.
      library.media.add(scanned('1', size: 100));
      final changes = reconcileInventory(
        existing: await inventory.allItems(),
        scanned: library.media,
        now: now,
      );
      expect(changes.added, 0);
      expect(changes.restored, 0);
      expect(changes.updates.containsKey(ids['1']), isFalse);
      final pending = await inventory.watchTab(LibraryTab.pending).first;
      expect(pending.map((i) => i.sourceMediaId), isNot(contains('1')));
    },
  );

  test('declining Android\'s prompt deletes and records nothing', () async {
    final ids = await scanIn();
    await inventory.markTransferred(
      ids['1']!,
      sha256: 'a',
      acknowledgementId: 'ack-1',
      at: now,
    );
    library.declineDeletes = true;

    final result = await service.delete(await service.review({ids['1']!}));

    expect(result.declined, isTrue);
    expect(result.deleted, 0);
    expect((await inventory.itemsByIds({ids['1']!})).single.deletedAt, isNull);
    expect(await inventory.watchDeleted().first, (files: 0, bytes: 0));
  });

  test('a file already gone is held, not deleted', () async {
    final ids = await scanIn();
    await inventory.markTransferred(
      ids['1']!,
      sha256: 'a',
      acknowledgementId: 'ack-1',
      at: now,
    );
    library.media.removeAt(0);

    final review = await service.review({ids['1']!});

    expect(review.deletable, isEmpty);
    expect(review.held.single.$2, contains('No longer on this phone'));
  });
}
