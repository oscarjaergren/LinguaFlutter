import 'package:flutter/material.dart';
import '../../domain/models/duplicate_match.dart';

/// Widget that displays a duplicate indicator on a card
class DuplicateIndicatorWidget extends StatelessWidget {
  final List<DuplicateMatch> duplicates;
  final VoidCallback? onTap;

  const DuplicateIndicatorWidget({
    super.key,
    required this.duplicates,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (duplicates.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final count = duplicates.length;
    final bestMatch = duplicates.first;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_copy, size: 16, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1
                        ? '1 potential duplicate'
                        : '$count potential duplicates',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    bestMatch.reason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.orange.shade600,
              ),
          ],
        ),
      ),
    );
  }
}
