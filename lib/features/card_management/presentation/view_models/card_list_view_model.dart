import 'package:flutter/foundation.dart';
import '../../../../shared/domain/card_provider.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../language/domain/language_provider.dart';

/// ViewModel for the card list screen, handling UI-specific logic and state
class CardListViewModel extends ChangeNotifier {
  final CardProvider _cardProvider;
  final LanguageProvider _languageProvider;

  // UI-specific state
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  bool _showOnlyDue = false;
  bool _showOnlyFavorites = false;

  CardListViewModel({
    required CardProvider cardProvider,
    required LanguageProvider languageProvider,
  })  : _cardProvider = cardProvider,
        _languageProvider = languageProvider {
    // Listen to provider changes
    _cardProvider.addListener(_onCardProviderChanged);
    _languageProvider.addListener(_onLanguageProviderChanged);
    
    // Initialize with current provider state
    _syncWithProviders();
  }

  @override
  void dispose() {
    _cardProvider.removeListener(_onCardProviderChanged);
    _languageProvider.removeListener(_onLanguageProviderChanged);
    super.dispose();
  }

  // Getters for UI state
  bool get isLoading => _cardProvider.isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get selectedTags => List.unmodifiable(_selectedTags);
  bool get showOnlyDue => _showOnlyDue;
  bool get showOnlyFavorites => _showOnlyFavorites;
  String? get errorMessage => _cardProvider.errorMessage;

  // Getters for card data
  List<CardModel> get displayCards => _cardProvider.filteredCards;
  List<CardModel> get allCards => _cardProvider.allCards;
  int get totalCards => _cardProvider.allCards.length;
  int get filteredCardsCount => _cardProvider.filteredCards.length;

  // Language-related getters
  String get activeLanguage => _languageProvider.activeLanguage;
  
  /// Get language details for the active language
  Map<String, String> get languageDetails {
    final details = _languageProvider.getLanguageDetails(_languageProvider.activeLanguage)!;
    return Map<String, String>.from(details);
  }

  // Statistics getters
  Map<String, dynamic> get stats => _cardProvider.stats;
  int get cardsToReview => _cardProvider.reviewCards.length;

  // UI Actions
  void startSearch() {
    _isSearching = true;
    notifyListeners();
  }

  void stopSearch() {
    _isSearching = false;
    _searchQuery = '';
    _cardProvider.searchCards('');
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _cardProvider.searchCards(query);
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    _cardProvider.filterByCategory(category);
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategory = '';
    _cardProvider.filterByCategory('');
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    _cardProvider.filterByTags(_selectedTags);
    notifyListeners();
  }

  void clearTagFilters() {
    _selectedTags.clear();
    _cardProvider.filterByTags([]);
    notifyListeners();
  }

  void toggleShowOnlyDue() {
    _showOnlyDue = !_showOnlyDue;
    _cardProvider.toggleShowOnlyDue();
    notifyListeners();
  }

  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _cardProvider.toggleShowOnlyFavorites();
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedCategory = '';
    _selectedTags.clear();
    _showOnlyDue = false;
    _showOnlyFavorites = false;
    _cardProvider.clearFilters();
    notifyListeners();
  }

  // Card actions
  Future<void> deleteCard(String cardId) async {
    try {
      await _cardProvider.deleteCard(cardId);
    } catch (e) {
      // Error is handled by CardProvider and exposed via errorMessage
      debugPrint('Error deleting card: $e');
    }
  }

  Future<void> toggleCardFavorite(String cardId) async {
    try {
      await _cardProvider.toggleFavorite(cardId);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> refreshCards() async {
    try {
      await _cardProvider.loadCards();
    } catch (e) {
      debugPrint('Error refreshing cards: $e');
    }
  }

  // Navigation helpers
  bool get canStartReview => cardsToReview > 0;
  
  String getCardCountText() {
    if (filteredCardsCount != totalCards) {
      return '$filteredCardsCount of $totalCards cards';
    }
    return '$totalCards cards';
  }

  String getReviewStatusText() {
    if (cardsToReview == 0) {
      return 'No cards to review';
    } else if (cardsToReview == 1) {
      return '1 card to review';
    } else {
      return '$cardsToReview cards to review';
    }
  }

  // Private methods
  void _onCardProviderChanged() {
    notifyListeners();
  }

  void _onLanguageProviderChanged() {
    notifyListeners();
  }

  void _syncWithProviders() {
    // Sync any initial state if needed
    _searchQuery = _cardProvider.searchQuery;
    _selectedCategory = _cardProvider.selectedCategory;
    _selectedTags = List.from(_cardProvider.selectedTags);
    _showOnlyDue = _cardProvider.showOnlyDue;
    _showOnlyFavorites = _cardProvider.showOnlyFavorites;
  }
}
