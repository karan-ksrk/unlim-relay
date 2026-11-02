import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/models/media_enums.dart';
import 'package:lumasync/services/inventory_reconciler.dart';

import '../fixtures/media_fixtures.dart';

void main() {
  final now = DateTime(2026, 11, 2, 12);

  test('new files are inserted as pending', () {
    final changes = reconcileInventory(
      existing: const [],
      scanned: [
        scanned('1'),
        scanned('2', kind: MediaKind.video),
      ],
      now: now,
    );

    expect(changes.added, 2);
    expect(changes.updates, isEmpty);
    expect(changes.inserts.map((c) => c.status.value), [
      TransferStatus.pending,
      TransferStatus.pending,
    ]);
    expect(changes.inserts.first.firstSeenAt.value, now);
    expect(changes.inserts.last.kind.value, MediaKind.video);
  });

  test('unchanged files produce no changes', () {
    final media = scanned('1');
    final changes = reconcileInventory(
      existing: [storedItem(10, media, status: TransferStatus.transferred)],
      scanned: [media],
      now: now,
    );

    expect(changes.isEmpty, isTrue);
  });

  test('changed content resets a transferred file to pending', () {
    final original = scanned('1', size: 1000);
    final edited = scanned('1', size: 2000, modifiedMillis: 2000000);
    final changes = reconcileInventory(
      existing: [
        storedItem(
          10,
          original,
          status: TransferStatus.transferred,
          sha256: 'abc',
          transferredAt: DateTime(2026, 2, 1),
          ackId: 'ack-1',
        ),
      ],
      scanned: [edited],
      now: now,
    );

    expect(changes.changed, 1);
    final update = changes.updates[10]!;
    expect(update.status, const Value(TransferStatus.pending));
    expect(update.sha256, const Value<String?>(null));
    expect(update.transferredAt, const Value<DateTime?>(null));
    expect(update.receiverAcknowledgementId, const Value<String?>(null));
    expect(update.sizeBytes, const Value(2000));
  });

  test('rename without content change keeps the status', () {
    final original = scanned('1', name: 'IMG_1.jpg');
    final renamed = scanned('1', name: 'IMG_1_renamed.jpg');
    final changes = reconcileInventory(
      existing: [storedItem(10, original, status: TransferStatus.transferred)],
      scanned: [renamed],
      now: now,
    );

    expect(changes.changed, 0);
    final update = changes.updates[10]!;
    expect(update.displayName, const Value('IMG_1_renamed.jpg'));
    expect(update.status.present, isFalse);
  });

  test('missing files are marked removed but kept', () {
    final changes = reconcileInventory(
      existing: [storedItem(10, scanned('1'))],
      scanned: const [],
      now: now,
    );

    expect(changes.removed, 1);
    expect(changes.inserts, isEmpty);
    expect(changes.updates[10]!.removedFromLibraryAt, Value<DateTime?>(now));
  });

  test('already removed files are not marked again', () {
    final changes = reconcileInventory(
      existing: [storedItem(10, scanned('1'), removedAt: DateTime(2026, 5))],
      scanned: const [],
      now: now,
    );

    expect(changes.isEmpty, isTrue);
  });

  test('a removed file that reappears is restored', () {
    final media = scanned('1');
    final changes = reconcileInventory(
      existing: [
        storedItem(
          10,
          media,
          status: TransferStatus.transferred,
          removedAt: DateTime(2026, 5),
        ),
      ],
      scanned: [media],
      now: now,
    );

    expect(changes.restored, 1);
    expect(changes.inserts, isEmpty);
    final update = changes.updates[10]!;
    expect(update.removedFromLibraryAt, const Value<DateTime?>(null));
    expect(update.status.present, isFalse);
  });

  test('a re-indexed file keeps its row and status', () {
    final before = scanned('1');
    final after = scanned('99', name: before.displayName);
    final changes = reconcileInventory(
      existing: [storedItem(10, before, status: TransferStatus.transferred)],
      scanned: [after],
      now: now,
    );

    expect(changes.added, 0);
    expect(changes.removed, 0);
    final update = changes.updates[10]!;
    expect(update.sourceMediaId, const Value('99'));
    expect(update.status.present, isFalse);
  });

  test('same name and size but different capture time is a new file', () {
    final changes = reconcileInventory(
      existing: [storedItem(10, scanned('1', takenMillis: 1))],
      scanned: [scanned('2', name: 'IMG_1.jpg', takenMillis: 2)],
      now: now,
    );

    expect(changes.added, 1);
    expect(changes.removed, 1);
  });
}
