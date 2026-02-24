import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';

import 'package:lingua_flutter/features/card_management/domain/providers/card_management_provider.dart';
import 'package:lingua_flutter/features/card_management/data/repositories/card_management_repository.dart';

@GenerateMocks([CardManagementRepository])
import 'card_management_provider_test.mocks.dart';

void main() {
  group('CardManagementProvider', () {
    late CardManagementProvider provider;
    late MockCardManagementRepository mockRepository;
    late String activeLanguage;

    setUp(() {
      mockRepository = MockCardManagementRepository();
      activeLanguage = 'de';
      provider = CardManagementProvider(
        getActiveLanguage: () => activeLanguage,
        repository: mockRepository,
      );

      // Default stubs
      when(mockRepository.getAllCards()).thenAnswer((_) async => <CardModel>[]);
    });

    tearDown(() {
      provider.dispose();
    });

    test('should have initial state', () {
      expect(provider.allCards, isEmpty);
      expect(provider.filteredCards, isEmpty);
      expect(provider.reviewCards, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.selectedTags, isEmpty);
      expect(provider.showOnlyDue, false);
      expect(provider.showOnlyFavorites, false);
      expect(provider.stats, isA<Map<String, dynamic>>());
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.availableTags, isEmpty);
    });

    test('should search cards', () {
      provider.searchCards('test query');
      expect(provider.searchQuery, 'test query');

      provider.searchCards('');
      expect(provider.searchQuery, '');
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
      provider.filterByTags(['tag1']);
      provider.toggleShowOnlyDue();
      provider.toggleShowOnlyFavorites();

      provider.clearFilters();

      expect(provider.searchQuery, '');
      expect(provider.selectedTags, isEmpty);
      expect(provider.showOnlyDue, false);
      expect(provider.showOnlyFavorites, false);
    });

    test('should load cards from repository', () async {
      final testCards = [
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
      ];
      when(mockRepository.getAllCards()).thenAnswer((_) async => testCards);

      await provider.loadCards();

      verify(mockRepository.getAllCards()).called(1);
      expect(provider.allCards.length, 1);
      expect(provider.allCards.first.frontText, 'Hello');
    });

    test('should add card via repository', () async {
      final newCard = CardModel.create(
        frontText: 'New',
        backText: 'Nuevo',
        language: 'es',
      );
      when(mockRepository.saveCard(any)).thenAnswer((_) async {});
      when(mockRepository.getAllCards()).thenAnswer((_) async => [newCard]);

      await provider.addCard(newCard);

      verify(mockRepository.saveCard(any)).called(1);
    });

    test('should delete card via repository', () async {
      when(mockRepository.deleteCard(any)).thenAnswer((_) async {});
      when(mockRepository.getAllCards()).thenAnswer((_) async => []);

      await provider.deleteCard('card-id');

      verify(mockRepository.deleteCard('card-id')).called(1);
    });
  });
}
