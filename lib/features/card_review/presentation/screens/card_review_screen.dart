import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../card_management/domain/card_provider.dart';
import '../../../../shared/services/animation_service.dart';
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
  bool _isDragging = false;
  bool _showAnswer = false;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startReviewSession();
    });
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
      curve: Curves.easeOut,
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
    if (cardProvider.reviewCards.isEmpty) {
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
    if (!_showAnswer || cardProvider.reviewCards.isEmpty) return;
    
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    if (!_showAnswer || cardProvider.reviewCards.isEmpty) return;
    
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
    if (!_showAnswer || cardProvider.reviewCards.isEmpty) return;
    
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
    
    if (cardProvider.reviewCards.isNotEmpty) {
      // Process the answer
      cardProvider.answerCard(isCorrect);
      
      // Reset state for next card
      if (mounted) {
        setState(() {
          _swipeOffset = 0.0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (cardProvider.reviewCards.isEmpty) {
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

          final currentCard = cardProvider.reviewCards.first;

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
                    'Swipe left to fail • Swipe right to pass',
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
    );
  }
}
