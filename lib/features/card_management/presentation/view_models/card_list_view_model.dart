import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../duplicate_detection/duplicate_detection.dart';
import '../../../language/domain/language_provider.dart';
import '../../domain/providers/card_management_provider.dart';

/// ViewModel for the card list screen, handling UI-specific logic and state
class CardListViewModel extends ChangeNotifier {
  final CardManagementProvider _cardManagement;
  final DuplicateDetectionProvider _duplicateDetection;
  final LanguageProvider _languageProvider;

  // UI-specific state
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  bool _showOnlyDue = false;
  bool _showOnlyFavorites = false;
  bool _showOnlyDuplicates = false;

  CardListViewModel({
    required CardManagementProvider cardManagement,
    required DuplicateDetectionProvider duplicateDetection,
    required LanguageProvider languageProvider,
  })  : _cardManagement = cardManagement,
        _duplicateDetection = duplicateDetection,
        _languageProvider = languageProvider {
    // Listen to provider changes
    _cardManagement.addListener(_onCardManagementChanged);
    _languageProvider.addListener(_onLanguageProviderChanged);
    
    // Initialize with current provider state
    _syncWithProviders();
  }

  @override
  void dispose() {
    _cardManagement.removeListener(_onCardManagementChanged);
    _languageProvider.removeListener(_onLanguageProviderChanged);
    super.dispose();
  }

  // Getters for UI state
  bool get isLoading => _cardManagement.isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get selectedTags => List.unmodifiable(_selectedTags);
  bool get showOnlyDue => _showOnlyDue;
  bool get showOnlyFavorites => _showOnlyFavorites;
  bool get showOnlyDuplicates => _showOnlyDuplicates;
  String? get errorMessage => _cardManagement.errorMessage;
  
  // Duplicate detection getters
  int get duplicateCount => _duplicateDetection.duplicateCount;
  bool cardHasDuplicates(String cardId) => _duplicateDetection.cardHasDuplicates(cardId);
  List<DuplicateMatch> getDuplicatesForCard(String cardId) => 
      _duplicateDetection.getDuplicatesForCard(cardId);

  // Getters for card data
  List<CardModel> get displayCards => _cardManagement.filteredCards;
  List<CardModel> get allCards => _cardManagement.allCards;
  int get totalCards => _cardManagement.allCards.length;
  int get filteredCardsCount => _cardManagement.filteredCards.length;

  // Language-related getters
  String get activeLanguage => _languageProvider.activeLanguage;
  
  /// Get language details for the active language
  Map<String, String> get languageDetails {
    final details = _languageProvider.getLanguageDetails(_languageProvider.activeLanguage)!;
    return Map<String, String>.from(details);
  }

  // Statistics getters
  Map<String, dynamic> get stats => _cardManagement.stats;
  int get cardsToReview => _cardManagement.reviewCards.length;

  // UI Actions
  void startSearch() {
    _isSearching = true;
    notifyListeners();
  }

  void stopSearch() {
    _isSearching = false;
    _searchQuery = '';
    _cardManagement.searchCards('');
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _cardManagement.searchCards(query);
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    _cardManagement.filterByCategory(category);
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategory = '';
    _cardManagement.filterByCategory('');
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    _cardManagement.filterByTags(_selectedTags);
    notifyListeners();
  }

  void clearTagFilters() {
    _selectedTags.clear();
    _cardManagement.filterByTags([]);
    notifyListeners();
  }

  void toggleShowOnlyDue() {
    _showOnlyDue = !_showOnlyDue;
    _cardManagement.toggleShowOnlyDue();
    notifyListeners();
  }

  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _cardManagement.toggleShowOnlyFavorites();
    notifyListeners();
  }

  void toggleShowOnlyDuplicates() {
    _showOnlyDuplicates = !_showOnlyDuplicates;
    _cardManagement.toggleShowOnlyDuplicates();
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedCategory = '';
    _selectedTags.clear();
    _showOnlyDue = false;
    _showOnlyFavorites = false;
    _showOnlyDuplicates = false;
    _cardManagement.clearFilters();
    notifyListeners();
  }

  // Card actions
  Future<void> deleteCard(String cardId) async {
    try {
      await _cardManagement.deleteCard(cardId);
    } catch (e) {
      // Error is handled by CardManagementProvider and exposed via errorMessage
      debugPrint('Error deleting card: $e');
    }
  }

  Future<void> toggleCardFavorite(String cardId) async {
    try {
      await _cardManagement.toggleFavorite(cardId);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> refreshCards() async {
    try {
      await _cardManagement.loadCards();
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
  void _onCardManagementChanged() {
    notifyListeners();
  }

  void _onLanguageProviderChanged() {
    notifyListeners();
  }

  void _syncWithProviders() {
    // Sync any initial state if needed
    _searchQuery = _cardManagement.searchQuery;
    _selectedCategory = _cardManagement.selectedCategory;
    _selectedTags = List.from(_cardManagement.selectedTags);
    _showOnlyDue = _cardManagement.showOnlyDue;
    _showOnlyFavorites = _cardManagement.showOnlyFavorites;
    _showOnlyDuplicates = _cardManagement.showOnlyDuplicates;
  }
}
