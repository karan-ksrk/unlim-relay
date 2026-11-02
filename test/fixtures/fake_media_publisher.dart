import 'dart:io';

import 'package:lumasync/data/plugin_adapters/media_publisher.dart';
import 'package:path/path.dart' as p;

/// Publishes into a temp "camera" folder, renaming on clashes like
/// MediaStore does.
class FakeMediaPublisher implements MediaPublisher {
  FakeMediaPublisher(this.cameraDirectory);

  final Directory cameraDirectory;
  final published = <String, File>{};
  final dateTaken = <String, DateTime?>{};
  var _nextId = 1000;

  @override
  Future<PublishedMedia> publish(
    File staged, {
    required String name,
    required bool isVideo,
    DateTime? dateTaken,
  }) async {
    await cameraDirectory.create(recursive: true);
    var target = File(p.join(cameraDirectory.path, name));
    for (var n = 1; await target.exists(); n++) {
      target = File(
        p.join(
          cameraDirectory.path,
          '${p.basenameWithoutExtension(name)} ($n)${p.extension(name)}',
        ),
      );
    }
    await staged.copy(target.path);
    final id = '${_nextId++}';
    published[id] = target;
    this.dateTaken[id] = dateTaken;
    return PublishedMedia(id: id, name: p.basename(target.path));
  }

  @override
  Future<File?> publishedFile(String mediaId) async {
    final file = published[mediaId];
    return file != null && await file.exists() ? file : null;
  }
}
