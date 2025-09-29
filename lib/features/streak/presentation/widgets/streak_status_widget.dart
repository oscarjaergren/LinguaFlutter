import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/streak_provider.dart';
import '../screens/streak_detail_screen.dart';

/// Widget to display streak status and statistics
class StreakStatusWidget extends StatelessWidget {
  final bool compact;
  
  const StreakStatusWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
        if (streakProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (compact) {
          return _buildCompactView(context, streakProvider);
        } else {
          return _buildDetailedView(context, streakProvider);
        }
      },
    );
  }

  Widget _buildCompactView(BuildContext context, StreakProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StreakDetailScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: provider.currentStreak > 0 ? Colors.orange : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${provider.currentStreak} day streak',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.streak.statusMessage,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.cardsReviewedToday > 0)
                    Chip(
                      label: Text('${provider.cardsReviewedToday} today'),
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context, StreakProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: provider.currentStreak > 0 ? Colors.orange : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learning Streak',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.getMotivationalMessage(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Milestones (if any)
            if (provider.achievedMilestones.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Milestones Achieved',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: provider.achievedMilestones.map((milestone) {
                  final isNew = provider.isNewMilestone(milestone);
                  return Chip(
                    label: Text('$milestone days'),
                    backgroundColor: isNew 
                        ? colorScheme.secondary 
                        : colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: isNew 
                          ? colorScheme.onSecondary 
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
