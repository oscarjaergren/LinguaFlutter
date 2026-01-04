import 'package:flutter/material.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../../../shared/domain/models/exercise_score.dart';
import '../../domain/models/exercise_preferences.dart';

/// Widget that displays per-exercise-type mastery for a card
class ExerciseMasteryWidget extends StatelessWidget {
  final CardModel card;
  final bool showHeader;
  final bool expandedByDefault;

  const ExerciseMasteryWidget({
    super.key,
    required this.card,
    this.showHeader = true,
    this.expandedByDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get all exercise scores that have been attempted
    final scores =
        card.exerciseScores.entries.where((e) => e.key.isImplemented).toList()
          ..sort((a, b) => a.key.index.compareTo(b.key.index));

    if (scores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Exercise Mastery',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  _buildOverallBadge(context),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Group by category
            _buildCategorySection(
              context,
              ExerciseCategory.recognition,
              scores.where((e) => e.key.isRecognition).toList(),
            ),
            const SizedBox(height: 12),
            _buildCategorySection(
              context,
              ExerciseCategory.production,
              scores.where((e) => e.key.isProduction).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallBadge(BuildContext context) {
    final theme = Theme.of(context);
    final level = card.overallMasteryLevel;
    final color = _getMasteryColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        level,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    ExerciseCategory category,
    List<MapEntry<ExerciseType, ExerciseScore>> scores,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (scores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              category == ExerciseCategory.recognition
                  ? Icons.visibility
                  : Icons.edit,
              size: 14,
              color: colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              category.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...scores.map(
          (entry) => _buildExerciseRow(context, entry.key, entry.value),
        ),
      ],
    );
  }

  Widget _buildExerciseRow(
    BuildContext context,
    ExerciseType type,
    ExerciseScore score,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasAttempts = score.totalAttempts > 0;
    final masteryLevel = score.masteryLevel;
    final color = _getMasteryColor(masteryLevel);
    final successRate = score.successRate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Exercise type icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: hasAttempts
                  ? color.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              type.icon,
              size: 16,
              color: hasAttempts ? color : colorScheme.outline,
            ),
          ),
          const SizedBox(width: 10),

          // Exercise name and stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasAttempts)
                  Text(
                    '${score.correctCount}/${score.totalAttempts} correct',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  )
                else
                  Text(
                    'Not practiced yet',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Progress bar and percentage
          if (hasAttempts) ...[
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: successRate / 100,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '${successRate.toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMasteryColor(String level) {
    switch (level) {
      case 'Mastered':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Learning':
        return Colors.orange;
      case 'Difficult':
        return Colors.red;
      case 'New':
      default:
        return Colors.grey;
    }
  }
}
