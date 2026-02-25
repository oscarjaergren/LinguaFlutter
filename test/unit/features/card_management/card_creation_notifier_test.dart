import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_management/presentation/view_models/card_creation_notifier.dart';
import 'package:lingua_flutter/features/card_management/presentation/view_models/card_creation_state.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/features/language/language.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';

class _TestCardManagementNotifier extends CardManagementNotifier {
  final List<CardModel> savedCards = [];
  final List<String> deletedCardIds = [];

  @override
  CardManagementState build() {
    return const CardManagementState();
  }

  @override
  Future<void> saveCard(CardModel card) async {
    savedCards.add(card);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    deletedCardIds.add(cardId);
  }
}

class _TestLanguageNotifier extends LanguageNotifier {
  @override
  LanguageState build() => const LanguageState(activeLanguage: 'de');
}

void main() {
  group('CardCreationNotifier', () {
    late _TestCardManagementNotifier testCardManagement;
    late _TestLanguageNotifier testLanguage;
    late ProviderContainer container;

    setUp(() {
      testCardManagement = _TestCardManagementNotifier();
      testLanguage = _TestLanguageNotifier();

      container = ProviderContainer(
        overrides: [
          cardManagementNotifierProvider.overrideWith(() => testCardManagement),
          languageNotifierProvider.overrideWith(() => testLanguage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    CardCreationNotifier getNotifier() =>
        container.read(cardCreationNotifierProvider.notifier);

    CardCreationState getState() =>
        container.read(cardCreationNotifierProvider);

    test('initial state is empty when no card is provided', () {
      final state = getState();
      expect(state.frontText, isEmpty);
      expect(state.backText, isEmpty);
      expect(state.isEditing, isFalse);
    });

    test('initial state is populated when card is loaded', () {
      final card = CardModel.create(
        frontText: 'Apfel',
        backText: 'Apple',
        language: 'de',
      ).copyWith(notes: 'A fruit');

      final notifier = getNotifier();
      notifier.loadCard(card);
      final state = getState();
      expect(state.frontText, 'Apfel');
      expect(state.backText, 'Apple');
      expect(state.notes, 'A fruit');
      expect(state.isEditing, isTrue);
    });

    test('updateFrontText updates the state', () {
      final notifier = getNotifier();
      notifier.updateFrontText('Haus');
      expect(getState().frontText, 'Haus');
    });

    test('updateBackText updates the state', () {
      final notifier = getNotifier();
      notifier.updateBackText('House');
      expect(getState().backText, 'House');
    });

    test('updateTags parses comma-separated tags', () {
      final notifier = getNotifier();
      notifier.updateTags('tag1, tag2 , tag3');
      expect(getState().tags, ['tag1', 'tag2', 'tag3']);
    });

    test('saveCard returns false if required fields are missing', () async {
      final notifier = getNotifier();
      final result = await notifier.saveCard();
      expect(result, isFalse);
      expect(getState().errorMessage, isNotNull);
      expect(testCardManagement.savedCards, isEmpty);
    });

    test('saveCard calls CardManagementNotifier for new card', () async {
      final notifier = getNotifier();
      notifier.updateFrontText('Auto');
      notifier.updateBackText('Car');

      final result = await notifier.saveCard();

      expect(result, isTrue);
      expect(testCardManagement.savedCards.length, 1);
    });

    test('deleteCard calls CardManagementNotifier for existing card', () async {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Test',
        language: 'de',
      );
      final notifier = getNotifier();
      notifier.loadCard(card);

      await notifier.deleteCard();

      expect(testCardManagement.deletedCardIds, contains(card.id));
    });
  });
}
