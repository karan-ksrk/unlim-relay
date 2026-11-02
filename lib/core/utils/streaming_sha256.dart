import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// SHA-256 over data fed in chunks, so large files are never held in
/// memory.
class StreamingSha256 {
  StreamingSha256() {
    _input = sha256.startChunkedConversion(_output);
  }

  final _output = _DigestSink();
  late final ByteConversionSink _input;

  void add(List<int> chunk) => _input.add(chunk);

  /// Lowercase hex digest. The hasher can't be used afterwards.
  String close() {
    _input.close();
    return _output.digest.toString();
  }

  static Future<String> ofFile(File file) async {
    final hasher = StreamingSha256();
    await for (final chunk in file.openRead()) {
      hasher.add(chunk);
    }
    return hasher.close();
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}
