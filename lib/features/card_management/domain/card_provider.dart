import 'package:flutter/foundation.dart';
import '../../../models/card_model.dart';
import '../../../shared/services/card_storage_service.dart';
import '../../streak/domain/streak_provider.dart';
import '../../language/domain/language_provider.dart';

/// Provider for managing card state and operations
class CardProvider extends ChangeNotifier {
  final CardStorageService _storageService = CardStorageService();
  StreakProvider? _streakProvider;

  CardProvider({required LanguageProvider languageProvider});
  
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

  // Computed properties
  bool get hasCards => _allCards.isNotEmpty;
  bool get hasReviewCards => _reviewCards.isNotEmpty;
  bool get isReviewComplete => _currentReviewIndex >= _currentReviewSession.length;
  double get reviewProgress => _currentReviewSession.isEmpty 
      ? 0.0 
      : (_currentReviewIndex / _currentReviewSession.length).clamp(0.0, 1.0);
  
  int get totalCards => _allCards.length;
  int get dueCards => _reviewCards.length;
  int get completedCards => _allCards.where((card) => !card.isDue).length;
  
  List<String> get allCategories => _allCards
      .map((card) => card.category)
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  
  List<String> get allTags => _allCards
      .expand((card) => card.tags)
      .toSet()
      .toList()
    ..sort();

  // Dependency injection
  void setStreakProvider(StreakProvider streakProvider) {
    _streakProvider = streakProvider;
  }

  /// Initialize the provider by loading cards
  Future<void> initialize() async {
    await loadCards();
  }

  /// Load all cards from storage
  Future<void> loadCards() async {
    _setLoading(true);
    _clearError();
    
    try {
      _allCards = await _storageService.loadCards();
      _updateFilteredCards();
      _updateReviewCards();
      _updateStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load cards: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save a card
  Future<void> saveCard(CardModel card) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _storageService.saveCard(card);
      
      // Update local collections
      final existingIndex = _allCards.indexWhere((c) => c.id == card.id);
      if (existingIndex >= 0) {
        _allCards[existingIndex] = card;
      } else {
        _allCards.add(card);
      }
      
      _updateFilteredCards();
      _updateReviewCards();
      _updateStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to save card: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a card
  Future<void> deleteCard(String cardId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _storageService.deleteCard(cardId);
      
      // Remove from local collections
      _allCards.removeWhere((card) => card.id == cardId);
      _updateFilteredCards();
      _updateReviewCards();
      _updateStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete card: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle favorite status of a card
  Future<void> toggleFavorite(String cardId) async {
    final card = _allCards.firstWhere((c) => c.id == cardId);
    final updatedCard = card.copyWith(isFavorite: !card.isFavorite);
    await saveCard(updatedCard);
  }

  /// Update card difficulty
  Future<void> updateCardDifficulty(String cardId, int difficulty) async {
    final card = _allCards.firstWhere((c) => c.id == cardId);
    final updatedCard = card.copyWith(difficulty: difficulty);
    await saveCard(updatedCard);
  }

  /// Start a review session
  void startReviewSession({List<CardModel>? customCards}) {
    _currentReviewSession = customCards ?? List.from(_reviewCards);
    _currentReviewSession.shuffle(); // Randomize order
    _currentReviewIndex = 0;
    _isReviewMode = true;
    _showingBack = false;
    _sessionCardsReviewed = 0;
    _sessionStartTime = DateTime.now();
    notifyListeners();
  }

  /// End the current review session
  void endReviewSession() {
    _isReviewMode = false;
    _currentReviewSession.clear();
    _currentReviewIndex = 0;
    _showingBack = false;
    _sessionStartTime = null;
    notifyListeners();
  }

  /// Flip the current card
  void flipCard() {
    _showingBack = !_showingBack;
    notifyListeners();
  }

  /// Answer the current card and move to next
  Future<void> answerCard(CardAnswer answer) async {
    if (_currentReviewIndex >= _currentReviewSession.length) return;
    
    final card = _currentReviewSession[_currentReviewIndex];
    final updatedCard = card.processAnswer(answer);
    
    // Save the updated card
    await saveCard(updatedCard);
    
    // Update streak if correct
    if (answer == CardAnswer.correct && _streakProvider != null) {
      await _streakProvider!.recordCardReview();
    }
    
    // Move to next card
    _sessionCardsReviewed++;
    _currentReviewIndex++;
    _showingBack = false;
    
    // If session is complete, end it
    if (isReviewComplete) {
      endReviewSession();
    }
    
    notifyListeners();
  }

  /// Go to previous card in review
  void previousCard() {
    if (_currentReviewIndex > 0) {
      _currentReviewIndex--;
      _showingBack = false;
      notifyListeners();
    }
  }

  /// Go to next card in review (without answering)
  void nextCard() {
    if (_currentReviewIndex < _currentReviewSession.length - 1) {
      _currentReviewIndex++;
      _showingBack = false;
      notifyListeners();
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _updateFilteredCards();
    notifyListeners();
  }

  /// Set selected category filter
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _updateFilteredCards();
    notifyListeners();
  }

  /// Toggle tag filter
  void toggleTagFilter(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    _updateFilteredCards();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedTags.clear();
    _showOnlyDue = false;
    _showOnlyFavorites = false;
    _updateFilteredCards();
    notifyListeners();
  }

  /// Toggle show only due cards
  void toggleShowOnlyDue() {
    _showOnlyDue = !_showOnlyDue;
    _updateFilteredCards();
    notifyListeners();
  }

  /// Toggle show only favorites
  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _updateFilteredCards();
    notifyListeners();
  }

  /// Export cards as JSON
  Future<String> exportCards() async {
    return await _storageService.exportCards();
  }

  /// Import cards from JSON
  Future<void> importCards(String cardsJson, {bool replaceExisting = false}) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _storageService.importCards(cardsJson, replaceExisting: replaceExisting);
      await loadCards(); // Reload all cards
    } catch (e) {
      _setError('Failed to import cards: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all cards
  Future<void> clearAllCards() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _storageService.clearAllCards();
      _allCards.clear();
      _updateFilteredCards();
      _updateReviewCards();
      _updateStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear cards: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _storageService.getStorageStats();
  }

  // Private helper methods

  void _updateFilteredCards() {
    _filteredCards = _allCards.where((card) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!card.front.toLowerCase().contains(query) &&
            !card.back.toLowerCase().contains(query) &&
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
      if (_selectedTags.isNotEmpty && 
          !_selectedTags.every((tag) => card.tags.contains(tag))) {
        return false;
      }
      
      // Due cards filter
      if (_showOnlyDue && !card.isDue) {
        return false;
      }
      
      // Favorites filter
      if (_showOnlyFavorites && !card.isFavorite) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _updateReviewCards() {
    _reviewCards = _allCards.where((card) => card.isDue).toList();
  }

  void _updateStats() {
    _stats = {
      'total': _allCards.length,
      'due': _reviewCards.length,
      'completed': _allCards.where((card) => !card.isDue).length,
      'favorites': _allCards.where((card) => card.isFavorite).length,
      'categories': allCategories.length,
      'tags': allTags.length,
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _storageService.dispose();
    super.dispose();
  }
}
