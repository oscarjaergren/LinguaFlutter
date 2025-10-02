import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/card_management/presentation/screens/card_list_screen.dart';
import '../../features/card_management/presentation/screens/card_creation_screen.dart';
import '../../features/card_review/presentation/screens/card_review_screen.dart';
import '../../features/card_review/presentation/screens/exercise_session_screen.dart';
import '../../features/debug/presentation/screens/debug_menu_screen.dart';
import '../domain/card_provider.dart';
import '../services/logger_service.dart';

/// Application routes configuration using go_router
class AppRouter {
  static const String dashboard = '/';
  static const String cards = '/cards';
  static const String cardCreation = '/card-creation';
  static const String cardEdit = '/card-edit';
  static const String cardReview = '/card-review';
  static const String exerciseSession = '/exercise-session';
  static const String debug = '/debug';
  static const String logs = '/logs';

  static final GoRouter router = GoRouter(
    initialLocation: dashboard,
    routes: [
      // Dashboard Screen (Home)
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Cards Screen
      GoRoute(
        path: cards,
        name: 'cards',
        builder: (context, state) => const CardsScreen(),
      ),
      
      // Card Creation Screen
      GoRoute(
        path: cardCreation,
        name: 'card-creation',
        builder: (context, state) => const CreationCreationScreen(),
      ),
      
      // Card Edit Screen
      GoRoute(
        path: '$cardEdit/:cardId',
        name: 'card-edit',
        builder: (context, state) {
          final cardId = state.pathParameters['cardId']!;
          final cardProvider = context.read<CardProvider>();
          final card = cardProvider.allCards.firstWhere(
            (c) => c.id == cardId,
            orElse: () => throw Exception('Card not found'),
          );
          return CreationCreationScreen(cardToEdit: card);
        },
      ),
      
      // Card Review Screen
      GoRoute(
        path: cardReview,
        name: 'card-review',
        builder: (context, state) => const CardReviewScreen(),
      ),
      
      // Exercise Session Screen
      GoRoute(
        path: exerciseSession,
        name: 'exercise-session',
        builder: (context, state) => const ExerciseSessionScreen(),
      ),
      
      // Debug Menu Screen
      GoRoute(
        path: debug,
        name: 'debug',
        builder: (context, state) => const DebugMenuScreen(),
      ),
      
      // Logs Screen (Talker UI)
      GoRoute(
        path: logs,
        name: 'logs',
        builder: (context, state) => TalkerScreen(
          talker: LoggerService.instance,
        ),
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Extension methods for type-safe navigation
extension AppRouterExtension on BuildContext {
  /// Navigate to dashboard screen
  void goToDashboard() => go(AppRouter.dashboard);
  
  /// Navigate to cards screen
  void goToCards() => go(AppRouter.cards);
  
  /// Navigate to card creation screen
  void goToCardCreation() => go(AppRouter.cardCreation);
  
  /// Navigate to card edit screen
  void goToCardEdit(String cardId) => go('${AppRouter.cardEdit}/$cardId');
  
  /// Navigate to card review screen
  void goToCardReview() => go(AppRouter.cardReview);
  
  /// Navigate to exercise session screen
  void goToExerciseSession() => go(AppRouter.exerciseSession);
  
  /// Navigate to debug menu
  void goToDebug() => go(AppRouter.debug);
  
  /// Navigate to logs screen
  void goToLogs() => go(AppRouter.logs);
  
  /// Push card creation screen
  void pushCardCreation() => push(AppRouter.cardCreation);
  
  /// Push card edit screen
  void pushCardEdit(String cardId) => push('${AppRouter.cardEdit}/$cardId');
  
  /// Push card review screen
  void pushCardReview() => push(AppRouter.cardReview);
  
  /// Push exercise session screen
  void pushExerciseSession() => push(AppRouter.exerciseSession);
  
  /// Push debug menu
  void pushDebug() => push(AppRouter.debug);
  
  /// Push logs screen
  void pushLogs() => push(AppRouter.logs);
  
  /// Push cards screen
  void pushCards() => push(AppRouter.cards);
}
