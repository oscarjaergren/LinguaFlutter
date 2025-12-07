import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../features/auth/auth.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/card_management/card_management.dart';
import '../../features/card_review/presentation/screens/practice_screen.dart';
import '../../features/debug/presentation/screens/debug_menu_screen.dart';
import '../services/logger_service.dart';
import '../services/supabase_service.dart';

/// Application routes configuration using go_router
class AppRouter {
  static const String dashboard = '/';
  static const String auth = '/auth';
  static const String cards = '/cards';
  static const String cardCreation = '/card-creation';
  static const String cardEdit = '/card-edit';
  static const String practice = '/practice';
  static const String debug = '/debug';
  static const String logs = '/logs';

  static final GoRouter router = GoRouter(
    initialLocation: auth, // Start at auth - redirect will handle if already logged in
    redirect: (context, state) {
      final isAuthenticated = SupabaseService.isAuthenticated;
      final path = state.matchedLocation;
      final isAuthRoute = path == auth;
      
      // Check if this is an auth callback (email confirmation, OAuth, etc.)
      // The token comes in the URL fragment which Supabase SDK handles automatically
      final isAuthCallback = path == '/auth/callback' || 
                             path.startsWith('/auth/callback');
      
      LoggerService.debug('Router redirect: path=$path, authenticated=$isAuthenticated, callback=$isAuthCallback');
      
      // Handle auth callback - redirect based on auth state
      // Supabase SDK should have already processed the token from the URL fragment
      if (isAuthCallback) {
        return isAuthenticated ? dashboard : auth;
      }
      
      // Not authenticated and not on auth page -> go to auth
      if (!isAuthenticated && !isAuthRoute) {
        return auth;
      }
      
      // Authenticated and on auth page -> go to dashboard
      if (isAuthenticated && isAuthRoute) {
        return dashboard;
      }
      
      // No redirect needed
      return null;
    },
    routes: [
      // Dashboard Screen (Home) - requires auth
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Auth Screen
      GoRoute(
        path: auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      
      // Auth callback route for email confirmation
      // This handles the redirect from Supabase after email verification
      GoRoute(
        path: '/auth/callback',
        name: 'auth-callback',
        builder: (context, state) {
          // Show loading while Supabase processes the token
          // The global redirect will handle navigation once auth state updates
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying your account...'),
                ],
              ),
            ),
          );
        },
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
          final cardManagement = context.read<CardManagementProvider>();
          final card = cardManagement.allCards.firstWhere(
            (c) => c.id == cardId,
            orElse: () => throw Exception('Card not found'),
          );
          return CreationCreationScreen(cardToEdit: card);
        },
      ),
      
      // Practice Screen
      GoRoute(
        path: practice,
        name: 'practice',
        builder: (context, state) => const PracticeScreen(),
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
    
    // Error handling - redirect unknown routes appropriately
    errorBuilder: (context, state) {
      LoggerService.warning('Unknown route: ${state.uri}');
      // Check if this might be an auth callback with tokens
      final uri = state.uri.toString();
      if (uri.contains('access_token') || uri.contains('refresh_token')) {
        // Auth callback - redirect based on auth state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(SupabaseService.isAuthenticated ? dashboard : auth);
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      // Regular unknown route
      return Scaffold(
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
      );
    },
  );
}

/// Extension methods for type-safe navigation
extension AppRouterExtension on BuildContext {
  /// Navigate to dashboard screen
  void goToDashboard() => go(AppRouter.dashboard);
  
  /// Navigate to auth screen
  void goToAuth() => go(AppRouter.auth);
  
  /// Push auth screen
  void pushAuth() => push(AppRouter.auth);
  
  /// Navigate to cards screen
  void goToCards() => go(AppRouter.cards);
  
  /// Navigate to card creation screen
  void goToCardCreation() => go(AppRouter.cardCreation);
  
  /// Navigate to card edit screen
  void goToCardEdit(String cardId) => go('${AppRouter.cardEdit}/$cardId');
  
  /// Navigate to practice screen
  void goToPractice() => go(AppRouter.practice);
  
  /// Navigate to debug menu
  void goToDebug() => go(AppRouter.debug);
  
  /// Navigate to logs screen
  void goToLogs() => go(AppRouter.logs);
  
  /// Push card creation screen
  void pushCardCreation() => push(AppRouter.cardCreation);
  
  /// Push card edit screen
  void pushCardEdit(String cardId) => push('${AppRouter.cardEdit}/$cardId');
  
  /// Push practice screen
  void pushPractice() => push(AppRouter.practice);
  
  /// Push debug menu
  void pushDebug() => push(AppRouter.debug);
  
  /// Push logs screen
  void pushLogs() => push(AppRouter.logs);
  
  /// Push cards screen
  void pushCards() => push(AppRouter.cards);
}
