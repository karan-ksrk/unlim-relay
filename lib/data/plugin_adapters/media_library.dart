import 'dart:io';
import 'dart:typed_data';

import '../models/media_enums.dart';

enum MediaAccess {
  /// All photos and videos are readable.
  full,

  /// Android 14+ "selected photos" access: only the user's picks are visible.
  limited,

  denied,
}

/// One camera file as reported by the media library.
class ScannedMedia {
  const ScannedMedia({
    required this.sourceMediaId,
    required this.displayName,
    required this.mimeType,
    required this.sizeBytes,
    required this.dateModified,
    required this.kind,
    this.dateTaken,
    this.relativePath,
  });

  final String sourceMediaId;
  final String displayName;
  final String mimeType;
  final int sizeBytes;
  final DateTime? dateTaken;
  final DateTime dateModified;
  final String? relativePath;
  final MediaKind kind;
}

typedef ScanProgressCallback = void Function(int scanned, int total);

/// Plugin-neutral access to the device media library.
abstract interface class MediaLibrary {
  /// Prompts for photo/video access if needed.
  Future<MediaAccess> requestAccess();

  Future<MediaAccess> currentAccess();

  /// Opens the system app settings so the user can change access.
  Future<void> openSettings();

  /// Re-opens the Android 14+ selected-photos picker.
  Future<void> changeLimitedSelection();

  /// Lists camera photos and videos in `DCIM/Camera` and its subfolders.
  Future<List<ScannedMedia>> listCameraMedia({ScanProgressCallback? onProgress});

  /// Returns a square JPEG thumbnail, or `null` if the file is gone.
  Future<Uint8List?> thumbnail(String sourceMediaId, {int size = 256});

  /// The original file, read with location metadata intact, or `null` if it
  /// no longer exists.
  Future<File?> originalFile(String sourceMediaId);

  /// The file as the library describes it now, or `null` if it is gone.
  Future<ScannedMedia?> describe(String sourceMediaId);

  /// Asks Android to delete these originals. Android shows its own
  /// confirmation; the result holds only the ids actually deleted (none if
  /// the user declined).
  Future<List<String>> delete(List<String> sourceMediaIds);
}
