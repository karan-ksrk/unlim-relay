import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/core/utils/streaming_sha256.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/media_enums.dart';
import 'package:lumasync/data/models/transfer_limits.dart';
import 'package:lumasync/data/plugin_adapters/media_library.dart';
import 'package:lumasync/data/repositories/media_inventory_repository.dart';
import 'package:lumasync/data/repositories/pairing_repository.dart';
import 'package:lumasync/data/repositories/received_files_repository.dart';
import 'package:lumasync/services/inventory_reconciler.dart';
import 'package:lumasync/services/protocol/messages.dart';
import 'package:lumasync/services/receiver_locator.dart';
import 'package:lumasync/services/receiver_server.dart';
import 'package:lumasync/services/receiver_storage_service.dart';
import 'package:lumasync/services/sender_client.dart';
import 'package:lumasync/services/tls_identity.dart';
import 'package:lumasync/services/transfer_orchestrator.dart';
import 'package:path/path.dart' as p;

import '../fixtures/app_overrides.dart';
import '../fixtures/fake_media_publisher.dart';
import '../fixtures/fake_secure_store.dart';
import '../fixtures/fake_settings_repository.dart';
import '../fixtures/media_fixtures.dart';

/// Sender and receiver talking real TLS over loopback, with real Drift
/// inventories and files on disk.
void main() {
  late TlsIdentity identity;
  late Directory temp;
  late AppDatabase senderDb;
  late AppDatabase receiverDb;
  late ReceiverServer server;
  late FakeMediaPublisher publisher;
  late DriftMediaInventoryRepository inventory;
  late FakeMediaLibrary library;
  late FakeSettingsRepository settings;
  late SenderClient client;
  late TransferOrchestrator orchestrator;
  late Directory staging;
  late DriftPairingRepository senderPairing;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    identity = await TlsIdentity.generate('LumaSync test receiver');
  });

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('lumasync_transfer_');
    senderDb = memoryDatabase();
    receiverDb = memoryDatabase();
    staging = Directory(p.join(temp.path, 'staging'));
    publisher = FakeMediaPublisher(Directory(p.join(temp.path, 'DCIM')));

    server = ReceiverServer(
      identity: identity,
      deviceId: 'receiver-1',
      displayName: 'Test Receiver',
      pairing: DriftPairingRepository(receiverDb, FakeSecureStore()),
      approvePairing: (_) async => true,
      storage: ReceiverStorageService(
        stagingDirectory: staging,
        publisher: publisher,
        received: DriftReceivedFilesRepository(receiverDb),
      ),
    );
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);

    client = SenderClient(deviceId: 'sender-1', displayName: 'Test Sender');
    senderPairing = DriftPairingRepository(senderDb, FakeSecureStore());
    final paired = await client.pair(
      server.createInvite('127.0.0.1'),
      now: DateTime(2026, 11, 2),
    );
    await senderPairing.savePairing(
      paired.receiver,
      authToken: paired.authToken,
    );

    inventory = DriftMediaInventoryRepository(senderDb);
    library = FakeMediaLibrary();
    settings = FakeSettingsRepository()
      ..limits = const TransferLimits(photosPerDay: null, videosPerDay: null);
    orchestrator = TransferOrchestrator(
      inventory: inventory,
      settings: settings,
      library: library,
      locator: ReceiverLocator(senderPairing, FakeServiceDiscovery()),
      client: client,
    );
  });

  tearDown(() async {
    await server.stop();
    await senderDb.close();
    await receiverDb.close();
    await temp.delete(recursive: true);
  });

  /// Writes a random file and adds it to the sender inventory as pending.
  Future<File> addSource(
    String id,
    int size, {
    MediaKind kind = MediaKind.image,
    int takenMillis = 1793613600000,
  }) async {
    final random = Random(id.hashCode);
    final file = File(p.join(temp.path, 'src', '$id.bin'));
    await file.create(recursive: true);
    await file.writeAsBytes(List.generate(size, (_) => random.nextInt(256)));
    library.files[id] = file;
    final media = scanned(id, size: size, kind: kind, takenMillis: takenMillis);
    await inventory.apply(
      reconcileInventory(
        existing: await inventory.allItems(),
        scanned: [
          for (final item in await inventory.allItems())
            if (item.removedFromLibraryAt == null)
              ScannedMedia(
                sourceMediaId: item.sourceMediaId,
                displayName: item.displayName,
                mimeType: item.mimeType,
                sizeBytes: item.sizeBytes,
                dateModified: DateTime.fromMillisecondsSinceEpoch(
                  item.dateModifiedMillis,
                ),
                dateTaken: item.dateTakenMillis == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        item.dateTakenMillis!,
                      ),
                relativePath: item.relativePath,
                kind: item.kind,
              ),
          media,
        ],
        now: DateTime(2026, 11, 2),
      ),
    );
    return file;
  }

  Future<MediaItem> itemFor(String id) async =>
      (await inventory.allItems()).singleWhere((i) => i.sourceMediaId == id);

  test('files arrive byte-identical and are marked transferred', () async {
    final photo = await addSource('1', 300 * 1024 + 7);
    final video = await addSource(
      '2',
      3 * 1024 * 1024 + 11,
      kind: MediaKind.video,
    );
    final progress = <TransferProgress>[];

    final summary = await orchestrator.run(onProgress: progress.add);

    expect(summary.delivered, 2);
    expect(summary.failed, 0);
    expect(publisher.published, hasLength(2));
    final sourceHashes = {
      await StreamingSha256.ofFile(photo),
      await StreamingSha256.ofFile(video),
    };
    final publishedHashes = {
      for (final file in publisher.published.values)
        await StreamingSha256.ofFile(file),
    };
    expect(publishedHashes, sourceHashes);

    for (final id in ['1', '2']) {
      final item = await itemFor(id);
      expect(item.status, TransferStatus.transferred);
      expect(item.receiverAcknowledgementId, isNotNull);
      expect(item.transferredAt, isNotNull);
      expect(sourceHashes, contains(item.sha256));
    }
    // Capture time is passed through for the gallery's date.
    expect(
      publisher.dateTaken.values,
      everyElement(DateTime.fromMillisecondsSinceEpoch(1793613600000)),
    );
    // Sources are untouched and staging is empty.
    expect(await photo.exists(), isTrue);
    expect(await staging.list().toList(), isEmpty);
    expect(progress.last.sentBytes, progress.last.totalBytes);
  });

  test('daily limits defer the rest until tomorrow', () async {
    settings.limits = const TransferLimits(photosPerDay: 2, videosPerDay: 1);
    for (var i = 0; i < 3; i++) {
      await addSource('p$i', 1000, takenMillis: 1000 + i);
    }
    for (var i = 0; i < 2; i++) {
      await addSource(
        'v$i',
        1000,
        kind: MediaKind.video,
        takenMillis: 2000 + i,
      );
    }

    final first = await orchestrator.run();
    expect(first.delivered, 3);
    expect(first.deferredPhotos, 1);
    expect(first.deferredVideos, 1);
    // Newest first: the oldest photo and video wait.
    expect((await itemFor('p0')).status, TransferStatus.pending);
    expect((await itemFor('v0')).status, TransferStatus.pending);

    final second = await orchestrator.run();
    expect(second.nothingToSend, isTrue);
    expect(second.deferredPhotos, 1);
    expect(publisher.published, hasLength(3));
  });

  test("'Run next batch' sends another batch past today's limit", () async {
    settings.limits = const TransferLimits(photosPerDay: 2, videosPerDay: 1);
    for (var i = 0; i < 5; i++) {
      await addSource('p$i', 1000, takenMillis: 1000 + i);
    }
    await addSource('v0', 1000, kind: MediaKind.video, takenMillis: 2000);

    final first = await orchestrator.run();
    expect(first.delivered, 3);
    expect(first.deferredPhotos, 3);

    final blocked = await orchestrator.run();
    expect(blocked.nothingToSend, isTrue);

    final extra = await orchestrator.run(extraBatch: true);
    expect(extra.delivered, 2);
    expect(extra.deferredPhotos, 1);
    // Next newest photos went; the oldest still waits.
    expect((await itemFor('p2')).status, TransferStatus.transferred);
    expect((await itemFor('p0')).status, TransferStatus.pending);
  });

  test('a retransmit is answered without a second copy', () async {
    await addSource('1', 5000);
    await orchestrator.run();
    final item = await itemFor('1');
    // Simulate a lost acknowledgement: the sender still thinks it's pending.
    await inventory.setStatus(item.id, TransferStatus.pending);

    final summary = await orchestrator.run();

    expect(summary.alreadyPresent, 1);
    expect(summary.delivered, 0);
    expect(publisher.published, hasLength(1));
    expect((await itemFor('1')).status, TransferStatus.transferred);
  });

  test('a missing source file fails without stopping the batch', () async {
    final gone = await addSource('1', 1000, takenMillis: 2);
    await addSource('2', 1000, takenMillis: 1);
    await gone.delete();

    final summary = await orchestrator.run();

    expect(summary.failed, 1);
    expect(summary.delivered, 1);
    final failed = await itemFor('1');
    expect(failed.status, TransferStatus.failed);
    expect(failed.lastError, contains('no longer'));
  });

  test(
    'cancelling mid-file leaves the item pending and nothing published',
    () async {
      await addSource('1', 4 * 1024 * 1024);
      var chunks = 0;

      final summary = await orchestrator.run(
        onProgress: (_) => chunks++,
        isCancelled: () => chunks > 1,
      );

      expect(summary.cancelled, isTrue);
      expect((await itemFor('1')).status, TransferStatus.pending);
      expect(publisher.published, isEmpty);
      // Give the receiver a moment to notice the closed socket.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(await staging.list().toList(), isEmpty);
    },
  );

  test('a size mismatch is rejected and nothing is published', () async {
    final source = await addSource('1', 2000);
    final link = await ReceiverLocator(
      senderPairing,
      FakeServiceDiscovery(),
    ).locate();
    final session = await client.openSession(
      receiver: link.receiver,
      host: link.host,
      port: link.port,
      authToken: link.authToken,
    );
    addTearDown(session.close);

    final outcome = await session.sendFile(
      const FileOffer(
        transferId: 'sender-1:999',
        name: 'IMG_short.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 5000,
        sourceModifiedMillis: 0,
      ),
      source.openRead,
    );

    expect(outcome, isA<FileNotDelivered>());
    expect((outcome as FileNotDelivered).reason, contains('Size mismatch'));
    expect(publisher.published, isEmpty);
  });

  test('items stuck mid-transfer after a crash go back to pending', () async {
    await addSource('1', 1000);
    final item = await itemFor('1');
    await inventory.setStatus(item.id, TransferStatus.verifying);

    expect(await inventory.resetInterrupted(), 1);
    expect((await itemFor('1')).status, TransferStatus.pending);
  });
}
