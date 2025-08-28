import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/card_provider.dart';
import '../widgets/iconify_icon.dart';
import '../widgets/milestone_celebration_dialog.dart';
import 'simple_card_creation_screen.dart';

/// Screen for reviewing cards with swipe gestures (like Anki/Duocards)
class CardReviewScreen extends StatefulWidget {
  const CardReviewScreen({super.key});

  @override
  State<CardReviewScreen> createState() => _CardReviewScreenState();
}

class _CardReviewScreenState extends State<CardReviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _colorController;
  late AnimationController _pageController;
  late AnimationController _bindingController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pageFlipAnimation;
  late Animation<double> _bindingAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _perspectiveAnimation;
  
  bool _isDragging = false;
  double _dragStartX = 0.0;
  double _currentDragPercent = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Animation for page turning (book-like)
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pageFlipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOutQuart,
    ));
    
    // Animation for book binding effect
    _bindingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bindingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bindingController,
      curve: Curves.easeOut,
    ));
    
    // Animation for card sliding
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Animation for color feedback during swipe
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Scale animation for feedback
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
    
    // Color animation for swipe feedback
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.green.withValues(alpha: 0.2),
    ).animate(_colorController);
    
    // Rotation animation for swipe feedback
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.08, // Subtle tilt for book-like feel
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
    
    // Shadow animation for depth
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    ));
    
    // Perspective animation for 3D effect
    _perspectiveAnimation = Tween<double>(
      begin: 0.0,
      end: 0.002,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _colorController.dispose();
    _pageController.dispose();
    _bindingController.dispose();
    super.dispose();
  }

  void _flipCard() {
    final provider = context.read<CardProvider>();
    // Use the animation controller's status to prevent multiple flips
    if (provider.currentCard == null || _pageController.isAnimating) return;

    _bindingController.forward();

    if (provider.showingBack) {
      _pageController.reverse().whenComplete(() {
        _bindingController.reverse();
      });
    } else {
      _pageController.forward().whenComplete(() {
        _bindingController.reverse();
      });
    }

    provider.flipCard();
  }

  Future<void> _answerCard(bool wasCorrect) async {
    final provider = context.read<CardProvider>();
    // Wait for any ongoing page flip to complete before answering
    if (_pageController.isAnimating) {
      await _pageController.forward();
    }

    // Just slide the card away - no flipping back
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: wasCorrect ? const Offset(1.2, 0.0) : const Offset(-1.2, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));

    // Slide the card away
    await _slideController.forward();

    // Answer the card
    await provider.answerCard(wasCorrect);

    // Check for milestone celebrations when session ends
    if (!provider.isReviewMode && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          MilestoneCelebrationDialog.showIfNeeded(context);
        }
      });
    }

    // Reset animations for the next card
    _pageController.reset();
    _slideController.reset();
    _colorController.reset();
    _bindingController.reset();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _dragStartX = details.globalPosition.dx;
    _currentDragPercent = 0.0;
    
    // Start color animation
    _colorController.reset();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    final dragDistance = details.globalPosition.dx - _dragStartX;
    final screenWidth = MediaQuery.of(context).size.width;
    final dragPercent = (dragDistance / screenWidth).clamp(-1.0, 1.0);
    
    _currentDragPercent = dragPercent;
    
    // Update slide animation
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(dragPercent, 0.0),
    ).animate(_slideController);
    
    _slideController.value = dragPercent.abs();
    
    // Update color animation based on swipe direction
    final isCorrect = dragPercent > 0;
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: isCorrect 
          ? Colors.green.withValues(alpha: 0.2 + (0.3 * dragPercent.abs()))
          : Colors.red.withValues(alpha: 0.2 + (0.3 * dragPercent.abs())),
    ).animate(_colorController);
    
    // Update rotation animation
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: dragPercent * 0.15, // Tilt in the direction of swipe
    ).animate(_colorController);
    
    // Animate color feedback
    _colorController.value = dragPercent.abs();
    
    // Haptic feedback at certain thresholds
    if (dragPercent.abs() > 0.3 && dragPercent.abs() < 0.35) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    
    final provider = context.read<CardProvider>();
    if (provider.currentCard == null) return;
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine if swipe was significant enough
    final swipeThreshold = screenWidth * 0.25; // Reduced threshold for easier swiping
    final velocityThreshold = 400.0; // Reduced threshold
    
    if (_slideController.value > (swipeThreshold / screenWidth) || velocity.abs() > velocityThreshold) {
      // Complete the swipe with haptic feedback
      HapticFeedback.mediumImpact();
      
      if (velocity > 0 || _currentDragPercent > 0) {
        // Swipe right (correct)
        _answerCard(true);
      } else {
        // Swipe left (incorrect)
        _answerCard(false);
      }
    } else {
      // Return to center with bounce and light haptic feedback
      HapticFeedback.lightImpact();
      _slideController.reverse();
      _colorController.reverse();
    }
  }

  /// Handle keyboard events for navigation
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final provider = context.read<CardProvider>();
      
      // Only handle keys when in review mode and session is not complete
      if (!provider.isReviewMode || provider.isReviewSessionComplete) {
        return KeyEventResult.ignored;
      }
      
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          // Left arrow = incorrect/swipe left
          HapticFeedback.mediumImpact();
          _answerCard(false);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          // Right arrow = correct/swipe right
          HapticFeedback.mediumImpact();
          _answerCard(true);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.arrowDown:
          // Space or up/down arrow = flip card
          HapticFeedback.lightImpact();
          _flipCard();
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _editCurrentCard(BuildContext context, CardProvider provider) async {
    final currentCard = provider.currentCard;
    if (currentCard == null) return;

    // Navigate to the card creation screen with the current card for editing
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => SimpleCardCreationScreen(cardToEdit: currentCard),
      ),
    );

    // If the card was edited (result is not null), we don't need to do anything special
    // The provider will automatically update the card in the review session
    if (result != null) {
      // Optional: Show a snack bar to confirm the edit
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Cards'),
          actions: [
            Consumer<CardProvider>(
              builder: (context, provider, child) {
                if (provider.isReviewMode && 
                    provider.currentCard != null && 
                    !provider.isReviewSessionComplete) {
                  return IconButton(
                    onPressed: () => _editCurrentCard(context, provider),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Current Card',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Consumer<CardProvider>(
              builder: (context, provider, child) {
                if (provider.isReviewMode && provider.currentReviewSession.isNotEmpty) {
                  final currentIndex = provider.isReviewSessionComplete 
                      ? provider.currentReviewSession.length 
                      : provider.currentReviewIndex + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Text(
                        '$currentIndex / ${provider.currentReviewSession.length}',
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
          if (!provider.isReviewMode || provider.isReviewSessionComplete) {
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
                    child: _buildCard(context, provider),
                  ),
                ),
              ),
              
              // Action buttons
              _buildActionButtons(context, provider),
            ],
          );
        },
      ),
    ), // Focus widget child: Scaffold
    ); // Focus widget
  }

  Widget _buildCard(BuildContext context, CardProvider provider) {
    final card = provider.currentCard;
    if (card == null) {
      // Return an empty container if no card is available
      return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        margin: const EdgeInsets.all(16.0),
        child: _buildBookContainer(
          context,
          const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    final showBack = provider.showingBack;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _rotationAnimation,
        _pageFlipAnimation,
        _bindingAnimation,
        _shadowAnimation,
        _perspectiveAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isDragging ? _scaleAnimation.value : 1.0,
          child: Transform.rotate(
            angle: _isDragging ? _rotationAnimation.value : 0.0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.6,
              margin: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  // Book spine/binding effect
                  _buildBookSpine(context),
                  
                  // Stack of underlying cards (next cards visible)
                  _buildCardStack(context, provider),
                  
                  // Current card on top
                  _buildCurrentCard(context, card, showBack, provider),
                  
                  // Page shadow for depth
                  _buildPageShadow(context),
                  
                  // Color overlay for swipe feedback
                  if (_isDragging)
                    _buildSwipeFeedback(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBookContainer(BuildContext context, Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
  
  Widget _buildBookSpine(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 8 + (4 * _bindingAnimation.value),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardStack(BuildContext context, CardProvider provider) {
    // Get the next few cards to show underneath
    final currentIndex = provider.currentReviewIndex;
    final reviewSession = provider.currentReviewSession;
    
    return Stack(
      children: [
        // Show up to 3 cards underneath for depth
        for (int i = 1; i <= 3; i++)
          if (currentIndex + i < reviewSession.length)
            _buildStackCard(context, reviewSession[currentIndex + i], i),
      ],
    );
  }
  
  Widget _buildStackCard(BuildContext context, CardModel card, int depth) {
    final offset = depth * 2.0; // Slight offset for each underlying card
    final opacity = 1.0 - (depth * 0.15); // Fade out deeper cards
    final scale = 1.0 - (depth * 0.02); // Slightly smaller for depth
    
    return Positioned(
      left: offset,
      top: offset,
      right: -offset,
      bottom: -offset,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: _buildBookContainer(
            context,
            Container(
              padding: const EdgeInsets.fromLTRB(32.0, 24.0, 24.0, 24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getPageColors(context, false), // Always show front for stack
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1 - (depth * 0.02)),
                    blurRadius: 2,
                    offset: Offset(0, depth.toDouble()),
                  ),
                ],
              ),
              child: _buildCardFront(context, card),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCurrentCard(BuildContext context, CardModel card, bool showBack, CardProvider provider) {
    return SlideTransition(
      position: _slideAnimation,
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, _perspectiveAnimation.value)
          ..rotateY(_pageFlipAnimation.value * 3.14159),
        child: _buildBookContainer(
          context,
          Container(
            padding: const EdgeInsets.fromLTRB(32.0, 24.0, 24.0, 24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getPageColors(context, showBack),
              ),
              // Paper texture effect with enhanced shadow for top card
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: _pageFlipAnimation.value < 0.5
                ? _buildCardFront(context, card)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildCardBack(context, card),
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPageShadow(BuildContext context) {
    if (_shadowAnimation.value == 0) return const SizedBox.shrink();
    
    return Positioned(
      left: 12 + (20 * _shadowAnimation.value),
      top: 4,
      bottom: 4,
      right: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withValues(alpha: 0.15 * _shadowAnimation.value),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSwipeFeedback(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _colorAnimation.value,
          ),
          child: Center(
            child: AnimatedScale(
              scale: _currentDragPercent.abs() > 0.3 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Icon(
                _currentDragPercent > 0 ? Icons.check_circle : Icons.cancel,
                size: 50 + (15 * _currentDragPercent.abs()),
                color: (_currentDragPercent > 0 ? Colors.green : Colors.red)
                    .withValues(alpha: 0.6 + (0.4 * _currentDragPercent.abs())),
              ),
            ),
          ),
        );
      },
    );
  }
  
  List<Color> _getPageColors(BuildContext context, bool showBack) {
    final baseColor = showBack
        ? Theme.of(context).colorScheme.secondaryContainer
        : Theme.of(context).colorScheme.primaryContainer;
    
    // Create a paper-like gradient
    return [
      baseColor.withValues(alpha: 0.95),
      baseColor.withValues(alpha: 0.85),
      baseColor.withValues(alpha: 0.9),
    ];
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
          card.germanArticle != null 
              ? '${card.germanArticle} ${card.frontText}'
              : card.frontText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          '${card.language.toUpperCase()} STUDY',
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
          card.germanArticle != null 
              ? '${card.germanArticle} ${card.frontText}'
              : card.frontText,
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
                    onPressed: () async {
                      await provider.endReviewSession();
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
