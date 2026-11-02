import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/repositories/pairing_repository.dart';
import 'package:lumasync/services/pairing_invite.dart';
import 'package:lumasync/services/protocol/luma_connection.dart';
import 'package:lumasync/services/protocol/messages.dart';
import 'package:lumasync/services/receiver_server.dart';
import 'package:lumasync/services/sender_client.dart';
import 'package:lumasync/services/tls_identity.dart';

import '../fixtures/fake_secure_store.dart';
import '../fixtures/media_fixtures.dart';

/// Real TLS over loopback: certificate generation, pinning, pairing and an
/// authenticated manifest exchange.
void main() {
  late TlsIdentity identity;
  late AppDatabase receiverDb;
  late AppDatabase senderDb;
  late DriftPairingRepository receiverPairing;
  late DriftPairingRepository senderPairing;
  late FakeSecureStore senderSecrets;
  late ReceiverServer server;
  late SenderClient client;
  late List<PairingRequestInfo> approvals;
  var approve = true;

  setUpAll(() async {
    // Two separate in-memory databases stand in for the two phones.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    identity = await TlsIdentity.generate('LumaSync test receiver');
  });

  setUp(() async {
    receiverDb = memoryDatabase();
    senderDb = memoryDatabase();
    receiverPairing = DriftPairingRepository(receiverDb, FakeSecureStore());
    senderSecrets = FakeSecureStore();
    senderPairing = DriftPairingRepository(senderDb, senderSecrets);
    approvals = [];
    approve = true;
    server = ReceiverServer(
      identity: identity,
      deviceId: 'receiver-1',
      displayName: 'Test Receiver',
      pairing: receiverPairing,
      approvePairing: (request) async {
        approvals.add(request);
        return approve;
      },
    );
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    client = SenderClient(deviceId: 'sender-1', displayName: 'Test Sender');
  });

  tearDown(() async {
    await server.stop();
    await receiverDb.close();
    await senderDb.close();
  });

  PairingInvite invite() => server.createInvite('127.0.0.1');

  Future<void> pairSender() async {
    final result = await client.pair(invite(), now: DateTime(2026, 11, 2));
    await senderPairing.savePairing(
      result.receiver,
      authToken: result.authToken,
    );
  }

  Manifest manifest(int files) => Manifest(
    sessionId: 'session-1',
    senderDeviceId: 'sender-1',
    files: [
      for (var i = 0; i < files; i++)
        ManifestFile(
          transferId: 't$i',
          name: 'IMG_$i.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1000 + i,
          dateTakenMillis: 1793613600000,
        ),
    ],
  );

  Future<ConnectionTestResult> runTest({String? token}) async {
    final receiver = (await senderPairing.pairedDevice())!;
    return client.testConnection(
      receiver: receiver,
      host: '127.0.0.1',
      port: server.port!,
      authToken: token ?? (await senderPairing.authToken('receiver-1'))!,
      manifest: manifest(3),
    );
  }

  test('generated certificate has a stable SHA-256 fingerprint', () {
    expect(identity.fingerprint, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(
      TlsIdentity(
        certificatePem: identity.certificatePem,
        privateKeyPem: identity.privateKeyPem,
      ).fingerprint,
      identity.fingerprint,
    );
  });

  test('pairing stores trust on both sides after approval', () async {
    await pairSender();

    expect(approvals.single.senderName, 'Test Sender');
    final onSender = (await senderPairing.pairedDevice())!;
    expect(onSender.deviceId, 'receiver-1');
    expect(onSender.peerRole, DeviceRole.receiver);
    expect(onSender.certificateFingerprint, identity.fingerprint);
    expect(await senderPairing.authToken('receiver-1'), isNotEmpty);

    final onReceiver = (await receiverPairing.pairedDevice())!;
    expect(onReceiver.deviceId, 'sender-1');
    expect(onReceiver.peerRole, DeviceRole.sender);
    expect(onReceiver.authTokenHash, hasLength(64));
    // The receiver never stores the token itself.
    expect(
      onReceiver.authTokenHash,
      isNot(await senderPairing.authToken('receiver-1')),
    );
  });

  test('declined pairing stores nothing', () async {
    approve = false;

    await expectLater(
      client.pair(invite(), now: DateTime(2026)),
      throwsA(isA<PairingRejectedException>()),
    );
    expect(await receiverPairing.pairedDevice(), isNull);
  });

  test('a pairing code works only once', () async {
    final code = invite();
    await client.pair(code, now: DateTime(2026));

    await expectLater(
      client.pair(code, now: DateTime(2026)),
      throwsA(isA<PairingRejectedException>()),
    );
    expect(approvals, hasLength(1));
  });

  test('a wrong secret is rejected without asking the user', () async {
    final real = invite();
    final forged = PairingInvite(
      receiverId: real.receiverId,
      receiverName: real.receiverName,
      host: real.host,
      port: real.port,
      fingerprint: real.fingerprint,
      secret: 'not-the-secret',
    );

    await expectLater(
      client.pair(forged, now: DateTime(2026)),
      throwsA(isA<PairingRejectedException>()),
    );
    expect(approvals, isEmpty);
  });

  test('a certificate that does not match the pin is refused', () async {
    final real = invite();
    final wrongPin = PairingInvite(
      receiverId: real.receiverId,
      receiverName: real.receiverName,
      host: real.host,
      port: real.port,
      fingerprint: 'a' * 64,
      secret: real.secret,
    );

    await expectLater(
      client.pair(wrongPin, now: DateTime(2026)),
      throwsA(isA<HandshakeException>()),
    );
    expect(approvals, isEmpty);
  });

  test('paired sender exchanges ping and manifest', () async {
    await pairSender();
    final events = <ReceiverEvent>[];
    final sub = server.events.listen(events.add);

    final result = await runTest();
    await pumpEventQueue();
    await sub.cancel();

    expect(result.receiverName, 'Test Receiver');
    expect(result.acknowledgedFiles, 3);
    expect(result.acknowledgedBytes, 1000 + 1001 + 1002);
    final received = events.whereType<ManifestReceived>().single;
    expect(received.senderName, 'Test Sender');
    expect(received.fileCount, 3);
  });

  test('a wrong token is unauthorized', () async {
    await pairSender();

    await expectLater(
      runTest(token: 'stolen-or-guessed'),
      throwsA(
        isA<RemoteErrorException>().having(
          (e) => e.error.code,
          'code',
          ErrorMessage.unauthorized,
        ),
      ),
    );
  });

  test('unpairing on the receiver revokes the sender', () async {
    await pairSender();
    await receiverPairing.revokePairing();

    await expectLater(runTest(), throwsA(isA<RemoteErrorException>()));
  });
}
