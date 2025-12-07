import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../language/domain/language_provider.dart';
import '../../data/repositories/card_management_repository.dart';

/// Provider for managing card data, filtering, and CRUD operations.
/// 
/// This is the primary provider for card management within the card_management feature.
/// Assumes user is authenticated - callers must ensure this.
class CardManagementProvider extends ChangeNotifier {
  final LanguageProvider _languageProvider;
  final CardManagementRepository _repository;

  // Core card data
  List<CardModel> _allCards = [];
  List<CardModel> _filteredCards = [];
  
  // Filter and search state
  String _searchQuery = '';
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  bool _showOnlyDue = false;
  bool _showOnlyFavorites = false;
  bool _showOnlyDuplicates = false;
  Set<String> _duplicateCardIds = {};
  
  // UI state
  bool _isLoading = false;
  String? _errorMessage;

  /// Create a CardManagementProvider with optional repository injection for testing.
  /// 
  /// By default uses [SupabaseCardManagementRepository]. Pass a mock implementation
  /// for unit testing.
  CardManagementProvider({
    required LanguageProvider languageProvider,
    CardManagementRepository? repository,
  })  : _languageProvider = languageProvider,
        _repository = repository ?? SupabaseCardManagementRepository() {
    _languageProvider.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  // ============================================================
  // Getters
  // ============================================================

  /// All cards in storage (unfiltered)
  List<CardModel> get allCards => List.unmodifiable(_allCards);
  
  /// Cards after applying current filters
  List<CardModel> get filteredCards => List.unmodifiable(_filteredCards);
  
  /// Cards that are due for review (filtered by active language)
  List<CardModel> get reviewCards => _allCards
      .where((card) => 
          card.isDue && 
          !card.isArchived &&
          (_languageProvider.activeLanguage.isEmpty || 
           card.language == _languageProvider.activeLanguage))
      .toList();

  // Filter state getters
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get selectedTags => List.unmodifiable(_selectedTags);
  bool get showOnlyDue => _showOnlyDue;
  bool get showOnlyFavorites => _showOnlyFavorites;
  bool get showOnlyDuplicates => _showOnlyDuplicates;
  
  // UI state getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Computed properties
  List<String> get categories => _allCards
      .map((card) => card.category)
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList()..sort();
      
  List<String> get availableTags => _allCards
      .expand((card) => card.tags)
      .toSet()
      .toList()..sort();

  /// Statistics for the current language filter
  Map<String, dynamic> get stats {
    final languageFilteredCards = _allCards.where((card) {
      return _languageProvider.activeLanguage.isEmpty || 
             card.language == _languageProvider.activeLanguage;
    }).toList();

    return {
      'totalCards': languageFilteredCards.length,
      'dueCards': reviewCards.length,
      'favoriteCards': languageFilteredCards.where((c) => c.isFavorite).length,
      'archivedCards': languageFilteredCards.where((c) => c.isArchived).length,
      'duplicateCards': languageFilteredCards.where((c) => _duplicateCardIds.contains(c.id)).length,
    };
  }

  // ============================================================
  // Card CRUD Operations
  // ============================================================

  /// Initialize the provider by loading cards
  Future<void> initialize() async {
    await loadCards();
  }

  /// Load all cards from storage
  Future<void> loadCards() async {
    _setLoading(true);
    try {
      _allCards = await _repository.getAllCards();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError('Failed to load cards: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save a card (create or update)
  Future<void> saveCard(CardModel card) async {
    try {
      await _repository.saveCard(card);
      await loadCards();
    } catch (e) {
      _setError('Failed to save card: $e');
    }
  }

  /// Add a new card
  Future<void> addCard(CardModel card) async {
    await saveCard(card);
  }

  /// Add multiple cards in batch
  Future<void> addMultipleCards(List<CardModel> cards) async {
    try {
      for (final card in cards) {
        await _repository.saveCard(card);
      }
      await loadCards();
    } catch (e) {
      _setError('Failed to add cards: $e');
      rethrow;
    }
  }

  /// Update an existing card
  Future<void> updateCard(CardModel card) async {
    await saveCard(card);
  }

  /// Delete a card by ID
  Future<void> deleteCard(String cardId) async {
    try {
      await _repository.deleteCard(cardId);
      await loadCards();
    } catch (e) {
      _setError('Failed to delete card: $e');
    }
  }

  /// Toggle archive status for a card
  Future<void> toggleArchive(String cardId) async {
    final card = _allCards.firstWhere((c) => c.id == cardId);
    final updatedCard = card.copyWith(isArchived: !card.isArchived);
    await updateCard(updatedCard);
  }

  /// Toggle favorite status for a card
  Future<void> toggleFavorite(String cardId) async {
    final card = _allCards.firstWhere((c) => c.id == cardId);
    final updatedCard = card.copyWith(isFavorite: !card.isFavorite);
    await updateCard(updatedCard);
  }

  /// Clear all cards from storage
  Future<void> clearAllCards() async {
    try {
      await _repository.clearAllCards();
      await loadCards();
    } catch (e) {
      _setError('Failed to clear cards: $e');
    }
  }

  // ============================================================
  // Search and Filter Operations
  // ============================================================

  /// Search cards by query
  void searchCards(String query) {
    _searchQuery = query.trim();
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

  /// Toggle show only due cards filter
  void toggleShowOnlyDue() {
    _showOnlyDue = !_showOnlyDue;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle show only favorites filter
  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle show only duplicates filter
  void toggleShowOnlyDuplicates() {
    _showOnlyDuplicates = !_showOnlyDuplicates;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all active filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedTags = [];
    _showOnlyDue = false;
    _showOnlyFavorites = false;
    _showOnlyDuplicates = false;
    _applyFilters();
    notifyListeners();
  }

  // ============================================================
  // Duplicate Detection Integration
  // ============================================================

  /// Update the set of card IDs that have duplicates.
  /// Called by DuplicateDetectionProvider when analysis completes.
  void updateDuplicateCardIds(Set<String> duplicateIds) {
    _duplicateCardIds = duplicateIds;
    if (_showOnlyDuplicates) {
      _applyFilters();
    }
    notifyListeners();
  }

  /// Check if a card has duplicates
  bool cardHasDuplicates(String cardId) => _duplicateCardIds.contains(cardId);

  /// Count of cards with duplicates
  int get duplicateCount => _duplicateCardIds.length;

  // ============================================================
  // Private Methods
  // ============================================================

  void _applyFilters() {
    _filteredCards = _allCards.where((card) {
      // Language filter
      if (_languageProvider.activeLanguage.isNotEmpty && 
          card.language != _languageProvider.activeLanguage) {
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
      
      // Duplicates filter
      if (_showOnlyDuplicates && !_duplicateCardIds.contains(card.id)) {
        return false;
      }

      // Archived filter (exclude archived by default)
      if (card.isArchived) {
        return false;
      }

      return true;
    }).toList();
  }

  void _onLanguageChanged() {
    _applyFilters();
    notifyListeners();
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
}
