import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// URL-safe random token with [bytes] of entropy.
String randomToken([int bytes = 32]) {
  final random = Random.secure();
  return base64Url
      .encode(List.generate(bytes, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

/// Lowercase hex SHA-256 of [value]'s UTF-8 bytes.
String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();

/// Compares secrets without leaking where they differ through timing.
bool constantTimeEquals(String a, String b) {
  final x = utf8.encode(a);
  final y = utf8.encode(b);
  var diff = x.length ^ y.length;
  for (var i = 0; i < min(x.length, y.length); i++) {
    diff |= x[i] ^ y[i];
  }
  return diff == 0;
}
