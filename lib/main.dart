import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/icon_provider.dart';
import 'providers/card_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/language_provider.dart';
import 'providers/mascot_provider.dart';
import 'screens/card_list_screen.dart';

void main() {
  runApp(const LinguaFlutterApp());
}

class LinguaFlutterApp extends StatelessWidget {
  const LinguaFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IconProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => MascotProvider()),
        ChangeNotifierProxyProvider<StreakProvider, CardProvider>(
          create: (_) => CardProvider(),
          update: (_, streakProvider, cardProvider) {
            cardProvider?.setStreakProvider(streakProvider);
            return cardProvider!;
          },
        ),
      ],
      child: FocusScope(
        child: MaterialApp(
          title: 'LinguaFlutter',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
          ),
          home: const CardListScreen(),
        ),
      ),
    );
  }
}
