import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/media_enums.dart';
import 'media_library.dart';

/// [MediaLibrary] backed by `package:photo_manager` (Android MediaStore).
class PhotoManagerMediaLibrary implements MediaLibrary {
  /// [inBackground] is for the WorkManager engine, which has no Activity.
  PhotoManagerMediaLibrary({this.inBackground = false});

  static final _log = Logger('PhotoManagerMediaLibrary');

  final bool inBackground;

  /// `mediaLocation` grants ACCESS_MEDIA_LOCATION so original files keep
  /// their GPS EXIF when read; without it Android redacts it.
  static const _permissionOption = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.common,
      mediaLocation: true,
    ),
  );

  static const _pageSize = 500;

  /// File size is a separate plugin call per asset; run a bounded number
  /// concurrently.
  static const _sizeConcurrency = 32;

  /// A custom `where` replaces the plugin's own image/video condition, so
  /// the media types (1 = image, 3 = video) are listed explicitly.
  static final _cameraFilter = CustomFilter.sql(
    where:
        "relative_path LIKE 'DCIM/Camera/%' "
        'AND ${CustomColumns.base.mediaType} IN (1, 3)',
    orderBy: [OrderByItem.asc(CustomColumns.base.id)],
  );

  @override
  Future<MediaAccess> requestAccess() async => _toAccess(
    await PhotoManager.requestPermissionExtend(
      requestOption: _permissionOption,
    ),
  );

  @override
  Future<MediaAccess> currentAccess() async {
    if (inBackground) return _backgroundAccess();
    return _toAccess(
      await PhotoManager.getPermissionState(requestOption: _permissionOption),
    );
  }

  /// photo_manager's permission check needs an Activity; permission_handler
  /// reads the same runtime permissions (READ_MEDIA_IMAGES/VIDEO, or storage
  /// on Android 12 and lower) from the application context.
  static Future<MediaAccess> _backgroundAccess() async {
    final statuses = [
      await Permission.photos.status,
      await Permission.videos.status,
    ];
    if (statuses.every((status) => status.isGranted)) return MediaAccess.full;
    if (statuses.any((status) => status.isGranted || status.isLimited)) {
      return MediaAccess.limited;
    }
    return MediaAccess.denied;
  }

  @override
  Future<void> openSettings() => PhotoManager.openSetting();

  @override
  Future<void> changeLimitedSelection() =>
      PhotoManager.presentLimited(type: RequestType.common);

  @override
  Future<List<ScannedMedia>> listCameraMedia({
    ScanProgressCallback? onProgress,
  }) async {
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
      filterOption: _cameraFilter,
    );
    if (paths.isEmpty) return const [];

    final path = paths.first;
    final total = await path.assetCountAsync;
    final result = <ScannedMedia>[];
    onProgress?.call(0, total);

    for (var start = 0; start < total; start += _pageSize) {
      final page = await path.getAssetListRange(
        start: start,
        end: min(start + _pageSize, total),
      );
      for (var i = 0; i < page.length; i += _sizeConcurrency) {
        final chunk = page.sublist(i, min(i + _sizeConcurrency, page.length));
        final sizes = await Future.wait(chunk.map((asset) => asset.fileSize));
        for (var j = 0; j < chunk.length; j++) {
          result.add(_toScanned(chunk[j], sizes[j]));
        }
      }
      onProgress?.call(result.length, total);
    }

    _log.fine('Listed ${result.length} of $total camera assets');
    return result;
  }

  @override
  Future<Uint8List?> thumbnail(String sourceMediaId, {int size = 256}) async {
    final asset = await AssetEntity.fromId(sourceMediaId);
    return asset?.thumbnailDataWithSize(ThumbnailSize.square(size));
  }

  /// On Android 11+ this is the file's real path, so nothing is copied;
  /// with ACCESS_MEDIA_LOCATION granted, reads are not GPS-redacted.
  @override
  Future<File?> originalFile(String sourceMediaId) async {
    final asset = await AssetEntity.fromId(sourceMediaId);
    return asset?.originFile;
  }

  static MediaAccess _toAccess(PermissionState state) {
    if (state.isAuth) return MediaAccess.full;
    if (state.hasAccess) return MediaAccess.limited;
    return MediaAccess.denied;
  }

  static ScannedMedia _toScanned(AssetEntity asset, int sizeBytes) {
    return ScannedMedia(
      sourceMediaId: asset.id,
      displayName: asset.title ?? '',
      mimeType: asset.mimeType ?? 'application/octet-stream',
      sizeBytes: sizeBytes,
      dateTaken: asset.createDateTime,
      dateModified: asset.modifiedDateTime,
      relativePath: asset.relativePath,
      kind: asset.type == AssetType.video ? MediaKind.video : MediaKind.image,
    );
  }
}
