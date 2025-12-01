import 'package:flutter/material.dart';
import '../../domain/providers/review_session_provider.dart';

/// Progress indicator for card review session
class ReviewProgressIndicator extends StatelessWidget {
  final ReviewSessionProvider reviewSession;

  const ReviewProgressIndicator({
    super.key,
    required this.reviewSession,
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
                'Card ${reviewSession.currentIndex + 1} of ${reviewSession.sessionCards.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${(reviewSession.progress * 100).toInt()}%',
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
            value: reviewSession.progress,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
