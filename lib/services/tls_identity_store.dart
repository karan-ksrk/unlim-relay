import '../data/plugin_adapters/secure_store.dart';
import 'tls_identity.dart';

/// Keeps the receiver's TLS identity in secure storage so its fingerprint,
/// which the sender pins, survives restarts.
class TlsIdentityStore {
  TlsIdentityStore(this._secureStore);

  static const _certificateKey = 'tls_certificate_pem';
  static const _privateKeyKey = 'tls_private_key_pem';

  final SecureStore _secureStore;

  Future<TlsIdentity> loadOrCreate(String commonName) async {
    final certificate = await _secureStore.read(_certificateKey);
    final privateKey = await _secureStore.read(_privateKeyKey);
    if (certificate != null && privateKey != null) {
      return TlsIdentity(certificatePem: certificate, privateKeyPem: privateKey);
    }
    final identity = await TlsIdentity.generate(commonName);
    await _secureStore.write(_privateKeyKey, identity.privateKeyPem);
    await _secureStore.write(_certificateKey, identity.certificatePem);
    return identity;
  }
}
