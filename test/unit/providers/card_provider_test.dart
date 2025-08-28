import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/providers/card_provider.dart';
import 'package:lingua_flutter/models/card_model.dart';
import 'package:lingua_flutter/providers/language_provider.dart';

void main() {
  group('CardProvider', () {
    late CardProvider provider;

    setUp(() {
      provider = CardProvider(languageProvider: LanguageProvider());
    });

    tearDown(() {
      provider.dispose();
    });

    test('should have initial state', () {
      expect(provider.allCards, isEmpty);
      expect(provider.filteredCards, isEmpty);
      expect(provider.reviewCards, isEmpty);
      expect(provider.currentReviewSession, isEmpty);
      expect(provider.currentReviewIndex, 0);
      expect(provider.isReviewMode, false);
      expect(provider.showingBack, false);
      expect(provider.searchQuery, isEmpty);
      expect(provider.selectedCategory, isEmpty);
      expect(provider.selectedTags, isEmpty);
      expect(provider.showOnlyDue, false);
      expect(provider.showOnlyFavorites, false);
      expect(provider.stats, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.currentCard, isNull);
      expect(provider.reviewProgress, 0.0);
      expect(provider.categories, isEmpty);
      expect(provider.availableTags, isEmpty);
    });

    test('should start and end review session', () {
      final card1 = CardModel.create(
        frontText: 'Hello',
        backText: 'Hola',
        language: 'es',
        category: 'Greetings',
      );

      final card2 = CardModel.create(
        frontText: 'Goodbye',
        backText: 'Adiós',
        language: 'es',
        category: 'Greetings',
      );

      provider.startReviewSession(cards: [card1, card2]);

      expect(provider.isReviewMode, true);
      expect(provider.currentReviewSession, [card1, card2]);
      expect(provider.currentReviewIndex, 0);
      expect(provider.showingBack, false);
      expect(provider.currentCard, card1);
      expect(provider.reviewProgress, 0.5);

      provider.endReviewSession();

      expect(provider.isReviewMode, false);
      expect(provider.currentReviewSession, isEmpty);
      expect(provider.currentReviewIndex, 0);
      expect(provider.showingBack, false);
      expect(provider.currentCard, isNull);
      expect(provider.reviewProgress, 0.0);
    });

    test('should flip card', () {
      final card = CardModel.create(
        frontText: 'Hello',
        backText: 'Hola',
        language: 'es',
        category: 'Greetings',
      );

      provider.startReviewSession(cards: [card]);

      expect(provider.showingBack, false);

      provider.flipCard();
      expect(provider.showingBack, true);

      provider.flipCard();
      expect(provider.showingBack, false);
    });

    test('should search cards', () {
      provider.searchCards('test query');
      expect(provider.searchQuery, 'test query');

      provider.searchCards('');
      expect(provider.searchQuery, '');
    });

    test('should filter by category', () {
      provider.filterByCategory('Vocabulary');
      expect(provider.selectedCategory, 'Vocabulary');

      provider.filterByCategory('');
      expect(provider.selectedCategory, '');
    });

    test('should filter by tags', () {
      provider.filterByTags(['tag1', 'tag2']);
      expect(provider.selectedTags, ['tag1', 'tag2']);

      provider.filterByTags([]);
      expect(provider.selectedTags, isEmpty);
    });

    test('should toggle filters', () {
      expect(provider.showOnlyDue, false);
      expect(provider.showOnlyFavorites, false);

      provider.toggleShowOnlyDue();
      expect(provider.showOnlyDue, true);

      provider.toggleShowOnlyFavorites();
      expect(provider.showOnlyFavorites, true);

      provider.toggleShowOnlyDue();
      expect(provider.showOnlyDue, false);

      provider.toggleShowOnlyFavorites();
      expect(provider.showOnlyFavorites, false);
    });

    test('should clear all filters', () {
      provider.searchCards('test');
      provider.filterByCategory('Vocabulary');
      provider.filterByTags(['tag1']);
      provider.toggleShowOnlyDue();
      provider.toggleShowOnlyFavorites();

      provider.clearFilters();

      expect(provider.searchQuery, '');
      expect(provider.selectedCategory, '');
      expect(provider.selectedTags, isEmpty);
      expect(provider.showOnlyDue, false);
      expect(provider.showOnlyFavorites, false);
    });

    test('should calculate review progress correctly', () {
      final cards = [
        CardModel.create(
          frontText: 'Card 1',
          backText: 'Tarjeta 1',
          language: 'es',
          category: 'Test',
        ),
        CardModel.create(
          frontText: 'Card 2',
          backText: 'Tarjeta 2',
          language: 'es',
          category: 'Test',
        ),
        CardModel.create(
          frontText: 'Card 3',
          backText: 'Tarjeta 3',
          language: 'es',
          category: 'Test',
        ),
      ];

      provider.startReviewSession(cards: cards);

      expect(provider.reviewProgress, 1.0 / 3.0);
      expect(provider.currentCard, cards[0]);
    });

    // Note: More complex tests involving actual card operations (add, update, delete)
    // would require mocking the CardStorageService or using a test-specific implementation.
    // For now, these tests cover the basic state management functionality.
  });
}
