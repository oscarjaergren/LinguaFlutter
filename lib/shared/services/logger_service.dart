import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'sentry_service.dart';

/// Centralized logging service using Talker with Sentry integration
class LoggerService {
  static late final Talker _talker;

  /// Initialize the logger service
  static void initialize() {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        enabled: true,
        // Enable console logs in debug mode OR on web (for production debugging)
        useConsoleLogs: kDebugMode || kIsWeb,
        useHistory: true,
        maxHistoryItems: 1000,
      ),
      logger: TalkerLogger(settings: TalkerLoggerSettings(enableColors: true)),
    );
  }

  /// Get the Talker instance for advanced usage
  static Talker get instance => _talker;

  static void debug(
    String message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _talker.debug(message, exception, stackTrace);
  }

  static void info(
    String message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _talker.info(message, exception, stackTrace);
    // Add as Sentry breadcrumb for debugging
    if (SentryService.isInitialized) {
      SentryService.addBreadcrumb(
        message: message,
        category: 'app',
        level: SentryLevel.info,
      );
    }
  }

  static void warning(
    String message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _talker.warning(message, exception, stackTrace);

    // Send unexpected warnings with exceptions to Sentry
    if (exception != null && SentryService.isInitialized) {
      SentryService.captureException(
        exception,
        stackTrace: stackTrace,
        hint: message,
      );
    }
  }

  static void error(
    String message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _talker.error(message, exception, stackTrace);

    // Send errors to Sentry in production
    if (SentryService.isInitialized) {
      if (exception != null) {
        SentryService.captureException(
          exception,
          stackTrace: stackTrace,
          hint: message,
        );
      } else {
        SentryService.captureMessage(message, level: SentryLevel.error);
      }
    }
  }

  static void critical(
    String message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _talker.critical(message, exception, stackTrace);

    // Send critical errors to Sentry
    if (SentryService.isInitialized) {
      if (exception != null) {
        SentryService.captureException(
          exception,
          stackTrace: stackTrace,
          hint: message,
        );
      } else {
        SentryService.captureMessage(message, level: SentryLevel.fatal);
      }
    }
  }
}
