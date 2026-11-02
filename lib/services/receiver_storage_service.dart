import 'dart:io';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../core/utils/secrets.dart';
import '../core/utils/streaming_sha256.dart';
import '../data/database/app_database.dart';
import '../data/plugin_adapters/media_publisher.dart';
import '../data/repositories/received_files_repository.dart';
import 'protocol/messages.dart';

/// Outcome of finishing one incoming file.
sealed class ReceiveResult {
  const ReceiveResult();
}

class ReceiveSaved extends ReceiveResult {
  const ReceiveSaved({
    required this.sha256,
    required this.acknowledgementId,
    required this.savedAs,
    this.duplicate = false,
  });

  final String sha256;
  final String acknowledgementId;
  final String savedAs;

  /// The same bytes were already published; no second copy was made.
  final bool duplicate;
}

class ReceiveRejected extends ReceiveResult {
  const ReceiveRejected(this.reason, {this.retryable = true});

  final String reason;
  final bool retryable;
}

/// A file being written to private staging. Never visible to the gallery.
class IncomingFile {
  IncomingFile._(this.offer, this.senderDeviceId, this._file, this._sink);

  final FileOffer offer;
  final String senderDeviceId;
  final File _file;
  final RandomAccessFile _sink;
  final _hasher = StreamingSha256();
  int _received = 0;

  /// Set when a write fails; later chunks are discarded until the sender's
  /// [FileComplete], then the file is rejected with this reason.
  String? failure;

  int get receivedBytes => _received;

  Future<void> write(Uint8List chunk) async {
    if (failure != null) return;
    _received += chunk.length;
    if (_received > offer.sizeBytes) {
      failure = 'Received more bytes than offered';
      return;
    }
    try {
      _hasher.add(chunk);
      await _sink.writeFrom(chunk);
    } on FileSystemException catch (error) {
      failure = _isNoSpace(error)
          ? 'The receiver is out of storage space.'
          : 'Could not write the file on the receiver: ${error.message}';
    }
  }

  static bool _isNoSpace(FileSystemException error) =>
      error.osError?.errorCode == 28; // ENOSPC
}

/// Stages, verifies and publishes incoming files (plan §6.2, §8).
class ReceiverStorageService {
  ReceiverStorageService({
    required this.stagingDirectory,
    required this._publisher,
    required this._received,
    this._clock = DateTime.now,
  });

  static final _log = Logger('ReceiverStorageService');

  final Directory stagingDirectory;
  final MediaPublisher _publisher;
  final ReceivedFilesRepository _received;
  final DateTime Function() _clock;

  /// Deletes partial files left by an interrupted session.
  Future<void> cleanStaging() async {
    if (!await stagingDirectory.exists()) return;
    await for (final entry in stagingDirectory.list()) {
      if (entry is File && entry.path.endsWith('.part')) {
        await entry.delete();
      }
    }
  }

  /// A verified copy of exactly this source file version that is still in
  /// the gallery, if one exists.
  Future<ReceivedFile?> alreadyReceived(FileOffer offer, String senderId) async {
    final record = await _received.findByTransfer(
      senderDeviceId: senderId,
      transferId: offer.transferId,
      sizeBytes: offer.sizeBytes,
      sourceModifiedMillis: offer.sourceModifiedMillis,
    );
    if (record == null) return null;
    final stillThere = await _publisher.publishedFile(record.publishedMediaId);
    return stillThere == null ? null : record;
  }

  Future<IncomingFile> begin(FileOffer offer, String senderId) async {
    await stagingDirectory.create(recursive: true);
    final file = File(p.join(stagingDirectory.path, '${randomToken(12)}.part'));
    final sink = await file.open(mode: FileMode.writeOnly);
    return IncomingFile._(offer, senderId, file, sink);
  }

  /// Verifies size and hash, publishes to DCIM/Camera and reads the
  /// published copy back. The staging file is always removed.
  Future<ReceiveResult> finish(IncomingFile incoming, String claimedSha) async {
    final offer = incoming.offer;
    try {
      await incoming._sink.close();
      if (incoming.failure case final failure?) {
        return ReceiveRejected(failure);
      }
      if (incoming.receivedBytes != offer.sizeBytes) {
        return ReceiveRejected(
          'Size mismatch: expected ${offer.sizeBytes} bytes, got '
          '${incoming.receivedBytes}.',
        );
      }
      final sha = incoming._hasher.close();
      if (!constantTimeEquals(sha, claimedSha)) {
        return const ReceiveRejected('Checksum mismatch; the file will be resent.');
      }

      // Same bytes under another transfer id (e.g. after a sender reinstall).
      final existing = await _received.findBySha256(sha);
      if (existing != null && await _publisher.publishedFile(existing.publishedMediaId) != null) {
        await _record(incoming, sha, existing.publishedMediaId, existing.publishedName);
        return ReceiveSaved(
          sha256: sha,
          acknowledgementId: existing.acknowledgementId,
          savedAs: existing.publishedName,
          duplicate: true,
        );
      }

      final published = await _publisher.publish(
        incoming._file,
        name: offer.name,
        isVideo: offer.isVideo,
        dateTaken: offer.dateTakenMillis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(offer.dateTakenMillis!),
      );
      final publishedFile = await _publisher.publishedFile(published.id);
      final publishedSha = publishedFile == null
          ? null
          : await StreamingSha256.ofFile(publishedFile);
      if (publishedSha != sha) {
        _log.severe('Read-back mismatch for ${published.name}');
        return const ReceiveRejected(
          'The saved copy did not match after publishing.',
        );
      }

      final ackId = await _record(incoming, sha, published.id, published.name);
      _log.info('Saved ${published.name} (${offer.sizeBytes} bytes)');
      return ReceiveSaved(
        sha256: sha,
        acknowledgementId: ackId,
        savedAs: published.name,
      );
    } on Object catch (error, stackTrace) {
      _log.severe('Publishing ${offer.name} failed', error, stackTrace);
      return ReceiveRejected('Could not save the file on the receiver: $error');
    } finally {
      await _deleteQuietly(incoming._file);
    }
  }

  Future<void> abort(IncomingFile incoming) async {
    try {
      await incoming._sink.close();
    } on Object {
      // Already closed.
    }
    await _deleteQuietly(incoming._file);
  }

  Future<String> _record(
    IncomingFile incoming,
    String sha,
    String mediaId,
    String name,
  ) async {
    final ackId = randomToken(12);
    await _received.add(
      ReceivedFilesCompanion.insert(
        senderDeviceId: incoming.senderDeviceId,
        transferId: incoming.offer.transferId,
        sha256: sha,
        sizeBytes: incoming.offer.sizeBytes,
        sourceModifiedMillis: Value(incoming.offer.sourceModifiedMillis),
        originalName: incoming.offer.name,
        publishedMediaId: mediaId,
        publishedName: name,
        acknowledgementId: ackId,
        receivedAt: _clock(),
      ),
    );
    return ackId;
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort; cleanStaging() retries on the next start.
    }
  }
}
