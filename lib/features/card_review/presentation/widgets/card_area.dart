import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/shared.dart';
import 'review_card.dart';

/// Interactive card area with drag gestures and animations
class CardArea extends StatelessWidget {
  final CardModel card;
  final CardProvider cardProvider;
  final AnimationService animationService;
  final double swipeOffset;
  final bool isDragging;
  final Color feedbackColor;
  final Animation<double> flipAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> swipeAnimation;
  final VoidCallback onTap;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const CardArea({
    super.key,
    required this.card,
    required this.cardProvider,
    required this.animationService,
    required this.swipeOffset,
    required this.isDragging,
    required this.feedbackColor,
    required this.flipAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
    required this.swipeAnimation,
    required this.onTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          if (!cardProvider.showingBack) {
            HapticFeedback.lightImpact();
            onTap();
          }
        },
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            flipAnimation,
            slideAnimation,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(swipeOffset, 0) + slideAnimation.value * 300,
              child: Transform.scale(
                scale: isDragging ? 1.05 : scaleAnimation.value,
                child: AnimatedBuilder(
                  animation: swipeAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: isDragging ? (swipeOffset / 300) * 0.1 : 0,
                      child: ReviewCard(
                        card: card,
                        swipeOffset: swipeOffset,
                        isDragging: isDragging,
                        feedbackColor: feedbackColor,
                        flipAnimation: flipAnimation,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
