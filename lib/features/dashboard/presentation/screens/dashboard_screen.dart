import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/navigation/app_router.dart';
import '../../../card_management/card_management.dart';
import '../../../mascot/domain/mascot_provider.dart';
import '../../../mascot/presentation/widgets/mascot_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/language_selector_widget.dart';

/// Main dashboard/landing screen showing overview and navigation
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reset mascot session when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MascotProvider>().resetSession();
    });

    return Scaffold(
      appBar: AppBar(
        title: const LanguageSelectorWidget(),
        actions: [
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
          final dueCount = cardManagement.filteredCards.where((c) => !c.isArchived && c.isDue).length;
          final learningCount = cardManagement.filteredCards.where((c) => !c.isArchived && !c.isDue && c.reviewCount > 0).length;
          final masteredCount = cardManagement.filteredCards.where((c) => !c.isArchived && c.masteryLevel == 'Mastered').length;
          final totalCards = cardManagement.filteredCards.where((c) => !c.isArchived).length;
          
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
                Consumer<MascotProvider>(
                  builder: (context, mascotProvider, child) {
                    return Center(
                      child: MascotWidget(
                        size: 120,
                        message: _getMascotMessage(dueCount, totalCards),
                        mascotState: dueCount > 0 ? MascotState.excited : MascotState.idle,
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
                      disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                _buildStreakIndicator(context),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startExerciseSession(BuildContext context, CardManagementProvider cardManagement) {
    if (cardManagement.reviewCards.isNotEmpty) {
      context.pushExerciseSession();
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

  String _getMascotMessage(int dueCount, int totalCards) {
    if (totalCards == 0) {
      return "Let's add some cards to get started!";
    } else if (dueCount == 0) {
      return "Great job! You're all caught up! 🎉";
    } else if (dueCount == 1) {
      return "Just 1 card waiting for you!";
    } else if (dueCount <= 5) {
      return "You have $dueCount cards to review. Let's go!";
    } else {
      return "$dueCount cards are ready. Time to learn!";
    }
  }

  Widget _buildStreakIndicator(BuildContext context) {
    // TODO: Connect to actual streak provider when ready
    const streakDays = 0; // Placeholder
    
    if (streakDays == 0) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Text(
              '$streakDays day streak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'Keep it up!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
