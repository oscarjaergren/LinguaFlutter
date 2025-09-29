import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/shared.dart';
import '../widgets/card_area.dart';
import '../widgets/review_progress_indicator.dart';
import '../widgets/review_completion_screen.dart';

class CardReviewScreen extends StatefulWidget {
  final AnimationService animationService;

  const CardReviewScreen({
    super.key,
    this.animationService = const ProductionAnimationService(),
  });

  @override
  State<CardReviewScreen> createState() => _CardReviewScreenState();
}

class _CardReviewScreenState extends State<CardReviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _swipeController;
  late AnimationController _transitionController;
  
  late Animation<double> _flipAnimation;
  late Animation<double> _swipeAnimation;
  late Animation<double> _scaleAnimation;

  double _swipeOffset = 0.0;
  double _swipeVerticalOffset = 0.0;
  bool _isDragging = false;
  bool _showAnswer = false;
  Color? _feedbackColor;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startReviewSession();
      _focusNode.requestFocus();
    });
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOut,
    ));
  }

  void _startReviewSession() {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    if (!cardProvider.isReviewMode) {
      cardProvider.startReviewSession();
    }
    setState(() {
      _showAnswer = false;
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _swipeController.dispose();
    _transitionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (!_showAnswer) {
      _flipController.forward();
      setState(() {
        _showAnswer = true;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    if (!_showAnswer || cardProvider.currentCard == null) return;
    
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    if (!_showAnswer || cardProvider.currentCard == null) return;
    
    setState(() {
      _swipeOffset += details.delta.dx;
      
      // Update feedback color based on swipe direction
      if (_swipeOffset.abs() > 50) {
        _feedbackColor = _swipeOffset > 0 ? Colors.green : Colors.red;
      } else {
        _feedbackColor = null;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    if (!_showAnswer || cardProvider.currentCard == null) return;
    
    setState(() {
      _isDragging = false;
      _feedbackColor = null;
    });

    // Determine if swipe was significant enough
    if (_swipeOffset.abs() > 100) {
      _answerCard(_swipeOffset > 0);
    } else {
      // Reset position
      setState(() {
        _swipeOffset = 0.0;
        _feedbackColor = null;
      });
    }
  }

  void _answerCard(bool isCorrect) async {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    
    if (cardProvider.currentCard != null) {
      // Process the answer
      await cardProvider.answerCard(isCorrect ? CardAnswer.correct : CardAnswer.incorrect);
      
      // Reset state for next card
      if (mounted) {
        setState(() {
          _swipeOffset = 0.0;
          _swipeVerticalOffset = 0.0;
          _feedbackColor = null;
          _showAnswer = false;
        });
        
        // Reset animations
        _flipController.reset();
        _swipeController.reset();
        _transitionController.reset();
      }
    }
  }

  void _handleKeyboardSwipe(bool isCorrect) async {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    if (!_showAnswer || cardProvider.currentCard == null) return;

    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    // Set feedback color and animate
    setState(() {
      _feedbackColor = isCorrect ? Colors.green : Colors.red;
    });

    // Animate the swipe - use screen width + extra to ensure card goes completely off
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = isCorrect ? (screenWidth + 200) : -(screenWidth + 200);
    final duration = const Duration(milliseconds: 600);
    
    // Animate swipe offset with arc motion
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < duration) {
      if (!mounted) return;
      
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      final easedProgress = Curves.easeInBack.transform(progress);
      
      // Create parabolic arc that goes UP (negative Y)
      // This creates an arc that peaks at progress = 0.5
      final arcHeight = 150.0; // Maximum height of the arc
      final verticalOffset = 4 * progress * (progress - 1) * arcHeight;
      
      setState(() {
        _swipeOffset = targetOffset * easedProgress;
        _swipeVerticalOffset = verticalOffset;
      });
      
      await Future.delayed(const Duration(milliseconds: 16));
    }

    // Complete the swipe
    if (mounted) {
      setState(() {
        _swipeOffset = targetOffset;
        _swipeVerticalOffset = 0.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 100));
      _answerCard(isCorrect);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final cardProvider = Provider.of<CardProvider>(context, listen: false);
      
      // Allow flipping the card with Space or Enter
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        if (!_showAnswer) {
          _flipCard();
          return KeyEventResult.handled;
        }
      }
      
      // Allow swiping only when answer is shown
      if (_showAnswer && cardProvider.currentCard != null) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _handleKeyboardSwipe(false);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _handleKeyboardSwipe(true);
          return KeyEventResult.handled;
        }
      }
    }
    
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Consumer<CardProvider>(
        builder: (context, cardProvider, child) {
          if (cardProvider.currentCard == null) {
            return ReviewCompletionScreen(
              cardProvider: cardProvider,
              onRestart: () {
                cardProvider.startReviewSession();
                setState(() {
                  _showAnswer = false;
                });
              },
              onClose: () => Navigator.of(context).pop(),
            );
          }

          final currentCard = cardProvider.currentCard!;

          return Column(
            children: [
              ReviewProgressIndicator(
                cardProvider: cardProvider,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: CardArea(
                  card: currentCard,
                  cardProvider: cardProvider,
                  animationService: widget.animationService,
                  swipeOffset: _swipeOffset,
                  swipeVerticalOffset: _swipeVerticalOffset,
                  isDragging: _isDragging,
                  feedbackColor: _feedbackColor ?? Colors.transparent,
                  flipAnimation: _flipAnimation,
                  slideAnimation: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(1.0, 0.0),
                  ).animate(_transitionController),
                  scaleAnimation: _scaleAnimation,
                  swipeAnimation: _swipeAnimation,
                  onTap: _flipCard,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                ),
              ),
              if (_showAnswer) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: const Text(
                    'Swipe or use ← → arrow keys • Left to fail • Right to pass',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          );
        },
      ),
      ),
    );
  }
}
