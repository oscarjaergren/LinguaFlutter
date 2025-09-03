import 'package:flutter/material.dart';
import 'package:lingua_flutter/shared/shared.dart';

/// Progress indicator for card review session
class ReviewProgressIndicator extends StatelessWidget {
  final CardProvider cardProvider;

  const ReviewProgressIndicator({
    super.key,
    required this.cardProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${cardProvider.currentReviewIndex + 1} of ${cardProvider.currentReviewSession.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${(cardProvider.reviewProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: cardProvider.reviewProgress,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
