import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/exercise_type.dart';
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
    // Keep this notifier state stable across dependency updates.
    // Dependencies are read on demand in methods to avoid resetting sessions.
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

  /// Starts a practice session with due cards.
  /// If [cards] is provided, uses those cards (useful for testing).
  /// Otherwise, automatically gets due cards from CardManagementState,
  /// respecting the active language filter.
  void startSession({List<CardModel>? cards}) {
    final reviewCards = cards ?? _getDueCardsForReview();

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

  /// Gets due cards for review, respecting the active language filter.
  /// This centralizes the logic for determining which cards should be reviewed.
  List<CardModel> _getDueCardsForReview() {
    final managementState = ref.read(cardManagementNotifierProvider);
    final activeLanguage = ref.read(languageNotifierProvider).activeLanguage;

    return managementState.allCards
        .where(
          (c) =>
              c.isDueForReview &&
              !c.isArchived &&
              (activeLanguage.isEmpty || c.language == activeLanguage),
        )
        .toList();
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

  /// Update a card in the session queue when it's edited externally
  void updateCardInQueue(CardModel updatedCard) {
    if (!state.isSessionActive) return;

    final updatedQueue = List<PracticeItem>.from(state.sessionQueue);
    bool changed = false;

    // Update all practice items for this card
    for (int i = 0; i < updatedQueue.length; i++) {
      if (updatedQueue[i].card.id == updatedCard.id) {
        updatedQueue[i] = PracticeItem(
          card: updatedCard,
          exerciseType: updatedQueue[i].exerciseType,
        );
        changed = true;
      }
    }

    if (changed) {
      state = state.copyWith(sessionQueue: updatedQueue);
      // If current card was updated, regenerate options if needed
      if (currentCard?.id == updatedCard.id) {
        _prepareCurrentExercise();
      }
    }
  }

  /// Remove a deleted card from the queue and skip if it's the current card
  Future<void> removeCardFromQueue(String cardId) async {
    if (!state.isSessionActive) return;

    final currentCardId = currentCard?.id;
    final wasCurrentCard = currentCardId == cardId;

    final updatedQueue = List<PracticeItem>.from(state.sessionQueue);

    // Count how many entries for this card appear strictly before the current
    // index — needed to correctly adjust the index after removal.
    final removedBeforeCount = updatedQueue
        .take(state.currentIndex)
        .where((item) => item.card.id == cardId)
        .length;

    // Remove all practice items for this card
    updatedQueue.removeWhere((item) => item.card.id == cardId);

    if (wasCurrentCard) {
      int nextIndex = state.currentIndex - removedBeforeCount;
      if (nextIndex < 0) nextIndex = 0;

      // Clamp index to valid range after removal
      if (nextIndex >= updatedQueue.length) {
        nextIndex = updatedQueue.isEmpty ? 0 : updatedQueue.length - 1;
      }

      // Check if session is now complete
      if (updatedQueue.isEmpty) {
        state = state.copyWith(
          sessionQueue: [],
          currentIndex: 0,
          isSessionComplete: true,
          isSessionActive: false,
          incorrectCount: state.incorrectCount + 1,
        );
        // endSession(); // Potentially call this after a delay or on user action
        return;
      }

      state = state.copyWith(
        sessionQueue: updatedQueue,
        currentIndex: nextIndex,
        incorrectCount: state.incorrectCount + 1,
        answerState: AnswerState.pending,
        currentAnswerCorrect: null,
        userInput: null,
      );

      _prepareCurrentExercise();
    } else if (removedBeforeCount > 0) {
      int nextIndex = state.currentIndex - removedBeforeCount;
      if (nextIndex < 0) nextIndex = 0;
      state = state.copyWith(
        sessionQueue: updatedQueue,
        currentIndex: nextIndex,
      );
    } else {
      state = state.copyWith(sessionQueue: updatedQueue);
    }
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
