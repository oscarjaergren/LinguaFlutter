import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/theme/theme.dart';
import 'features/card_review/card_review.dart';
import 'features/card_management/card_management.dart';
import 'features/auth/auth.dart';
import 'shared/navigation/app_router.dart';
import 'shared/services/logger_service.dart';
import 'shared/services/sentry_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await _initializeServices();
    LoggerService.info('App startup: services ready');

    final error = await _initializeSupabase();
    if (error != null) {
      LoggerService.error('App startup failed: Supabase error');
      runApp(_ErrorApp(error: error));
      return;
    }
    LoggerService.info('App startup: Supabase ready');

    runApp(await _buildApp());
    LoggerService.info('App startup complete');
  } catch (e, stackTrace) {
    // Capture any early startup failures before services are ready
    debugPrint('Fatal startup error: $e');
    SentryService.captureException(e, stackTrace: stackTrace);
    runApp(_ErrorApp(error: e.toString()));
  }
}

// Build-time constants - must be const for String.fromEnvironment
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const _sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT');
const _sentryRelease = String.fromEnvironment('SENTRY_RELEASE');

Future<void> _initializeServices() async {
  await SentryService.initialize(
    dsn: _sentryDsn.trim().isEmpty ? null : _sentryDsn.trim(),
    environment: _sentryEnvironment.trim().isEmpty
        ? _defaultEnvironment
        : _sentryEnvironment.trim(),
    release: _sentryRelease.trim().isEmpty ? null : _sentryRelease.trim(),
  );

  LoggerService.initialize();
}

Future<String?> _initializeSupabase() async {
  try {
    await SupabaseAuthService.initialize();
    return null;
  } catch (e, stackTrace) {
    LoggerService.error('Supabase initialization failed', e, stackTrace);
    await SentryService.captureException(e, stackTrace: stackTrace);
    return e.toString();
  }
}

String get _defaultEnvironment {
  if (kReleaseMode) return 'production';
  if (kProfileMode) return 'profile';
  return 'development';
}

Future<Widget> _buildApp() async {
  // Create Riverpod container
  final container = ProviderContainer();

  // Initialize providers that need async setup
  await container.read(themeNotifierProvider.notifier).initialize();
  await container
      .read(exercisePreferencesNotifierProvider.notifier)
      .initialize();
  await container.read(cardEnrichmentNotifierProvider.notifier).initialize();

  // Initialize Card Management if already authenticated
  if (container.read(authNotifierProvider).isAuthenticated) {
    await container.read(cardManagementNotifierProvider.notifier).initialize();
  }

  // Listen for auth state changes to initialize card management
  container.listen<AuthState>(authNotifierProvider, (previous, next) async {
    if (previous?.isAuthenticated != true && next.isAuthenticated) {
      LoggerService.info(
        '🔐 User authenticated, initializing CardManagementNotifier...',
      );
      try {
        await container
            .read(cardManagementNotifierProvider.notifier)
            .initialize();
        LoggerService.info('✅ CardManagementNotifier initialized');
      } catch (e) {
        LoggerService.error('Failed to initialize CardManagementNotifier', e);
      }
    }
  });

  LoggerService.info('App startup: providers ready');

  _setupErrorHandlers();

  return UncontrolledProviderScope(
    container: container,
    child: const LinguaFlutterApp(),
  );
}

void _setupErrorHandlers() {
  FlutterError.onError = (details) {
    LoggerService.error('Flutter error', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerService.error('Uncaught async error', error, stack);
    return true;
  };
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Configuration Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode ? error : 'Unable to connect. Please try again.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LinguaFlutterApp extends ConsumerWidget {
  const LinguaFlutterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    return MaterialApp.router(
      title: 'LinguaFlutter',
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeState.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
