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

    // Log initialization
    _talker.info('🚀 LoggerService initialized');
  }

  /// Get the Talker instance
  static Talker get instance => _talker;

  // Convenience methods for different log levels
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

  // Feature-specific logging methods
  /// Log card-related actions
  static void logCardAction(String action, String cardId, [Map<String, dynamic>? metadata]) {
    _talker.info('🃏 Card $action: $cardId${metadata != null ? ' - $metadata' : ''}');
  }
  
  /// Log language changes
  static void logLanguageChange(String fromLanguage, String toLanguage) {
    _talker.info('🌍 Language changed: $fromLanguage → $toLanguage');
  }
  
  /// Log review session data
  static void logReviewSession(String sessionType, Map<String, dynamic> sessionData) {
    _talker.info('📚 Review session $sessionType: $sessionData');
  }
  
  /// Log navigation events
  static void logNavigation(String from, String to) {
    _talker.debug('🧭 Navigation: $from → $to');
  }
  
  /// Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    _talker.debug('⚡ Performance: $operation took ${duration.inMilliseconds}ms');
  }
  
  /// Log user interactions
  static void logUserInteraction(String interaction, [Map<String, dynamic>? context]) {
    _talker.debug('👤 User interaction: $interaction${context != null ? ' - $context' : ''}');
  }
  
  // Advanced logging methods
  
  /// Log with custom message
  static void logCustom(String message, [Map<String, dynamic>? metadata]) {
    _talker.info(message);
  }
  
  /// Log performance with automatic timing
  static Future<T> logTimed<T>(String operation, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      logPerformance(operation, stopwatch.elapsed);
      return result;
    } catch (e, stackTrace) {
      error('Failed during timed operation: $operation', e, stackTrace);
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }
  
  /// Share logs (useful for debugging)
  static void shareLogs() {
    _talker.info('📤 Sharing logs...');
    // Implementation would depend on platform-specific sharing
  }

  // Error handling
  static void handleError(Object error, StackTrace stackTrace, [String? context]) {
    _talker.handle(
      error,
      stackTrace,
      context ?? 'Unknown context',
    );
  }


  // Memory and cleanup
  static void dispose() {
    _talker.info('🛑 LoggerService disposed');
  }
}
