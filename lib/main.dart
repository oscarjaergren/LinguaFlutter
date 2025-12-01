import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/icon_search/icon_search.dart';
import 'features/streak/streak.dart';
import 'features/language/language.dart';
import 'features/mascot/mascot.dart';
import 'features/theme/theme.dart';
import 'features/card_review/card_review.dart';
import 'features/card_management/card_management.dart';
import 'features/duplicate_detection/duplicate_detection.dart';
import 'shared/navigation/app_router.dart';
import 'shared/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first
  LoggerService.initialize();
  LoggerService.info('🚀 LinguaFlutter app starting...');

  final prefs = await SharedPreferences.getInstance();

  // Create core providers
  final languageProvider = LanguageProvider();
  final streakProvider = StreakProvider();
  final themeProvider = ThemeProvider(prefs: prefs);
  
  // Create feature-specific providers (VSA architecture)
  final cardManagementProvider = CardManagementProvider(
    languageProvider: languageProvider,
  );
  final duplicateDetectionProvider = DuplicateDetectionProvider();

  // Initialize providers that need async setup
  await cardManagementProvider.initialize();
  await streakProvider.loadStreak();
  
  LoggerService.info('✅ All providers initialized successfully');

  runApp(
    MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: streakProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        
        // Feature-specific providers (VSA)
        ChangeNotifierProvider.value(value: cardManagementProvider),
        ChangeNotifierProvider.value(value: duplicateDetectionProvider),
        
        // UI providers
        ChangeNotifierProvider(create: (_) => MascotProvider()),
        ChangeNotifierProvider(create: (_) => IconProvider()),
        
        // Session providers
        ChangeNotifierProxyProvider<CardManagementProvider, ReviewSessionProvider>(
          create: (context) => ReviewSessionProvider(
            updateCard: context.read<CardManagementProvider>().updateCard,
          ),
          update: (context, cardManagement, previous) =>
              previous ?? ReviewSessionProvider(updateCard: cardManagement.updateCard),
        ),
        ChangeNotifierProxyProvider<CardManagementProvider, ExerciseSessionProvider>(
          create: (context) {
            final cm = context.read<CardManagementProvider>();
            return ExerciseSessionProvider(
              getReviewCards: () => cm.reviewCards,
              getAllCards: () => cm.allCards,
              updateCard: cm.updateCard,
            );
          },
          update: (context, cardManagement, previous) =>
              previous ?? ExerciseSessionProvider(
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
