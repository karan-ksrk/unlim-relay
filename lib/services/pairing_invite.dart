/// Everything the sender needs to pair, encoded in the receiver's QR code.
class PairingInvite {
  const PairingInvite({
    required this.receiverId,
    required this.receiverName,
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.secret,
  });

  static const scheme = 'lumasync';

  final String receiverId;
  final String receiverName;
  final String host;
  final int port;

  /// SHA-256 of the receiver's TLS certificate.
  final String fingerprint;

  /// One-time pairing secret.
  final String secret;

  String toUri() => Uri(
    scheme: scheme,
    host: 'pair',
    queryParameters: {
      'v': '1',
      'id': receiverId,
      'n': receiverName,
      'h': host,
      'p': '$port',
      'fp': fingerprint,
      's': secret,
    },
  ).toString();

  /// Parses a scanned code; returns `null` for anything that isn't a valid
  /// LumaSync pairing code.
  static PairingInvite? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != scheme || uri.host != 'pair') return null;
    final q = uri.queryParameters;
    final port = int.tryParse(q['p'] ?? '');
    final fingerprint = q['fp'] ?? '';
    if (q['v'] != '1' ||
        port == null ||
        port <= 0 ||
        port > 65535 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(fingerprint)) {
      return null;
    }
    final id = q['id'], name = q['n'], host = q['h'], secret = q['s'];
    if ([id, name, host, secret].any((v) => v == null || v.isEmpty)) {
      return null;
    }
    return PairingInvite(
      receiverId: id!,
      receiverName: name!,
      host: host!,
      port: port,
      fingerprint: fingerprint,
      secret: secret!,
    );
  }
}
