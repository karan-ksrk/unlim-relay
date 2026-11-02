import 'dart:async';
import 'dart:typed_data';

class ProtocolException implements Exception {
  const ProtocolException(this.message);

  final String message;

  @override
  String toString() => 'ProtocolException: $message';
}

enum FrameType {
  /// UTF-8 JSON control message.
  control(1),

  /// Raw file bytes (Milestone 4).
  data(2);

  const FrameType(this.code);

  final int code;

  static FrameType? fromCode(int code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

class Frame {
  const Frame(this.type, this.payload);

  final FrameType type;
  final Uint8List payload;
}

/// Wire format: 1-byte type, 4-byte big-endian payload length, payload.
abstract final class FrameCodec {
  static const headerBytes = 5;

  /// Upper bound per frame, so a peer can't make us buffer unbounded data.
  static const maxPayloadBytes = 1024 * 1024;

  static Uint8List encode(Frame frame) {
    final length = frame.payload.length;
    if (length > maxPayloadBytes) {
      throw ProtocolException('Frame of $length bytes exceeds the limit');
    }
    final bytes = Uint8List(headerBytes + length);
    ByteData.sublistView(bytes)
      ..setUint8(0, frame.type.code)
      ..setUint32(1, length);
    bytes.setRange(headerBytes, bytes.length, frame.payload);
    return bytes;
  }
}

/// Reassembles frames from arbitrarily split socket chunks.
class FrameDecoder extends StreamTransformerBase<Uint8List, Frame> {
  const FrameDecoder();

  @override
  Stream<Frame> bind(Stream<Uint8List> stream) {
    return Stream.eventTransformed(stream, _FrameSink.new);
  }
}

class _FrameSink implements EventSink<Uint8List> {
  _FrameSink(this._out);

  final EventSink<Frame> _out;
  final _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  @override
  void add(Uint8List chunk) {
    _buffer
      ..add(_pending)
      ..add(chunk);
    var bytes = _buffer.takeBytes();
    var offset = 0;
    try {
      while (bytes.length - offset >= FrameCodec.headerBytes) {
        final header = ByteData.sublistView(bytes, offset);
        final type = FrameType.fromCode(header.getUint8(0));
        final length = header.getUint32(1);
        if (type == null) {
          throw ProtocolException('Unknown frame type ${header.getUint8(0)}');
        }
        if (length > FrameCodec.maxPayloadBytes) {
          throw ProtocolException('Frame of $length bytes exceeds the limit');
        }
        final end = offset + FrameCodec.headerBytes + length;
        if (bytes.length < end) break;
        _out.add(
          Frame(
            type,
            Uint8List.fromList(
              bytes.sublist(offset + FrameCodec.headerBytes, end),
            ),
          ),
        );
        offset = end;
      }
    } on ProtocolException catch (error, stackTrace) {
      bytes = Uint8List(0);
      offset = 0;
      _out.addError(error, stackTrace);
    }
    _pending = Uint8List.sublistView(bytes, offset);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _out.addError(error, stackTrace);

  @override
  void close() {
    if (_pending.isNotEmpty) {
      _out.addError(const ProtocolException('Connection closed mid-frame'));
    }
    _out.close();
  }
}
