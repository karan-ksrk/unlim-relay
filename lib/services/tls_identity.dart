import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';

/// The receiver's self-signed TLS certificate and key.
///
/// The sender pins [fingerprint] (taken from the pairing QR code) instead of
/// trusting a certificate authority.
class TlsIdentity {
  TlsIdentity({required this.certificatePem, required this.privateKeyPem})
    : fingerprint = certificateFingerprint(_pemToDer(certificatePem));

  final String certificatePem;
  final String privateKeyPem;

  /// Lowercase hex SHA-256 of the certificate DER.
  final String fingerprint;

  SecurityContext toServerContext() => SecurityContext(withTrustedRoots: false)
    ..useCertificateChainBytes(utf8.encode(certificatePem))
    ..usePrivateKeyBytes(utf8.encode(privateKeyPem));

  /// Generates an RSA-2048 key and 10-year certificate. Takes a few seconds,
  /// so it runs on a background isolate.
  static Future<TlsIdentity> generate(String commonName) =>
      Isolate.run(() => _generate(commonName));

  static TlsIdentity _generate(String commonName) {
    final pair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    final privateKey = pair.privateKey as RSAPrivateKey;
    final publicKey = pair.publicKey as RSAPublicKey;
    final csr = X509Utils.generateRsaCsrPem(
      {'CN': commonName},
      privateKey,
      publicKey,
    );
    final certificate = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      3650,
      serialNumber: '${Random.secure().nextInt(0x7fffffff) + 1}',
    );
    return TlsIdentity(
      certificatePem: certificate,
      privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey),
    );
  }

  static Uint8List _pemToDer(String pem) {
    final body = const LineSplitter()
        .convert(pem)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('-----'))
        .join();
    return base64.decode(body);
  }
}

/// Lowercase hex SHA-256 of a DER certificate.
String certificateFingerprint(List<int> der) => sha256.convert(der).toString();
