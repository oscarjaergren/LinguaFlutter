import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/icon_provider.dart';
import 'providers/card_provider.dart';
import 'providers/streak_provider.dart';
import 'screens/icon_search_screen.dart';
import 'screens/card_list_screen.dart';
import 'screens/card_creation_screen.dart';

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
        ChangeNotifierProxyProvider<StreakProvider, CardProvider>(
          create: (_) => CardProvider(),
          update: (_, streakProvider, cardProvider) {
            cardProvider?.setStreakProvider(streakProvider);
            return cardProvider!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'LinguaFlutter',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinguaFlutter'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.language,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to LinguaFlutter',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A card-based language learning app with icon search functionality.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CardListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz),
                label: const Text('My Cards'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CardCreationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_card),
                label: const Text('Create Card'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IconSearchScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Search Icons'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
