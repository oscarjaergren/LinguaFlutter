import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/exercise_type.dart';

/// Function type for persisting card updates
typedef UpdateCardCallback = Future<void> Function(CardModel card);

/// Function type for getting cards
typedef GetCardsCallback = List<CardModel> Function();

/// Represents a single practice item: a card + exercise type combination
class PracticeItem {
  final CardModel card;
  final ExerciseType exerciseType;
  
  const PracticeItem({
    required this.card,
    required this.exerciseType,
  });
  
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
  DateTime? _sessionStartTime;
  
  // Statistics
  int _correctCount = 0;
  int _incorrectCount = 0;
  
  // Current exercise state
  AnswerState _answerState = AnswerState.pending;
  bool? _currentAnswerCorrect;
  List<String>? _multipleChoiceOptions;
  String? _userInput;
  
  PracticeSessionProvider({
    required GetCardsCallback getReviewCards,
    required GetCardsCallback getAllCards,
    required UpdateCardCallback updateCard,
  })  : _getReviewCards = getReviewCards,
        _getAllCards = getAllCards,
        _updateCard = updateCard;
  
  // === Getters ===
  
  List<PracticeItem> get sessionQueue => _sessionQueue;
  int get currentIndex => _currentIndex;
  bool get isSessionActive => _isSessionActive;
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
  
  double get progress =>
      _sessionQueue.isEmpty ? 0.0 : (_currentIndex + 1) / _sessionQueue.length;
  
  int get remainingCount => 
      _sessionQueue.isEmpty ? 0 : _sessionQueue.length - _currentIndex - 1;
  
  int get totalCount => _sessionQueue.length;
  
  double get accuracy =>
      (_correctCount + _incorrectCount) == 0
          ? 0.0
          : _correctCount / (_correctCount + _incorrectCount);
  
  bool get canSwipe => _answerState == AnswerState.answered;
  
  Duration get sessionDuration {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }
  
  // === Session Management ===
  
  /// Start a new practice session
  void startSession({List<CardModel>? cards}) {
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
    
    for (final card in cards) {
      // Get due exercise types for this card
      final dueTypes = card.dueExerciseTypes;
      
      if (dueTypes.isEmpty) {
        // If no specific exercise is due, pick one random implemented type
        final implementedTypes = ExerciseType.values
            .where((t) => t.isImplemented && _canDoExercise(card, t))
            .toList();
        
        if (implementedTypes.isNotEmpty) {
          implementedTypes.shuffle();
          queue.add(PracticeItem(card: card, exerciseType: implementedTypes.first));
        }
      } else {
        // Add only due exercises that can be performed
        for (final type in dueTypes) {
          if (_canDoExercise(card, type)) {
            queue.add(PracticeItem(card: card, exerciseType: type));
          }
        }
      }
    }
    
    // Shuffle for variety
    queue.shuffle();
    
    return queue;
  }
  
  /// Check if an exercise can be performed on a card
  bool _canDoExercise(CardModel card, ExerciseType type) {
    if (type.requiresIcon && card.icon == null) {
      return false;
    }
    return true;
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
    final allCards = _getAllCards()
        .where((c) => c.id != currentCard!.id && c.backText != correctAnswer)
        .toList()
      ..shuffle();
    
    // Get 3 wrong answers
    final wrongAnswers = allCards
        .take(3)
        .map((c) => c.backText)
        .toList();
    
    // Combine and shuffle
    final options = [correctAnswer, ...wrongAnswers]..shuffle();
    _multipleChoiceOptions = options;
  }
  
  /// End the current session
  void endSession() {
    _isSessionActive = false;
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
      endSession();
    }
  }
  
  /// Skip current exercise without answering
  void skipExercise() {
    if (_currentIndex < _sessionQueue.length - 1) {
      _currentIndex++;
      _answerState = AnswerState.pending;
      _currentAnswerCorrect = null;
      _userInput = null;
      _prepareCurrentExercise();
      notifyListeners();
    } else {
      endSession();
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
