import '../../../../shared/shared.dart';
import '../repositories/review_repository.dart';

/// Service for handling card review business logic
class ReviewService {
  final ReviewRepository _repository;
  
  ReviewService({ReviewRepository? repository})
      : _repository = repository ?? LocalReviewRepository();

  /// Get cards ready for review based on spaced repetition algorithm
  Future<List<CardModel>> getReviewCards({
    String? category,
    String? language,
    int? maxCards,
  }) async {
    List<CardModel> cards;
    
    if (category != null) {
      cards = await _repository.getCardsByCategory(category);
    } else if (language != null) {
      cards = await _repository.getCardsByLanguage(language);
    } else {
      cards = await _repository.getDueCards();
    }
    
    // Filter to only due cards
    cards = cards.where((card) => card.isDue).toList();
    
    // Sort by priority (cards that haven't been reviewed in longer time first)
    cards.sort((a, b) {
      final aLastReview = a.lastReviewed ?? DateTime(1970);
      final bLastReview = b.lastReviewed ?? DateTime(1970);
      return aLastReview.compareTo(bLastReview);
    });
    
    // Limit number of cards if specified
    if (maxCards != null && cards.length > maxCards) {
      cards = cards.take(maxCards).toList();
    }
    
    return cards;
  }

  /// Process a card answer and update the card with spaced repetition logic
  Future<CardModel> processCardAnswer(CardModel card, CardAnswer answer) async {
    final updatedCard = card.processAnswer(answer);
    await _repository.updateCardAfterReview(updatedCard);
    return updatedCard;
  }

  /// Get review session recommendations based on user's current progress
  Future<Map<String, dynamic>> getSessionRecommendations() async {
    final stats = await _repository.getReviewStats();
    final dueCards = stats['dueCards'] as int;
    
    int recommendedCards;
    String sessionType;
    
    if (dueCards == 0) {
      recommendedCards = 0;
      sessionType = 'No cards due';
    } else if (dueCards <= 10) {
      recommendedCards = dueCards;
      sessionType = 'Quick review';
    } else if (dueCards <= 25) {
      recommendedCards = 20;
      sessionType = 'Standard session';
    } else {
      recommendedCards = 30;
      sessionType = 'Extended session';
    }
    
    return {
      'recommendedCards': recommendedCards,
      'sessionType': sessionType,
      'totalDue': dueCards,
      'estimatedTime': _estimateSessionTime(recommendedCards),
    };
  }

  /// Calculate optimal review intervals based on card difficulty and performance
  Duration calculateNextReviewInterval(CardModel card, bool wasCorrect) {
    if (!wasCorrect) {
      // If incorrect, review again soon
      return const Duration(hours: 4);
    }
    
    final successRate = card.successRate;
    final reviewCount = card.reviewCount;
    
    // Base intervals by difficulty
    final baseHours = switch (card.difficulty) {
      1 => 24,   // 1 day
      2 => 72,   // 3 days
      3 => 168,  // 1 week
      4 => 336,  // 2 weeks
      5 => 720,  // 1 month
      _ => 24,
    };
    
    // Adjust based on performance
    double multiplier = 1.0;
    
    if (successRate >= 90 && reviewCount >= 5) {
      multiplier = 2.0; // Double interval for mastered cards
    } else if (successRate >= 70) {
      multiplier = 1.5; // Increase interval for good performance
    } else if (successRate < 50) {
      multiplier = 0.5; // Decrease interval for poor performance
    }
    
    final adjustedHours = (baseHours * multiplier).round();
    return Duration(hours: adjustedHours);
  }

  /// Get detailed review statistics
  Future<Map<String, dynamic>> getDetailedStats() async {
    final baseStats = await _repository.getReviewStats();
    
    return {
      ...baseStats,
      'recommendations': await getSessionRecommendations(),
    };
  }

  /// Estimate session time based on number of cards
  int _estimateSessionTime(int cardCount) {
    // Estimate 30 seconds per card on average
    return (cardCount * 0.5).round();
  }
}
