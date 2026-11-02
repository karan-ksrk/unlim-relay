import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/models/transfer_limits.dart';
import 'package:lumasync/data/repositories/settings_repository.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.role]);

  DeviceRole? role;
  DateTime? lastScanAt;
  String id = 'test-device-id';
  TransferLimits limits = const TransferLimits();
  bool receiverReady = false;
  bool launchSound = true;

  @override
  Future<DeviceRole?> readDeviceRole() async => role;

  @override
  Future<void> saveDeviceRole(DeviceRole role) async => this.role = role;

  @override
  Future<void> clearDeviceRole() async => role = null;

  @override
  Future<DateTime?> readLastScanAt() async => lastScanAt;

  @override
  Future<void> saveLastScanAt(DateTime at) async => lastScanAt = at;

  @override
  Future<String> deviceId() async => id;

  @override
  Future<TransferLimits> readTransferLimits() async => limits;

  @override
  Future<void> saveTransferLimits(TransferLimits limits) async =>
      this.limits = limits;

  @override
  Future<bool> readReceiverReady() async => receiverReady;

  @override
  Future<void> saveReceiverReady(bool ready) async => receiverReady = ready;

  @override
  Future<bool> readLaunchSound() async => launchSound;

  @override
  Future<void> saveLaunchSound(bool enabled) async => launchSound = enabled;
}
