import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/core/utils/secrets.dart';
import 'package:lumasync/services/pairing_invite.dart';
import 'package:lumasync/services/protocol/frame_codec.dart';
import 'package:lumasync/services/protocol/messages.dart';

Frame control(String text) =>
    Frame(FrameType.control, Uint8List.fromList(utf8.encode(text)));

Future<List<Frame>> decode(List<List<int>> chunks) =>
    Stream.fromIterable(chunks.map(Uint8List.fromList))
        .transform(const FrameDecoder())
        .toList();

void main() {
  group('FrameDecoder', () {
    test('decodes frames split across arbitrary chunks', () async {
      final bytes = [
        ...FrameCodec.encode(control('hello')),
        ...FrameCodec.encode(control('world!')),
      ];
      // One byte at a time is the worst case.
      final frames = await decode([
        for (final b in bytes) [b],
      ]);

      expect(frames.map((f) => utf8.decode(f.payload)), ['hello', 'world!']);
    });

    test('decodes several frames from one chunk', () async {
      final frames = await decode([
        [
          ...FrameCodec.encode(control('a')),
          ...FrameCodec.encode(control('')),
          ...FrameCodec.encode(control('c')),
        ],
      ]);

      expect(frames.map((f) => utf8.decode(f.payload)), ['a', '', 'c']);
    });

    test('rejects oversized frames before buffering them', () async {
      final header = ByteData(5)
        ..setUint8(0, FrameType.control.code)
        ..setUint32(1, FrameCodec.maxPayloadBytes + 1);

      expect(
        decode([header.buffer.asUint8List()]),
        throwsA(isA<ProtocolException>()),
      );
    });

    test('rejects unknown frame types', () {
      expect(
        decode([
          [9, 0, 0, 0, 0],
        ]),
        throwsA(isA<ProtocolException>()),
      );
    });

    test('reports a connection closed mid-frame', () {
      final bytes = FrameCodec.encode(control('truncated'));

      expect(
        decode([bytes.sublist(0, bytes.length - 2)]),
        throwsA(isA<ProtocolException>()),
      );
    });
  });

  group('messages', () {
    LumaMessage roundTrip(LumaMessage message) => LumaMessage.fromJson(
      jsonDecode(jsonEncode(message.toJson())) as Map<String, Object?>,
    );

    test('round-trip through JSON', () {
      final messages = <LumaMessage>[
        const PairRequest(
          pairingSecret: 's',
          senderId: 'a',
          senderName: 'iQOO',
        ),
        const PairAccepted(receiverId: 'b', receiverName: 'R', authToken: 't'),
        const PairRejected(reason: 'no'),
        const Hello(senderId: 'a', authToken: 't'),
        const HelloAccepted(receiverId: 'b', receiverName: 'R'),
        const Ping(42),
        const Pong(42),
        const Manifest(
          sessionId: 'x',
          senderDeviceId: 'a',
          files: [
            ManifestFile(
              transferId: '1',
              name: 'IMG_1.jpg',
              mimeType: 'image/jpeg',
              sizeBytes: 5,
              dateTakenMillis: 1793613600000,
            ),
          ],
        ),
        const ManifestAck(sessionId: 'x', fileCount: 1, totalBytes: 5),
        const ErrorMessage(code: 'unauthorized', message: 'm'),
      ];

      for (final message in messages) {
        expect(roundTrip(message).toJson(), message.toJson());
      }
    });

    test('manifest carries no location fields', () {
      const file = ManifestFile(
        transferId: '1',
        name: 'IMG_1.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 5,
      );

      expect(
        file.toJson().keys,
        unorderedEquals([
          'transferId',
          'name',
          'mimeType',
          'sizeBytes',
          'dateTakenMillis',
          'sha256',
        ]),
      );
    });

    test('rejects unknown types and malformed fields', () {
      expect(
        () => LumaMessage.fromJson({'type': 'teleport'}),
        throwsA(isA<ProtocolException>()),
      );
      expect(
        () => LumaMessage.fromJson({'type': 'ping', 'nonce': 'seven'}),
        throwsA(isA<ProtocolException>()),
      );
    });
  });

  group('PairingInvite', () {
    final invite = PairingInvite(
      receiverId: 'r1',
      receiverName: 'Redmi Note 7 Pro',
      host: '192.168.1.20',
      port: 47863,
      fingerprint: 'ab' * 32,
      secret: randomToken(24),
    );

    test('round-trips through the QR text', () {
      final parsed = PairingInvite.tryParse(invite.toUri())!;

      expect(parsed.receiverName, 'Redmi Note 7 Pro');
      expect(parsed.host, '192.168.1.20');
      expect(parsed.port, 47863);
      expect(parsed.fingerprint, invite.fingerprint);
      expect(parsed.secret, invite.secret);
    });

    test('ignores codes that are not LumaSync invites', () {
      expect(PairingInvite.tryParse('https://example.com'), isNull);
      expect(PairingInvite.tryParse('lumasync://pair?v=1'), isNull);
      expect(
        PairingInvite.tryParse(
          invite.toUri().replaceFirst('fp=${invite.fingerprint}', 'fp=xyz'),
        ),
        isNull,
      );
    });
  });

  test('constantTimeEquals', () {
    expect(constantTimeEquals('abc', 'abc'), isTrue);
    expect(constantTimeEquals('abc', 'abd'), isFalse);
    expect(constantTimeEquals('abc', 'ab'), isFalse);
  });
}
