import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/practice_session_notifier.dart';

/// Modal dialog showing current practice session statistics
class PracticeStatsModal extends ConsumerWidget {
  const PracticeStatsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(practiceSessionNotifierProvider);
    final theme = Theme.of(context);

    final correctCount = sessionState.runCorrectCount;
    final incorrectCount = sessionState.runIncorrectCount;
    final totalCount = correctCount + incorrectCount;
    final accuracy = totalCount == 0 ? 0.0 : correctCount / totalCount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Practice Stats',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.check_circle,
                  value: '$correctCount',
                  label: 'Correct',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  icon: Icons.cancel,
                  value: '$incorrectCount',
                  label: 'Incorrect',
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Accuracy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${(accuracy * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Accuracy',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Duration (if session has started)
            if (sessionState.sessionStartTime != null) ...[
              Consumer(
                builder: (context, ref, child) {
                  final duration = DateTime.now().difference(sessionState.sessionStartTime!);
                  final minutes = duration.inMinutes;
                  final seconds = duration.inSeconds % 60;
                  final formattedDuration = minutes > 0 
                      ? '$minutes min $seconds sec' 
                      : '$seconds sec';
                  
                  return Text(
                    'Time: $formattedDuration',
                    style: TextStyle(
                      color: Colors.grey[600], 
                      fontSize: 16,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
