import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/features/duplicate_detection/domain/duplicate_detection_provider.dart';

void main() {
  group('DuplicateDetectionProvider', () {
    late DuplicateDetectionProvider provider;

    setUp(() {
      provider = DuplicateDetectionProvider();
    });

    test('should have initial state', () {
      expect(provider.duplicateMap, isEmpty);
      expect(provider.isAnalyzing, false);
      expect(provider.duplicateCount, 0);
      expect(provider.cardIdsWithDuplicates, isEmpty);
    });

    test('should detect exact duplicates', () {
      final cards = [
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
      ];

      provider.analyzeCards(cards);

      expect(provider.duplicateCount, 2); // Both cards have duplicates
      expect(provider.cardHasDuplicates(cards[0].id), true);
      expect(provider.cardHasDuplicates(cards[1].id), true);
    });

    test('should not detect duplicates for unique cards', () {
      final cards = [
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
        CardModel.create(
          frontText: 'Goodbye',
          backText: 'Adiós',
          language: 'es',
        ),
      ];

      provider.analyzeCards(cards);

      expect(provider.duplicateCount, 0);
      expect(provider.cardHasDuplicates(cards[0].id), false);
    });

    test('should get duplicates for specific card', () {
      final cards = [
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
      ];

      provider.analyzeCards(cards);

      final duplicates = provider.getDuplicatesForCard(cards[0].id);
      expect(duplicates, isNotEmpty);
      expect(duplicates.first.duplicateCard.id, cards[1].id);
    });

    test('should return empty list for card without duplicates', () {
      final duplicates = provider.getDuplicatesForCard('non-existent-id');
      expect(duplicates, isEmpty);
    });

    test('should clear duplicate data', () {
      final cards = [
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
      ];

      provider.analyzeCards(cards);
      expect(provider.duplicateCount, greaterThan(0));

      provider.clear();

      expect(provider.duplicateCount, 0);
      expect(provider.duplicateMap, isEmpty);
    });

    test('should filter cards with duplicates', () {
      final cards = [
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
        CardModel.create(
          frontText: 'Unique',
          backText: 'Único',
          language: 'es',
        ),
      ];

      provider.analyzeCards(cards);

      final cardsWithDuplicates = provider.filterCardsWithDuplicates(cards);
      expect(cardsWithDuplicates.length, 2);
      expect(cardsWithDuplicates.any((c) => c.frontText == 'Unique'), false);
    });

    test('should analyze cards for specific language', () {
      final cards = [
        CardModel.create(frontText: 'Hello', backText: 'Hola', language: 'es'),
        CardModel.create(frontText: 'Hello', backText: 'Hallo', language: 'de'),
      ];

      provider.analyzeCardsForLanguage(cards, 'es');

      // Only Spanish cards analyzed, so no duplicates found
      expect(provider.duplicateCount, 0);
    });

    test('should notify listeners during analysis', () {
      var notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      final cards = [
        CardModel.create(frontText: 'Test', backText: 'Prueba', language: 'es'),
      ];

      provider.analyzeCards(cards);

      // Should notify at start (isAnalyzing = true) and end (isAnalyzing = false)
      expect(notificationCount, 2);
    });
  });
}
