import 'package:flutter/foundation.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../duplicate_detection/duplicate_detection.dart';

import '../../domain/providers/card_management_provider.dart';

/// ViewModel for the card list screen, handling UI-specific logic and state
class CardListViewModel extends ChangeNotifier {
  final CardManagementProvider _cardManagement;
  final DuplicateDetectionProvider _duplicateDetection;
  final String Function() _getActiveLanguage;
  final Map<String, dynamic>? Function(String) _getLanguageDetails;

  // UI-only state not tracked by CardManagementProvider
  bool _isSearching = false;

  CardListViewModel({
    required CardManagementProvider cardManagement,
    required DuplicateDetectionProvider duplicateDetection,
    required String Function() getActiveLanguage,
    required Map<String, dynamic>? Function(String) getLanguageDetails,
  }) : _cardManagement = cardManagement,
       _duplicateDetection = duplicateDetection,
       _getActiveLanguage = getActiveLanguage,
       _getLanguageDetails = getLanguageDetails {
    // Listen to provider changes
    _cardManagement.addListener(_onCardManagementChanged);
  }

  @override
  void dispose() {
    _cardManagement.removeListener(_onCardManagementChanged);
    super.dispose();
  }

  void notifyLanguageChanged() {
    notifyListeners();
  }

  // Getters for UI state
  bool get isLoading => _cardManagement.isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _cardManagement.searchQuery;
  List<String> get selectedTags => _cardManagement.selectedTags;
  bool get showOnlyDue => _cardManagement.showOnlyDue;
  bool get showOnlyFavorites => _cardManagement.showOnlyFavorites;
  bool get showOnlyDuplicates => _cardManagement.showOnlyDuplicates;
  String? get errorMessage => _cardManagement.errorMessage;

  // Duplicate detection getters
  int get duplicateCount => _duplicateDetection.duplicateCount;
  bool cardHasDuplicates(String cardId) =>
      _duplicateDetection.cardHasDuplicates(cardId);
  List<DuplicateMatch> getDuplicatesForCard(String cardId) =>
      _duplicateDetection.getDuplicatesForCard(cardId);

  // Getters for card data
  List<CardModel> get displayCards => _cardManagement.filteredCards;
  List<CardModel> get allCards => _cardManagement.allCards;
  int get totalCards => _cardManagement.allCards.length;
  int get filteredCardsCount => _cardManagement.filteredCards.length;

  // Language-related getters
  String get activeLanguage => _getActiveLanguage();

  /// Get language details for the active language
  Map<String, String> get languageDetails {
    final details = _getLanguageDetails(_getActiveLanguage());
    if (details == null) {
      return <String, String>{'name': _getActiveLanguage(), 'flag': ''};
    }
    // Convert to Map<String, String> ensuring safety
    return details.map((key, value) => MapEntry(key, value.toString()));
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
    _cardManagement.searchCards('');
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _cardManagement.searchCards(query);
  }

  void toggleTag(String tag) {
    final updated = List<String>.from(_cardManagement.selectedTags);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    _cardManagement.filterByTags(updated);
  }

  void clearTagFilters() {
    _cardManagement.filterByTags([]);
  }

  void toggleShowOnlyDue() {
    _cardManagement.toggleShowOnlyDue();
  }

  void toggleShowOnlyFavorites() {
    _cardManagement.toggleShowOnlyFavorites();
  }

  void toggleShowOnlyDuplicates() {
    _cardManagement.toggleShowOnlyDuplicates();
  }

  void clearAllFilters() {
    _cardManagement.clearFilters();
  }

  // Card actions
  Future<void> deleteCard(String cardId) async {
    try {
      await _cardManagement.deleteCard(cardId);
    } catch (e) {
      // Error is handled by CardManagementProvider and exposed via errorMessage
      LoggerService.error('Error deleting card', e);
    }
  }

  Future<void> toggleCardFavorite(String cardId) async {
    try {
      await _cardManagement.toggleFavorite(cardId);
    } catch (e) {
      LoggerService.error('Error toggling favorite', e);
    }
  }

  Future<void> refreshCards() async {
    try {
      await _cardManagement.loadCards();
    } catch (e) {
      LoggerService.error('Error refreshing cards', e);
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
}
