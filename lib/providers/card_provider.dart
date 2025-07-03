import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../services/card_storage_service.dart';
import 'streak_provider.dart';

/// Provider for managing card state and operations
class CardProvider extends ChangeNotifier {
  final CardStorageService _storageService = CardStorageService();
  StreakProvider? _streakProvider;
  
  // Card collections
  List<CardModel> _allCards = [];
  List<CardModel> _filteredCards = [];
  List<CardModel> _reviewCards = [];
  
  // Current review session state
  List<CardModel> _currentReviewSession = [];
  int _currentReviewIndex = 0;
  bool _isReviewMode = false;
  bool _showingBack = false;
  
  // Session tracking
  int _sessionCardsReviewed = 0;
  DateTime? _sessionStartTime;
  
  // Filters and search
  String _searchQuery = '';
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  bool _showOnlyDue = false;
  bool _showOnlyFavorites = false;
  
  // Statistics
  Map<String, int> _stats = {};
  
  // Loading states
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<CardModel> get allCards => _allCards;
  List<CardModel> get filteredCards => _filteredCards;
  List<CardModel> get reviewCards => _reviewCards;
  List<CardModel> get currentReviewSession => _currentReviewSession;
  int get currentReviewIndex => _currentReviewIndex;
  bool get isReviewMode => _isReviewMode;
  bool get showingBack => _showingBack;
  int get sessionCardsReviewed => _sessionCardsReviewed;
  DateTime? get sessionStartTime => _sessionStartTime;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get selectedTags => _selectedTags;
  bool get showOnlyDue => _showOnlyDue;
  bool get showOnlyFavorites => _showOnlyFavorites;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Current card in review
  CardModel? get currentCard {
    if (!_isReviewMode || _currentReviewSession.isEmpty || _currentReviewIndex >= _currentReviewSession.length) {
      return null;
    }
    return _currentReviewSession[_currentReviewIndex];
  }
  
  // Progress in current review session
  double get reviewProgress {
    if (_currentReviewSession.isEmpty) return 0.0;
    return (_currentReviewIndex + 1) / _currentReviewSession.length;
  }
  
  // Available categories
  List<String> get categories {
    final categories = _allCards.map((card) => card.category).toSet().toList();
    categories.sort();
    return categories;
  }
  
  // Available tags
  List<String> get availableTags {
    final tags = <String>{};
    for (final card in _allCards) {
      tags.addAll(card.tags);
    }
    final tagList = tags.toList();
    tagList.sort();
    return tagList;
  }

  /// Initialize the provider by loading cards from storage
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _allCards = await _storageService.loadCards();
      _applyFilters();
      _updateStats();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load cards: $e';
      debugPrint('Card loading error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new card
  Future<void> addCard(CardModel card) async {
    try {
      await _storageService.saveCard(card);
      _allCards.add(card);
      _applyFilters();
      _updateStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add card: $e';
      debugPrint('Card adding error: $e');
      notifyListeners();
    }
  }

  /// Update an existing card
  Future<void> updateCard(CardModel card) async {
    try {
      await _storageService.saveCard(card);
      final index = _allCards.indexWhere((c) => c.id == card.id);
      if (index >= 0) {
        _allCards[index] = card;
        _applyFilters();
        _updateStats();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update card: $e';
      debugPrint('Card updating error: $e');
      notifyListeners();
    }
  }

  /// Delete a card
  Future<void> deleteCard(String cardId) async {
    try {
      await _storageService.deleteCard(cardId);
      _allCards.removeWhere((card) => card.id == cardId);
      _applyFilters();
      _updateStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete card: $e';
      debugPrint('Card deletion error: $e');
      notifyListeners();
    }
  }

  /// Toggle favorite status of a card
  Future<void> toggleFavorite(String cardId) async {
    final card = _allCards.firstWhere((c) => c.id == cardId);
    final updatedCard = card.copyWith(
      isFavorite: !card.isFavorite,
      updatedAt: DateTime.now(),
    );
    await updateCard(updatedCard);
  }

  /// Archive or unarchive a card
  Future<void> toggleArchive(String cardId) async {
    final card = _allCards.firstWhere((c) => c.id == cardId);
    final updatedCard = card.copyWith(
      isArchived: !card.isArchived,
      updatedAt: DateTime.now(),
    );
    await updateCard(updatedCard);
  }

  /// Start a review session with filtered cards
  void startReviewSession({List<CardModel>? cards}) {
    _currentReviewSession = cards ?? _reviewCards;
    _currentReviewIndex = 0;
    _isReviewMode = true;
    _showingBack = false;
    _sessionCardsReviewed = 0;
    _sessionStartTime = DateTime.now();
    notifyListeners();
  }

  /// End the current review session
  Future<void> endReviewSession() async {
    // Update streak if cards were reviewed
    if (_sessionCardsReviewed > 0 && _streakProvider != null) {
      await _streakProvider!.updateStreakWithReview(
        cardsReviewed: _sessionCardsReviewed,
      );
    }
    
    _currentReviewSession = [];
    _currentReviewIndex = 0;
    _isReviewMode = false;
    _showingBack = false;
    _sessionCardsReviewed = 0;
    _sessionStartTime = null;
    notifyListeners();
  }

  /// Flip the current card to show back
  void flipCard() {
    _showingBack = !_showingBack;
    notifyListeners();
  }

  /// Answer the current card and move to next
  Future<void> answerCard(bool wasCorrect) async {
    if (currentCard == null) return;
    
    // Calculate next review date based on spaced repetition algorithm
    final nextReviewDate = _calculateNextReviewDate(currentCard!, wasCorrect);
    
    // Update card with review data
    final updatedCard = currentCard!.copyWithReview(
      wasCorrect: wasCorrect,
      nextReviewDate: nextReviewDate,
    );
    
    await updateCard(updatedCard);
    
    // Increment session cards reviewed
    _sessionCardsReviewed++;
    
    // Move to next card
    if (_currentReviewIndex < _currentReviewSession.length - 1) {
      _currentReviewIndex++;
      _showingBack = false;
      notifyListeners();
    } else {
      // End review session
      await endReviewSession();
    }
  }

  /// Search and filter cards
  void searchCards(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Filter by tags
  void filterByTags(List<String> tags) {
    _selectedTags = tags;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle show only due cards
  void toggleShowOnlyDue() {
    _showOnlyDue = !_showOnlyDue;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle show only favorites
  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedTags = [];
    _showOnlyDue = false;
    _showOnlyFavorites = false;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all cards
  Future<void> clearAllCards() async {
    try {
      await _storageService.clearAllCards();
      _allCards.clear();
      _applyFilters();
      _updateStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear all cards: $e';
      debugPrint('Clear all cards error: $e');
      notifyListeners();
    }
  }

  /// Apply current filters to cards
  void _applyFilters() {
    _filteredCards = _allCards.where((card) {
      // Skip archived cards unless specifically searching for them
      if (card.isArchived && !_searchQuery.contains('archived')) {
        return false;
      }
      
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!card.frontText.toLowerCase().contains(query) &&
            !card.backText.toLowerCase().contains(query) &&
            !card.category.toLowerCase().contains(query) &&
            !card.tags.any((tag) => tag.toLowerCase().contains(query))) {
          return false;
        }
      }
      
      // Category filter
      if (_selectedCategory.isNotEmpty && card.category != _selectedCategory) {
        return false;
      }
      
      // Tags filter
      if (_selectedTags.isNotEmpty) {
        if (!_selectedTags.any((tag) => card.tags.contains(tag))) {
          return false;
        }
      }
      
      // Due cards filter
      if (_showOnlyDue && !card.isDueForReview) {
        return false;
      }
      
      // Favorites filter
      if (_showOnlyFavorites && !card.isFavorite) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Update review cards (only cards that are due for review)
    _reviewCards = _filteredCards.where((card) => card.isDueForReview).toList();
  }

  /// Update statistics
  void _updateStats() {
    _stats = {
      'total': _allCards.length,
      'due': _allCards.where((card) => card.isDueForReview).length,
      'favorites': _allCards.where((card) => card.isFavorite).length,
      'archived': _allCards.where((card) => card.isArchived).length,
      'new': _allCards.where((card) => card.reviewCount == 0).length,
      'learning': _allCards.where((card) => card.masteryLevel == 'Learning').length,
      'mastered': _allCards.where((card) => card.masteryLevel == 'Mastered').length,
    };
  }

  /// Calculate next review date using spaced repetition algorithm
  DateTime _calculateNextReviewDate(CardModel card, bool wasCorrect) {
    const intervals = [1, 2, 4, 8, 16, 32]; // Days
    
    int currentInterval = 0;
    if (card.nextReview != null) {
      final daysSinceLastReview = DateTime.now().difference(card.lastReviewed ?? card.createdAt).inDays;
      currentInterval = intervals.indexWhere((interval) => interval >= daysSinceLastReview);
      if (currentInterval == -1) currentInterval = intervals.length - 1;
    }
    
    int nextInterval;
    if (wasCorrect) {
      // Move to next interval if correct
      nextInterval = (currentInterval + 1).clamp(0, intervals.length - 1);
    } else {
      // Reset to first interval if incorrect
      nextInterval = 0;
    }
    
    return DateTime.now().add(Duration(days: intervals[nextInterval]));
  }

  /// Set the streak provider for session tracking
  void setStreakProvider(StreakProvider streakProvider) {
    _streakProvider = streakProvider;
  }

  @override
  void dispose() {
    _storageService.dispose();
    super.dispose();
  }
}
