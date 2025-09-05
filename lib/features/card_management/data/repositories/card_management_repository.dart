import '../../../../shared/shared.dart';

/// Repository interface for card management operations
abstract class CardManagementRepository {
  /// Get all cards
  Future<List<CardModel>> getAllCards();
  
  /// Get cards by category
  Future<List<CardModel>> getCardsByCategory(String category);
  
  /// Get cards by language
  Future<List<CardModel>> getCardsByLanguage(String language);
  
  /// Search cards by text
  Future<List<CardModel>> searchCards(String query);
  
  /// Save a card (create or update)
  Future<void> saveCard(CardModel card);
  
  /// Delete a card
  Future<void> deleteCard(String cardId);
  
  /// Get all categories
  Future<List<String>> getCategories();
  
  /// Get all tags
  Future<List<String>> getTags();
  
  /// Clear all cards
  Future<void> clearAllCards();
}

/// Local implementation of card management repository
class LocalCardManagementRepository implements CardManagementRepository {
  final CardStorageService _storageService;
  
  LocalCardManagementRepository({CardStorageService? storageService})
      : _storageService = storageService ?? CardStorageService();

  @override
  Future<List<CardModel>> getAllCards() async {
    return await _storageService.loadCards();
  }

  @override
  Future<List<CardModel>> getCardsByCategory(String category) async {
    final allCards = await _storageService.loadCards();
    return allCards.where((card) => card.category == category).toList();
  }

  @override
  Future<List<CardModel>> getCardsByLanguage(String language) async {
    final allCards = await _storageService.loadCards();
    return allCards.where((card) => card.language == language).toList();
  }

  @override
  Future<List<CardModel>> searchCards(String query) async {
    final allCards = await _storageService.loadCards();
    final lowerQuery = query.toLowerCase();
    
    return allCards.where((card) {
      return card.frontText.toLowerCase().contains(lowerQuery) ||
             card.backText.toLowerCase().contains(lowerQuery) ||
             card.category.toLowerCase().contains(lowerQuery) ||
             card.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  @override
  Future<void> saveCard(CardModel card) async {
    await _storageService.saveCard(card);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await _storageService.deleteCard(cardId);
  }

  @override
  Future<List<String>> getCategories() async {
    final allCards = await _storageService.loadCards();
    return allCards
        .map((card) => card.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()..sort();
  }

  @override
  Future<List<String>> getTags() async {
    final allCards = await _storageService.loadCards();
    return allCards
        .expand((card) => card.tags)
        .toSet()
        .toList()..sort();
  }

  @override
  Future<void> clearAllCards() async {
    await _storageService.clearAllCards();
  }
}
