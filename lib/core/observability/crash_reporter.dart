import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized crash and error reporting via Firebase Crashlytics.
///
/// Usage:
/// - Call [init] once in main() before runApp.
/// - Set [FlutterError.onError] to [recordFlutterError].
/// - Wrap main() body with [runZonedGuarded] using [recordError].
/// - Call [setUserId] after login to attach user context to reports.
class CrashReporter {
  const CrashReporter._();

  /// Initialize Firebase Crashlytics.
  /// In debug mode, crash collection is disabled to avoid noise.
  static Future<void> init() async {
    // Disable Crashlytics in debug builds — only collect in profile/release
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }

  /// Handler for Flutter framework errors (widget build errors, etc.).
  /// Pass this to [FlutterError.onError].
  static void recordFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, print to console as usual
      FlutterError.dumpErrorToConsole(details);
    } else {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  }

  /// Handler for async errors outside the Flutter framework.
  /// Pass this as the second argument to [runZonedGuarded].
  static void recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) {
    if (kDebugMode) {
      debugPrint('[CrashReporter] Error: $error');
      debugPrint('[CrashReporter] Stack: $stack');
    } else {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
    }
  }

  /// Attach a user ID to all subsequent crash reports.
  /// Call this after successful login, clear on logout.
  static Future<void> setUserId(String? userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
  }

  /// Add a custom key-value pair to crash reports for extra context.
  static Future<void> setCustomKey(String key, Object value) async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }

  /// Log a non-fatal message that appears in the Crashlytics console.
  static void log(String message) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    }
  }
}
