import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../card_management/domain/providers/card_management_notifier.dart';
import '../../domain/providers/exercise_preferences_notifier.dart';
import '../../../language/language.dart';
import 'practice_session_types.dart';
import 'practice_session_state.dart';

final practiceSessionNotifierProvider =
    NotifierProvider<PracticeSessionNotifier, PracticeSessionState>(
      () => PracticeSessionNotifier(),
    );

class PracticeSessionNotifier extends Notifier<PracticeSessionState> {
  static const int _minCardsForMultipleChoice = 4;

  @override
  PracticeSessionState build() {
    // Watch relevant dependencies
    ref.watch(cardManagementNotifierProvider);
    ref.watch(exercisePreferencesNotifierProvider);

    return const PracticeSessionState();
  }

  // === Getters (Proxied from state) ===

  PracticeItem? get currentItem =>
      state.isSessionActive && state.currentIndex < state.sessionQueue.length
      ? state.sessionQueue[state.currentIndex]
      : null;

  CardModel? get currentCard => currentItem?.card;
  ExerciseType? get currentExerciseType => currentItem?.exerciseType;

  bool get canSwipe => state.answerState == AnswerState.answered;

  // === Session Management ===

  void startSession({List<CardModel>? cards}) {
    final cardsToUse =
        cards ?? ref.read(cardManagementNotifierProvider).allCards;
    // Filter cards by due status and language if needed (logic similar to PracticeSessionProvider)
    // Actually, PracticeSessionProvider gets review cards from a callback.
    // For now, let's just assume we get them from CardManagementNotifier.

    final activeLanguage = ref.read(languageNotifierProvider).activeLanguage;
    final reviewCards = cardsToUse
        .where(
          (c) =>
              c.isDueForReview &&
              !c.isArchived &&
              (activeLanguage.isEmpty || c.language == activeLanguage),
        )
        .toList();

    if (reviewCards.isEmpty) {
      state = state.copyWith(isSessionActive: false);
      return;
    }

    final queue = _buildPracticeQueue(reviewCards);
    state = state.copyWith(
      sessionQueue: queue,
      currentIndex: 0,
      isSessionActive: queue.isNotEmpty,
      isSessionComplete: false,
      sessionStartTime: DateTime.now(),
      correctCount: 0,
      incorrectCount: 0,
      answerState: AnswerState.pending,
      currentAnswerCorrect: null,
      userInput: null,
      progress: 0.0,
    );

    _prepareCurrentExercise();
  }

  List<PracticeItem> _buildPracticeQueue(List<CardModel> cards) {
    final queue = <PracticeItem>[];
    final allCards = ref.read(cardManagementNotifierProvider).allCards;
    final prefs = ref.read(exercisePreferencesNotifierProvider).preferences;
    final hasEnoughCardsForMultipleChoice =
        allCards.length >= _minCardsForMultipleChoice;

    for (final card in cards) {
      final dueTypes = card.dueExerciseTypes
          .where((t) => prefs.isEnabled(t))
          .where(
            (t) => t.canUse(
              card,
              hasEnoughCardsForMultipleChoice: hasEnoughCardsForMultipleChoice,
            ),
          )
          .toList();

      if (dueTypes.isEmpty) {
        final availableTypes = ExerciseType.values
            .where((t) => t.isImplemented && prefs.isEnabled(t))
            .where(
              (t) => t.canUse(
                card,
                hasEnoughCardsForMultipleChoice:
                    hasEnoughCardsForMultipleChoice,
              ),
            )
            .toList();

        if (availableTypes.isNotEmpty) {
          if (prefs.prioritizeWeaknesses) {
            availableTypes.sort((a, b) => _compareByWeakness(card, a, b));
            queue.add(
              PracticeItem(card: card, exerciseType: availableTypes.first),
            );
          } else {
            availableTypes.shuffle();
            queue.add(
              PracticeItem(card: card, exerciseType: availableTypes.first),
            );
          }
        }
      } else {
        if (prefs.prioritizeWeaknesses) {
          dueTypes.sort((a, b) => _compareByWeakness(card, a, b));
          queue.add(PracticeItem(card: card, exerciseType: dueTypes.first));
        } else {
          for (final type in dueTypes) {
            queue.add(PracticeItem(card: card, exerciseType: type));
          }
        }
      }
    }

    if (prefs.prioritizeWeaknesses) {
      queue.sort(
        (a, b) => _compareByWeakness(a.card, a.exerciseType, b.exerciseType),
      );
    } else {
      queue.shuffle();
    }

    return queue;
  }

  int _compareByWeakness(CardModel card, ExerciseType a, ExerciseType b) {
    final scoreA = card.getExerciseScore(a);
    final scoreB = card.getExerciseScore(b);
    final rateA = scoreA?.totalAttempts == 0
        ? -1.0
        : (scoreA?.successRate ?? 0.0);
    final rateB = scoreB?.totalAttempts == 0
        ? -1.0
        : (scoreB?.successRate ?? 0.0);
    return rateA.compareTo(rateB);
  }

  void _prepareCurrentExercise() {
    final type = currentExerciseType;
    if (type == null) return;

    if (type == ExerciseType.multipleChoiceText ||
        type == ExerciseType.multipleChoiceIcon) {
      _generateMultipleChoiceOptions();
    } else {
      state = state.copyWith(multipleChoiceOptions: null);
    }
    state = state.copyWith(userInput: null);
  }

  void _generateMultipleChoiceOptions() {
    final card = currentCard;
    if (card == null) return;

    final correctAnswer = card.backText;
    final allCards =
        ref
            .read(cardManagementNotifierProvider)
            .allCards
            .where((c) => c.id != card.id && c.backText != correctAnswer)
            .toList()
          ..shuffle();

    final wrongAnswers = allCards.take(3).map((c) => c.backText).toList();
    final options = [correctAnswer, ...wrongAnswers]..shuffle();
    state = state.copyWith(multipleChoiceOptions: options);
  }

  void endSession() {
    state = state.copyWith(
      isSessionActive: false,
      isSessionComplete: false,
      sessionQueue: [],
      currentIndex: 0,
    );
  }

  // === Answer Handling ===

  void updateUserInput(String input) {
    state = state.copyWith(userInput: input);
  }

  void checkAnswer({required bool isCorrect}) {
    state = state.copyWith(
      answerState: AnswerState.answered,
      currentAnswerCorrect: isCorrect,
    );
  }

  void confirmAnswerAndAdvance({required bool markedCorrect}) async {
    final card = currentCard;
    final type = currentExerciseType;
    if (card == null || type == null) return;

    final updatedCard = card.copyWithExerciseResult(
      exerciseType: type,
      wasCorrect: markedCorrect,
    );

    await ref
        .read(cardManagementNotifierProvider.notifier)
        .updateCard(updatedCard);

    final updatedQueue = List<PracticeItem>.from(state.sessionQueue);
    updatedQueue[state.currentIndex] = PracticeItem(
      card: updatedCard,
      exerciseType: type,
    );

    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= updatedQueue.length;

    state = state.copyWith(
      sessionQueue: updatedQueue,
      currentIndex: isComplete ? state.currentIndex : nextIndex,
      correctCount: state.correctCount + (markedCorrect ? 1 : 0),
      incorrectCount: state.incorrectCount + (markedCorrect ? 0 : 1),
      isSessionComplete: isComplete,
      isSessionActive: !isComplete,
      answerState: AnswerState.pending,
      currentAnswerCorrect: null,
      userInput: null,
      progress: (nextIndex) / updatedQueue.length,
    );

    if (!isComplete) {
      _prepareCurrentExercise();
    }
  }
}
