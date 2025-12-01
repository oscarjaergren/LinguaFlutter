import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../card_management/domain/providers/card_management_provider.dart';
import '../../../streak/domain/streak_provider.dart';
import '../../../mascot/domain/mascot_provider.dart';
import '../../domain/providers/review_session_provider.dart';

/// ViewModel for card review functionality, handling review session state and logic
class CardReviewViewModel extends ChangeNotifier {
  final CardManagementProvider _cardManagement;
  final ReviewSessionProvider _reviewSession;
  final StreakProvider _streakProvider;
  final MascotProvider _mascotProvider;

  // Review session state
  bool _showingBack = false;
  bool _sessionActive = false;
  DateTime? _sessionStartTime;
  int _sessionCardsReviewed = 0;
  int _sessionCorrectAnswers = 0;

  // Current card state
  CardModel? _currentCard;
  int _currentCardIndex = 0;

  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  bool _showConfetti = false;

  CardReviewViewModel({
    required CardManagementProvider cardManagement,
    required ReviewSessionProvider reviewSession,
    required StreakProvider streakProvider,
    required MascotProvider mascotProvider,
  })  : _cardManagement = cardManagement,
        _reviewSession = reviewSession,
        _streakProvider = streakProvider,
        _mascotProvider = mascotProvider {
    
    // Listen to provider changes
    _cardManagement.addListener(_onCardManagementChanged);
    _reviewSession.addListener(_onReviewSessionChanged);
    _streakProvider.addListener(_onStreakProviderChanged);
    _mascotProvider.addListener(_onMascotProviderChanged);
  }

  @override
  void dispose() {
    _cardManagement.removeListener(_onCardManagementChanged);
    _reviewSession.removeListener(_onReviewSessionChanged);
    _streakProvider.removeListener(_onStreakProviderChanged);
    _mascotProvider.removeListener(_onMascotProviderChanged);
    super.dispose();
  }

  // Getters for review state
  bool get showingBack => _showingBack;
  bool get sessionActive => _sessionActive;
  DateTime? get sessionStartTime => _sessionStartTime;
  int get sessionCardsReviewed => _sessionCardsReviewed;
  int get sessionCorrectAnswers => _sessionCorrectAnswers;
  double get sessionAccuracy => 
      _sessionCardsReviewed > 0 ? _sessionCorrectAnswers / _sessionCardsReviewed : 0.0;

  // Current card getters
  CardModel? get currentCard => _currentCard;
  int get currentCardIndex => _currentCardIndex;
  bool get hasCurrentCard => _currentCard != null;

  // Session progress getters
  List<CardModel> get reviewCards => _reviewSession.sessionCards;
  int get totalCardsInSession => reviewCards.length;
  int get remainingCards => totalCardsInSession - _currentCardIndex;
  double get progressPercentage => 
      totalCardsInSession > 0 ? (_currentCardIndex / totalCardsInSession) : 0.0;

  // UI state getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showConfetti => _showConfetti;

  // Streak and mascot getters
  int get currentStreak => _streakProvider.currentStreak;
  bool get streakActive => _streakProvider.isStreakActive;
  String get mascotMessage => _mascotProvider.currentMessage ?? '';
  bool get mascotVisible => _mascotProvider.isVisible;

  // Session management
  Future<bool> startReviewSession({List<CardModel>? specificCards}) async {
    if (_sessionActive) {
      return false;
    }

    _setLoading(true);
    
    try {
      List<CardModel> cardsToReview;
      
      if (specificCards != null && specificCards.isNotEmpty) {
        cardsToReview = specificCards;
      } else {
        cardsToReview = _cardManagement.reviewCards;
      }

      if (cardsToReview.isEmpty) {
        _setError('No cards available for review');
        _setLoading(false);
        return false;
      }

      // Initialize session
      _reviewSession.startSession(cardsToReview);
      
      _sessionActive = true;
      _sessionStartTime = DateTime.now();
      _sessionCardsReviewed = 0;
      _sessionCorrectAnswers = 0;
      _currentCardIndex = 0;
      _showingBack = false;
      
      // Set current card
      _currentCard = cardsToReview.isNotEmpty ? cardsToReview[0] : null;
      
      // Initialize mascot for session
      _mascotProvider.reactToAction(MascotAction.sessionCompleted);
      
      _setLoading(false);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to start review session: ${e.toString()}');
      return false;
    }
  }

  void flipCard() {
    if (!_sessionActive || _currentCard == null) return;
    
    _showingBack = !_showingBack;
    
    if (_showingBack) {
      // Card flipped to back - trigger mascot encouragement
      _mascotProvider.reactToAction(MascotAction.cardCompleted);
    }
    
    notifyListeners();
  }

  Future<void> markCardCorrect() async {
    if (!_sessionActive || _currentCard == null || !_showingBack) return;

    await _processCardAnswer(true);
  }

  Future<void> markCardIncorrect() async {
    if (!_sessionActive || _currentCard == null || !_showingBack) return;

    await _processCardAnswer(false);
  }

  Future<void> _processCardAnswer(bool isCorrect) async {
    if (_currentCard == null) return;

    _setLoading(true);

    try {
      // Update card statistics - use existing method
      await _reviewSession.answerCard(isCorrect ? CardAnswer.correct : CardAnswer.incorrect);
      
      // Update session statistics
      _sessionCardsReviewed++;
      if (isCorrect) {
        _sessionCorrectAnswers++;
      }

      // Update streak with review session
      await _streakProvider.updateStreakWithReview(cardsReviewed: 1);

      // Trigger mascot response
      if (isCorrect) {
        _mascotProvider.reactToAction(MascotAction.cardCompleted);
      } else {
        _mascotProvider.reactToAction(MascotAction.struggling);
      }

      // Move to next card or end session
      await _moveToNextCard();
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to process answer: ${e.toString()}');
    }
  }

  Future<void> _moveToNextCard() async {
    _currentCardIndex++;
    _showingBack = false;

    if (_currentCardIndex >= reviewCards.length) {
      // Session completed
      await _endReviewSession();
    } else {
      // Move to next card
      _currentCard = reviewCards[_currentCardIndex];
      notifyListeners();
    }
  }

  Future<void> _endReviewSession() async {
    _sessionActive = false;
    _currentCard = null;

    // Show confetti for good performance
    if (_sessionCorrectAnswers / _sessionCardsReviewed >= 0.8) {
      _showConfetti = true;
    }

    // Update mascot for session end
    _mascotProvider.reactToAction(MascotAction.sessionCompleted);

    // End the provider's review session
    _reviewSession.endSession();
    
    notifyListeners();
  }

  void skipCard() {
    if (!_sessionActive || _currentCard == null) return;
    
    // Move to next card without recording an answer
    _moveToNextCard();
  }

  void exitReviewSession() {
    if (!_sessionActive) return;
    
    _sessionActive = false;
    _currentCard = null;
    _showingBack = false;
    
    // End the provider's review session
    _reviewSession.endSession();
    
    // Reset mascot
    _mascotProvider.resetSession();
    
    notifyListeners();
  }

  void hideConfetti() {
    _showConfetti = false;
    notifyListeners();
  }

  // Statistics and progress
  String getProgressText() {
    if (!_sessionActive) return '';
    return '${_currentCardIndex + 1} of $totalCardsInSession';
  }

  String getSessionStatsText() {
    if (_sessionCardsReviewed == 0) return 'No cards reviewed yet';
    
    final accuracy = (sessionAccuracy * 100).round();
    return '$_sessionCorrectAnswers/$_sessionCardsReviewed correct ($accuracy%)';
  }

  Duration getSessionDuration() {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  String getSessionDurationText() {
    final duration = getSessionDuration();
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _onCardManagementChanged() {
    notifyListeners();
  }

  void _onReviewSessionChanged() {
    // Update current card if it changed in the provider
    if (_sessionActive && _currentCardIndex < reviewCards.length) {
      _currentCard = reviewCards[_currentCardIndex];
    }
    notifyListeners();
  }

  void _onStreakProviderChanged() {
    notifyListeners();
  }

  void _onMascotProviderChanged() {
    notifyListeners();
  }
}
