import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';

/// Function type for persisting card updates
typedef UpdateCardCallback = Future<void> Function(CardModel card);

/// Provider for managing card review session state
class ReviewSessionProvider extends ChangeNotifier {
  final UpdateCardCallback _updateCard;
  
  // Session state
  List<CardModel> _sessionCards = [];
  int _currentIndex = 0;
  bool _showingBack = false;
  DateTime? _sessionStartTime;
  int _cardsReviewed = 0;
  int _correctAnswers = 0;
  bool _isSessionActive = false;

  ReviewSessionProvider({required UpdateCardCallback updateCard})
      : _updateCard = updateCard;

  // Getters
  List<CardModel> get sessionCards => _sessionCards;
  int get currentIndex => _currentIndex;
  bool get showingBack => _showingBack;
  DateTime? get sessionStartTime => _sessionStartTime;
  int get cardsReviewed => _cardsReviewed;
  int get correctAnswers => _correctAnswers;
  bool get isSessionActive => _isSessionActive;
  
  CardModel? get currentCard => _sessionCards.isNotEmpty && 
      _currentIndex < _sessionCards.length
      ? _sessionCards[_currentIndex]
      : null;
      
  double get progress => _sessionCards.isEmpty 
      ? 0.0 
      : (_currentIndex + 1) / _sessionCards.length;
      
  double get accuracy => _cardsReviewed == 0 
      ? 0.0 
      : _correctAnswers / _cardsReviewed;
      
  bool get hasNextCard => _currentIndex < _sessionCards.length - 1;
  bool get hasPreviousCard => _currentIndex > 0;
  bool get isSessionComplete => _currentIndex >= _sessionCards.length;

  /// Start a new review session with the given cards
  void startSession(List<CardModel> cards) {
    _sessionCards = List.from(cards);
    _currentIndex = 0;
    _showingBack = false;
    _sessionStartTime = DateTime.now();
    _cardsReviewed = 0;
    _correctAnswers = 0;
    _isSessionActive = true;
    notifyListeners();
  }

  /// End the current review session
  void endSession() {
    _sessionCards = [];
    _currentIndex = 0;
    _showingBack = false;
    _sessionStartTime = null;
    _cardsReviewed = 0;
    _correctAnswers = 0;
    _isSessionActive = false;
    notifyListeners();
  }

  /// Flip the current card to show the back
  void flipCard() {
    if (currentCard != null && !_showingBack) {
      _showingBack = true;
      notifyListeners();
    }
  }

  /// Move to the next card in the session
  void nextCard() {
    if (hasNextCard) {
      _currentIndex++;
      _showingBack = false;
      notifyListeners();
    }
  }

  /// Move to the previous card in the session
  void previousCard() {
    if (hasPreviousCard) {
      _currentIndex--;
      _showingBack = false;
      notifyListeners();
    }
  }

  /// Process an answer for the current card and persist the update
  Future<void> answerCard(CardAnswer answer) async {
    if (currentCard != null) {
      // Update card with spaced repetition result
      final updatedCard = currentCard!.processAnswer(answer);
      await _updateCard(updatedCard);
      
      _cardsReviewed++;
      if (answer == CardAnswer.correct) {
        _correctAnswers++;
      }
      
      // Move to next card or end session
      if (hasNextCard) {
        nextCard();
      } else {
        _isSessionActive = false;
        notifyListeners();
      }
    }
  }

  /// Reset the current card to show front
  void resetCardView() {
    _showingBack = false;
    notifyListeners();
  }

  /// Get session duration
  Duration get sessionDuration {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  /// Get session statistics
  Map<String, dynamic> get sessionStats => {
    'totalCards': _sessionCards.length,
    'cardsReviewed': _cardsReviewed,
    'correctAnswers': _correctAnswers,
    'accuracy': accuracy,
    'duration': sessionDuration,
    'isComplete': isSessionComplete,
  };
}
