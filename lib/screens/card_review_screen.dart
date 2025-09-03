import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/card_provider.dart';
import '../services/animation_service.dart';

/// Modern card review screen with book-like aesthetics and industry-standard UX
class CardReviewScreen extends StatefulWidget {
  final List<CardModel>? initialCards;
  final AnimationService animationService;

  const CardReviewScreen({
    super.key,
    this.initialCards,
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
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  double _swipeOffset = 0.0;
  bool _isDragging = false;
  Color _feedbackColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Defer review session start to avoid setState during build
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

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, 0),
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOut,
    ));
  }

  void _startReviewSession() {
    final cardProvider = context.read<CardProvider>();
    // Use initialCards if provided, otherwise let CardProvider use its review cards
    if (widget.initialCards != null && widget.initialCards!.isNotEmpty) {
      cardProvider.startReviewSession(cards: widget.initialCards);
    } else {
      cardProvider.startReviewSession();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _swipeController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final cardProvider = context.read<CardProvider>();
    
    if (!cardProvider.showingBack) {
      // Flip to show answer
      HapticFeedback.lightImpact();
      cardProvider.flipCard();
      if (widget.animationService.animationsEnabled) {
        widget.animationService.forward(_flipController);
      }
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final cardProvider = context.read<CardProvider>();
    if (!cardProvider.showingBack) return;
    
    setState(() {
      _isDragging = true;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final cardProvider = context.read<CardProvider>();
    if (!cardProvider.showingBack) return;

    setState(() {
      _swipeOffset += details.delta.dx;
      
      // Update feedback color based on swipe direction and distance
      final normalizedOffset = (_swipeOffset / 200).clamp(-1.0, 1.0);
      if (normalizedOffset > 0.2) {
        _feedbackColor = Colors.green.withValues(alpha: normalizedOffset * 0.3);
      } else if (normalizedOffset < -0.2) {
        _feedbackColor = Colors.red.withValues(alpha: (-normalizedOffset) * 0.3);
      } else {
        _feedbackColor = Colors.transparent;
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final cardProvider = context.read<CardProvider>();
    if (!cardProvider.showingBack) return;

    setState(() {
      _isDragging = false;
      _feedbackColor = Colors.transparent;
    });

    const threshold = 100.0;
    
    if (_swipeOffset > threshold) {
      // Swipe right - "Know"
      _answerCard(true);
    } else if (_swipeOffset < -threshold) {
      // Swipe left - "Don't Know"
      _answerCard(false);
    } else {
      // Snap back to center
      setState(() {
        _swipeOffset = 0.0;
        _feedbackColor = Colors.transparent;
      });
    }
  }

  void _answerCard(bool wasCorrect) async {
    HapticFeedback.mediumImpact();
    
    final cardProvider = context.read<CardProvider>();
    
    // Animate card exit
    if (widget.animationService.animationsEnabled) {
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(wasCorrect ? 1.2 : -1.2, 0),
      ).animate(CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInOut,
      ));
      
      await widget.animationService.forward(_transitionController);
    }
    
    // Process the answer
    await cardProvider.answerCard(wasCorrect);
    
    // Reset animations for next card
    _resetAnimations();
  }

  void _resetAnimations() {
    setState(() {
      _swipeOffset = 0.0;
      _feedbackColor = Colors.transparent;
    });
    
    _flipController.reset();
    _swipeController.reset();
    _transitionController.reset();
  }

  void _handleButtonAnswer(int difficulty) {
    // Convert difficulty to boolean for now (can be expanded later)
    final wasCorrect = difficulty >= 2; // Good or Easy
    _answerCard(wasCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0), // Paper-like background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Consumer<CardProvider>(
          builder: (context, cardProvider, child) {
            if (cardProvider.isReviewSessionComplete) {
              return const Text('Review Complete');
            }
            
            final current = cardProvider.currentReviewIndex + 1;
            final total = cardProvider.currentReviewSession.length;
            return Text('Card $current of $total');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final cardProvider = context.read<CardProvider>();
              await cardProvider.endReviewSession();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, cardProvider, child) {
          if (cardProvider.isReviewSessionComplete) {
            return _buildCompletionScreen(cardProvider);
          }
          
          final currentCard = cardProvider.currentCard;
          if (currentCard == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Column(
            children: [
              _buildProgressIndicator(cardProvider),
              Expanded(
                child: _buildCardArea(currentCard, cardProvider),
              ),
              if (cardProvider.showingBack) _buildAnswerButtons(),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(CardProvider cardProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: LinearProgressIndicator(
        value: cardProvider.reviewProgress,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildCardArea(CardModel card, CardProvider cardProvider) {
    return Center(
      child: GestureDetector(
        onTap: _handleTap,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _flipController,
            _transitionController,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_swipeOffset, 0) + _slideAnimation.value * 300,
              child: Transform.scale(
                scale: _isDragging ? 1.05 : _scaleAnimation.value,
                child: AnimatedBuilder(
                  animation: _swipeAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _isDragging ? (_swipeOffset / 300) * 0.1 : 0,
                      child: _buildCard(card, cardProvider),
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

  Widget _buildCard(CardModel card, CardProvider cardProvider) {
    return RepaintBoundary(
      child: Container(
        width: 320,
        height: 400,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isDragging ? [
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
            if (_feedbackColor != Colors.transparent)
              Container(
                decoration: BoxDecoration(
                  color: _feedbackColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            // Card content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final isShowingFront = _flipAnimation.value < 0.5;
                    if (isShowingFront) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_flipAnimation.value * 3.14159),
                        child: _buildCardFront(card),
                      );
                    } else {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY((_flipAnimation.value - 1) * 3.14159),
                        child: _buildCardBack(card),
                      );
                    }
                  },
                );
              },
              child: cardProvider.showingBack
                  ? _buildCardBack(card)
                  : _buildCardFront(card),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront(CardModel card) {
    return Container(
      key: const ValueKey('front'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.icon != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Icon(
                Icons.help_outline, // Placeholder - replace with actual icon
                size: 48,
                color: Colors.grey[600],
              ),
            ),
          Text(
            card.frontText,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Tap to reveal answer',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(CardModel card) {
    return Container(
      key: const ValueKey('back'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.frontText,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            card.backText,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Swipe left (don\'t know) or right (know)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleButtonAnswer(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Again'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleButtonAnswer(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Hard'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleButtonAnswer(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Good'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleButtonAnswer(3),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Easy'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen(CardProvider cardProvider) {
    final sessionDuration = cardProvider.sessionStartTime != null
        ? DateTime.now().difference(cardProvider.sessionStartTime!)
        : Duration.zero;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Review Complete!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You reviewed ${cardProvider.sessionCardsReviewed} cards',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Time: ${sessionDuration.inMinutes}:${(sessionDuration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              await cardProvider.endReviewSession();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
