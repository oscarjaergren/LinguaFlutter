import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../features/card_management/presentation/screens/card_list_screen.dart';
import '../../features/card_management/presentation/screens/simple_card_creation_screen.dart';
import '../../features/card_review/presentation/screens/card_review_screen.dart';
import '../../features/debug/presentation/screens/debug_menu_screen.dart';
import '../services/logger_service.dart';

/// Application routes configuration using go_router
class AppRouter {
  static const String cardList = '/';
  static const String cardCreation = '/card-creation';
  static const String cardEdit = '/card-edit';
  static const String cardReview = '/card-review';
  static const String debug = '/debug';
  static const String logs = '/logs';

  static final GoRouter router = GoRouter(
    initialLocation: cardList,
    routes: [
      // Card List Screen (Home)
      GoRoute(
        path: cardList,
        name: 'card-list',
        builder: (context, state) => const CardListScreen(),
      ),
      
      // Card Creation Screen
      GoRoute(
        path: cardCreation,
        name: 'card-creation',
        builder: (context, state) => const SimpleCardCreationScreen(),
      ),
      
      // Card Edit Screen
      GoRoute(
        path: cardEdit,
        name: 'card-edit',
        builder: (context, state) {
          // TODO: Pass cardId to load existing card for editing
          return const SimpleCardCreationScreen();
        },
      ),
      
      // Card Review Screen
      GoRoute(
        path: cardReview,
        name: 'card-review',
        builder: (context, state) => const CardReviewScreen(),
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
              onPressed: () => context.go(cardList),
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
  /// Navigate to card list screen
  void goToCardList() => go(AppRouter.cardList);
  
  /// Navigate to card creation screen
  void goToCardCreation() => go(AppRouter.cardCreation);
  
  /// Navigate to card edit screen
  void goToCardEdit(String cardId) => go('${AppRouter.cardEdit}?cardId=$cardId');
  
  /// Navigate to card review screen
  void goToCardReview() => go(AppRouter.cardReview);
  
  /// Navigate to debug menu
  void goToDebug() => go(AppRouter.debug);
  
  /// Navigate to logs screen
  void goToLogs() => go(AppRouter.logs);
  
  /// Push card creation screen
  void pushCardCreation() => push(AppRouter.cardCreation);
  
  /// Push card edit screen
  void pushCardEdit(String cardId) => push('${AppRouter.cardEdit}?cardId=$cardId');
  
  /// Push card review screen
  void pushCardReview() => push(AppRouter.cardReview);
  
  /// Push debug menu
  void pushDebug() => push(AppRouter.debug);
  
  /// Push logs screen
  void pushLogs() => push(AppRouter.logs);
}
