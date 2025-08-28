import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/icon_provider.dart';
import 'providers/card_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/language_provider.dart';
import 'providers/mascot_provider.dart';
import 'package:lingua_flutter/providers/theme_provider.dart';
import 'screens/card_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Create providers
  final languageProvider = LanguageProvider();
  final streakProvider = StreakProvider();
  final cardProvider = CardProvider(languageProvider: languageProvider);
  final themeProvider = ThemeProvider(prefs: prefs);

  // Set up dependencies between providers
  cardProvider.setStreakProvider(streakProvider);

  // Initialize providers that need async setup
  await cardProvider.initialize();
  await streakProvider.loadStreak();

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
        return MaterialApp(
          title: 'LinguaFlutter',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const CardListScreen(),
        );
      },
    );
  }
}
