import '../../../../shared/shared.dart';
import '../../../../shared/services/supabase_card_service.dart';

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

/// Supabase implementation of card management repository.
/// Assumes user is authenticated - callers must ensure this.
class SupabaseCardManagementRepository implements CardManagementRepository {
  final SupabaseCardService _supabaseService;
  
  SupabaseCardManagementRepository({SupabaseCardService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseCardService();

  @override
  Future<List<CardModel>> getAllCards() async {
    return await _supabaseService.loadCards();
  }

  @override
  Future<List<CardModel>> getCardsByCategory(String category) async {
    final allCards = await _supabaseService.loadCards();
    return allCards.where((card) => card.category == category).toList();
  }

  @override
  Future<List<CardModel>> getCardsByLanguage(String language) async {
    return await _supabaseService.loadCards(languageCode: language);
  }

  @override
  Future<List<CardModel>> searchCards(String query) async {
    final allCards = await _supabaseService.loadCards();
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
    await _supabaseService.saveCard(card);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await _supabaseService.deleteCard(cardId);
  }

  @override
  Future<List<String>> getCategories() async {
    final allCards = await _supabaseService.loadCards();
    return allCards
        .map((card) => card.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()..sort();
  }

  @override
  Future<List<String>> getTags() async {
    final allCards = await _supabaseService.loadCards();
    return allCards
        .expand((card) => card.tags)
        .toSet()
        .toList()..sort();
  }

  @override
  Future<void> clearAllCards() async {
    await _supabaseService.clearAllCards();
  }
}
