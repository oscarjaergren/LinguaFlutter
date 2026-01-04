import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A swipeable card container for exercise content
/// Handles swipe gestures to mark answers correct (right) or incorrect (left)
class SwipeableExerciseCard extends StatefulWidget {
  /// The exercise content to display inside the card
  final Widget child;

  /// Whether swiping is currently enabled (after answer is checked)
  final bool canSwipe;

  /// Called when user swipes right (marking correct)
  final VoidCallback onSwipeRight;

  /// Called when user swipes left (marking incorrect)
  final VoidCallback onSwipeLeft;

  /// Optional callback for when card is tapped
  final VoidCallback? onTap;

  /// Background color of the card
  final Color? backgroundColor;

  const SwipeableExerciseCard({
    super.key,
    required this.child,
    required this.canSwipe,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    this.onTap,
    this.backgroundColor,
  });

  @override
  State<SwipeableExerciseCard> createState() => SwipeableExerciseCardState();
}

/// State class for SwipeableExerciseCard - public to allow keyboard swipe triggering
class SwipeableExerciseCardState extends State<SwipeableExerciseCard>
    with TickerProviderStateMixin {
  double _swipeOffset = 0.0;
  double _swipeVerticalOffset = 0.0;
  bool _isDragging = false;
  Color? _feedbackColor;

  late AnimationController _resetController;
  late Animation<double> _resetAnimation;
  double _animationStartOffset = 0.0;

  // Swipe completion animation
  AnimationController? _swipeController;
  Animation<double>? _swipeAnimation;
  double _swipeStartOffset = 0.0;
  double _swipeTargetOffset = 0.0;
  bool? _swipeIsCorrect;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _resetAnimation = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOut,
    );
    _resetController.addListener(_onResetAnimation);
  }

  @override
  void dispose() {
    _resetController.dispose();
    _swipeController?.dispose();
    super.dispose();
  }

  void _onResetAnimation() {
    setState(() {
      _swipeOffset = _animationStartOffset * (1 - _resetAnimation.value);
      _swipeVerticalOffset = 0;
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.canSwipe) return;

    _resetController.stop();
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.canSwipe) return;

    setState(() {
      _swipeOffset += details.delta.dx;
      _swipeVerticalOffset +=
          details.delta.dy * 0.3; // Dampen vertical movement

      // Update feedback color based on swipe direction
      if (_swipeOffset.abs() > 50) {
        _feedbackColor = _swipeOffset > 0
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.red.withValues(alpha: 0.3);
      } else {
        _feedbackColor = null;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.canSwipe) return;

    setState(() {
      _isDragging = false;
    });

    // Determine if swipe was significant enough
    if (_swipeOffset.abs() > 100) {
      HapticFeedback.mediumImpact();
      _completeSwipe(_swipeOffset > 0);
    } else {
      // Reset position with animation
      _animationStartOffset = _swipeOffset;
      _resetController.forward(from: 0);
      setState(() {
        _feedbackColor = null;
      });
    }
  }

  void _completeSwipe(bool isCorrect) {
    final screenWidth = MediaQuery.of(context).size.width;
    _swipeTargetOffset = isCorrect ? (screenWidth + 200) : -(screenWidth + 200);
    _swipeStartOffset = _swipeOffset;
    _swipeIsCorrect = isCorrect;

    // Dispose previous controller if exists
    _swipeController?.dispose();

    // Create new animation controller for swipe completion
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _swipeAnimation = CurvedAnimation(
      parent: _swipeController!,
      curve: Curves.easeInBack,
    );

    _swipeController!.addListener(_onSwipeAnimation);
    _swipeController!.addStatusListener(_onSwipeAnimationStatus);
    _swipeController!.forward();
  }

  void _onSwipeAnimation() {
    if (_swipeAnimation == null) return;

    final progress = _swipeAnimation!.value;

    // Create arc motion
    const arcHeight = 100.0;
    final verticalOffset = 4 * progress * (progress - 1) * arcHeight;

    setState(() {
      _swipeOffset =
          _swipeStartOffset +
          (_swipeTargetOffset - _swipeStartOffset) * progress;
      _swipeVerticalOffset = verticalOffset;
    });
  }

  void _onSwipeAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Trigger callback
      if (_swipeIsCorrect == true) {
        widget.onSwipeRight();
      } else if (_swipeIsCorrect == false) {
        widget.onSwipeLeft();
      }

      // Reset state for next card
      setState(() {
        _swipeOffset = 0;
        _swipeVerticalOffset = 0;
        _feedbackColor = null;
      });

      // Clean up
      _swipeController?.removeListener(_onSwipeAnimation);
      _swipeController?.removeStatusListener(_onSwipeAnimationStatus);
    }
  }

  /// Handle keyboard swipe (arrow keys)
  void handleKeyboardSwipe(bool isCorrect) {
    if (!widget.canSwipe) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _feedbackColor = isCorrect
          ? Colors.green.withValues(alpha: 0.3)
          : Colors.red.withValues(alpha: 0.3);
    });
    _completeSwipe(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _isDragging ? (_swipeOffset / 500) * 0.1 : 0.0;
    final scale = _isDragging ? 1.02 : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        child: Transform.translate(
          offset: Offset(_swipeOffset, _swipeVerticalOffset),
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isDragging ? 0.2 : 0.1,
                    ),
                    blurRadius: _isDragging ? 20 : 10,
                    offset: Offset(0, _isDragging ? 8 : 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Main content
                    widget.child,

                    // Feedback overlay
                    if (_feedbackColor != null)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _feedbackColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                    // Swipe indicators
                    if (widget.canSwipe && _swipeOffset.abs() > 30)
                      Positioned(
                        top: 20,
                        left: _swipeOffset > 0 ? null : 20,
                        right: _swipeOffset > 0 ? 20 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _swipeOffset > 0 ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _swipeOffset > 0 ? Icons.check : Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _swipeOffset > 0 ? 'CORRECT' : 'INCORRECT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
