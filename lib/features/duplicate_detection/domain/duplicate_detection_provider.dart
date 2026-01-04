import 'package:flutter/foundation.dart';
import '../../../shared/domain/models/card_model.dart';
import '../data/services/duplicate_detection_service.dart';
import 'models/duplicate_match.dart';

/// Provider for managing duplicate detection state
class DuplicateDetectionProvider extends ChangeNotifier {
  final DuplicateDetectionService _service;

  Map<String, List<DuplicateMatch>> _duplicateMap = {};
  bool _isAnalyzing = false;

  DuplicateDetectionProvider({DuplicateDetectionService? service})
    : _service = service ?? DuplicateDetectionService();

  // Getters

  /// Map of card IDs to their duplicate matches
  Map<String, List<DuplicateMatch>> get duplicateMap => _duplicateMap;

  /// Whether duplicate analysis is in progress
  bool get isAnalyzing => _isAnalyzing;

  /// Total count of cards with duplicates
  int get duplicateCount => _duplicateMap.length;

  /// Check if a specific card has duplicates
  bool cardHasDuplicates(String cardId) => _duplicateMap.containsKey(cardId);

  /// Get duplicates for a specific card
  List<DuplicateMatch> getDuplicatesForCard(String cardId) =>
      _duplicateMap[cardId] ?? [];

  /// Get all card IDs that have duplicates
  Set<String> get cardIdsWithDuplicates => _duplicateMap.keys.toSet();

  // Actions

  /// Analyze a list of cards for duplicates
  void analyzeCards(List<CardModel> cards) {
    _isAnalyzing = true;
    notifyListeners();

    try {
      _duplicateMap = _service.findAllDuplicates(cards);
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Analyze cards filtered by language
  void analyzeCardsForLanguage(List<CardModel> allCards, String language) {
    final cardsToCheck = language.isEmpty
        ? allCards
        : allCards.where((c) => c.language == language).toList();

    analyzeCards(cardsToCheck);
  }

  /// Clear all duplicate data
  void clear() {
    _duplicateMap = {};
    notifyListeners();
  }

  /// Get cards that have duplicates from a list
  List<CardModel> filterCardsWithDuplicates(List<CardModel> cards) {
    return cards.where((card) => _duplicateMap.containsKey(card.id)).toList();
  }
}
