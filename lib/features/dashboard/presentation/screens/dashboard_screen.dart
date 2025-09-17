import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/shared.dart';
import '../../../../shared/navigation/app_router.dart';
import '../../../mascot/domain/mascot_provider.dart';
import '../../../streak/presentation/widgets/streak_status_widget.dart';
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
      body: Consumer<CardProvider>(
        builder: (context, cardProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Statistics cards row
                Row(
                  children: [
                    Expanded(
                      child: StatsCardWidget(
                        title: 'To learn',
                        count: cardProvider.allCards.where((c) => !c.isArchived && c.isDue).length,
                        color: Colors.green,
                        icon: Icons.school,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCardWidget(
                        title: 'Known',
                        count: cardProvider.allCards.where((c) => !c.isArchived && !c.isDue).length,
                        color: Colors.blue,
                        icon: Icons.lightbulb,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCardWidget(
                        title: 'Learned',
                        count: cardProvider.stats['totalCards'] ?? 0,
                        color: Colors.orange,
                        icon: Icons.star,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Streak status
                const StreakStatusWidget(),
                
                const SizedBox(height: 32),
                
                // Mascot illustration area
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pets,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _startReview(context, cardProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'START',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Navigation cards
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.library_books),
                    title: const Text('Cards'),
                    subtitle: Text('${cardProvider.allCards.length} cards'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushCards(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startReview(BuildContext context, CardProvider cardProvider) {
    if (cardProvider.reviewCards.isNotEmpty) {
      context.pushCardReview();
    } else {
      // Remove any currently showing SnackBars
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Show new SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No cards available for review'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
