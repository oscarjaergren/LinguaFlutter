import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../../../shared/domain/models/exercise_score.dart';
import '../../../card_management/presentation/screens/card_creation_screen.dart';
import '../../domain/providers/practice_session_provider.dart';
import '../../domain/providers/exercise_preferences_provider.dart';
import '../widgets/swipeable_exercise_card.dart';
import '../widgets/exercises/exercise_content_widget.dart';
import '../widgets/practice_completion_screen.dart';
import '../widgets/practice_progress_bar.dart';
import '../widgets/exercise_filter_sheet.dart';

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
    final provider = Provider.of<PracticeSessionProvider>(
      context,
      listen: false,
    );
    final prefsProvider = Provider.of<ExercisePreferencesProvider>(
      context,
      listen: false,
    );

    if (!provider.isSessionActive) {
      // Start session with current exercise preferences
      provider.startSession(preferences: prefsProvider.preferences);
    }
  }

  Future<void> _showFilterSheet() async {
    final provider = Provider.of<PracticeSessionProvider>(
      context,
      listen: false,
    );
    final prefsProvider = Provider.of<ExercisePreferencesProvider>(
      context,
      listen: false,
    );

    final newPrefs = await ExerciseFilterSheet.show(
      context,
      currentPreferences: provider.exercisePreferences,
    );

    if (newPrefs != null && mounted) {
      // Update both providers
      await prefsProvider.updatePreferences(newPrefs);
      provider.updateExercisePreferences(newPrefs);
    }
  }

  Future<void> _editCurrentCard(
    BuildContext context,
    PracticeSessionProvider provider,
  ) async {
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
      final provider = Provider.of<PracticeSessionProvider>(
        context,
        listen: false,
      );

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

  void _selectMultipleChoiceOption(
    PracticeSessionProvider provider,
    int index,
  ) {
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
            // Filter button
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter exercise types',
              onPressed: _showFilterSheet,
            ),
            // Progress counter
            Consumer<PracticeSessionProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
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
            if (provider.currentCard == null ||
                provider.currentExerciseType == null) {
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

                const SizedBox(height: 16),

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Text(
                    provider.canSwipe
                        ? 'Enter = Confirm • ← = Wrong • → = Correct'
                        : '1-4 = Select option • Enter = Reveal',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
    final card = widget.provider.currentCard!;
    final exerciseType = widget.provider.currentExerciseType!;
    final score = card.getExerciseScore(exerciseType);
    final masteryLevel = score?.masteryLevel ?? "New";
    final currentStreak = score?.currentStreak ?? 0;
    final masteryProgress = score?.masteryProgress ?? 0.0;
    final color = _getMasteryColor(masteryLevel);

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
          Column(
            children: [
              Expanded(
                child: ExerciseContentWidget(
                  card: card,
                  exerciseType: exerciseType,
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
              ),
              // Mastery info bar at bottom of card
              _buildMasteryBar(
                context,
                exerciseType,
                masteryLevel,
                currentStreak,
                masteryProgress,
                color,
                score,
              ),
            ],
          ),
          // Edit button in top-right corner of card
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[400]),
              tooltip: 'Edit card',
              onPressed: widget.onEditCard,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryBar(
    BuildContext context,
    ExerciseType exerciseType,
    String masteryLevel,
    int currentStreak,
    double masteryProgress,
    Color color,
    ExerciseScore? score,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Exercise type icon and name
          Icon(exerciseType.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            _getExerciseShortName(exerciseType),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          // Streak with progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '$currentStreak/5',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: masteryProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Mastery level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              masteryLevel,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMasteryColor(String masteryLevel) {
    switch (masteryLevel) {
      case 'Mastered':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Learning':
        return Colors.orange;
      case 'Difficult':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getExerciseShortName(ExerciseType type) {
    switch (type) {
      case ExerciseType.readingRecognition:
        return 'Reading';
      case ExerciseType.writingTranslation:
        return 'Writing';
      case ExerciseType.multipleChoiceText:
        return 'Multiple Choice';
      case ExerciseType.multipleChoiceIcon:
        return 'Icon Choice';
      case ExerciseType.reverseTranslation:
        return 'Reverse';
      case ExerciseType.listening:
        return 'Listening';
      case ExerciseType.speakingPronunciation:
        return 'Speaking';
      case ExerciseType.sentenceFill:
        return 'Fill Blank';
      case ExerciseType.sentenceBuilding:
        return 'Sentence';
      case ExerciseType.conjugationPractice:
        return 'Conjugation';
      case ExerciseType.articleSelection:
        return 'Article';
    }
  }
}
