import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../../card_management/presentation/screens/card_creation_screen.dart';
import '../../../card_review/domain/providers/practice_session_types.dart';
import '../../../card_review/domain/providers/practice_session_notifier.dart';
import '../../../card_review/domain/providers/practice_session_state.dart';
import '../../../card_review/domain/providers/exercise_preferences_notifier.dart';
import '../widgets/exercise_filter_sheet.dart';
import '../widgets/practice_progress_bar.dart';
import '../widgets/practice_completion_screen.dart';
import '../widgets/exercises/exercise_content_widget.dart';
import '../widgets/swipeable_exercise_card.dart';
import '../../../../shared/domain/models/card_model.dart';

/// Screen where users practice their cards through various exercises
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final GlobalKey<_SwipeableCardWrapperState> _cardKey = GlobalKey();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _showFilterSheet() async {
    final currentPrefs = ref
        .read(exercisePreferencesNotifierProvider)
        .preferences;

    final newPrefs = await ExerciseFilterSheet.show(
      context,
      currentPreferences: currentPrefs,
    );

    if (newPrefs != null && mounted) {
      // Update Riverpod notifier
      await ref
          .read(exercisePreferencesNotifierProvider.notifier)
          .updatePreferences(newPrefs);
      // PracticeSessionNotifier watches preferences, so it will react automatically if we implement it.
      // Or we can call a method if we want to force rebuild.
    }
  }

  Future<void> _editCurrentCard(
    BuildContext context,
    CardModel? currentCard,
  ) async {
    if (currentCard == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardCreationScreen(cardToEdit: currentCard),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final state = ref.read(practiceSessionNotifierProvider);
      final notifier = ref.read(practiceSessionNotifierProvider.notifier);

      // Allow swiping only when answer has been checked
      if (notifier.canSwipe) {
        // Arrow keys or Enter to confirm answer
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          notifier.confirmAnswerAndAdvance(
            markedCorrect: state.currentAnswerCorrect ?? true,
          );
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          notifier.confirmAnswerAndAdvance(markedCorrect: false);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          notifier.confirmAnswerAndAdvance(markedCorrect: true);
          return KeyEventResult.handled;
        }
      } else {
        final type = notifier.currentExerciseType;
        // Exercise specific shortcuts
        if (type == ExerciseType.readingRecognition ||
            type == ExerciseType.multipleChoiceText ||
            type == ExerciseType.multipleChoiceIcon) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _revealAnswer(notifier);
            return KeyEventResult.handled;
          }

          // Number keys 1-4 for multiple choice
          if (type != ExerciseType.readingRecognition) {
            if (event.logicalKey == LogicalKeyboardKey.digit1) {
              _selectMultipleChoiceOption(state, notifier, 0);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
              _selectMultipleChoiceOption(state, notifier, 1);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
              _selectMultipleChoiceOption(state, notifier, 2);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
              _selectMultipleChoiceOption(state, notifier, 3);
              return KeyEventResult.handled;
            }
          }
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _selectMultipleChoiceOption(
    PracticeSessionState state,
    PracticeSessionNotifier notifier,
    int index,
  ) {
    final options = state.multipleChoiceOptions;
    if (options == null || index >= options.length) return;

    final selectedOption = options[index];
    final correctAnswer = notifier.currentCard?.backText;
    final isCorrect = selectedOption == correctAnswer;
    notifier.checkAnswer(isCorrect: isCorrect);
  }

  void _revealAnswer(PracticeSessionNotifier notifier) {
    // For reading recognition - reveal the answer
    if (ref.read(practiceSessionNotifierProvider).answerState ==
        AnswerState.pending) {
      notifier.checkAnswer(isCorrect: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(practiceSessionNotifierProvider);
    final sessionNotifier = ref.read(practiceSessionNotifierProvider.notifier);

    // Auto-start session if not active when screen opens
    if (!sessionState.isSessionActive && !sessionState.isSessionComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sessionNotifier.startSession();
      });
    }

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
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${sessionState.currentIndex + 1}/${sessionState.sessionQueue.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: (() {
          // Session completed
          if (!sessionState.isSessionActive && sessionState.isSessionComplete) {
            // Calculate duration (this is approximate if not stored in state)
            final duration = sessionState.sessionStartTime != null
                ? DateTime.now().difference(sessionState.sessionStartTime!)
                : Duration.zero;

            return PracticeCompletionScreen(
              correctCount: sessionState.correctCount,
              incorrectCount: sessionState.incorrectCount,
              duration: duration,
              onRestart: () => sessionNotifier.startSession(),
              onClose: () => Navigator.of(context).pop(),
            );
          }

          final currentCard = sessionNotifier.currentCard;
          final currentType = sessionNotifier.currentExerciseType;

          // No current card (shouldn't happen but handle gracefully)
          if (currentCard == null || currentType == null) {
            if (!sessionState.isSessionActive) {
              // If not active and not complete, maybe we need to start?
              // Or just show a message.
              return const Center(
                child: Text("Start a session from the card list"),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Progress bar
              PracticeProgressBar(
                progress: sessionState.progress,
                correctCount: sessionState.correctCount,
                incorrectCount: sessionState.incorrectCount,
              ),

              const SizedBox(height: 16),

              // Swipeable card with exercise content
              Expanded(
                child: _SwipeableCardWrapper(
                  key: _cardKey,
                  sessionState: sessionState,
                  sessionNotifier: sessionNotifier,
                  onEditCard: () => _editCurrentCard(context, currentCard),
                ),
              ),

              // Keyboard hints
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Text(
                  sessionNotifier.canSwipe
                      ? 'Enter = Confirm • ← = Wrong • → = Correct'
                      : '1-4 = Select option • Enter = Reveal',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        })(),
      ),
    );
  }
}

class _SwipeableCardWrapper extends StatefulWidget {
  final PracticeSessionState sessionState;
  final PracticeSessionNotifier sessionNotifier;
  final VoidCallback onEditCard;

  const _SwipeableCardWrapper({
    super.key,
    required this.sessionState,
    required this.sessionNotifier,
    required this.onEditCard,
  });

  @override
  State<_SwipeableCardWrapper> createState() => _SwipeableCardWrapperState();
}

class _SwipeableCardWrapperState extends State<_SwipeableCardWrapper> {
  @override
  Widget build(BuildContext context) {
    final card = widget.sessionNotifier.currentCard!;
    final type = widget.sessionNotifier.currentExerciseType!;
    final options = widget.sessionState.multipleChoiceOptions;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SwipeableExerciseCard(
          canSwipe: widget.sessionNotifier.canSwipe,
          onSwipeRight: () async {
            widget.sessionNotifier.confirmAnswerAndAdvance(markedCorrect: true);
          },
          onSwipeLeft: () async {
            widget.sessionNotifier.confirmAnswerAndAdvance(
              markedCorrect: false,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ExerciseContentWidget(
              card: card,
              exerciseType: type,
              answerState: widget.sessionState.answerState,
              multipleChoiceOptions: options,
              currentAnswerCorrect: widget.sessionState.currentAnswerCorrect,
              onCheckAnswer: (isCorrect) {
                widget.sessionNotifier.checkAnswer(isCorrect: isCorrect);
              },
              onOverrideAnswer: (isCorrect) {
                widget.sessionNotifier.checkAnswer(isCorrect: isCorrect);
              },
            ),
          ),
        ),
      ),
    );
  }
}
