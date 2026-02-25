import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_management/presentation/view_models/card_list_notifier.dart';
import 'package:lingua_flutter/features/card_management/presentation/view_models/card_list_state.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';

class _TestCardManagementNotifier extends CardManagementNotifier {
  final List<String> searchQueries = [];
  final List<String> deletedCardIds = [];
  final List<String> toggledFavoriteIds = [];

  @override
  CardManagementState build() {
    return CardManagementState(
      allCards: [
        CardModel.create(frontText: 'front', backText: 'back', language: 'de'),
      ],
    );
  }

  @override
  void searchCards(String query) {
    searchQueries.add(query);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    deletedCardIds.add(cardId);
  }

  @override
  Future<void> toggleFavorite(String cardId) async {
    toggledFavoriteIds.add(cardId);
  }
}

void main() {
  group('CardListNotifier', () {
    late _TestCardManagementNotifier testCardManagement;
    late ProviderContainer container;

    setUp(() {
      testCardManagement = _TestCardManagementNotifier();

      container = ProviderContainer(
        overrides: [
          cardManagementNotifierProvider.overrideWith(() => testCardManagement),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    CardListNotifier getNotifier() =>
        container.read(cardListNotifierProvider.notifier);

    CardListState getState() => container.read(cardListNotifierProvider);

    test('initial state has isSearching false', () {
      expect(getState().isSearching, isFalse);
    });

    test('toggleSearch toggles isSearching and clears search if false', () {
      final notifier = getNotifier();

      notifier.toggleSearch();
      expect(getState().isSearching, isTrue);

      notifier.toggleSearch();
      expect(getState().isSearching, isFalse);
      expect(testCardManagement.searchQueries, contains(''));
    });

    test('updateSearchQuery calls CardManagementNotifier', () {
      final notifier = getNotifier();
      notifier.updateSearchQuery('test');
      expect(testCardManagement.searchQueries, contains('test'));
    });

    test('deleteCard calls CardManagementNotifier', () async {
      final notifier = getNotifier();

      await notifier.deleteCard('123');
      expect(testCardManagement.deletedCardIds, contains('123'));
    });

    test('toggleFavorite calls CardManagementNotifier', () async {
      final notifier = getNotifier();

      await notifier.toggleFavorite('123');
      expect(testCardManagement.toggledFavoriteIds, contains('123'));
    });
  });
}
