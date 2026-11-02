import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

class PublishedMedia {
  const PublishedMedia({required this.id, required this.name});

  /// MediaStore id.
  final String id;

  /// Final display name; Android renames on a clash with an existing file.
  final String name;
}

/// Publishes verified files into the receiver's public camera folder so the
/// gallery and backup apps see them (plan §8).
abstract interface class MediaPublisher {
  static const cameraRelativePath = 'DCIM/Camera/';

  /// Copies [staged] byte-for-byte into DCIM/Camera. [dateTaken] sets the
  /// MediaStore capture date; the file's embedded metadata is untouched.
  Future<PublishedMedia> publish(
    File staged, {
    required String name,
    required bool isVideo,
    DateTime? dateTaken,
  });

  /// The published file for read-back verification, or `null` if gone.
  Future<File?> publishedFile(String mediaId);
}

/// [MediaPublisher] using `photo_manager`'s editor, which inserts a
/// MediaStore row and stream-copies the bytes (no re-encoding). No storage
/// permission is needed on Android 10+.
class PhotoManagerMediaPublisher implements MediaPublisher {
  const PhotoManagerMediaPublisher();

  @override
  Future<PublishedMedia> publish(
    File staged, {
    required String name,
    required bool isVideo,
    DateTime? dateTaken,
  }) async {
    final entity = isVideo
        ? await PhotoManager.editor.saveVideo(
            staged,
            title: name,
            relativePath: MediaPublisher.cameraRelativePath,
            creationDate: dateTaken,
          )
        : await PhotoManager.editor.saveImageWithPath(
            staged.path,
            title: name,
            relativePath: MediaPublisher.cameraRelativePath,
            creationDate: dateTaken,
          );
    return PublishedMedia(id: entity.id, name: entity.title ?? name);
  }

  @override
  Future<File?> publishedFile(String mediaId) async {
    final entity = await AssetEntity.fromId(mediaId);
    return entity?.originFile;
  }
}
