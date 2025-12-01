import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../../card_management/domain/providers/card_management_provider.dart';

/// Model representing a card with a specific exercise type to practice
class ExerciseItem {
  final CardModel card;
  final ExerciseType exerciseType;
  
  const ExerciseItem({
    required this.card,
    required this.exerciseType,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseItem &&
          runtimeType == other.runtimeType &&
          card.id == other.card.id &&
          exerciseType == other.exerciseType;
  
  @override
  int get hashCode => card.id.hashCode ^ exerciseType.hashCode;
}

/// Provider for managing exercise practice sessions
class ExerciseSessionProvider extends ChangeNotifier {
  final CardManagementProvider cardManagement;
  
  // Session state
  List<ExerciseItem> _sessionQueue = [];
  int _currentIndex = 0;
  bool _isSessionActive = false;
  DateTime? _sessionStartTime;
  int _correctCount = 0;
  int _incorrectCount = 0;
  
  // Current exercise state
  bool _isAnswerShown = false;
  List<String>? _multipleChoiceOptions;
  
  ExerciseSessionProvider({required this.cardManagement});
  
  // Getters
  List<ExerciseItem> get sessionQueue => _sessionQueue;
  int get currentIndex => _currentIndex;
  bool get isSessionActive => _isSessionActive;
  DateTime? get sessionStartTime => _sessionStartTime;
  int get correctCount => _correctCount;
  int get incorrectCount => _incorrectCount;
  bool get isAnswerShown => _isAnswerShown;
  List<String>? get multipleChoiceOptions => _multipleChoiceOptions;
  
  ExerciseItem? get currentExercise => 
      _isSessionActive && _currentIndex < _sessionQueue.length
          ? _sessionQueue[_currentIndex]
          : null;
  
  CardModel? get currentCard => currentExercise?.card;
  ExerciseType? get currentExerciseType => currentExercise?.exerciseType;
  
  double get progress =>
      _sessionQueue.isEmpty ? 0.0 : (_currentIndex + 1) / _sessionQueue.length;
  
  int get remainingCount => 
      _sessionQueue.length - _currentIndex - 1;
  
  int get totalCount => _sessionQueue.length;
  
  double get sessionAccuracy =>
      (_correctCount + _incorrectCount) == 0
          ? 0.0
          : _correctCount / (_correctCount + _incorrectCount);
  
  /// Start a new exercise session with specified cards
  void startSession({List<CardModel>? cards}) {
    final cardsToUse = cards ?? cardManagement.reviewCards;
    
    // Build exercise queue
    _sessionQueue = _buildExerciseQueue(cardsToUse);
    _currentIndex = 0;
    _isSessionActive = _sessionQueue.isNotEmpty;
    _sessionStartTime = DateTime.now();
    _correctCount = 0;
    _incorrectCount = 0;
    _isAnswerShown = false;
    
    // Generate options for first exercise if needed
    _prepareCurrentExercise();
    
    notifyListeners();
  }
  
  /// Build a queue of exercises from cards
  List<ExerciseItem> _buildExerciseQueue(List<CardModel> cards) {
    final queue = <ExerciseItem>[];
    
    for (final card in cards) {
      // Get due exercise types for this card
      final dueTypes = card.dueExerciseTypes;
      
      if (dueTypes.isEmpty) {
        // If no specific exercise is due, include all implemented types
        for (final type in ExerciseType.values) {
          if (type.isImplemented && _canDoExercise(card, type)) {
            queue.add(ExerciseItem(card: card, exerciseType: type));
          }
        }
      } else {
        // Add only due exercises that can be performed
        for (final type in dueTypes) {
          if (_canDoExercise(card, type)) {
            queue.add(ExerciseItem(card: card, exerciseType: type));
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
    // Check if exercise requires an icon
    if (type.requiresIcon && card.icon == null) {
      return false;
    }
    
    return true;
  }
  
  /// Prepare the current exercise (generate options for multiple choice, etc.)
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
  }
  
  /// Generate multiple choice options for current card
  void _generateMultipleChoiceOptions() {
    if (currentCard == null) return;
    
    final correctAnswer = currentCard!.backText;
    final allCards = cardManagement.allCards
        .where((c) => c.id != currentCard!.id)
        .toList()
      ..shuffle();
    
    // Get 3 wrong answers
    final wrongAnswers = allCards
        .take(3)
        .map((c) => c.backText)
        .where((text) => text != correctAnswer)
        .toList();
    
    // Combine and shuffle
    final options = [correctAnswer, ...wrongAnswers]..shuffle();
    _multipleChoiceOptions = options;
  }
  
  /// Show the answer for current exercise
  void showAnswer() {
    _isAnswerShown = true;
    notifyListeners();
  }
  
  /// Submit an answer for the current exercise
  Future<void> submitAnswer({required bool isCorrect}) async {
    if (currentCard == null || currentExerciseType == null) return;
    
    // Update card with exercise result
    final updatedCard = currentCard!.copyWithExerciseResult(
      exerciseType: currentExerciseType!,
      wasCorrect: isCorrect,
    );
    
    // Save updated card
    await cardManagement.updateCard(updatedCard);
    
    // Update session stats
    if (isCorrect) {
      _correctCount++;
    } else {
      _incorrectCount++;
    }
    
    // Move to next exercise or end session
    if (_currentIndex < _sessionQueue.length - 1) {
      _currentIndex++;
      _isAnswerShown = false;
      _prepareCurrentExercise();
      notifyListeners();
    } else {
      endSession();
    }
  }
  
  /// End the current session
  void endSession() {
    _isSessionActive = false;
    _sessionQueue = [];
    _currentIndex = 0;
    _isAnswerShown = false;
    _multipleChoiceOptions = null;
    notifyListeners();
  }
  
  /// Skip current exercise
  void skipExercise() {
    if (_currentIndex < _sessionQueue.length - 1) {
      _currentIndex++;
      _isAnswerShown = false;
      _prepareCurrentExercise();
      notifyListeners();
    } else {
      endSession();
    }
  }
  
  /// Restart the session with same cards
  void restartSession() {
    if (_sessionQueue.isNotEmpty) {
      final cards = _sessionQueue.map((e) => e.card).toSet().toList();
      startSession(cards: cards);
    }
  }
}
