import 'frame_codec.dart';

/// Bumped on any incompatible change to messages or framing.
const currentProtocolVersion = 1;

/// Control messages exchanged as JSON frames (plan §7).
///
/// Messages carry only what the protocol needs; no GPS or other embedded
/// metadata travels outside the file bytes.
sealed class LumaMessage {
  const LumaMessage();

  String get type;

  Map<String, Object?> get body;

  Map<String, Object?> toJson() => {'type': type, ...body};

  static LumaMessage fromJson(Map<String, Object?> json) {
    T field<T>(String name) {
      final value = json[name];
      if (value is T) return value;
      throw ProtocolException('Message ${json['type']} has a bad "$name"');
    }

    return switch (json['type']) {
      'pairRequest' => PairRequest(
        protocolVersion: field<int>('protocolVersion'),
        pairingSecret: field<String>('pairingSecret'),
        senderId: field<String>('senderId'),
        senderName: field<String>('senderName'),
      ),
      'pairAccepted' => PairAccepted(
        receiverId: field<String>('receiverId'),
        receiverName: field<String>('receiverName'),
        authToken: field<String>('authToken'),
      ),
      'pairRejected' => PairRejected(reason: field<String>('reason')),
      'hello' => Hello(
        protocolVersion: field<int>('protocolVersion'),
        senderId: field<String>('senderId'),
        authToken: field<String>('authToken'),
      ),
      'helloAccepted' => HelloAccepted(
        receiverId: field<String>('receiverId'),
        receiverName: field<String>('receiverName'),
      ),
      'ping' => Ping(field<int>('nonce')),
      'pong' => Pong(field<int>('nonce')),
      'manifest' => Manifest(
        protocolVersion: field<int>('protocolVersion'),
        sessionId: field<String>('sessionId'),
        senderDeviceId: field<String>('senderDeviceId'),
        files: [
          for (final file in field<List<Object?>>('files'))
            if (file is Map<String, Object?>)
              ManifestFile.fromJson(file)
            else
              throw const ProtocolException('Bad manifest entry'),
        ],
      ),
      'manifestAck' => ManifestAck(
        sessionId: field<String>('sessionId'),
        fileCount: field<int>('fileCount'),
        totalBytes: field<int>('totalBytes'),
      ),
      'fileOffer' => FileOffer(
        transferId: field<String>('transferId'),
        name: field<String>('name'),
        mimeType: field<String>('mimeType'),
        sizeBytes: field<int>('sizeBytes'),
        dateTakenMillis: json['dateTakenMillis'] == null
            ? null
            : field<int>('dateTakenMillis'),
        sourceModifiedMillis: field<int>('sourceModifiedMillis'),
      ),
      'fileAccept' => FileAccept(transferId: field<String>('transferId')),
      'fileAlreadyPresent' => FileAlreadyPresent(
        transferId: field<String>('transferId'),
        sha256: field<String>('sha256'),
        acknowledgementId: field<String>('acknowledgementId'),
      ),
      'fileComplete' => FileComplete(
        transferId: field<String>('transferId'),
        sha256: field<String>('sha256'),
      ),
      'fileAck' => FileAck(
        transferId: field<String>('transferId'),
        sha256: field<String>('sha256'),
        acknowledgementId: field<String>('acknowledgementId'),
        savedAs: field<String>('savedAs'),
      ),
      'fileRejected' => FileRejected(
        transferId: field<String>('transferId'),
        reason: field<String>('reason'),
        retryable: field<bool>('retryable'),
      ),
      'error' => ErrorMessage(
        code: field<String>('code'),
        message: field<String>('message'),
      ),
      final other => throw ProtocolException('Unknown message type $other'),
    };
  }
}

class PairRequest extends LumaMessage {
  const PairRequest({
    this.protocolVersion = currentProtocolVersion,
    required this.pairingSecret,
    required this.senderId,
    required this.senderName,
  });

  final int protocolVersion;
  final String pairingSecret;
  final String senderId;
  final String senderName;

  @override
  String get type => 'pairRequest';

  @override
  Map<String, Object?> get body => {
    'protocolVersion': protocolVersion,
    'pairingSecret': pairingSecret,
    'senderId': senderId,
    'senderName': senderName,
  };
}

class PairAccepted extends LumaMessage {
  const PairAccepted({
    required this.receiverId,
    required this.receiverName,
    required this.authToken,
  });

  final String receiverId;
  final String receiverName;

  /// Long-term secret the sender presents in [Hello]. Store securely.
  final String authToken;

  @override
  String get type => 'pairAccepted';

  @override
  Map<String, Object?> get body => {
    'receiverId': receiverId,
    'receiverName': receiverName,
    'authToken': authToken,
  };
}

class PairRejected extends LumaMessage {
  const PairRejected({required this.reason});

  final String reason;

  @override
  String get type => 'pairRejected';

  @override
  Map<String, Object?> get body => {'reason': reason};
}

class Hello extends LumaMessage {
  const Hello({
    this.protocolVersion = currentProtocolVersion,
    required this.senderId,
    required this.authToken,
  });

  final int protocolVersion;
  final String senderId;
  final String authToken;

  @override
  String get type => 'hello';

  @override
  Map<String, Object?> get body => {
    'protocolVersion': protocolVersion,
    'senderId': senderId,
    'authToken': authToken,
  };
}

class HelloAccepted extends LumaMessage {
  const HelloAccepted({required this.receiverId, required this.receiverName});

  final String receiverId;
  final String receiverName;

  @override
  String get type => 'helloAccepted';

  @override
  Map<String, Object?> get body => {
    'receiverId': receiverId,
    'receiverName': receiverName,
  };
}

class Ping extends LumaMessage {
  const Ping(this.nonce);

  final int nonce;

  @override
  String get type => 'ping';

  @override
  Map<String, Object?> get body => {'nonce': nonce};
}

class Pong extends LumaMessage {
  const Pong(this.nonce);

  final int nonce;

  @override
  String get type => 'pong';

  @override
  Map<String, Object?> get body => {'nonce': nonce};
}

class ManifestFile {
  const ManifestFile({
    required this.transferId,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    this.dateTakenMillis,
    this.sha256,
  });

  factory ManifestFile.fromJson(Map<String, Object?> json) {
    final transferId = json['transferId'];
    final name = json['name'];
    final mimeType = json['mimeType'];
    final sizeBytes = json['sizeBytes'];
    final dateTaken = json['dateTakenMillis'];
    final sha256 = json['sha256'];
    if (transferId is! String ||
        name is! String ||
        mimeType is! String ||
        sizeBytes is! int ||
        (dateTaken != null && dateTaken is! int) ||
        (sha256 != null && sha256 is! String)) {
      throw const ProtocolException('Bad manifest entry');
    }
    return ManifestFile(
      transferId: transferId,
      name: name,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      dateTakenMillis: dateTaken as int?,
      sha256: sha256 as String?,
    );
  }

  final String transferId;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final int? dateTakenMillis;

  /// Computed while streaming in Milestone 4; `null` until then.
  final String? sha256;

  Map<String, Object?> toJson() => {
    'transferId': transferId,
    'name': name,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'dateTakenMillis': dateTakenMillis,
    'sha256': sha256,
  };
}

class Manifest extends LumaMessage {
  const Manifest({
    this.protocolVersion = currentProtocolVersion,
    required this.sessionId,
    required this.senderDeviceId,
    required this.files,
  });

  final int protocolVersion;
  final String sessionId;
  final String senderDeviceId;
  final List<ManifestFile> files;

  @override
  String get type => 'manifest';

  @override
  Map<String, Object?> get body => {
    'protocolVersion': protocolVersion,
    'sessionId': sessionId,
    'senderDeviceId': senderDeviceId,
    'files': [for (final file in files) file.toJson()],
  };
}

class ManifestAck extends LumaMessage {
  const ManifestAck({
    required this.sessionId,
    required this.fileCount,
    required this.totalBytes,
  });

  final String sessionId;
  final int fileCount;
  final int totalBytes;

  @override
  String get type => 'manifestAck';

  @override
  Map<String, Object?> get body => {
    'sessionId': sessionId,
    'fileCount': fileCount,
    'totalBytes': totalBytes,
  };
}

/// Sender proposes the next file. Data frames follow only after
/// [FileAccept].
class FileOffer extends LumaMessage {
  const FileOffer({
    required this.transferId,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.sourceModifiedMillis,
    this.dateTakenMillis,
  });

  final String transferId;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final int? dateTakenMillis;
  final int sourceModifiedMillis;

  bool get isVideo => mimeType.startsWith('video/');

  @override
  String get type => 'fileOffer';

  @override
  Map<String, Object?> get body => {
    'transferId': transferId,
    'name': name,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'dateTakenMillis': dateTakenMillis,
    'sourceModifiedMillis': sourceModifiedMillis,
  };
}

class FileAccept extends LumaMessage {
  const FileAccept({required this.transferId});

  final String transferId;

  @override
  String get type => 'fileAccept';

  @override
  Map<String, Object?> get body => {'transferId': transferId};
}

/// The receiver already holds a verified, published copy of the offered
/// file, so no bytes are sent.
class FileAlreadyPresent extends LumaMessage {
  const FileAlreadyPresent({
    required this.transferId,
    required this.sha256,
    required this.acknowledgementId,
  });

  final String transferId;
  final String sha256;
  final String acknowledgementId;

  @override
  String get type => 'fileAlreadyPresent';

  @override
  Map<String, Object?> get body => {
    'transferId': transferId,
    'sha256': sha256,
    'acknowledgementId': acknowledgementId,
  };
}

/// Sent after the last data frame, with the SHA-256 of every byte sent.
class FileComplete extends LumaMessage {
  const FileComplete({required this.transferId, required this.sha256});

  final String transferId;
  final String sha256;

  @override
  String get type => 'fileComplete';

  @override
  Map<String, Object?> get body => {'transferId': transferId, 'sha256': sha256};
}

/// Final acknowledgement: size and hash verified, file published to
/// DCIM/Camera and read back. Only this marks a file transferred.
class FileAck extends LumaMessage {
  const FileAck({
    required this.transferId,
    required this.sha256,
    required this.acknowledgementId,
    required this.savedAs,
  });

  final String transferId;
  final String sha256;
  final String acknowledgementId;
  final String savedAs;

  @override
  String get type => 'fileAck';

  @override
  Map<String, Object?> get body => {
    'transferId': transferId,
    'sha256': sha256,
    'acknowledgementId': acknowledgementId,
    'savedAs': savedAs,
  };
}

class FileRejected extends LumaMessage {
  const FileRejected({
    required this.transferId,
    required this.reason,
    required this.retryable,
  });

  final String transferId;
  final String reason;
  final bool retryable;

  @override
  String get type => 'fileRejected';

  @override
  Map<String, Object?> get body => {
    'transferId': transferId,
    'reason': reason,
    'retryable': retryable,
  };
}

class ErrorMessage extends LumaMessage {
  const ErrorMessage({required this.code, required this.message});

  static const unauthorized = 'unauthorized';
  static const unsupportedVersion = 'unsupportedVersion';
  static const unexpectedMessage = 'unexpectedMessage';

  final String code;
  final String message;

  @override
  String get type => 'error';

  @override
  Map<String, Object?> get body => {'code': code, 'message': message};
}
