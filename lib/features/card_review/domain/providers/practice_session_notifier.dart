import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/card_model_extensions.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../../card_management/domain/providers/card_management_notifier.dart';
import '../../../language/domain/language_notifier.dart';
import 'practice_session_state.dart';
import 'practice_session_types.dart';
import 'exercise_preferences_notifier.dart';
import 'card_filter_utils.dart';

final practiceSessionNotifierProvider =
    NotifierProvider<PracticeSessionNotifier, PracticeSessionState>(
      () => PracticeSessionNotifier(),
    );

class PracticeSessionNotifier extends Notifier<PracticeSessionState> {
  @override
  PracticeSessionState build() {
    // Keep this notifier state stable across dependency updates.
    // Dependencies are read on demand in methods to avoid resetting sessions.
    return const PracticeSessionState();
  }

  // === Getters (Proxied from state) ===

  PracticeItem? get currentItem => state.currentItem;

  CardModel? get currentCard => currentItem?.card;
  ExerciseType? get currentExerciseType => currentItem?.exerciseType;

  bool get canSwipe => state.answerState == AnswerState.answered;

  bool get hasCurrentItem => currentItem != null && !state.noDueItems;

  // === Continuous Practice Flow Management ===

  /// Starts practice by loading the next item.
  ///
  /// When [cards] is provided (primarily in tests), selects the next item
  /// from that explicit list instead of reading from CardManagementState.
  Future<void> startSession({List<CardModel>? cards}) async {
    if (cards != null) {
      _loadNextItemFromCards(cards);
    } else {
      await loadNextItem();
    }
  }

  /// Load the next due practice item from the global card state.
  ///
  /// If no due items are available, sets [noDueItems] and clears [currentItem].
  Future<void> loadNextItem() async {
    final managementState = ref.read(cardManagementNotifierProvider);
    final activeLanguage = ref.read(languageNotifierProvider).activeLanguage;
    final prefs = ref.read(exercisePreferencesNotifierProvider).preferences;

    // Use shared filtering logic
    final reviewCards = managementState.allCards.filterForPractice(
      prefs,
      activeLanguage,
    );

    _selectAndSetNextItem(reviewCards);
  }

  /// Internal helper used by tests to select the next item from an explicit
  /// list of cards rather than the global card management state.
  void _loadNextItemFromCards(List<CardModel> cards) {
    final prefs = ref.read(exercisePreferencesNotifierProvider).preferences;
    final reviewCards = cards
        .where((c) => c.isDueForAnyExercise(prefs) && !c.isArchived)
        .toList();

    _selectAndSetNextItem(reviewCards);
  }

  /// Build candidate practice items from cards and select the next one,
  /// updating state accordingly.
  void _selectAndSetNextItem(List<CardModel> cards) {
    if (cards.isEmpty) {
      _resetToEmptyState();
      return;
    }

    final items = _buildPracticeItems(cards);
    if (items.isEmpty) {
      _resetToEmptyState();
      return;
    }

    // Set session start time only if this is the first item of the session
    final startTime = state.sessionStartTime ?? DateTime.now();

    final nextItem = items.first;

    state = state.copyWith(
      currentItem: nextItem,
      noDueItems: false,
      answerState: AnswerState.pending,
      currentAnswerCorrect: null,
      userInput: null,
      sessionStartTime: startTime,
    );

    _prepareCurrentExercise();
  }

  /// Resets state to empty when no cards are available
  void _resetToEmptyState() {
    state = state.copyWith(
      currentItem: null,
      noDueItems: true,
      answerState: AnswerState.pending,
      currentAnswerCorrect: null,
      multipleChoiceOptions: null,
      userInput: null,
    );
  }

  List<PracticeItem> _buildPracticeItems(List<CardModel> cards) {
    final items = <PracticeItem>[];
    final prefs = ref.read(exercisePreferencesNotifierProvider).preferences;
    final allCards = ref.read(cardManagementNotifierProvider).allCards;
    final hasEnoughCardsForMultipleChoice = allCards
        .hasEnoughForMultipleChoice();

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

      if (dueTypes.isNotEmpty) {
        final bestExercise = prefs.prioritizeWeaknesses
            ? (dueTypes..sort((a, b) => _compareByWeakness(card, a, b))).first
            : dueTypes.first;

        items.add(PracticeItem(card: card, exerciseType: bestExercise));
      }
      // If no due exercises, skip this card entirely
    }

    // Sort by weakness if enabled, otherwise shuffle
    if (prefs.prioritizeWeaknesses) {
      items.sort(
        (a, b) => _compareByWeakness(a.card, a.exerciseType, b.exerciseType),
      );
    } else {
      items.shuffle();
    }

    return items;
  }

  int _compareByWeakness(CardModel card, ExerciseType a, ExerciseType b) {
    final scoreA = card.getExerciseScore(a);
    final scoreB = card.getExerciseScore(b);

    // Handle new cards (no attempts) - give them neutral priority
    if (scoreA?.totalAttempts == 0 && scoreB?.totalAttempts == 0) return 0;
    if (scoreA?.totalAttempts == 0) return 1; // New cards after practiced ones
    if (scoreB?.totalAttempts == 0) return -1;

    // Compare success rates for practiced cards
    final rateA = scoreA?.successRate ?? 0.0;
    final rateB = scoreB?.successRate ?? 0.0;
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

    // Only update userInput if it's not already null to avoid unnecessary rebuilds
    if (state.userInput != null) {
      state = state.copyWith(userInput: null);
    }
  }

  void _generateMultipleChoiceOptions() {
    final card = currentCard;
    if (card == null || card.backText.isEmpty) {
      state = state.copyWith(multipleChoiceOptions: null);
      return;
    }

    final allCards = ref.read(cardManagementNotifierProvider).allCards;
    final wrongAnswerCards = card.filterWrongAnswerCards(allCards);

    // Validate we have enough cards for multiple choice
    if (wrongAnswerCards.length < 3) {
      LoggerService.warning(
        'Not enough cards for multiple choice options (need at least 3 wrong answers, found ${wrongAnswerCards.length})',
      );
      state = state.copyWith(multipleChoiceOptions: null);
      return;
    }

    final correctAnswer = card.backText;
    wrongAnswerCards.shuffle();
    final wrongAnswers = wrongAnswerCards
        .take(3)
        .map((c) => c.backText)
        .toList();
    final options = [correctAnswer, ...wrongAnswers]..shuffle();
    state = state.copyWith(multipleChoiceOptions: options);
  }

  /// Update a card in the session queue when it's edited externally
  void updateCardInQueue(CardModel updatedCard) {
    final item = currentItem;
    if (item == null) return;

    if (item.card.id == updatedCard.id) {
      state = state.copyWith(
        currentItem: PracticeItem(
          card: updatedCard,
          exerciseType: item.exerciseType,
        ),
      );
      _prepareCurrentExercise();
    }
  }

  /// Remove a deleted card from the queue and skip if it's the current card
  Future<void> removeCardFromQueue(String cardId) async {
    final item = currentItem;
    if (item == null) return;

    if (item.card.id == cardId) {
      // Clear current item and immediately move to the next one.
      state = state.copyWith(
        currentItem: null,
        answerState: AnswerState.pending,
        currentAnswerCorrect: null,
        multipleChoiceOptions: null,
        userInput: null,
      );
      await loadNextItem();
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

    // First, update the exercise-specific score.
    final cardWithExerciseResult = card.copyWithExerciseResult(
      exerciseType: type,
      wasCorrect: markedCorrect,
    );

    // Derive the card-level nextReview from the earliest exercise nextReview.
    final nextReviewFromExercises = cardWithExerciseResult.exerciseScores.values
        .map((score) => score.nextReview)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (earliest, candidate) =>
              earliest == null || candidate.isBefore(earliest)
              ? candidate
              : earliest,
        );

    // Then update the overall review counters and card.nextReview.
    final updatedCard = cardWithExerciseResult.copyWithReview(
      wasCorrect: markedCorrect,
      nextReviewDate: nextReviewFromExercises,
    );

    try {
      await ref
          .read(cardManagementNotifierProvider.notifier)
          .updateCard(updatedCard);

      // Update state immediately after successful card update, before loading next item
      state = state.copyWith(
        runCorrectCount: state.runCorrectCount + (markedCorrect ? 1 : 0),
        runIncorrectCount: state.runIncorrectCount + (markedCorrect ? 0 : 1),
        answerState: AnswerState.pending,
        currentAnswerCorrect: null,
        userInput: null,
      );

      // Only advance after state is updated
      await loadNextItem();
    } catch (e) {
      LoggerService.error('Failed to update card ${card.id}', e);
      // Don't advance if update failed - keep current state for retry
    }
  }
}
