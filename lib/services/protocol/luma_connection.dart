import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';

import 'frame_codec.dart';
import 'messages.dart';

/// The peer answered with an [ErrorMessage].
class RemoteErrorException implements Exception {
  const RemoteErrorException(this.error);

  final ErrorMessage error;

  @override
  String toString() => 'Peer error ${error.code}: ${error.message}';
}

sealed class Incoming {
  const Incoming();
}

class IncomingMessage extends Incoming {
  const IncomingMessage(this.message);

  final LumaMessage message;
}

class IncomingData extends Incoming {
  const IncomingData(this.bytes);

  final Uint8List bytes;
}

/// Request/response messaging plus raw data frames over one TLS socket.
///
/// The socket is only read when a caller asks for the next frame, so a slow
/// consumer applies TCP backpressure instead of buffering in memory.
class LumaConnection {
  LumaConnection(this._socket)
    : _incoming = StreamQueue(_socket.transform(const FrameDecoder()));

  static const defaultTimeout = Duration(seconds: 15);

  final Socket _socket;
  final StreamQueue<Frame> _incoming;

  String get remoteAddress => _socket.remoteAddress.address;

  void send(LumaMessage message) {
    final json = utf8.encode(jsonEncode(message.toJson()));
    _socket.add(FrameCodec.encode(Frame(FrameType.control, json)));
  }

  /// Sends file bytes as one data frame (at most
  /// [FrameCodec.maxPayloadBytes]).
  void sendData(List<int> bytes) {
    if (bytes.length > FrameCodec.maxPayloadBytes) {
      throw ProtocolException('Data chunk of ${bytes.length} bytes is too big');
    }
    final header = ByteData(FrameCodec.headerBytes)
      ..setUint8(0, FrameType.data.code)
      ..setUint32(1, bytes.length);
    _socket
      ..add(header.buffer.asUint8List())
      ..add(bytes);
  }

  /// Waits until buffered output has been handed to the OS.
  Future<void> flush() => _socket.flush();

  /// Next control message or data chunk, or `null` once the peer closed.
  Future<Incoming?> nextAny({Duration timeout = defaultTimeout}) async {
    if (!await _incoming.hasNext.timeout(timeout)) return null;
    final frame = await _incoming.next;
    return switch (frame.type) {
      FrameType.control => IncomingMessage(_decode(frame.payload)),
      FrameType.data => IncomingData(frame.payload),
    };
  }

  /// Next control message, or `null` once the peer has closed.
  Future<LumaMessage?> next({Duration timeout = defaultTimeout}) async {
    return switch (await nextAny(timeout: timeout)) {
      null => null,
      IncomingMessage(:final message) => message,
      IncomingData() => throw const ProtocolException('Unexpected data frame'),
    };
  }

  /// Next message, which must be a [T]. Peer errors are thrown as
  /// [RemoteErrorException].
  Future<T> expect<T extends LumaMessage>({
    Duration timeout = defaultTimeout,
  }) async {
    final message = await next(timeout: timeout);
    return switch (message) {
      final T expected => expected,
      ErrorMessage() => throw RemoteErrorException(message),
      null => throw const SocketException('Connection closed by peer'),
      _ => throw ProtocolException('Expected $T, got ${message.type}'),
    };
  }

  Future<void> close() async {
    try {
      await _socket.flush();
      await _socket.close();
    } on Object {
      // Already closed by the peer.
    }
    _socket.destroy();
    await _incoming.cancel(immediate: true);
  }

  static LumaMessage _decode(Uint8List payload) {
    final json = jsonDecode(utf8.decode(payload));
    if (json is! Map<String, Object?>) {
      throw const ProtocolException('Control frame is not a JSON object');
    }
    return LumaMessage.fromJson(json);
  }
}
