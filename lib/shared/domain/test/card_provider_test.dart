import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_management/card_management.dart';
import 'package:lingua_flutter/features/language/language.dart';
import 'package:lingua_flutter/shared/domain/card_provider.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';

/// Mock repository for testing
class MockCardRepository implements CardManagementRepository {
  List<CardModel> _cards = [];

  @override
  Future<List<CardModel>> getAllCards() async {
    return List.from(_cards);
  }

  @override
  Future<List<CardModel>> getCardsByCategory(String category) async {
    return _cards.where((card) => card.category == category).toList();
  }

  @override
  Future<List<CardModel>> getCardsByLanguage(String language) async {
    return _cards.where((card) => card.language == language).toList();
  }

  @override
  Future<List<CardModel>> searchCards(String query) async {
    final lowerQuery = query.toLowerCase();
    return _cards.where((card) {
      return card.frontText.toLowerCase().contains(lowerQuery) ||
             card.backText.toLowerCase().contains(lowerQuery) ||
             card.category.toLowerCase().contains(lowerQuery) ||
             card.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  @override
  Future<void> saveCard(CardModel card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      _cards[index] = card;
    } else {
      _cards.add(card);
    }
  }

  @override
  Future<void> deleteCard(String cardId) async {
    _cards.removeWhere((c) => c.id == cardId);
  }

  @override
  Future<List<String>> getCategories() async {
    return _cards
        .map((card) => card.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()..sort();
  }

  @override
  Future<List<String>> getTags() async {
    return _cards
        .expand((card) => card.tags)
        .toSet()
        .toList()..sort();
  }

  @override
  Future<void> clearAllCards() async {
    _cards.clear();
  }

  // Helper method to add cards directly for testing
  void addCards(List<CardModel> cards) {
    _cards.addAll(cards);
  }
}

void main() {
  group('CardProvider - Language Filtering', () {
    late MockCardRepository mockRepo;
    late LanguageProvider languageProvider;
    late CardProvider cardProvider;

    setUp(() {
      mockRepo = MockCardRepository();
      languageProvider = LanguageProvider();
      cardProvider = CardProvider(
        languageProvider: languageProvider,
        repository: mockRepo,
      );
    });

    test('should filter cards by language when language is switched', () async {
      // Arrange: Create cards in different languages
      final spanishCards = [
        CardModel.create(
          frontText: 'Hello',
          backText: 'Hola',
          language: 'es',
          category: 'Greetings',
        ),
        CardModel.create(
          frontText: 'Goodbye',
          backText: 'Adiós',
          language: 'es',
          category: 'Greetings',
        ),
      ];

      final germanCards = [
        CardModel.create(
          frontText: 'Hello',
          backText: 'Hallo',
          language: 'de',
          category: 'Greetings',
        ),
      ];

      mockRepo.addCards([...spanishCards, ...germanCards]);

      // Act: Load cards with Spanish as active language
      languageProvider.setActiveLanguage('es');
      await cardProvider.loadCards();

      // Assert: Should only show Spanish cards
      expect(cardProvider.filteredCards.length, 2);
      expect(cardProvider.filteredCards.every((c) => c.language == 'es'), true);

      // Act: Switch to German
      languageProvider.setActiveLanguage('de');
      cardProvider.onLanguageChanged();

      // Assert: Should only show German cards
      expect(cardProvider.filteredCards.length, 1);
      expect(cardProvider.filteredCards.every((c) => c.language == 'de'), true);
    });

    test('should calculate stats based on current language filter', () async {
      // Arrange: Create cards in different languages with different states
      final spanishCards = [
        CardModel.create(
          frontText: 'Hello',
          backText: 'Hola',
          language: 'es',
          category: 'Greetings',
        ),
        CardModel.create(
          frontText: 'Goodbye',
          backText: 'Adiós',
          language: 'es',
          category: 'Greetings',
        ).copyWith(
          nextReview: DateTime.now().subtract(const Duration(days: 1)),
        ),
        CardModel.create(
          frontText: 'Thank you',
          backText: 'Gracias',
          language: 'es',
          category: 'Greetings',
        ).copyWith(
          nextReview: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      final germanCards = [
        CardModel.create(
          frontText: 'Hello',
          backText: 'Hallo',
          language: 'de',
          category: 'Greetings',
        ),
        CardModel.create(
          frontText: 'Goodbye',
          backText: 'Auf Wiedersehen',
          language: 'de',
          category: 'Greetings',
        ),
      ];

      mockRepo.addCards([...spanishCards, ...germanCards]);

      // Act: Load cards with Spanish as active language
      languageProvider.setActiveLanguage('es');
      await cardProvider.loadCards();

      // Assert: Stats should only count Spanish cards
      expect(cardProvider.stats['totalCards'], 3, reason: 'Should count only Spanish cards');
      expect(cardProvider.stats['dueCards'], 2, reason: 'Should count 2 due Spanish cards (new + past due)');

      // Act: Switch to German
      languageProvider.setActiveLanguage('de');
      cardProvider.onLanguageChanged();

      // Assert: Stats should now count German cards
      expect(cardProvider.stats['totalCards'], 2, reason: 'Should count only German cards');
      expect(cardProvider.stats['dueCards'], 2, reason: 'Should count 2 due German cards (both new)');
    });

    test('should update review cards when language is changed', () async {
      // Arrange: Create cards in different languages
      final spanishCards = [
        CardModel.create(
          frontText: 'Hello',
          backText: 'Hola',
          language: 'es',
          category: 'Greetings',
        ), // New card = due
      ];

      final germanCards = [
        CardModel.create(
          frontText: 'Hello',
          backText: 'Hallo',
          language: 'de',
          category: 'Greetings',
        ), // New card = due
        CardModel.create(
          frontText: 'Goodbye',
          backText: 'Auf Wiedersehen',
          language: 'de',
          category: 'Greetings',
        ), // New card = due
      ];

      mockRepo.addCards([...spanishCards, ...germanCards]);

      // Act: Load cards with Spanish as active language
      languageProvider.setActiveLanguage('es');
      await cardProvider.loadCards();

      // Assert: Should only have Spanish cards due for review
      expect(cardProvider.reviewCards.length, 1);
      expect(cardProvider.reviewCards.every((c) => c.language == 'es'), true);

      // Act: Switch to German
      languageProvider.setActiveLanguage('de');
      cardProvider.onLanguageChanged();

      // Assert: Should only have German cards due for review
      expect(cardProvider.reviewCards.length, 2);
      expect(cardProvider.reviewCards.every((c) => c.language == 'de'), true);
    });
  });
}
