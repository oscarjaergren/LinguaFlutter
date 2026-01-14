import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized Sentry configuration and error tracking service
class SentryService {
  static bool _isInitialized = false;

  /// Initialize Sentry with configuration from environment variables
  static Future<void> initialize() async {
    // Try dart-define first (for production builds), then fall back to .env
    const dartDefineDsn = String.fromEnvironment('SENTRY_DSN');
    
    // On web, only use dart-define. On other platforms, fall back to .env
    String? sentryDsn;
    if (dartDefineDsn.isNotEmpty) {
      sentryDsn = dartDefineDsn;
    } else if (!kIsWeb) {
      // Only access dotenv on non-web platforms
      sentryDsn = dotenv.env['SENTRY_DSN'];
    }
    
    if (kDebugMode) {
      debugPrint('🔍 Sentry DSN check:');
      debugPrint('  - Platform: ${kIsWeb ? "web" : "native"}');
      debugPrint('  - dart-define: ${dartDefineDsn.isEmpty ? "empty" : "found"}');
      if (!kIsWeb) {
        debugPrint('  - dotenv: ${dotenv.env['SENTRY_DSN']?.isEmpty ?? true ? "empty" : "found"}');
      }
      debugPrint('  - final DSN: ${sentryDsn?.isEmpty ?? true ? "empty" : "found"}');
    }
    
    if (sentryDsn == null || sentryDsn.isEmpty) {
      debugPrint('⚠️ Sentry DSN not found in environment variables. Sentry will not be initialized.');
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        
        // Environment configuration
        options.environment = kDebugMode ? 'development' : 'production';
        
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
        
        // Set release version
        options.release = 'lingua_flutter@1.0.0+1';
        
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
      scope.setTag('platform', defaultTargetPlatform.name);
    });
    
    if (kDebugMode) {
      print('✅ Sentry initialized successfully');
    }
  }

  /// Check if Sentry is initialized
  static bool get isInitialized => _isInitialized;

  /// Capture an exception with optional context
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    Map<String, dynamic>? extras,
  }) async {
    if (!_isInitialized) return;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'message': hint}) : null,
      withScope: (scope) {
        if (extras != null) {
          extras.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  /// Capture a message with level
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (!_isInitialized) return;

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extras != null) {
          extras.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  /// Add breadcrumb for tracking user actions
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
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
    Map<String, dynamic>? extras,
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
  static void setContext(String key, dynamic value) {
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
  }
}
