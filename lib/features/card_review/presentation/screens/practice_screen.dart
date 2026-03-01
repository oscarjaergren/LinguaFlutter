import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../card_management/presentation/screens/card_creation_screen.dart';
import '../../../card_review/domain/providers/practice_session_types.dart';
import '../../../card_review/domain/providers/practice_session_notifier.dart';
import '../../../card_review/domain/providers/practice_session_state.dart';
import '../../../card_review/domain/providers/exercise_preferences_notifier.dart';
import '../widgets/exercise_filter_sheet.dart';
import '../widgets/practice_progress_bar.dart';
import '../widgets/exercises/exercise_content_widget.dart';
import '../widgets/swipeable_exercise_card.dart';
import '../widgets/practice_stats_modal.dart';

/// Screen where users practice their cards through various exercises
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
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

  void _showStatsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PracticeStatsModal(),
    );
  }

  Future<void> _editCurrentCard(
    BuildContext context,
    CardModel currentCard,
  ) async {
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

    // Ensure we have a current item when the screen opens.
    if (!sessionState.noDueItems && sessionNotifier.currentItem == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // Capture context before async operations
        final context = this.context;

        try {
          await sessionNotifier.startSession();
        } catch (e) {
          LoggerService.error('Failed to start practice session', e);
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to start practice session: ${e.toString()}',
                ),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await sessionNotifier.startSession();
                    } catch (retryError) {
                      LoggerService.error('Retry failed', retryError);
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Retry failed: ${retryError.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          }
        }
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
            // Simple run counters (correct / incorrect)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${sessionState.runCorrectCount} correct, ${sessionState.runIncorrectCount} incorrect',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: (() {
          final currentCard = sessionNotifier.currentCard;
          final currentType = sessionNotifier.currentExerciseType;

          // No due items available
          if (sessionState.noDueItems && currentCard == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You have no cards due right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Come back later, or browse and add cards from your library.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // No current card yet – still loading next item
          final card = currentCard;
          final type = currentType;
          if (card == null || type == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Progress bar with stats button
              Row(
                children: [
                  Expanded(child: PracticeProgressBar()),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showStatsModal(context),
                    icon: const Icon(Icons.analytics_outlined),
                    tooltip: 'Practice Stats',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Swipeable card with exercise content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                      maxHeight: 600,
                    ),
                    child: SwipeableExerciseCard(
                      canSwipe: sessionNotifier.canSwipe,
                      onSwipeRight: () async {
                        sessionNotifier.confirmAnswerAndAdvance(
                          markedCorrect: true,
                        );
                      },
                      onSwipeLeft: () async {
                        sessionNotifier.confirmAnswerAndAdvance(
                          markedCorrect: false,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ExerciseContentWidget(
                          card: card,
                          exerciseType: type,
                          answerState: sessionState.answerState,
                          multipleChoiceOptions:
                              sessionState.multipleChoiceOptions,
                          currentAnswerCorrect:
                              sessionState.currentAnswerCorrect,
                          onCheckAnswer: (isCorrect) {
                            sessionNotifier.checkAnswer(isCorrect: isCorrect);
                          },
                          onOverrideAnswer: (isCorrect) {
                            sessionNotifier.checkAnswer(isCorrect: isCorrect);
                          },
                          onEditCard: () => _editCurrentCard(context, card),
                        ),
                      ),
                    ),
                  ),
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
