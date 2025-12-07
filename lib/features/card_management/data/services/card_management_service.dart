import '../../../../shared/shared.dart';
import '../repositories/card_management_repository.dart';

/// Service for card management business logic.
/// Assumes user is authenticated - callers must ensure this.
class CardManagementService {
  final CardManagementRepository _repository;
  
  CardManagementService({CardManagementRepository? repository})
      : _repository = repository ?? SupabaseCardManagementRepository();

  /// Create a new card with validation
  Future<CardModel> createCard({
    required String frontText,
    required String backText,
    required String language,
    required String category,
    List<String> tags = const [],
    int difficulty = 1,
    String? germanArticle,
    IconModel? icon,
  }) async {
    // Validate input
    if (frontText.trim().isEmpty) {
      throw ArgumentError('Front text cannot be empty');
    }
    if (backText.trim().isEmpty) {
      throw ArgumentError('Back text cannot be empty');
    }
    if (language.trim().isEmpty) {
      throw ArgumentError('Language cannot be empty');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError('Category cannot be empty');
    }
    if (difficulty < 1 || difficulty > 5) {
      throw ArgumentError('Difficulty must be between 1 and 5');
    }

    final card = CardModel.create(
      frontText: frontText.trim(),
      backText: backText.trim(),
      language: language.trim(),
      category: category.trim(),
      tags: tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
      difficulty: difficulty,
      germanArticle: germanArticle?.trim(),
      icon: icon,
    );

    await _repository.saveCard(card);
    return card;
  }

  /// Update an existing card
  Future<CardModel> updateCard(CardModel card) async {
    // Validate card
    if (card.frontText.trim().isEmpty) {
      throw ArgumentError('Front text cannot be empty');
    }
    if (card.backText.trim().isEmpty) {
      throw ArgumentError('Back text cannot be empty');
    }
    if (card.language.trim().isEmpty) {
      throw ArgumentError('Language cannot be empty');
    }
    if (card.category.trim().isEmpty) {
      throw ArgumentError('Category cannot be empty');
    }

    final updatedCard = card.copyWith(updatedAt: DateTime.now());
    await _repository.saveCard(updatedCard);
    return updatedCard;
  }

  /// Delete a card by ID
  Future<void> deleteCard(String cardId) async {
    if (cardId.trim().isEmpty) {
      throw ArgumentError('Card ID cannot be empty');
    }
    await _repository.deleteCard(cardId);
  }

  /// Get filtered and sorted cards
  Future<List<CardModel>> getFilteredCards({
    String? category,
    String? language,
    List<String>? tags,
    String? searchQuery,
    bool showOnlyDue = false,
    bool showOnlyFavorites = false,
    bool includeArchived = false,
  }) async {
    List<CardModel> cards;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      cards = await _repository.searchCards(searchQuery.trim());
    } else if (category != null && category.trim().isNotEmpty) {
      cards = await _repository.getCardsByCategory(category.trim());
    } else if (language != null && language.trim().isNotEmpty) {
      cards = await _repository.getCardsByLanguage(language.trim());
    } else {
      cards = await _repository.getAllCards();
    }

    // Apply additional filters
    cards = cards.where((card) {
      // Archive filter
      if (!includeArchived && card.isArchived) return false;
      
      // Due filter
      if (showOnlyDue && !card.isDue) return false;
      
      // Favorites filter
      if (showOnlyFavorites && !card.isFavorite) return false;
      
      // Tags filter
      if (tags != null && tags.isNotEmpty) {
        if (!tags.every((tag) => card.tags.contains(tag))) return false;
      }
      
      return true;
    }).toList();

    // Sort by creation date (newest first)
    cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return cards;
  }

  /// Get card statistics
  Future<Map<String, dynamic>> getCardStatistics() async {
    final allCards = await _repository.getAllCards();
    final activeCards = allCards.where((card) => !card.isArchived).toList();
    
    return {
      'totalCards': allCards.length,
      'activeCards': activeCards.length,
      'archivedCards': allCards.length - activeCards.length,
      'favoriteCards': activeCards.where((card) => card.isFavorite).length,
      'dueCards': activeCards.where((card) => card.isDue).length,
      'categories': await _repository.getCategories(),
      'tags': await _repository.getTags(),
      'averageSuccessRate': activeCards.isEmpty
          ? 0.0
          : activeCards.map((card) => card.successRate).reduce((a, b) => a + b) /
              activeCards.length,
    };
  }

  /// Duplicate a card
  Future<CardModel> duplicateCard(CardModel originalCard) async {
    final duplicatedCard = CardModel.create(
      frontText: '${originalCard.frontText} (Copy)',
      backText: originalCard.backText,
      language: originalCard.language,
      category: originalCard.category,
      tags: List.from(originalCard.tags),
      difficulty: originalCard.difficulty,
      germanArticle: originalCard.germanArticle,
      icon: originalCard.icon,
    );

    await _repository.saveCard(duplicatedCard);
    return duplicatedCard;
  }

  /// Archive/unarchive a card
  Future<CardModel> toggleArchiveCard(CardModel card) async {
    final updatedCard = card.copyWith(
      isArchived: !card.isArchived,
      updatedAt: DateTime.now(),
    );
    await _repository.saveCard(updatedCard);
    return updatedCard;
  }

  /// Toggle favorite status of a card
  Future<CardModel> toggleFavoriteCard(CardModel card) async {
    final updatedCard = card.copyWith(
      isFavorite: !card.isFavorite,
      updatedAt: DateTime.now(),
    );
    await _repository.saveCard(updatedCard);
    return updatedCard;
  }

  /// Import cards from a list
  Future<List<CardModel>> importCards(List<Map<String, dynamic>> cardsData) async {
    final importedCards = <CardModel>[];
    
    for (final cardData in cardsData) {
      try {
        final card = CardModel.create(
          frontText: cardData['frontText'] ?? '',
          backText: cardData['backText'] ?? '',
          language: cardData['language'] ?? 'en',
          category: cardData['category'] ?? 'General',
          tags: List<String>.from(cardData['tags'] ?? []),
          difficulty: cardData['difficulty'] ?? 1,
          germanArticle: cardData['germanArticle'],
        );
        
        await _repository.saveCard(card);
        importedCards.add(card);
      } catch (e) {
        // Skip invalid cards but continue importing others
        continue;
      }
    }
    
    return importedCards;
  }

  /// Export cards to a list of maps
  Future<List<Map<String, dynamic>>> exportCards({
    bool includeArchived = false,
  }) async {
    final cards = await getFilteredCards(includeArchived: includeArchived);
    return cards.map((card) => card.toJson()).toList();
  }
}
