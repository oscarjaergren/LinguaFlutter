import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/icon_search/icon_search.dart';
import 'features/streak/streak.dart';
import 'features/language/language.dart';
import 'features/mascot/mascot.dart';
import 'features/theme/theme.dart';
import 'features/card_review/card_review.dart';
import 'features/card_management/card_management.dart';
import 'features/auth/auth.dart';
import 'features/duplicate_detection/duplicate_detection.dart';
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

Future<void> _initializeServices() async {
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env not required on all platforms
    }
  }

  await SentryService.initialize(
    dsn: _getEnvVar('SENTRY_DSN'),
    environment: _getEnvVar('SENTRY_ENVIRONMENT') ?? _defaultEnvironment,
    release: _getEnvVar('SENTRY_RELEASE'),
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

String? _getEnvVar(String key) {
  final buildTime = String.fromEnvironment(key).trim();
  if (buildTime.isNotEmpty) return buildTime;
  if (kIsWeb) return null;
  return dotenv.env[key]?.trim();
}

String get _defaultEnvironment {
  if (kReleaseMode) return 'production';
  if (kProfileMode) return 'profile';
  return 'development';
}

Future<Widget> _buildApp() async {
  // Create core providers
  final authProvider = AuthProvider();
  final languageProvider = LanguageProvider();
  final streakProvider = StreakProvider();
  final themeProvider = ThemeProvider();
  final exercisePreferencesProvider = ExercisePreferencesProvider();

  // Create feature-specific providers (VSA architecture)
  final cardManagementProvider = CardManagementProvider(
    languageProvider: languageProvider,
  );
  final duplicateDetectionProvider = DuplicateDetectionProvider();
  final cardEnrichmentProvider = CardEnrichmentProvider();

  // Initialize providers that need async setup
  await themeProvider.initialize();
  await cardEnrichmentProvider.initialize();
  await exercisePreferencesProvider.initialize();

  // Wire up auth state change callback to initialize data providers
  authProvider.onAuthStateChanged = (isAuthenticated) async {
    if (isAuthenticated) {
      LoggerService.info(
        '🔐 User authenticated, initializing data providers...',
      );
      try {
        await cardManagementProvider.initialize();
        await streakProvider.loadStreak();
        LoggerService.info('✅ Data providers initialized');
      } catch (e) {
        LoggerService.error('Failed to initialize data providers', e);
      }
    } else {
      LoggerService.info('🔓 User signed out');
    }
  };

  // If already authenticated (e.g., session restored), initialize now
  if (authProvider.isAuthenticated) {
    await cardManagementProvider.initialize();
    await streakProvider.loadStreak();
  }

  LoggerService.info('App startup: providers ready');

  _setupErrorHandlers();

  return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: streakProvider),
        ChangeNotifierProvider.value(value: themeProvider),

        // Feature-specific providers (VSA)
        ChangeNotifierProvider.value(value: cardManagementProvider),
        ChangeNotifierProvider.value(value: duplicateDetectionProvider),
        ChangeNotifierProvider.value(value: cardEnrichmentProvider),

        // UI providers
        ChangeNotifierProvider(create: (_) => MascotProvider()),
        ChangeNotifierProvider(create: (_) => IconProvider()),

        // Exercise preferences provider
        ChangeNotifierProvider.value(value: exercisePreferencesProvider),

        // Practice session provider
        ChangeNotifierProxyProvider<
          CardManagementProvider,
          PracticeSessionProvider
        >(
          create: (context) {
            final cm = context.read<CardManagementProvider>();
            return PracticeSessionProvider(
              getReviewCards: () => cm.reviewCards,
              getAllCards: () => cm.allCards,
              updateCard: cm.updateCard,
            );
          },
          update: (context, cardManagement, previous) =>
              previous ??
              PracticeSessionProvider(
                getReviewCards: () => cardManagement.reviewCards,
                getAllCards: () => cardManagement.allCards,
                updateCard: cardManagement.updateCard,
              ),
        ),
      ],
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

class LinguaFlutterApp extends StatelessWidget {
  const LinguaFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'LinguaFlutter',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
