import '../../../../shared/shared.dart';

/// Repository interface for card review data operations
abstract class ReviewRepository {
  /// Get cards that are due for review
  Future<List<CardModel>> getDueCards();
  
  /// Get cards filtered by category
  Future<List<CardModel>> getCardsByCategory(String category);
  
  /// Get cards filtered by language
  Future<List<CardModel>> getCardsByLanguage(String language);
  
  /// Update card after review
  Future<void> updateCardAfterReview(CardModel card);
  
  /// Get review statistics
  Future<Map<String, dynamic>> getReviewStats();
}

/// Local implementation of review repository
class LocalReviewRepository implements ReviewRepository {
  final CardStorageService _storageService;
  
  LocalReviewRepository({CardStorageService? storageService})
      : _storageService = storageService ?? CardStorageService();

  @override
  Future<List<CardModel>> getDueCards() async {
    final allCards = await _storageService.loadCards();
    return allCards.where((card) => card.isDue && !card.isArchived).toList();
  }

  @override
  Future<List<CardModel>> getCardsByCategory(String category) async {
    final allCards = await _storageService.loadCards();
    return allCards
        .where((card) => card.category == category && !card.isArchived)
        .toList();
  }

  @override
  Future<List<CardModel>> getCardsByLanguage(String language) async {
    final allCards = await _storageService.loadCards();
    return allCards
        .where((card) => card.language == language && !card.isArchived)
        .toList();
  }

  @override
  Future<void> updateCardAfterReview(CardModel card) async {
    await _storageService.saveCard(card);
  }

  @override
  Future<Map<String, dynamic>> getReviewStats() async {
    final allCards = await _storageService.loadCards();
    final dueCards = allCards.where((card) => card.isDue && !card.isArchived);
    
    return {
      'totalCards': allCards.length,
      'dueCards': dueCards.length,
      'reviewedToday': allCards.where((card) {
        final today = DateTime.now();
        final lastReviewed = card.lastReviewed;
        return lastReviewed != null &&
            lastReviewed.year == today.year &&
            lastReviewed.month == today.month &&
            lastReviewed.day == today.day;
      }).length,
      'averageSuccessRate': allCards.isEmpty
          ? 0.0
          : allCards.map((card) => card.successRate).reduce((a, b) => a + b) /
              allCards.length,
    };
  }
}
