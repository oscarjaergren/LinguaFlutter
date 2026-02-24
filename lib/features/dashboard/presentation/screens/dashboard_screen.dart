import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart'
    show
        Provider,
        ChangeNotifierProvider,
        MultiProvider,
        Consumer; // Only show what's needed from provider
import '../../../../shared/navigation/app_router.dart';
import '../../../auth/auth.dart';
import '../../../card_management/card_management.dart';
import '../../../mascot/domain/mascot_provider.dart';
import '../../../mascot/presentation/widgets/mascot_widget.dart';
import '../../../streak/streak.dart';
import '../../../streak/domain/streak_provider.dart';
import '../../../theme/theme.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/language_selector_widget.dart';

/// Main dashboard/landing screen showing overview and navigation
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset mascot session when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mascotNotifierProvider.notifier).resetSession();
    });

    return Scaffold(
      appBar: AppBar(
        title: const LanguageSelectorWidget(),
        actions: [
          // Theme toggle
          const ThemeToggleButton(),
          // Auth/Profile button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAuthenticated) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  tooltip: 'Account',
                  onSelected: (value) {
                    if (value == 'settings') {
                      context.pushSettings();
                    } else if (value == 'signout') {
                      authProvider.signOut();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        authProvider.userEmail ?? 'Signed in',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                onPressed: () => context.pushAuth(),
                icon: const Icon(Icons.login),
                tooltip: 'Sign in to sync data',
              );
            },
          ),
          // Debug menu
          if (kDebugMode)
            IconButton(
              onPressed: () => context.pushDebug(),
              icon: const Icon(Icons.bug_report),
            ),
        ],
      ),
      body: Consumer<CardManagementProvider>(
        builder: (context, cardManagement, child) {
          final dueCount = cardManagement.filteredCards
              .where((c) => !c.isArchived && c.isDueForReview)
              .length;
          final learningCount = cardManagement.filteredCards
              .where(
                (c) => !c.isArchived && !c.isDueForReview && c.reviewCount > 0,
              )
              .length;
          final masteredCount = cardManagement.filteredCards
              .where((c) => !c.isArchived && c.masteryLevel == 'Mastered')
              .length;
          final totalCards = cardManagement.filteredCards
              .where((c) => !c.isArchived)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Statistics cards row
                Row(
                  children: [
                    Expanded(
                      child: StatsCardWidget(
                        title: 'Due Now',
                        count: dueCount,
                        color: Colors.green,
                        icon: Icons.schedule,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCardWidget(
                        title: 'Learning',
                        count: learningCount,
                        color: Colors.amber,
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCardWidget(
                        title: 'Mastered',
                        count: masteredCount,
                        color: Colors.blue,
                        icon: Icons.check_circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Mascot with speech bubble
                Builder(
                  builder: (context) {
                    final mascotState = ref.watch(mascotNotifierProvider);
                    final mascotNotifier = ref.read(
                      mascotNotifierProvider.notifier,
                    );
                    final streakState = ref.watch(streakNotifierProvider);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      mascotNotifier.showContextualMessage(
                        totalCards: totalCards,
                        dueCards: dueCount,
                        currentStreak: streakState.streak.currentStreak,
                        hasStudiedToday:
                            streakState.streak.cardsReviewedToday > 0,
                      );
                    });

                    return Center(
                      child: MascotWidget(
                        size: 120,
                        message: mascotState.currentMessage,
                        mascotState: mascotState.currentState,
                        onTap: () =>
                            mascotNotifier.reactToAction(MascotAction.tapped),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Primary action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: dueCount > 0
                        ? () => _startExerciseSession(context, cardManagement)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      disabledBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: Text(
                      dueCount > 0
                          ? 'START LEARNING ($dueCount due)'
                          : 'ALL CAUGHT UP!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Browse cards
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.library_books),
                    title: const Text('Browse Cards'),
                    subtitle: Text('$totalCards cards total'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushCards(),
                  ),
                ),

                // Streak indicator (compact)
                const SizedBox(height: 8),
                const StreakStatusWidget(compact: true),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startExerciseSession(
    BuildContext context,
    CardManagementProvider cardManagement,
  ) {
    if (cardManagement.reviewCards.isNotEmpty) {
      context.pushPractice();
    } else {
      _showNoCardsMessage(context);
    }
  }

  void _showNoCardsMessage(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('No cards available for review'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isVisuallyDark = brightness == Brightness.dark;
    return IconButton(
      onPressed: () => ref
          .read(themeNotifierProvider.notifier)
          .toggleTheme(currentBrightness: brightness),
      icon: Icon(isVisuallyDark ? Icons.light_mode : Icons.dark_mode),
      tooltip: isVisuallyDark ? 'Switch to light mode' : 'Switch to dark mode',
    );
  }
}
