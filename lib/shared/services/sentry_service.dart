import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized Sentry configuration and error tracking service
class SentryService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  static String? _normalizeEnvValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  /// Initialize Sentry with configuration from environment variables
  static Future<void> initialize({
    required String? dsn,
    required String environment,
    String? release,
  }) async {
    if (_isInitialized || _isInitializing) {
      return;
    }

    _isInitializing = true;

    try {
      final normalizedDsn = _normalizeEnvValue(dsn);
      if (normalizedDsn == null) {
        debugPrint('⚠️ Sentry DSN not configured. Skipping initialization.');
        return;
      }

      final trimmedRelease = release?.trim();

      await SentryFlutter.init(
        (options) {
          options.dsn = normalizedDsn;

          // Environment configuration
          options.environment = environment;

          // Sample rate for performance monitoring (1.0 = 100%)
          options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;

          // Enable automatic breadcrumbs
          options.enableAutoSessionTracking = true;

          // Capture failed HTTP requests
          options.captureFailedRequests = true;

          // Debug options
          options.debug = kDebugMode;

          // Attach stack traces to messages
          options.attachStacktrace = true;

          if (trimmedRelease != null && trimmedRelease.isNotEmpty) {
            options.release = trimmedRelease;
          }

          // Filter out sensitive data
          options.beforeSend = (event, hint) {
            // Add custom filtering logic here if needed
            return event;
          };
        },
      );

      _isInitialized = true;

      // Set platform tag
      Sentry.configureScope((scope) {
        scope.setTag('platform', kIsWeb ? 'web' : defaultTargetPlatform.name);
      });

      if (kDebugMode) {
        debugPrint('✅ Sentry initialized successfully');
      }
    } catch (error, stackTrace) {
      debugPrint('⚠️ Sentry initialization failed: $error');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Check if Sentry is initialized
  static bool get isInitialized => _isInitialized;

  /// Capture an exception with optional context
  static Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? hint,
    Map<String, Object?>? extras,
  }) async {
    if (!_isInitialized) return;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'message': hint}) : null,
      withScope: (scope) {
        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }
      },
    );
  }

  /// Capture a message with level
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, Object?>? extras,
  }) async {
    if (!_isInitialized) return;

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }
      },
    );
  }

  /// Add breadcrumb for tracking user actions
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, Object?>? data,
  }) {
    if (!_isInitialized) return;

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
      ),
    );
  }

  /// Set user context for error tracking
  static void setUser({
    String? id,
    String? email,
    String? username,
    Map<String, Object?>? extras,
  }) {
    if (!_isInitialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: id,
          email: email,
          username: username,
          data: extras,
        ),
      );
    });
  }

  /// Clear user context (on logout)
  static void clearUser() {
    if (!_isInitialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Set custom context/tags
  static void setContext(String key, Object? value) {
    if (!_isInitialized) return;

    Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// Set a custom tag
  static void setTag(String key, String value) {
    if (!_isInitialized) return;

    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Start a transaction for performance monitoring
  static ISentrySpan startTransaction(
    String name,
    String operation, {
    String? description,
  }) {
    if (!_isInitialized) {
      return NoOpSentrySpan();
    }

    return Sentry.startTransaction(
      name,
      operation,
      description: description,
    );
  }

  /// Close Sentry (call on app dispose if needed)
  static Future<void> close() async {
    if (!_isInitialized) return;
    await Sentry.close();
    _isInitialized = false;
    _isInitializing = false;
  }
}
