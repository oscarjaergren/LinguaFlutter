import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/features/language/domain/language_provider.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_provider.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/review_session_provider.dart';

void main() {
  group('CardManagementProvider', () {
    late CardManagementProvider provider;

    setUp(() {
      provider = CardManagementProvider(languageProvider: LanguageProvider());
    });

    tearDown(() {
      provider.dispose();
    });

    test('should have initial state', () {
      expect(provider.allCards, isEmpty);
      expect(provider.filteredCards, isEmpty);
      expect(provider.reviewCards, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.selectedCategory, isEmpty);
      expect(provider.selectedTags, isEmpty);
      expect(provider.showOnlyDue, false);
      expect(provider.showOnlyFavorites, false);
      expect(provider.stats, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.categories, isEmpty);
      expect(provider.availableTags, isEmpty);
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
  });

  group('ReviewSessionProvider', () {
    late ReviewSessionProvider provider;
    late CardManagementProvider cardManagement;

    setUp(() {
      cardManagement = CardManagementProvider(languageProvider: LanguageProvider());
      provider = ReviewSessionProvider(cardManagement: cardManagement);
    });

    tearDown(() {
      provider.dispose();
      cardManagement.dispose();
    });

    test('should have initial state', () {
      expect(provider.sessionCards, isEmpty);
      expect(provider.currentIndex, 0);
      expect(provider.showingBack, false);
      expect(provider.isSessionActive, false);
      expect(provider.currentCard, isNull);
      expect(provider.progress, 0.0);
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

      provider.startSession([card1, card2]);

      expect(provider.isSessionActive, true);
      expect(provider.sessionCards, [card1, card2]);
      expect(provider.currentIndex, 0);
      expect(provider.showingBack, false);
      expect(provider.currentCard, card1);
      expect(provider.progress, 0.5);

      provider.endSession();

      expect(provider.isSessionActive, false);
      expect(provider.sessionCards, isEmpty);
      expect(provider.currentIndex, 0);
      expect(provider.showingBack, false);
      expect(provider.currentCard, isNull);
      expect(provider.progress, 0.0);
    });

    test('should flip card', () {
      final card = CardModel.create(
        frontText: 'Hello',
        backText: 'Hola',
        language: 'es',
        category: 'Greetings',
      );

      provider.startSession([card]);

      expect(provider.showingBack, false);

      provider.flipCard();
      expect(provider.showingBack, true);
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

      provider.startSession(cards);

      expect(provider.progress, 1.0 / 3.0);
      expect(provider.currentCard, cards[0]);
    });
  });
}
