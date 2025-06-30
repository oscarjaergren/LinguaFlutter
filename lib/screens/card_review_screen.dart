import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/card_provider.dart';
import '../widgets/iconify_icon.dart';

/// Screen for reviewing cards with swipe gestures (like Anki/Duocards)
class CardReviewScreen extends StatefulWidget {
  const CardReviewScreen({super.key});

  @override
  State<CardReviewScreen> createState() => _CardReviewScreenState();
}

class _CardReviewScreenState extends State<CardReviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _slideController;
  late Animation<double> _flipAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isDragging = false;
  double _dragStartX = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Animation for card flipping
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    // Animation for card sliding
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _flipCard() {
    final provider = context.read<CardProvider>();
    
    if (provider.showingBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    
    provider.flipCard();
  }

  Future<void> _answerCard(bool wasCorrect) async {
    final provider = context.read<CardProvider>();
    
    // Animate slide out
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: wasCorrect ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    await _slideController.forward();
    
    // Answer the card
    await provider.answerCard(wasCorrect);
    
    // Reset animations
    _flipController.reset();
    _slideController.reset();
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_slideController);
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _dragStartX = details.globalPosition.dx;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    final dragDistance = details.globalPosition.dx - _dragStartX;
    final screenWidth = MediaQuery.of(context).size.width;
    final dragPercent = (dragDistance / screenWidth).clamp(-1.0, 1.0);
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(dragPercent, 0.0),
    ).animate(_slideController);
    
    _slideController.value = dragPercent.abs();
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine if swipe was significant enough
    final swipeThreshold = screenWidth * 0.3;
    final velocityThreshold = 500.0;
    
    if (_slideController.value > (swipeThreshold / screenWidth) || velocity.abs() > velocityThreshold) {
      // Complete the swipe
      if (velocity > 0 || _dragStartX < screenWidth / 2) {
        // Swipe right (correct)
        _answerCard(true);
      } else {
        // Swipe left (incorrect)
        _answerCard(false);
      }
    } else {
      // Return to center
      _slideController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Cards'),
        actions: [
          Consumer<CardProvider>(
            builder: (context, provider, child) {
              if (provider.isReviewMode && provider.currentReviewSession.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      '${provider.currentReviewIndex + 1} / ${provider.currentReviewSession.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, child) {
          if (!provider.isReviewMode || provider.currentCard == null) {
            return _buildSessionComplete(context, provider);
          }
          
          return Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LinearProgressIndicator(
                  value: provider.reviewProgress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              
              // Card area
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTap: _flipCard,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_flipAnimation.value * 3.14159),
                            child: _buildCard(context, provider),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              
              // Action buttons
              _buildActionButtons(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, CardProvider provider) {
    final card = provider.currentCard!;
    final showBack = provider.showingBack;
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.5,
      margin: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: showBack
                  ? [
                      Theme.of(context).colorScheme.secondaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.7),
                    ]
                  : [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
            ),
          ),
          child: _flipAnimation.value < 0.5
              ? _buildCardFront(context, card)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: _buildCardBack(context, card),
                ),
        ),
      ),
    );
  }

  Widget _buildCardFront(BuildContext context, CardModel card) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (card.icon != null) ...[
          IconifyIcon(
            icon: card.icon!,
            size: 64,
          ),
          const SizedBox(height: 24),
        ],
        Text(
          card.frontText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          '${card.frontLanguage.toUpperCase()} → ${card.backLanguage.toUpperCase()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Tap to reveal answer',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardBack(BuildContext context, CardModel card) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (card.icon != null) ...[
          IconifyIcon(
            icon: card.icon!,
            size: 48,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          card.frontText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          card.backText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        _buildCardStats(context, card),
      ],
    );
  }

  Widget _buildCardStats(BuildContext context, CardModel card) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                label: 'Reviews',
                value: card.reviewCount.toString(),
              ),
              _StatColumn(
                label: 'Success',
                value: '${card.successRate.toInt()}%',
              ),
              _StatColumn(
                label: 'Level',
                value: card.masteryLevel,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Swipe or use buttons below',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CardProvider provider) {
    if (!provider.showingBack) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _flipCard,
            icon: const Icon(Icons.flip_to_back),
            label: const Text('Show Answer'),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _answerCard(false),
              icon: const Icon(Icons.close),
              label: const Text('Incorrect'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _answerCard(true),
              icon: const Icon(Icons.check),
              label: const Text('Correct'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionComplete(BuildContext context, CardProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Review Complete!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Great job! You\'ve completed all your review cards.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Cards'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      provider.startReviewSession();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Review Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
