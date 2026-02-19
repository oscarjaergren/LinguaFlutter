import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../models/exercise_preferences.dart';

/// Function type for persisting card updates
typedef UpdateCardCallback = Future<void> Function(CardModel card);

/// Function type for getting cards
typedef GetCardsCallback = List<CardModel> Function();

/// Function type called when a session completes, with the total cards reviewed
typedef SessionCompleteCallback = Future<void> Function(int cardsReviewed);

/// Represents a single practice item: a card + exercise type combination
class PracticeItem {
  final CardModel card;
  final ExerciseType exerciseType;

  const PracticeItem({required this.card, required this.exerciseType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeItem &&
          runtimeType == other.runtimeType &&
          card.id == other.card.id &&
          exerciseType == other.exerciseType;

  @override
  int get hashCode => card.id.hashCode ^ exerciseType.hashCode;
}

/// State of the current exercise answer
enum AnswerState {
  /// User hasn't answered yet
  pending,

  /// User has submitted an answer, waiting for confirmation swipe
  answered,
}

/// Unified provider for practice sessions
/// Combines card review and exercise functionality with swipeable card UX
class PracticeSessionProvider extends ChangeNotifier {
  final GetCardsCallback _getReviewCards;
  final GetCardsCallback _getAllCards;
  final UpdateCardCallback _updateCard;

  // Session state
  List<PracticeItem> _sessionQueue = [];
  int _currentIndex = 0;
  bool _isSessionActive = false;
  bool _isSessionComplete = false;
  DateTime? _sessionStartTime;

  // Exercise filtering
  ExercisePreferences _exercisePreferences = ExercisePreferences.defaults();

  // Statistics
  int _correctCount = 0;
  int _incorrectCount = 0;

  // Current exercise state
  AnswerState _answerState = AnswerState.pending;
  bool? _currentAnswerCorrect;
  List<String>? _multipleChoiceOptions;
  String? _userInput;

  // Minimum cards required for multiple choice exercises
  static const int _minCardsForMultipleChoice = 4;

  final SessionCompleteCallback? _onSessionComplete;

  PracticeSessionProvider({
    required GetCardsCallback getReviewCards,
    required GetCardsCallback getAllCards,
    required UpdateCardCallback updateCard,
    SessionCompleteCallback? onSessionComplete,
  }) : _getReviewCards = getReviewCards,
       _getAllCards = getAllCards,
       _updateCard = updateCard,
       _onSessionComplete = onSessionComplete;

  // === Getters ===

  List<PracticeItem> get sessionQueue => _sessionQueue;
  int get currentIndex => _currentIndex;
  bool get isSessionActive => _isSessionActive;
  bool get isSessionComplete => _isSessionComplete;
  DateTime? get sessionStartTime => _sessionStartTime;
  int get correctCount => _correctCount;
  int get incorrectCount => _incorrectCount;
  AnswerState get answerState => _answerState;
  bool? get currentAnswerCorrect => _currentAnswerCorrect;
  List<String>? get multipleChoiceOptions => _multipleChoiceOptions;
  String? get userInput => _userInput;

  PracticeItem? get currentItem =>
      _isSessionActive && _currentIndex < _sessionQueue.length
      ? _sessionQueue[_currentIndex]
      : null;

  CardModel? get currentCard => currentItem?.card;
  ExerciseType? get currentExerciseType => currentItem?.exerciseType;

  double get progress {
    if (_isSessionComplete) return 1.0;
    if (_sessionQueue.isEmpty) return 0.0;
    return (_currentIndex + 1) / _sessionQueue.length;
  }

  int get remainingCount =>
      _sessionQueue.isEmpty ? 0 : _sessionQueue.length - _currentIndex - 1;

  int get totalCount => _sessionQueue.length;

  double get accuracy => (_correctCount + _incorrectCount) == 0
      ? 0.0
      : _correctCount / (_correctCount + _incorrectCount);

  bool get canSwipe => _answerState == AnswerState.answered;

  ExercisePreferences get exercisePreferences => _exercisePreferences;

  Duration get sessionDuration {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  // === Session Management ===

  /// Update exercise preferences and optionally rebuild the queue
  void updateExercisePreferences(
    ExercisePreferences preferences, {
    bool rebuildQueue = true,
  }) {
    _exercisePreferences = preferences;

    if (rebuildQueue && _isSessionActive) {
      // Rebuild the queue with new preferences, keeping current progress
      final remainingCards = _sessionQueue
          .skip(_currentIndex)
          .map((item) => item.card)
          .toSet()
          .toList();

      if (remainingCards.isNotEmpty) {
        final newQueue = _buildPracticeQueue(remainingCards);
        if (newQueue.isNotEmpty) {
          _sessionQueue = [..._sessionQueue.take(_currentIndex), ...newQueue];
        }
      }
    }

    notifyListeners();
  }

  /// Start a new practice session
  void startSession({
    List<CardModel>? cards,
    ExercisePreferences? preferences,
  }) {
    if (preferences != null) {
      _exercisePreferences = preferences;
    }

    final cardsToUse = cards ?? _getReviewCards();

    if (cardsToUse.isEmpty) {
      _isSessionActive = false;
      notifyListeners();
      return;
    }

    // Build exercise queue
    _sessionQueue = _buildPracticeQueue(cardsToUse);
    _currentIndex = 0;
    _isSessionActive = _sessionQueue.isNotEmpty;
    _isSessionComplete = false;
    _sessionStartTime = DateTime.now();
    _correctCount = 0;
    _incorrectCount = 0;
    _answerState = AnswerState.pending;
    _currentAnswerCorrect = null;
    _userInput = null;

    // Prepare first exercise
    _prepareCurrentExercise();

    notifyListeners();
  }

  /// Build a queue of practice items from cards
  List<PracticeItem> _buildPracticeQueue(List<CardModel> cards) {
    final queue = <PracticeItem>[];
    final allCards = _getAllCards();
    final hasEnoughCardsForMultipleChoice =
        allCards.length >= _minCardsForMultipleChoice;

    for (final card in cards) {
      // Get due exercise types for this card, filtered by preferences
      final dueTypes = card.dueExerciseTypes
          .where((t) => _exercisePreferences.isEnabled(t))
          .where(
            (t) => _canDoExercise(card, t, hasEnoughCardsForMultipleChoice),
          )
          .toList();

      if (dueTypes.isEmpty) {
        // If no specific exercise is due, pick from enabled types
        final availableTypes = ExerciseType.values
            .where((t) => t.isImplemented)
            .where((t) => _exercisePreferences.isEnabled(t))
            .where(
              (t) => _canDoExercise(card, t, hasEnoughCardsForMultipleChoice),
            )
            .toList();

        if (availableTypes.isNotEmpty) {
          // If prioritizing weaknesses, sort by weakness
          if (_exercisePreferences.prioritizeWeaknesses) {
            availableTypes.sort((a, b) => _compareByWeakness(card, a, b));
            // Take the weakest exercise type
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
        // Add only due exercises that can be performed
        if (_exercisePreferences.prioritizeWeaknesses) {
          // Sort due types by weakness and add the weakest
          dueTypes.sort((a, b) => _compareByWeakness(card, a, b));
          queue.add(PracticeItem(card: card, exerciseType: dueTypes.first));
        } else {
          // Add all due exercises
          for (final type in dueTypes) {
            queue.add(PracticeItem(card: card, exerciseType: type));
          }
        }
      }
    }

    // Shuffle for variety, but if prioritizing weaknesses, sort globally by weakness
    if (_exercisePreferences.prioritizeWeaknesses) {
      queue.sort(
        (a, b) => _compareByWeakness(a.card, a.exerciseType, b.exerciseType),
      );
    } else {
      queue.shuffle();
    }

    return queue;
  }

  /// Compare two exercise types by weakness (lower success rate = weaker = should come first)
  int _compareByWeakness(CardModel card, ExerciseType a, ExerciseType b) {
    final scoreA = card.getExerciseScore(a);
    final scoreB = card.getExerciseScore(b);

    // New exercises (no attempts) should be prioritized
    final rateA = scoreA?.totalAttempts == 0
        ? -1.0
        : (scoreA?.successRate ?? 0.0);
    final rateB = scoreB?.totalAttempts == 0
        ? -1.0
        : (scoreB?.successRate ?? 0.0);

    // Lower success rate = weaker = comes first
    return rateA.compareTo(rateB);
  }

  /// Check if an exercise can be performed on a card.
  ///
  /// Delegates entirely to [ExerciseType.canUse] — each exercise type owns
  /// its own card requirements.
  bool _canDoExercise(
    CardModel card,
    ExerciseType type,
    bool hasEnoughCardsForMultipleChoice,
  ) {
    return type.canUse(
      card,
      hasEnoughCardsForMultipleChoice: hasEnoughCardsForMultipleChoice,
    );
  }

  /// Prepare the current exercise (generate options, etc.)
  void _prepareCurrentExercise() {
    if (currentExerciseType == null) return;

    final type = currentExerciseType!;

    // Generate multiple choice options if needed
    if (type == ExerciseType.multipleChoiceText ||
        type == ExerciseType.multipleChoiceIcon) {
      _generateMultipleChoiceOptions();
    } else {
      _multipleChoiceOptions = null;
    }

    _userInput = null;
  }

  /// Generate multiple choice options for current card
  void _generateMultipleChoiceOptions() {
    if (currentCard == null) return;

    final correctAnswer = currentCard!.backText;
    final allCards =
        _getAllCards()
            .where(
              (c) => c.id != currentCard!.id && c.backText != correctAnswer,
            )
            .toList()
          ..shuffle();

    // Get 3 wrong answers
    final wrongAnswers = allCards.take(3).map((c) => c.backText).toList();

    // Combine and shuffle
    final options = [correctAnswer, ...wrongAnswers]..shuffle();
    _multipleChoiceOptions = options;
  }

  /// Update a card in the session queue when it's edited externally
  void updateCardInQueue(CardModel updatedCard) {
    if (!_isSessionActive) return;

    // Update all practice items for this card
    for (int i = 0; i < _sessionQueue.length; i++) {
      if (_sessionQueue[i].card.id == updatedCard.id) {
        _sessionQueue[i] = PracticeItem(
          card: updatedCard,
          exerciseType: _sessionQueue[i].exerciseType,
        );
      }
    }

    // If current card was updated, regenerate options if needed
    if (currentCard?.id == updatedCard.id) {
      _prepareCurrentExercise();
    }

    notifyListeners();
  }

  /// Remove a deleted card from the queue and skip if it's the current card
  Future<void> removeCardFromQueue(String cardId) async {
    if (!_isSessionActive) return;

    final currentCardId = currentCard?.id;
    final wasCurrentCard = currentCardId == cardId;

    // Count how many entries for this card appear strictly before the current
    // index — needed to correctly adjust the index after removal (Bug 1+2).
    final removedBeforeCount = _sessionQueue
        .take(_currentIndex)
        .where((item) => item.card.id == cardId)
        .length;

    // Remove all practice items for this card
    _sessionQueue.removeWhere((item) => item.card.id == cardId);

    // If we removed the current card, adjust index and prepare next exercise
    if (wasCurrentCard) {
      // The current card may have appeared multiple times before the current
      // index (Bug 1). Subtract those entries first, then clamp.
      _currentIndex -= removedBeforeCount;
      if (_currentIndex < 0) _currentIndex = 0;

      // Clamp index to valid range after removal
      if (_currentIndex >= _sessionQueue.length) {
        _currentIndex = _sessionQueue.isEmpty ? 0 : _sessionQueue.length - 1;
      }

      // Reset answer state for new card
      _answerState = AnswerState.pending;
      _currentAnswerCorrect = null;
      _userInput = null;

      // Count the deleted card as incorrect so totalReviewed is consistent
      // with skipExercise (Bug 3).
      _incorrectCount++;

      // Check if session is now complete
      if (_sessionQueue.isEmpty) {
        _isSessionComplete = true;
        final totalReviewed = _correctCount + _incorrectCount;
        try {
          await _onSessionComplete?.call(totalReviewed);
        } catch (e) {
          debugPrint('onSessionComplete error: $e');
        } finally {
          endSession(); // endSession calls notifyListeners(); return to avoid double-notify
        }
        return;
      } else {
        _prepareCurrentExercise();
      }
    } else if (removedBeforeCount > 0) {
      // One or more entries for this card were before the current index.
      // Shift the index back by that exact count so the same card stays current.
      _currentIndex -= removedBeforeCount;
      // Clamp defensively.
      if (_currentIndex < 0) _currentIndex = 0;
    }
    // If removedBeforeCount == 0 the removed card was after the current index;
    // no index adjustment is needed.

    notifyListeners();
  }

  /// End the current session
  void endSession() {
    _isSessionActive = false;
    _isSessionComplete = false;
    _sessionQueue = [];
    _currentIndex = 0;
    _answerState = AnswerState.pending;
    _currentAnswerCorrect = null;
    _multipleChoiceOptions = null;
    _userInput = null;
    notifyListeners();
  }

  /// Restart the session with same cards
  void restartSession() {
    if (_sessionQueue.isNotEmpty) {
      final cards = _sessionQueue.map((e) => e.card).toSet().toList();
      startSession(cards: cards);
    } else {
      startSession();
    }
  }

  // === Answer Handling ===

  /// Update user input (for writing exercises)
  void updateUserInput(String input) {
    _userInput = input;
    notifyListeners();
  }

  /// Check the answer and transition to answered state
  /// The user can then swipe to confirm and move to next card
  void checkAnswer({required bool isCorrect}) {
    _answerState = AnswerState.answered;
    _currentAnswerCorrect = isCorrect;
    notifyListeners();
  }

  /// Override the auto-validated answer (user can mark correct/incorrect)
  void overrideAnswer({required bool isCorrect}) {
    _currentAnswerCorrect = isCorrect;
    notifyListeners();
  }

  /// Confirm the answer via swipe and move to next card
  /// Called when user swipes right (correct) or left (incorrect)
  Future<void> confirmAnswerAndAdvance({required bool markedCorrect}) async {
    if (currentCard == null || currentExerciseType == null) return;

    // Update card with exercise result
    final updatedCard = currentCard!.copyWithExerciseResult(
      exerciseType: currentExerciseType!,
      wasCorrect: markedCorrect,
    );

    // Save updated card
    await _updateCard(updatedCard);

    // Update the card reference in the session queue so UI shows updated scores
    _sessionQueue[_currentIndex] = PracticeItem(
      card: updatedCard,
      exerciseType: currentExerciseType!,
    );

    // Update session stats
    if (markedCorrect) {
      _correctCount++;
    } else {
      _incorrectCount++;
    }

    // Move to next exercise or end session
    if (_currentIndex < _sessionQueue.length - 1) {
      _currentIndex++;
      _answerState = AnswerState.pending;
      _currentAnswerCorrect = null;
      _userInput = null;
      _prepareCurrentExercise();
      notifyListeners();
    } else {
      _isSessionComplete = true;
      final totalReviewed = _correctCount + _incorrectCount;
      try {
        await _onSessionComplete?.call(totalReviewed);
      } catch (e) {
        debugPrint('onSessionComplete error: $e');
      } finally {
        endSession();
      }
    }
  }

  /// Skip current exercise without answering
  Future<void> skipExercise() async {
    if (!_isSessionActive) return;
    // Do not skip if the user has already submitted an answer — they must
    // confirm via confirmAnswerAndAdvance to avoid double-counting (Bug 3).
    if (_answerState == AnswerState.answered) return;

    // Persist the skipped card as incorrect so spaced-repetition state is updated.
    // Only count as incorrect (Bug 2) when there is actually a card to persist.
    if (currentCard != null && currentExerciseType != null) {
      final updatedCard = currentCard!.copyWithExerciseResult(
        exerciseType: currentExerciseType!,
        wasCorrect: false,
      );
      await _updateCard(updatedCard);
      _sessionQueue[_currentIndex] = PracticeItem(
        card: updatedCard,
        exerciseType: currentExerciseType!,
      );
      // Count the skipped card as incorrect so it's included in totalReviewed
      _incorrectCount++;
    }

    if (_currentIndex < _sessionQueue.length - 1) {
      _currentIndex++;
      _answerState = AnswerState.pending;
      _currentAnswerCorrect = null;
      _userInput = null;
      _prepareCurrentExercise();
      notifyListeners();
    } else {
      _isSessionComplete = true;
      final totalReviewed = _correctCount + _incorrectCount;
      try {
        await _onSessionComplete?.call(totalReviewed);
      } catch (e) {
        debugPrint('onSessionComplete error: $e');
      } finally {
        endSession();
      }
    }
  }

  // === Session Statistics ===

  Map<String, dynamic> get sessionStats => {
    'totalCards': _sessionQueue.length,
    'completed': _correctCount + _incorrectCount,
    'correctCount': _correctCount,
    'incorrectCount': _incorrectCount,
    'accuracy': accuracy,
    'duration': sessionDuration,
  };
}
