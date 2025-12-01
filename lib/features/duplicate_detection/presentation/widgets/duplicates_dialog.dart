import 'package:flutter/material.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../domain/models/duplicate_match.dart';

/// Dialog for displaying and managing duplicate cards
class DuplicatesDialog extends StatelessWidget {
  final CardModel card;
  final List<DuplicateMatch> duplicates;
  final void Function(CardModel card)? onDeleteCard;

  const DuplicatesDialog({
    super.key,
    required this.card,
    required this.duplicates,
    this.onDeleteCard,
  });

  /// Show the duplicates dialog
  static Future<void> show(
    BuildContext context, {
    required CardModel card,
    required List<DuplicateMatch> duplicates,
    void Function(CardModel card)? onDeleteCard,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DuplicatesDialog(
        card: card,
        duplicates: duplicates,
        onDeleteCard: onDeleteCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.content_copy, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text('Potential Duplicates')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This card:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            _CardPreview(card: card),
            const SizedBox(height: 16),
            Text(
              'May be a duplicate of:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: duplicates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final match = duplicates[index];
                  return _DuplicateItem(
                    match: match,
                    onDelete: onDeleteCard != null
                        ? () {
                            Navigator.of(context).pop();
                            onDeleteCard!(match.duplicateCard);
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _CardPreview extends StatelessWidget {
  final CardModel card;

  const _CardPreview({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.frontText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.backText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateItem extends StatelessWidget {
  final DuplicateMatch match;
  final VoidCallback? onDelete;

  const _DuplicateItem({
    required this.match,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final duplicateCard = match.duplicateCard;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      duplicateCard.frontText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duplicateCard.backText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Delete this duplicate',
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStrategyIcon(match.strategy),
                  size: 14,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${match.reason} (${(match.similarityScore * 100).toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStrategyIcon(DuplicateMatchStrategy strategy) {
    return switch (strategy) {
      DuplicateMatchStrategy.exactMatch => Icons.check_circle,
      DuplicateMatchStrategy.caseInsensitive => Icons.text_fields,
      DuplicateMatchStrategy.normalizedWhitespace => Icons.space_bar,
      DuplicateMatchStrategy.fuzzyMatch => Icons.blur_on,
      DuplicateMatchStrategy.sameFrontDifferentBack => Icons.swap_horiz,
      DuplicateMatchStrategy.sameBackDifferentFront => Icons.swap_vert,
    };
  }
}
