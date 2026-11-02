import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lumasync/data/database/app_database.dart';
import 'package:lumasync/data/models/media_enums.dart';
import 'package:lumasync/data/plugin_adapters/media_library.dart';

/// In-memory database whose query streams close synchronously, so widget
/// tests don't leave pending timers.
AppDatabase memoryDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

ScannedMedia scanned(
  String id, {
  String? name,
  int size = 1000,
  int modifiedMillis = 1000000,
  int? takenMillis = 500000,
  MediaKind kind = MediaKind.image,
}) => ScannedMedia(
  sourceMediaId: id,
  displayName:
      name ?? (kind == MediaKind.video ? 'VID_$id.mp4' : 'IMG_$id.jpg'),
  mimeType: kind == MediaKind.video ? 'video/mp4' : 'image/jpeg',
  sizeBytes: size,
  dateTaken: takenMillis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(takenMillis),
  dateModified: DateTime.fromMillisecondsSinceEpoch(modifiedMillis),
  relativePath: 'DCIM/Camera/',
  kind: kind,
);

/// Builds a stored row as if [media] had been inserted earlier.
MediaItem storedItem(
  int id,
  ScannedMedia media, {
  TransferStatus status = TransferStatus.pending,
  String? sha256,
  DateTime? transferredAt,
  String? ackId,
  DateTime? removedAt,
  DateTime? deletedAt,
}) => MediaItem(
  id: id,
  sourceMediaId: media.sourceMediaId,
  displayName: media.displayName,
  mimeType: media.mimeType,
  sizeBytes: media.sizeBytes,
  dateTakenMillis: media.dateTaken?.millisecondsSinceEpoch,
  dateModifiedMillis: media.dateModified.millisecondsSinceEpoch,
  relativePath: media.relativePath,
  kind: media.kind,
  sha256: sha256,
  status: status,
  firstSeenAt: DateTime(2026, 1, 1),
  transferredAt: transferredAt,
  receiverAcknowledgementId: ackId,
  lastError: null,
  removedFromLibraryAt: removedAt,
  deletedAt: deletedAt,
);

/// Scriptable [MediaLibrary] for tests.
class FakeMediaLibrary implements MediaLibrary {
  FakeMediaLibrary({this.access = MediaAccess.full, List<ScannedMedia>? media})
    : media = media ?? [];

  MediaAccess access;
  List<ScannedMedia> media;
  int accessRequests = 0;
  int listCalls = 0;

  /// Source files by media id, for transfer tests.
  final files = <String, File>{};

  @override
  Future<MediaAccess> requestAccess() async {
    accessRequests++;
    return access;
  }

  @override
  Future<MediaAccess> currentAccess() async => access;

  @override
  Future<void> openSettings() async {}

  @override
  Future<void> changeLimitedSelection() async {}

  @override
  Future<List<ScannedMedia>> listCameraMedia({
    ScanProgressCallback? onProgress,
  }) async {
    listCalls++;
    onProgress?.call(media.length, media.length);
    return List.of(media);
  }

  @override
  Future<Uint8List?> thumbnail(String sourceMediaId, {int size = 256}) async =>
      null;

  @override
  Future<File?> originalFile(String sourceMediaId) async =>
      files[sourceMediaId];

  /// Ids Android "deleted"; set [declineDeletes] to simulate the user
  /// refusing the system prompt.
  final deleted = <String>[];
  bool declineDeletes = false;

  @override
  Future<ScannedMedia?> describe(String sourceMediaId) async {
    for (final item in media) {
      if (item.sourceMediaId == sourceMediaId) return item;
    }
    return null;
  }

  @override
  Future<List<String>> delete(List<String> sourceMediaIds) async {
    if (declineDeletes) return const [];
    deleted.addAll(sourceMediaIds);
    media.removeWhere((m) => sourceMediaIds.contains(m.sourceMediaId));
    return sourceMediaIds;
  }
}
