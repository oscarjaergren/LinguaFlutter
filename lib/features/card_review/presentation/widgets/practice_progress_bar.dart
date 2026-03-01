import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/practice_session_notifier.dart';
import '../../domain/providers/due_cards_provider.dart';

/// Enhanced progress bar for practice, showing due cards remaining and score counts.
class PracticeProgressBar extends ConsumerWidget {
  const PracticeProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(practiceSessionNotifierProvider);
    final totalDueCards = ref.watch(dueCardsProvider);

    // Calculate remaining due cards
    final completedInSession =
        sessionState.runCorrectCount + sessionState.runIncorrectCount;
    final remainingDueCards = (totalDueCards - completedInSession).clamp(
      0,
      totalDueCards,
    );
    final progress = totalDueCards > 0
        ? (completedInSession / totalDueCards).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      height: 80, // Fixed height to prevent overflow
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 6,
            ),

            const SizedBox(height: 8),

            // Progress text and score chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Progress info
                Flexible(
                  child: Text(
                    remainingDueCards > 0
                        ? '$remainingDueCards cards left'
                        : 'All caught up!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 12),

                // Score chips
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildScoreChip(
                      icon: Icons.check_circle,
                      count: sessionState.runCorrectCount,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildScoreChip(
                      icon: Icons.cancel,
                      count: sessionState.runIncorrectCount,
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
