import 'package:flutter/foundation.dart';
import 'models/card_model.dart';
import '../../features/language/language.dart';
import '../../features/card_management/card_management.dart';

/// Shared provider for managing cards across all features
class CardProvider extends ChangeNotifier {
  final CardManagementRepository _repository;
  final LanguageProvider languageProvider;

  // Core card data
  List<CardModel> _allCards = [];
  List<CardModel> _filteredCards = [];
  List<CardModel> _reviewCards = [];
  
  // Review session state
  List<CardModel> _currentReviewSession = [];
  int _currentReviewIndex = 0;
  bool _isReviewMode = false;
  bool _showingBack = false;
  DateTime? _sessionStartTime;
  int _sessionCardsReviewed = 0;
  
  // Filter and search state
  String _searchQuery = '';
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  bool _showOnlyDue = false;
  bool _showOnlyFavorites = false;
  
  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};

  CardProvider({
    required this.languageProvider,
    CardManagementRepository? repository,
  }) : _repository = repository ?? LocalCardManagementRepository() {
    _initialize();
  }

  // Getters
  List<CardModel> get allCards => _allCards;
  List<CardModel> get filteredCards => _filteredCards;
  List<CardModel> get reviewCards => _reviewCards;
  List<CardModel> get currentReviewSession => _currentReviewSession;
  int get currentReviewIndex => _currentReviewIndex;
  bool get isReviewMode => _isReviewMode;
  bool get showingBack => _showingBack;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get selectedTags => _selectedTags;
  bool get showOnlyDue => _showOnlyDue;
  bool get showOnlyFavorites => _showOnlyFavorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get stats => _stats;
  DateTime? get sessionStartTime => _sessionStartTime;
  int get sessionCardsReviewed => _sessionCardsReviewed;
  
  // Computed properties
  CardModel? get currentCard => _currentReviewSession.isNotEmpty && 
      _currentReviewIndex < _currentReviewSession.length
      ? _currentReviewSession[_currentReviewIndex]
      : null;
      
  double get reviewProgress => _currentReviewSession.isEmpty 
      ? 0.0 
      : (_currentReviewIndex + 1) / _currentReviewSession.length;
      
  List<String> get categories => _allCards
      .map((card) => card.category)
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList()..sort();
      
  List<String> get availableTags => _allCards
      .expand((card) => card.tags)
      .toSet()
      .toList()..sort();

  Future<void> _initialize() async {
    await loadCards();
  }

  Future<void> initialize() async {
    await _initialize();
  }

  // Card management methods
  Future<void> loadCards() async {
    _setLoading(true);
    try {
      _allCards = await _repository.getAllCards();
      _applyFilters();
      _updateReviewCards();
      _calculateStats();
      _clearError();
    } catch (e) {
      _setError('Failed to load cards: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveCard(CardModel card) async {
    try {
      await _repository.saveCard(card);
      await loadCards(); // Reload to get updated data
    } catch (e) {
      _setError('Failed to save card: $e');
    }
  }

  Future<void> addCard(CardModel card) async {
    await saveCard(card);
  }

  Future<void> updateCard(CardModel card) async {
    await saveCard(card);
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _repository.deleteCard(cardId);
      await loadCards();
    } catch (e) {
      _setError('Failed to delete card: $e');
    }
  }

  Future<void> toggleArchive(String cardId) async {
    final card = _allCards.firstWhere((c) => c.id == cardId);
    final updatedCard = card.copyWith(isArchived: !card.isArchived);
    await updateCard(updatedCard);
  }

  Future<void> toggleFavorite(String cardId) async {
    final card = _allCards.firstWhere((c) => c.id == cardId);
    final updatedCard = card.copyWith(isFavorite: !card.isFavorite);
    await updateCard(updatedCard);
  }

  // Search and filter methods
  void searchCards(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void filterByTags(List<String> tags) {
    _selectedTags = tags;
    _applyFilters();
    notifyListeners();
  }

  void toggleShowOnlyDue() {
    _showOnlyDue = !_showOnlyDue;
    _applyFilters();
    notifyListeners();
  }

  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedTags = [];
    _showOnlyDue = false;
    _showOnlyFavorites = false;
    _applyFilters();
    notifyListeners();
  }

  // Review session methods
  void startReviewSession({List<CardModel>? cards}) {
    _currentReviewSession = cards ?? _reviewCards;
    _currentReviewIndex = 0;
    _isReviewMode = true;
    _showingBack = false;
    _sessionStartTime = DateTime.now();
    _sessionCardsReviewed = 0;
    notifyListeners();
  }

  void endReviewSession() {
    _currentReviewSession = [];
    _currentReviewIndex = 0;
    _isReviewMode = false;
    _showingBack = false;
    notifyListeners();
  }

  void flipCard() {
    _showingBack = !_showingBack;
    notifyListeners();
  }

  void nextCard() {
    if (_currentReviewIndex < _currentReviewSession.length - 1) {
      _currentReviewIndex++;
      _showingBack = false;
      notifyListeners();
    }
  }

  void previousCard() {
    if (_currentReviewIndex > 0) {
      _currentReviewIndex--;
      _showingBack = false;
      notifyListeners();
    }
  }

  Future<void> answerCard(CardAnswer answer) async {
    if (currentCard != null) {
      final updatedCard = currentCard!.processAnswer(answer);
      await updateCard(updatedCard);
      _sessionCardsReviewed++;
      
      // Move to next card or end session
      if (_currentReviewIndex < _currentReviewSession.length - 1) {
        nextCard();
      } else {
        // Last card answered - end the session
        endReviewSession();
      }
    }
  }

  Future<void> clearAllCards() async {
    try {
      await _repository.clearAllCards();
      await loadCards();
    } catch (e) {
      _setError('Failed to clear cards: $e');
    }
  }

  // Language change handler
  void onLanguageChanged() {
    _applyFilters();
    _updateReviewCards();
    notifyListeners();
  }

  // Private helper methods
  void _applyFilters() {
    _filteredCards = _allCards.where((card) {
      // Language filter
      if (languageProvider.activeLanguage.isNotEmpty && 
          card.language != languageProvider.activeLanguage) {
        return false;
      }

      // Search filter
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
      if (_selectedTags.isNotEmpty && 
          !_selectedTags.every((tag) => card.tags.contains(tag))) {
        return false;
      }

      // Due filter
      if (_showOnlyDue && !card.isDue) {
        return false;
      }

      // Favorites filter
      if (_showOnlyFavorites && !card.isFavorite) {
        return false;
      }

      // Archived filter (exclude archived by default)
      if (card.isArchived) {
        return false;
      }

      return true;
    }).toList();
  }

  void _updateReviewCards() {
    _reviewCards = _allCards
        .where((card) => 
            card.isDue && 
            !card.isArchived &&
            (languageProvider.activeLanguage.isEmpty || 
             card.language == languageProvider.activeLanguage))
        .toList();
  }

  void _calculateStats() {
    _stats = {
      'totalCards': _allCards.length,
      'dueCards': _reviewCards.length,
      'favoriteCards': _allCards.where((c) => c.isFavorite).length,
      'archivedCards': _allCards.where((c) => c.isArchived).length,
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
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
