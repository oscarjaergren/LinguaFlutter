import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Centralized logging service using Talker
class LoggerService {
  static late final Talker _talker;
  
  /// Initialize the logger service
  static void initialize() {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        enabled: true,
        useConsoleLogs: kDebugMode,
        useHistory: true,
        maxHistoryItems: 1000,
      ),
      logger: TalkerLogger(
        settings: TalkerLoggerSettings(
          enableColors: true,
        ),
      ),
    );
  }

  /// Get the Talker instance for advanced usage
  static Talker get instance => _talker;

  static void debug(String message, [Object? exception, StackTrace? stackTrace]) {
    _talker.debug(message, exception, stackTrace);
  }

  static void info(String message, [Object? exception, StackTrace? stackTrace]) {
    _talker.info(message, exception, stackTrace);
  }

  static void warning(String message, [Object? exception, StackTrace? stackTrace]) {
    _talker.warning(message, exception, stackTrace);
  }

  static void error(String message, [Object? exception, StackTrace? stackTrace]) {
    _talker.error(message, exception, stackTrace);
  }

  static void critical(String message, [Object? exception, StackTrace? stackTrace]) {
    _talker.critical(message, exception, stackTrace);
  }
}
