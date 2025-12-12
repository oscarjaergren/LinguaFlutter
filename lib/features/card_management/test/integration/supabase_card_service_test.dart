/// Integration tests for SupabaseCardService
///
/// These tests run against a real PostgreSQL database via Docker.
/// Ensure the test containers are running before executing:
///   docker-compose -f docker-compose.test.yml up -d
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/features/card_management/data/services/supabase_card_service.dart';
import 'package:lingua_flutter/shared/test_helpers/supabase_test_helper.dart';

void main() {
  late SupabaseCardService cardService;

  setUpAll(() async {
    await SupabaseTestHelper.initialize();
    await SupabaseTestHelper.waitForDatabase();
    await SupabaseTestHelper.signInTestUser();
  });

  setUp(() async {
    cardService = SupabaseCardService();
    await SupabaseTestHelper.cleanTestUserCards();
  });

  tearDown(() async {
    await SupabaseTestHelper.reset();
  });

  tearDownAll(() async {
    await SupabaseTestHelper.dispose();
  });

  group('SupabaseCardService Integration Tests', () {
    test('should save and load a card', () async {
      final card = CardModel.create(
        frontText: 'Hallo',
        backText: 'Hello',
        language: 'de',
        category: 'Greetings',
      );

      final savedCard = await cardService.saveCard(card);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards, hasLength(1));
      expect(loadedCards.first.id, equals(savedCard.id));
      expect(loadedCards.first.frontText, equals('Hallo'));
      expect(loadedCards.first.backText, equals('Hello'));
      expect(loadedCards.first.language, equals('de'));
      expect(loadedCards.first.category, equals('Greetings'));
    });

    test('should update an existing card', () async {
      final card = CardModel.create(
        frontText: 'Original',
        backText: 'Original',
        language: 'de',
        category: 'Test',
      );
      final savedCard = await cardService.saveCard(card);

      final updatedCard = savedCard.copyWith(
        frontText: 'Updated',
        backText: 'Updated',
      );
      await cardService.saveCard(updatedCard);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards, hasLength(1));
      expect(loadedCards.first.frontText, equals('Updated'));
      expect(loadedCards.first.backText, equals('Updated'));
    });

    test('should delete a card', () async {
      final card = CardModel.create(
        frontText: 'ToDelete',
        backText: 'ToDelete',
        language: 'de',
        category: 'Test',
      );
      final savedCard = await cardService.saveCard(card);

      await cardService.deleteCard(savedCard.id);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards, isEmpty);
    });

    test('should filter cards by language', () async {
      final germanCard = CardModel.create(
        frontText: 'Hallo',
        backText: 'Hello',
        language: 'de',
        category: 'Greetings',
      );
      final spanishCard = CardModel.create(
        frontText: 'Hola',
        backText: 'Hello',
        language: 'es',
        category: 'Greetings',
      );
      await cardService.saveCard(germanCard);
      await cardService.saveCard(spanishCard);

      final germanCards = await cardService.loadCards(languageCode: 'de');
      final spanishCards = await cardService.loadCards(languageCode: 'es');
      final allCards = await cardService.loadCards();

      expect(germanCards, hasLength(1));
      expect(germanCards.first.frontText, equals('Hallo'));
      expect(spanishCards, hasLength(1));
      expect(spanishCards.first.frontText, equals('Hola'));
      expect(allCards, hasLength(2));
    });

    test('should save multiple cards', () async {
      final cards = [
        CardModel.create(
          frontText: 'Eins',
          backText: 'One',
          language: 'de',
          category: 'Numbers',
        ),
        CardModel.create(
          frontText: 'Zwei',
          backText: 'Two',
          language: 'de',
          category: 'Numbers',
        ),
        CardModel.create(
          frontText: 'Drei',
          backText: 'Three',
          language: 'de',
          category: 'Numbers',
        ),
      ];

      await cardService.saveCards(cards);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards, hasLength(3));
    });

    test('should persist review count and correct count', () async {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Test',
        language: 'de',
        category: 'Test',
      );
      final savedCard = await cardService.saveCard(card);

      final reviewedCard = savedCard.copyWith(
        reviewCount: 10,
        correctCount: 8,
      );
      await cardService.saveCard(reviewedCard);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards.first.reviewCount, equals(10));
      expect(loadedCards.first.correctCount, equals(8));
      expect(loadedCards.first.masteryLevel, equals('Good'));
    });

    test('should persist favorite status', () async {
      final card = CardModel.create(
        frontText: 'Favorite',
        backText: 'Favorite',
        language: 'de',
        category: 'Test',
      );
      final savedCard = await cardService.saveCard(card);

      final favoriteCard = savedCard.copyWith(isFavorite: true);
      await cardService.saveCard(favoriteCard);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards.first.isFavorite, isTrue);
    });

    test('should persist archived status', () async {
      final card = CardModel.create(
        frontText: 'Archive',
        backText: 'Archive',
        language: 'de',
        category: 'Test',
      );
      final savedCard = await cardService.saveCard(card);

      final archivedCard = savedCard.copyWith(isArchived: true);
      await cardService.saveCard(archivedCard);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards.first.isArchived, isTrue);
    });

    test('should persist tags', () async {
      final card = CardModel.create(
        frontText: 'Tagged',
        backText: 'Tagged',
        language: 'de',
        category: 'Test',
        tags: ['important', 'review', 'grammar'],
      );

      await cardService.saveCard(card);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards.first.tags, containsAll(['important', 'review', 'grammar']));
    });

    test('should persist examples', () async {
      final baseCard = CardModel.create(
        frontText: 'sprechen',
        backText: 'to speak',
        language: 'de',
        category: 'Verbs',
      );
      final card = baseCard.copyWith(
        examples: [
          'Ich spreche Deutsch.',
          'Er spricht sehr schnell.',
        ],
      );

      await cardService.saveCard(card);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards.first.examples, hasLength(2));
      expect(loadedCards.first.examples, contains('Ich spreche Deutsch.'));
    });

    test('should persist notes', () async {
      final baseCard = CardModel.create(
        frontText: 'Test',
        backText: 'Test',
        language: 'de',
        category: 'Test',
      );
      final card = baseCard.copyWith(
        notes: 'This is a note about the word.',
      );

      await cardService.saveCard(card);
      final loadedCards = await cardService.loadCards();

      expect(loadedCards.first.notes, equals('This is a note about the word.'));
    });
  });
}
