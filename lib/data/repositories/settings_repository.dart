import '../../core/utils/secrets.dart';
import '../database/app_database.dart';
import '../models/device_role.dart';
import '../models/transfer_limits.dart';

/// Persists app-level preferences.
abstract interface class SettingsRepository {
  Future<DeviceRole?> readDeviceRole();

  Future<void> saveDeviceRole(DeviceRole role);

  Future<void> clearDeviceRole();

  Future<DateTime?> readLastScanAt();

  Future<void> saveLastScanAt(DateTime at);

  /// This install's random identifier, created on first use.
  Future<String> deviceId();

  Future<TransferLimits> readTransferLimits();

  Future<void> saveTransferLimits(TransferLimits limits);

  /// Whether the receiver should listen whenever the app is open.
  Future<bool> readReceiverReady();

  Future<void> saveReceiverReady(bool ready);
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  static const _deviceRoleKey = 'device_role';
  static const _lastScanAtKey = 'last_camera_scan_at';
  static const _deviceIdKey = 'device_id';
  static const _photoLimitKey = 'daily_photo_limit';
  static const _videoLimitKey = 'daily_video_limit';
  static const _receiverReadyKey = 'receiver_ready';

  /// Stored for "no limit", since a missing key means "use the default".
  static const _unlimited = 'none';

  @override
  Future<DeviceRole?> readDeviceRole() async =>
      DeviceRole.tryParse(await _read(_deviceRoleKey));

  @override
  Future<void> saveDeviceRole(DeviceRole role) =>
      _write(_deviceRoleKey, role.name);

  @override
  Future<void> clearDeviceRole() async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.name.equals(_deviceRoleKey))).go();
  }

  @override
  Future<DateTime?> readLastScanAt() async {
    final value = await _read(_lastScanAtKey);
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  @override
  Future<void> saveLastScanAt(DateTime at) =>
      _write(_lastScanAtKey, at.toUtc().toIso8601String());

  @override
  Future<String> deviceId() async {
    final existing = await _read(_deviceIdKey);
    if (existing != null) return existing;
    final id = randomToken(16);
    await _write(_deviceIdKey, id);
    return id;
  }

  @override
  Future<TransferLimits> readTransferLimits() async => TransferLimits(
    photosPerDay: _parseLimit(
      await _read(_photoLimitKey),
      TransferLimits.defaultPhotosPerDay,
    ),
    videosPerDay: _parseLimit(
      await _read(_videoLimitKey),
      TransferLimits.defaultVideosPerDay,
    ),
  );

  @override
  Future<void> saveTransferLimits(TransferLimits limits) async {
    await _write(_photoLimitKey, '${limits.photosPerDay ?? _unlimited}');
    await _write(_videoLimitKey, '${limits.videosPerDay ?? _unlimited}');
  }

  @override
  Future<bool> readReceiverReady() async =>
      await _read(_receiverReadyKey) == 'true';

  @override
  Future<void> saveReceiverReady(bool ready) =>
      _write(_receiverReadyKey, '$ready');

  static int? _parseLimit(String? stored, int fallback) {
    if (stored == null) return fallback;
    if (stored == _unlimited) return null;
    return int.tryParse(stored) ?? fallback;
  }

  Future<String?> _read(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.name.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String key, String value) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(name: key, value: value),
        );
  }
}
