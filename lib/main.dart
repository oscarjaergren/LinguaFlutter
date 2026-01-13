import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env file not found, continuing without environment variables');
  }

  // Initialize logging first
  LoggerService.initialize();
  LoggerService.info('🚀 LinguaFlutter app starting...');

  // Initialize Sentry for error tracking
  await SentryService.initialize();

  // Initialize Supabase auth
  await SupabaseAuthService.initialize();

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

  LoggerService.info('✅ Core providers initialized successfully');

  // Set up Flutter error handlers to capture errors in Sentry
  FlutterError.onError = (FlutterErrorDetails details) {
    LoggerService.error(
      'Flutter error caught',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  // Capture errors in async code
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerService.error('Uncaught async error', error, stack);
    return true;
  };

  runApp(
    MultiProvider(
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
    ),
  );
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
