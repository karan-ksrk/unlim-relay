import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Routes `package:logging` records to the console.
///
/// Debug builds log everything; release builds log INFO and above.
/// Never log GPS coordinates or other private media metadata (plan §11).
void configureLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer(
      '${record.time.toIso8601String()} '
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) buffer.write(' | ${record.error}');
    debugPrint(buffer.toString());
    if (record.stackTrace != null) debugPrint(record.stackTrace.toString());
  });
}
