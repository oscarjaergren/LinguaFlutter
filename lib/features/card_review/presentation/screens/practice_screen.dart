import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../../../../shared/domain/models/exercise_type.dart';
import '../../../../shared/domain/models/exercise_score.dart';
import '../../../card_management/presentation/screens/card_creation_screen.dart';
import '../../../card_review/domain/providers/practice_session_provider.dart';
import '../../../card_review/domain/providers/exercise_preferences_notifier.dart';
import '../../../card_review/domain/models/exercise_preferences.dart';
import '../widgets/exercise_filter_sheet.dart';
import '../widgets/practice_progress_bar.dart';
import '../widgets/practice_completion_screen.dart';
import '../widgets/exercises/exercise_content_widget.dart';
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
    // We still access PracticeSessionProvider via Provider package for now
    final provider = provider_pkg.Provider.of<PracticeSessionProvider>(
      context,
      listen: false,
    );

    final newPrefs = await ExerciseFilterSheet.show(
      context,
      currentPreferences: ref
          .read(exercisePreferencesNotifierProvider)
          .preferences,
    );

    if (newPrefs != null && mounted) {
      // Update Riverpod notifier and session provider
      await ref
          .read(exercisePreferencesNotifierProvider.notifier)
          .updatePreferences(newPrefs);
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
      final provider = provider_pkg.Provider.of<PracticeSessionProvider>(
        context,
        listen: false,
      );

      // Allow swiping only when answer has been checked
      if (provider.canSwipe) {
        // Arrow keys or Enter to confirm answer
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          provider.confirmAnswerAndAdvance(
            markedCorrect: provider.currentAnswerCorrect ?? true,
          );
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          provider.confirmAnswerAndAdvance(markedCorrect: false);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          provider.confirmAnswerAndAdvance(markedCorrect: true);
          return KeyEventResult.handled;
        }
      } else {
        // Exercise specific shortcuts
        if (provider.currentExerciseType == ExerciseType.readingRecognition ||
            provider.currentExerciseType == ExerciseType.multipleChoiceText ||
            provider.currentExerciseType == ExerciseType.multipleChoiceIcon) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _revealAnswer(provider);
            return KeyEventResult.handled;
          }

          // Number keys 1-4 for multiple choice
          if (provider.currentExerciseType != ExerciseType.readingRecognition) {
            if (event.logicalKey == LogicalKeyboardKey.digit1) {
              _selectMultipleChoiceOption(provider, 0);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
              _selectMultipleChoiceOption(provider, 1);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
              _selectMultipleChoiceOption(provider, 2);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
              _selectMultipleChoiceOption(provider, 3);
              return KeyEventResult.handled;
            }
          }
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
            provider_pkg.Consumer<PracticeSessionProvider>(
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
        body: provider_pkg.Consumer<PracticeSessionProvider>(
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
              ],
            );
          },
        ),
      ),
    );
  }
}

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
  @override
  Widget build(BuildContext context) {
    final card = widget.provider.currentCard!;
    final type = widget.provider.currentExerciseType!;
    final options = widget.provider.multipleChoiceOptions;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ExerciseContentWidget(
            card: card,
            exerciseType: type,
            answerState: widget.provider.answerState,
            multipleChoiceOptions: options,
            currentAnswerCorrect: widget.provider.currentAnswerCorrect,
            onCheckAnswer: (isCorrect) {
              widget.provider.checkAnswer(isCorrect: isCorrect);
            },
            onOverrideAnswer: (isCorrect) {
              widget.provider.checkAnswer(isCorrect: isCorrect);
            },
          ),
        ),
      ),
    );
  }
}
