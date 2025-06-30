import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/streak_provider.dart';

/// Dialog to celebrate milestone achievements
class MilestoneCelebrationDialog extends StatelessWidget {
  final List<int> milestones;
  
  const MilestoneCelebrationDialog({
    super.key,
    required this.milestones,
  });

  static void showIfNeeded(BuildContext context) {
    final streakProvider = context.read<StreakProvider>();
    if (streakProvider.newMilestones.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => MilestoneCelebrationDialog(
          milestones: streakProvider.newMilestones,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.celebration,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Milestone Achieved!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Milestone text
          Text(
            _getMilestoneText(),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Motivational message
          Text(
            _getMotivationalMessage(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Milestone badges
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: milestones.map((milestone) {
              return Chip(
                label: Text('$milestone Days'),
                backgroundColor: colorScheme.secondary,
                labelStyle: TextStyle(
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<StreakProvider>().clearNewMilestones();
            Navigator.of(context).pop();
          },
          child: Text(
            'Continue Learning!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
  
  String _getMilestoneText() {
    if (milestones.length == 1) {
      return 'You\'ve reached a ${milestones.first}-day learning streak!';
    } else {
      return 'You\'ve achieved multiple milestones: ${milestones.join(", ")} days!';
    }
  }
  
  String _getMotivationalMessage() {
    final highestMilestone = milestones.reduce((a, b) => a > b ? a : b);
    
    if (highestMilestone <= 7) {
      return 'Great start! Consistency is the key to mastery.';
    } else if (highestMilestone <= 30) {
      return 'Excellent dedication! You\'re building a powerful habit.';
    } else if (highestMilestone <= 100) {
      return 'Incredible commitment! You\'re truly dedicated to learning.';
    } else {
      return 'Legendary achievement! You\'re an inspiration to others.';
    }
  }
}
