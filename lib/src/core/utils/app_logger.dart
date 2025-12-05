import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global logger instance for debug/development
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: kDebugMode ? Level.debug : Level.info,
);

/// Simplified logger for production builds
final productionLogger = Logger(
  printer: SimplePrinter(colors: false),
  level: Level.info,
);

/// Legacy AppLogger class for backward compatibility
/// New code should use appLogger directly: appLogger.i(), appLogger.e(), etc.
class AppLogger {
  static const String _tag = 'Tasker';

  /// Log a debug message
  static void debug(String message, {String? tag}) {
    appLogger.d('[${tag ?? _tag}] $message');
  }

  /// Log an info message
  static void info(String message, {String? tag}) {
    appLogger.i('[${tag ?? _tag}] $message');
  }

  /// Log a warning message
  static void warning(String message, {String? tag, dynamic error}) {
    appLogger.w('[${tag ?? _tag}] $message', error: error);
  }

  /// Log an error message
  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    appLogger.e(
      '[${tag ?? _tag}] $message',
      error: error,
      stackTrace: stackTrace,
    );

    // TODO: Send to Firebase Crashlytics in production
    // if (kReleaseMode && error != null) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // }
  }

  /// Log a feature action (for analytics tracking)
  static void logAction(String action, {Map<String, dynamic>? parameters}) {
    appLogger.i(
      'Action: $action ${parameters != null ? parameters.toString() : ''}',
    );

    // TODO: Send to Firebase Analytics in production
    // if (kReleaseMode) {
    //   FirebaseAnalytics.instance.logEvent(
    //     name: action,
    //     parameters: parameters,
    //   );
    // }
  }

  /// Log user sign in
  static void logSignIn(String method) {
    logAction('user_sign_in', parameters: {'method': method});
  }

  /// Log user sign out
  static void logSignOut() {
    logAction('user_sign_out');
  }

  /// Log project created
  static void logProjectCreated(String projectId) {
    logAction('project_created', parameters: {'project_id': projectId});
  }

  /// Log task created
  static void logTaskCreated(String taskId, String projectId) {
    logAction(
      'task_created',
      parameters: {'task_id': taskId, 'project_id': projectId},
    );
  }

  /// Log chat message sent
  static void logMessageSent(String projectId) {
    logAction('message_sent', parameters: {'project_id': projectId});
  }
}

/// Log a synchronous operation with timing information.
T logTimed<T>(
  String operation,
  T Function() action, {
  Level level = Level.info,
}) {
  final stopwatch = Stopwatch()..start();
  try {
    final result = action();
    stopwatch.stop();
    appLogger.log(
      level,
      '$operation completed in ${stopwatch.elapsedMilliseconds}ms',
    );
    return result;
  } catch (error, stackTrace) {
    stopwatch.stop();
    appLogger.e(
      '$operation failed after ${stopwatch.elapsedMilliseconds}ms',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// Log an async operation with timing information.
Future<T> logTimedAsync<T>(
  String operation,
  Future<T> Function() action, {
  Level level = Level.info,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final result = await action();
    stopwatch.stop();
    appLogger.log(
      level,
      '$operation completed in ${stopwatch.elapsedMilliseconds}ms',
    );
    return result;
  } catch (error, stackTrace) {
    stopwatch.stop();
    appLogger.e(
      '$operation failed after ${stopwatch.elapsedMilliseconds}ms',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// Mask an email address for safe logging (e.g., jo***@domain.com).
String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return '***@***';
  final username = parts.first;
  final maskedUser = username.length <= 2
      ? '***'
      : '${username.substring(0, 2)}***';
  return '$maskedUser@${parts.last}';
}

/// Mask sensitive text, keeping only the first [visibleChars].
String maskText(String text, {int visibleChars = 3}) {
  if (text.isEmpty) return '***';
  final prefix = text.length <= visibleChars
      ? text
      : text.substring(0, visibleChars);
  return prefix.padRight(prefix.length + 3, '*');
}

/// Format a byte length into a human-friendly string.
String formatDataSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 2)} ${units[unitIndex]}';
}

/// Build a structured error context string for consistent logging.
String buildErrorContext(Map<String, dynamic> context) {
  return context.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join(', ');
}
