import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/card_model.dart';

/// Service for storing and retrieving cards from local storage
class CardStorageService {
  static const String _storageKey = 'lingua_flutter_cards';
  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load all cards from storage
  Future<List<CardModel>> loadCards() async {
    await _ensureInitialized();
    
    try {
      final cardsJson = _prefs!.getString(_storageKey);
      if (cardsJson == null || cardsJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> cardsList = jsonDecode(cardsJson);
      return cardsList
          .map((cardJson) => CardModel.fromJson(cardJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's an error loading cards (likely due to format changes),
      // clear the storage and return empty list
      print('Error loading cards, clearing storage: $e');
      await clearAllCards();
      return [];
    }
  }

  /// Save a single card
  Future<void> saveCard(CardModel card) async {
    final cards = await loadCards();
    
    // Remove existing card with same ID if it exists
    cards.removeWhere((existingCard) => existingCard.id == card.id);
    
    // Add the new/updated card
    cards.add(card);
    
    // Save all cards back to storage
    await saveCards(cards);
  }

  /// Save multiple cards
  Future<void> saveCards(List<CardModel> cards) async {
    await _ensureInitialized();
    
    try {
      final cardsJson = jsonEncode(cards.map((card) => card.toJson()).toList());
      await _prefs!.setString(_storageKey, cardsJson);
    } catch (e) {
      throw Exception('Failed to save cards to storage: $e');
    }
  }

  /// Delete a card by ID
  Future<void> deleteCard(String cardId) async {
    final cards = await loadCards();
    cards.removeWhere((card) => card.id == cardId);
    await saveCards(cards);
  }

  /// Clear all cards from storage
  Future<void> clearAllCards() async {
    await _ensureInitialized();
    await _prefs!.remove(_storageKey);
  }

  /// Export cards as JSON string
  Future<String> exportCards() async {
    final cards = await loadCards();
    return jsonEncode(cards.map((card) => card.toJson()).toList());
  }

  /// Import cards from JSON string
  Future<void> importCards(String cardsJson, {bool replaceExisting = false}) async {
    try {
      final List<dynamic> cardsList = jsonDecode(cardsJson);
      final importedCards = cardsList
          .map((cardJson) => CardModel.fromJson(cardJson as Map<String, dynamic>))
          .toList();
      
      if (replaceExisting) {
        await saveCards(importedCards);
      } else {
        final existingCards = await loadCards();
        final allCards = [...existingCards];
        
        // Add imported cards, avoiding duplicates
        for (final importedCard in importedCards) {
          if (!allCards.any((card) => card.id == importedCard.id)) {
            allCards.add(importedCard);
          }
        }
        
        await saveCards(allCards);
      }
    } catch (e) {
      throw Exception('Failed to import cards: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    await _ensureInitialized();
    
    final cards = await loadCards();
    return {
      'totalCards': cards.length,
      'storageSize': _prefs!.getString(_storageKey)?.length ?? 0,
      'categories': cards.map((card) => card.category).toSet().length,
      'lastModified': cards.isNotEmpty 
          ? cards.map((card) => card.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  /// Dispose of resources
  void dispose() {
    // SharedPreferences doesn't need explicit disposal
    _prefs = null;
  }
}
