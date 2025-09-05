import 'package:flutter/material.dart';
import 'package:lingua_flutter/shared/domain/card_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/icon_search/icon_search.dart';
import 'features/streak/streak.dart';
import 'features/language/language.dart';
import 'features/mascot/mascot.dart';
import 'features/theme/theme.dart';
import 'shared/navigation/app_router.dart';
import 'shared/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first
  LoggerService.initialize();
  LoggerService.info('🚀 LinguaFlutter app starting...');

  final prefs = await SharedPreferences.getInstance();

  // Create providers
  final languageProvider = LanguageProvider();
  final streakProvider = StreakProvider();
  final cardProvider = CardProvider(languageProvider: languageProvider);
  final themeProvider = ThemeProvider(prefs: prefs);

  // Initialize providers that need async setup
  await cardProvider.initialize();
  await streakProvider.loadStreak();
  
  LoggerService.info('✅ All providers initialized successfully');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: cardProvider),
        ChangeNotifierProvider.value(value: streakProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => MascotProvider()),
        ChangeNotifierProvider(create: (_) => IconProvider()),
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
