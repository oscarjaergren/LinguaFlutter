import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../card_management/presentation/screens/card_creation_screen.dart';
import '../../domain/providers/practice_session_provider.dart';
import '../widgets/swipeable_exercise_card.dart';
import '../widgets/exercises/exercise_content_widget.dart';
import '../widgets/practice_completion_screen.dart';
import '../widgets/practice_progress_bar.dart';

/// Unified practice screen with swipeable exercise cards
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<_SwipeableCardWrapperState> _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _startSession() {
    final provider = Provider.of<PracticeSessionProvider>(context, listen: false);
    if (!provider.isSessionActive) {
      provider.startSession();
    }
  }

  Future<void> _editCurrentCard(BuildContext context, PracticeSessionProvider provider) async {
    final currentCard = provider.currentCard;
    if (currentCard == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreationCreationScreen(cardToEdit: currentCard),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final provider = Provider.of<PracticeSessionProvider>(context, listen: false);
      
      // Allow swiping only when answer has been checked
      if (provider.canSwipe) {
        // Arrow keys or Enter to confirm answer
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _cardKey.currentState?.triggerSwipe(false);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                   event.logicalKey == LogicalKeyboardKey.enter ||
                   event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          // Enter confirms with current answer correctness
          final isCorrect = provider.currentAnswerCorrect ?? true;
          _cardKey.currentState?.triggerSwipe(isCorrect);
          return KeyEventResult.handled;
        }
      } else {
        // Before answer checked - number keys for multiple choice
        if (event.logicalKey == LogicalKeyboardKey.digit1 ||
            event.logicalKey == LogicalKeyboardKey.numpad1) {
          _selectMultipleChoiceOption(provider, 0);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
                   event.logicalKey == LogicalKeyboardKey.numpad2) {
          _selectMultipleChoiceOption(provider, 1);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
                   event.logicalKey == LogicalKeyboardKey.numpad3) {
          _selectMultipleChoiceOption(provider, 2);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
                   event.logicalKey == LogicalKeyboardKey.numpad4) {
          _selectMultipleChoiceOption(provider, 3);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                   event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          // Enter reveals answer for reading recognition
          _revealAnswer(provider);
          return KeyEventResult.handled;
        }
      }
    }
    
    return KeyEventResult.ignored;
  }

  void _selectMultipleChoiceOption(PracticeSessionProvider provider, int index) {
    final options = provider.multipleChoiceOptions;
    if (options == null || index >= options.length) return;
    
    final selectedOption = options[index];
    final correctAnswer = provider.currentCard?.backText;
    final isCorrect = selectedOption == correctAnswer;
    provider.checkAnswer(isCorrect: isCorrect);
  }

  void _revealAnswer(PracticeSessionProvider provider) {
    // For reading recognition - reveal the answer
    if (provider.answerState == AnswerState.pending) {
      provider.checkAnswer(isCorrect: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Practice'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Consumer<PracticeSessionProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      '${provider.currentIndex + 1}/${provider.totalCount}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<PracticeSessionProvider>(
          builder: (context, provider, child) {
            // Session completed
            if (!provider.isSessionActive) {
              return PracticeCompletionScreen(
                correctCount: provider.correctCount,
                incorrectCount: provider.incorrectCount,
                duration: provider.sessionDuration,
                onRestart: () => provider.restartSession(),
                onClose: () => Navigator.of(context).pop(),
              );
            }

            // No current card (shouldn't happen but handle gracefully)
            if (provider.currentCard == null || provider.currentExerciseType == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // Progress bar
                PracticeProgressBar(
                  progress: provider.progress,
                  correctCount: provider.correctCount,
                  incorrectCount: provider.incorrectCount,
                ),
                
                // Stats display (above the card)
                const SizedBox(height: 8),
                _buildStatsRow(context, provider),
                
                // Swipeable card with exercise content
                Expanded(
                  child: _SwipeableCardWrapper(
                    key: _cardKey,
                    provider: provider,
                    onEditCard: () => _editCurrentCard(context, provider),
                  ),
                ),
                
                // Keyboard hints
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Text(
                    provider.canSwipe
                        ? 'Enter = Confirm • ← = Wrong • → = Correct'
                        : '1-4 = Select option • Enter = Reveal',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, PracticeSessionProvider provider) {
    final card = provider.currentCard!;
    final exerciseType = provider.currentExerciseType!;
    final score = card.getExerciseScore(exerciseType);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatChip(
            context,
            Icons.school,
            'Overall: ${card.overallMasteryLevel}',
          ),
          const SizedBox(width: 12),
          if (score != null)
            _buildStatChip(
              context,
              Icons.check_circle_outline,
              '${score.correctCount}/${score.totalAttempts}',
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper widget to handle swipeable card with state
class _SwipeableCardWrapper extends StatefulWidget {
  final PracticeSessionProvider provider;
  final VoidCallback onEditCard;

  const _SwipeableCardWrapper({
    super.key,
    required this.provider,
    required this.onEditCard,
  });

  @override
  State<_SwipeableCardWrapper> createState() => _SwipeableCardWrapperState();
}

class _SwipeableCardWrapperState extends State<_SwipeableCardWrapper> {
  final GlobalKey<SwipeableExerciseCardState> _swipeCardKey = GlobalKey();

  void triggerSwipe(bool isCorrect) {
    // Access the swipeable card's keyboard swipe handler
    _swipeCardKey.currentState?.handleKeyboardSwipe(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return SwipeableExerciseCard(
      key: _swipeCardKey,
      canSwipe: widget.provider.canSwipe,
      onSwipeRight: () {
        widget.provider.confirmAnswerAndAdvance(markedCorrect: true);
      },
      onSwipeLeft: () {
        widget.provider.confirmAnswerAndAdvance(markedCorrect: false);
      },
      child: Stack(
        children: [
          ExerciseContentWidget(
            card: widget.provider.currentCard!,
            exerciseType: widget.provider.currentExerciseType!,
            multipleChoiceOptions: widget.provider.multipleChoiceOptions,
            answerState: widget.provider.answerState,
            currentAnswerCorrect: widget.provider.currentAnswerCorrect,
            onCheckAnswer: (isCorrect) {
              widget.provider.checkAnswer(isCorrect: isCorrect);
            },
            onOverrideAnswer: (isCorrect) {
              widget.provider.overrideAnswer(isCorrect: isCorrect);
              // Trigger swipe animation when user marks answer
              triggerSwipe(isCorrect);
            },
          ),
          // Edit button in top-right corner of card
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.edit,
                color: Colors.grey[400],
              ),
              tooltip: 'Edit card',
              onPressed: widget.onEditCard,
            ),
          ),
        ],
      ),
    );
  }
}
