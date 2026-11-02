import 'dart:async';
import 'dart:io';

import 'protocol/frame_codec.dart';
import 'protocol/luma_connection.dart';
import 'receiver_locator.dart';
import 'sender_client.dart';
import '../app/app_info.dart';

/// User-facing explanation for a pairing or transfer failure.
String describeTransferError(Object error, {String? host}) => switch (error) {
  HandshakeException() =>
    'The receiver could not be verified. Show a new pairing code on the '
        'receiver and scan it again.',
  NotPairedException() => '$error',
  PairingRejectedException(:final reason) => reason,
  RemoteErrorException(:final error) => error.message,
  SocketException(:final osError?) when _refusedCodes.contains(osError.errorCode) =>
    'The receiver${host == null ? '' : ' at $host'} is not accepting '
        'connections. Open $appName on the receiver phone and turn on Ready '
        'to receive.',
  SocketException() || TimeoutException() =>
    'Could not reach the receiver${host == null ? '' : ' at $host'}. Make '
        'sure $appName is open on it with Ready to receive on, and both '
        'phones are on the same Wi-Fi.',
  ProtocolException(:final message) => 'Communication error: $message',
  FileSystemException(:final message) => 'Could not read the file: $message',
  _ => 'Something went wrong: $error',
};

/// Connection refused: ECONNREFUSED on Android/Linux (111), and on Windows
/// (1225, 10061) where the tests run.
const _refusedCodes = {111, 1225, 10061};
