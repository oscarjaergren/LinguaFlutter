import 'package:flutter/material.dart';

/// Screen shown when a practice session is completed
class PracticeCompletionScreen extends StatelessWidget {
  final int correctCount;
  final int incorrectCount;
  final Duration duration;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const PracticeCompletionScreen({
    super.key,
    required this.correctCount,
    required this.incorrectCount,
    required this.duration,
    required this.onRestart,
    required this.onClose,
  });

  int get totalCount => correctCount + incorrectCount;
  
  double get accuracy => totalCount == 0 ? 0.0 : correctCount / totalCount;

  String get _formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.amber,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Session Complete!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 32),
            
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
            
            const SizedBox(height: 24),
            
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
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Duration
            Text(
              'Time: $_formattedDuration',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(140, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Practice Again'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
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
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
