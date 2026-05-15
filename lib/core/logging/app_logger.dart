import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized logger that only outputs in debug mode.
/// Error-level logs are also forwarded to Firebase Crashlytics in non-debug builds.
class AppLogger {
  const AppLogger._();

  /// Debug-level message — general development logs.
  static void d(String message, {String tag = 'App'}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Info-level message — notable lifecycle events.
  static void i(String message, {String tag = 'App'}) {
    if (kDebugMode) {
      debugPrint('[$tag][INFO] $message');
    }
  }

  /// Warning-level message — unexpected but recoverable situations.
  static void w(String message, {String tag = 'App'}) {
    if (kDebugMode) {
      debugPrint('[$tag][WARN] $message');
    }
  }

  /// Error-level message — failures that need attention.
  /// In non-debug builds, forwards to Firebase Crashlytics as a non-fatal error.
  static void e(
    String message, {
    Object? error,
    StackTrace? stack,
    String tag = 'App',
  }) {
    if (kDebugMode) {
      debugPrint('[$tag][ERROR] $message${error != null ? ': $error' : ''}');
      if (stack != null) {
        debugPrint('[$tag][STACK] $stack');
      }
    } else if (error != null) {
      // Forward to Crashlytics as non-fatal in profile/release builds
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: '[$tag] $message',
        fatal: false,
      );
    }
  }

  /// Structured API call log — safe, no body/token content.
  static void api(
    String method,
    String path, {
    int? statusCode,
    String tag = 'API',
  }) {
    if (kDebugMode) {
      final status = statusCode != null ? ' → $statusCode' : '';
      debugPrint('[$tag] $method $path$status');
    }
  }
}
