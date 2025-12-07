import 'package:flutter/material.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../duplicate_detection/duplicate_detection.dart';
import '../../../icon_search/presentation/widgets/icon_display_widget.dart';

/// Widget for displaying individual card items in the list
class CardItemWidget extends StatelessWidget {
  final CardModel card;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final List<DuplicateMatch>? duplicates;
  final VoidCallback? onDuplicateTap;

  const CardItemWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.duplicates,
    this.onDuplicateTap,
  });
  
  bool get hasDuplicates => duplicates != null && duplicates!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // Add a subtle border for cards with duplicates
      shape: hasDuplicates 
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.orange.withValues(alpha: 0.6),
                width: 2,
              ),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with favorite and actions
              Row(
                children: [
                  // Icon if available
                  if (card.icon != null) ...[
                    IconDisplayWidget(
                      iconPath: card.icon!.svgUrl,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Front text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (card.germanArticle != null) ...[
                              Text(
                                card.germanArticle!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                card.frontText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.backText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Favorite button
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      card.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: card.isFavorite ? Colors.red : null,
                    ),
                  ),
                  
                  // More actions menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Card metadata
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // Category chip
                  _buildChip(
                    context,
                    card.category,
                    colorScheme.primaryContainer,
                    colorScheme.onPrimaryContainer,
                  ),
                  
                  // Mastery level indicator
                  _buildMasteryChip(context, card.masteryLevel),
                  
                  // Tags
                  ...card.tags.map(
                    (tag) => _buildChip(
                      context,
                      tag,
                      colorScheme.secondaryContainer,
                      colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
              
              // Duplicate indicator
              if (hasDuplicates) ...[  
                const SizedBox(height: 8),
                _buildDuplicateIndicator(context),
              ],
              
              // Review status
              if (card.nextReview != null) ...[
                const SizedBox(height: 8),
                _buildReviewStatus(context, card),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMasteryChip(BuildContext context, String masteryLevel) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (masteryLevel) {
      case 'Mastered':
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green.shade700;
        icon = Icons.star;
        break;
      case 'Good':
        backgroundColor = Colors.lightGreen.withValues(alpha: 0.2);
        textColor = Colors.lightGreen.shade700;
        icon = Icons.thumb_up;
        break;
      case 'Learning':
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange.shade700;
        icon = Icons.school;
        break;
      case 'Difficult':
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red.shade700;
        icon = Icons.warning;
        break;
      default: // 'New'
        backgroundColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue.shade700;
        icon = Icons.fiber_new;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            masteryLevel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateIndicator(BuildContext context) {
    return DuplicateIndicatorWidget(
      duplicates: duplicates!,
      onTap: onDuplicateTap,
    );
  }

  Widget _buildReviewStatus(BuildContext context, CardModel card) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final nextReview = card.nextReview!;
    final isDue = nextReview.isBefore(now);
    
    final statusText = isDue 
        ? 'Due for review'
        : 'Next review: ${_formatDate(nextReview)}';
    
    final statusColor = isDue 
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      children: [
        Icon(
          isDue ? Icons.schedule : Icons.schedule_outlined,
          size: 16,
          color: statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
          ),
        ),
        if (card.reviewCount > 0) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.replay,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '${card.reviewCount} reviews',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}
