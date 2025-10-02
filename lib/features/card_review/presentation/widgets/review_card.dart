import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/shared.dart';

/// Individual flashcard widget with flip animation and visual feedback
class ReviewCard extends StatelessWidget {
  final CardModel card;
  final double swipeOffset;
  final bool isDragging;
  final Color feedbackColor;
  final Animation<double> flipAnimation;

  const ReviewCard({
    super.key,
    required this.card,
    required this.swipeOffset,
    required this.isDragging,
    required this.feedbackColor,
    required this.flipAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CardProvider>(
      builder: (context, cardProvider, child) {
        return RepaintBoundary(
          child: Container(
            width: 320,
            height: 400,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDragging ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Feedback overlay
                if (feedbackColor != Colors.transparent)
                  Container(
                    decoration: BoxDecoration(
                      color: feedbackColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                // Card content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return AnimatedBuilder(
                      animation: flipAnimation,
                      builder: (context, child) {
                        final isShowingFront = flipAnimation.value < 0.5;
                        if (isShowingFront) {
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(flipAnimation.value * 3.14159),
                            child: _buildCardFront(),
                          );
                        } else {
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY((flipAnimation.value - 1) * 3.14159),
                            child: _buildCardBack(),
                          );
                        }
                      },
                    );
                  },
                  child: cardProvider.showingBack 
                      ? _buildCardBack() 
                      : _buildCardFront(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFront() {
    return Container(
      key: const ValueKey('front'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.quiz_outlined,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  card.frontText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              SpeakerButton(
                text: card.frontText,
                languageCode: card.language,
                size: 32,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Tap to reveal answer',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      key: const ValueKey('back'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          Text(
            card.backText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Swipe left (don\'t know) or right (know)',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
