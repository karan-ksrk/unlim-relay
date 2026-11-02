import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/device_role.dart';
import 'package:lumasync/data/models/transfer_limits.dart';
import 'package:lumasync/data/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  test('returns null before a role is saved', () async {
    expect(await repo.readDeviceRole(), isNull);
  });

  test('saves, overwrites and clears the role', () async {
    await repo.saveDeviceRole(DeviceRole.sender);
    expect(await repo.readDeviceRole(), DeviceRole.sender);

    await repo.saveDeviceRole(DeviceRole.receiver);
    expect(await repo.readDeviceRole(), DeviceRole.receiver);

    await repo.clearDeviceRole();
    expect(await repo.readDeviceRole(), isNull);
  });

  test('transfer limits default to 100 photos and 5 videos', () async {
    expect(
      await repo.readTransferLimits(),
      const TransferLimits(photosPerDay: 100, videosPerDay: 5),
    );
  });

  test('transfer limits persist, including "no limit"', () async {
    await repo.saveTransferLimits(
      const TransferLimits(photosPerDay: 30, videosPerDay: null),
    );

    expect(
      await repo.readTransferLimits(),
      const TransferLimits(photosPerDay: 30, videosPerDay: null),
    );
  });

  test('device id is created once and then stable', () async {
    final first = await repo.deviceId();
    expect(first, isNotEmpty);
    expect(await repo.deviceId(), first);
  });
}
