import 'package:flutter/material.dart';
import '../../../../shared/shared.dart';

/// Widget displaying exercise statistics and mastery level
class ExerciseStatsWidget extends StatelessWidget {
  final CardModel card;
  final ExerciseType currentExerciseType;

  const ExerciseStatsWidget({
    super.key,
    required this.card,
    required this.currentExerciseType,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseScore = card.getExerciseScore(currentExerciseType);
    final overallMastery = card.overallMasteryLevel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? Colors.grey[850] : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall mastery
            Row(
              children: [
                Icon(
                  _getMasteryIcon(overallMastery),
                  size: 20,
                  color: _getMasteryColor(overallMastery),
                ),
                const SizedBox(width: 8),
                Text(
                  'Overall: $overallMastery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getMasteryColor(overallMastery),
                  ),
                ),
                const Spacer(),
                // Exercise-specific stats
                if (exerciseScore != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${exerciseScore.correctCount}/${exerciseScore.totalAttempts}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (exerciseScore != null && exerciseScore.totalAttempts > 0) ...[
              const SizedBox(height: 8),
              // Success rate bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: exerciseScore.successRate / 100,
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getMasteryColor(exerciseScore.masteryLevel),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${exerciseScore.successRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${currentExerciseType.displayName}: ${exerciseScore.masteryLevel}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getMasteryIcon(String mastery) {
    switch (mastery) {
      case 'Mastered':
        return Icons.emoji_events;
      case 'Good':
        return Icons.thumb_up;
      case 'Learning':
        return Icons.school;
      case 'Difficult':
        return Icons.trending_down;
      default:
        return Icons.fiber_new;
    }
  }

  Color _getMasteryColor(String mastery) {
    switch (mastery) {
      case 'Mastered':
        return Colors.amber;
      case 'Good':
        return Colors.green;
      case 'Learning':
        return Colors.blue;
      case 'Difficult':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
