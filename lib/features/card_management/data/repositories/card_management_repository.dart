import '../../../../shared/domain/models/card_model.dart';
import '../services/supabase_card_service.dart';

/// Repository interface for card management operations
abstract class CardManagementRepository {
  /// Get all cards
  Future<List<CardModel>> getAllCards();

  /// Get cards by language
  Future<List<CardModel>> getCardsByLanguage(String language);

  /// Save a card (create or update)
  Future<void> saveCard(CardModel card);

  /// Delete a card
  Future<void> deleteCard(String cardId);

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
  Future<List<CardModel>> getCardsByLanguage(String language) async {
    return await _supabaseService.loadCards(languageCode: language);
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
  Future<void> clearAllCards() async {
    await _supabaseService.clearAllCards();
  }
}
