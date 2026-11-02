import 'package:drift/drift.dart';

import '../models/device_role.dart';
import '../models/media_enums.dart';

/// Small key/value store for app-level preferences such as the device role.
class AppSettings extends Table {
  TextColumn get name => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

/// Sender inventory of camera photos and videos (plan §11).
///
/// The source file is re-resolved through the media plugin by
/// [sourceMediaId], so no content URI is stored.
@DataClassName('MediaItem')
@TableIndex(name: 'media_items_status', columns: {#status})
@TableIndex(name: 'media_items_source_media_id', columns: {#sourceMediaId})
class MediaItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// MediaStore `_id`. Can change after a restore or re-index.
  TextColumn get sourceMediaId => text()();
  TextColumn get displayName => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();

  /// MediaStore `DATE_TAKEN`, or `DATE_ADDED` when the file has none.
  IntColumn get dateTakenMillis => integer().nullable()();
  IntColumn get dateModifiedMillis => integer()();
  TextColumn get relativePath => text().nullable()();
  TextColumn get kind => textEnum<MediaKind>()();

  /// Filled in during transfer (Milestone 4).
  TextColumn get sha256 => text().nullable()();
  TextColumn get status => textEnum<TransferStatus>()();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get transferredAt => dateTime().nullable()();
  TextColumn get receiverAcknowledgementId => text().nullable()();
  TextColumn get lastError => text().nullable()();

  /// Set when the file is no longer in the media library. The row stays as
  /// history and is never deleted automatically.
  DateTimeColumn get removedFromLibraryAt => dateTime().nullable()();
}

/// The trusted peer (plan §7 and §11). Unpairing deletes the row.
///
/// Reusable secrets never live here: the sender keeps its auth token in
/// secure storage, and the receiver stores only the token's hash.
@DataClassName('PairedDevice')
class PairedDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get displayName => text()();
  TextColumn get peerRole => textEnum<DeviceRole>()();

  /// Receiver certificate SHA-256, pinned by the sender.
  TextColumn get certificateFingerprint => text().nullable()();

  /// SHA-256 of the sender's auth token, kept by the receiver.
  TextColumn get authTokenHash => text().nullable()();

  TextColumn get lastKnownHost => text().nullable()();
  IntColumn get lastKnownPort => integer().nullable()();
  DateTimeColumn get pairedAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

/// Files the receiver verified and published (plan §6, §8). Used to answer
/// retransmits without saving a second copy.
@DataClassName('ReceivedFile')
@TableIndex(name: 'received_files_transfer_id', columns: {#transferId})
@TableIndex(name: 'received_files_sha256', columns: {#sha256})
class ReceivedFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderDeviceId => text()();
  TextColumn get transferId => text()();
  TextColumn get sha256 => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get sourceModifiedMillis => integer().nullable()();
  TextColumn get originalName => text()();

  /// MediaStore id of the published copy.
  TextColumn get publishedMediaId => text()();

  /// Final name in DCIM/Camera; Android renames on a name clash.
  TextColumn get publishedName => text()();
  TextColumn get acknowledgementId => text()();
  DateTimeColumn get receivedAt => dateTime()();
}

/// The daily schedule and its last run (plan §9, §11). A single row, id 1.
@DataClassName('ScheduleRow')
class ScheduleSettingsTable extends Table {
  @override
  String get tableName => 'schedule_settings';

  IntColumn get id => integer()();
  BoolColumn get enabled => boolean()();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();

  /// ISO weekdays as "1,2,3".
  TextColumn get weekdays => text()();
  BoolColumn get wifiOnly => boolean()();
  BoolColumn get chargingOnly => boolean()();
  IntColumn get retryHours => integer()();
  DateTimeColumn get enabledAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastOutcome => text().nullable()();
  TextColumn get lastMessage => text().nullable()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  DateTimeColumn get nextRunEstimate => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A lease that keeps a scheduled run and a manual transfer from running
/// at once. The scheduled run uses its own Flutter engine and database
/// connection, so an in-memory flag can't do this.
class TransferLocks extends Table {
  TextColumn get name => text()();
  TextColumn get owner => text()();
  IntColumn get expiresAtMillis => integer()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}
