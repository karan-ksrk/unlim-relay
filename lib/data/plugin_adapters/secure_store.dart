import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key/value storage for secrets (plan §11).
abstract interface class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// [SecureStore] backed by the Android Keystore via
/// `package:flutter_secure_storage`.
class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
