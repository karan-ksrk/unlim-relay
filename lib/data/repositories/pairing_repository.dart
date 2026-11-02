import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../plugin_adapters/secure_store.dart';

/// Stores the single trusted peer and, on the sender, its auth token.
abstract interface class PairingRepository {
  Stream<PairedDevice?> watchPairedDevice();

  Future<PairedDevice?> pairedDevice();

  /// Replaces any existing pairing with [device]. A sender passes the
  /// receiver-issued [authToken], which goes to secure storage.
  Future<void> savePairing(PairedDevice device, {String? authToken});

  /// The sender's token for [receiverId], if paired.
  Future<String?> authToken(String receiverId);

  Future<void> recordSeen(
    String deviceId, {
    required DateTime at,
    String? host,
    int? port,
  });

  /// Removes trust: deletes the row and any stored token.
  Future<void> revokePairing();
}

class DriftPairingRepository implements PairingRepository {
  DriftPairingRepository(this._db, this._secureStore);

  final AppDatabase _db;
  final SecureStore _secureStore;

  static String _tokenKey(String receiverId) => 'auth_token_$receiverId';

  @override
  Stream<PairedDevice?> watchPairedDevice() =>
      (_db.select(_db.pairedDevices)..limit(1)).watchSingleOrNull();

  @override
  Future<PairedDevice?> pairedDevice() =>
      (_db.select(_db.pairedDevices)..limit(1)).getSingleOrNull();

  @override
  Future<void> savePairing(PairedDevice device, {String? authToken}) async {
    await revokePairing();
    if (authToken != null) {
      await _secureStore.write(_tokenKey(device.deviceId), authToken);
    }
    await _db.into(_db.pairedDevices).insert(device);
  }

  @override
  Future<String?> authToken(String receiverId) =>
      _secureStore.read(_tokenKey(receiverId));

  @override
  Future<void> recordSeen(
    String deviceId, {
    required DateTime at,
    String? host,
    int? port,
  }) async {
    await (_db.update(
      _db.pairedDevices,
    )..where((t) => t.deviceId.equals(deviceId))).write(
      PairedDevicesCompanion(
        lastSeenAt: Value(at),
        lastKnownHost: host == null ? const Value.absent() : Value(host),
        lastKnownPort: port == null ? const Value.absent() : Value(port),
      ),
    );
  }

  @override
  Future<void> revokePairing() async {
    final existing = await _db.select(_db.pairedDevices).get();
    for (final device in existing) {
      await _secureStore.delete(_tokenKey(device.deviceId));
    }
    await _db.delete(_db.pairedDevices).go();
  }
}
