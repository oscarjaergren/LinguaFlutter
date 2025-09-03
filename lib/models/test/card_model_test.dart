import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/models/card_model.dart';
import 'package:lingua_flutter/models/icon_model.dart';

void main() {
  group('CardModel', () {
    test('should create card with required fields', () {
      final card = CardModel.create(
        frontText: 'Hello',
        backText: 'Hola',
        language: 'es',
        category: 'Greetings',
      );

      expect(card.frontText, 'Hello');
      expect(card.backText, 'Hola');
      expect(card.language, 'es');
      expect(card.category, 'Greetings');
      expect(card.tags, isEmpty);
      expect(card.icon, isNull);
      expect(card.germanArticle, isNull);
      expect(card.isFavorite, false);
      expect(card.isArchived, false);
      expect(card.difficulty, 0);
      expect(card.reviewCount, 0);
      expect(card.correctCount, 0);
      expect(card.lastReviewed, isNull);
      expect(card.nextReview, isNull);
      expect(card.createdAt, isA<DateTime>());
      expect(card.updatedAt, isA<DateTime>());
    });

    test('should create card with all fields', () {
      final icon = IconModel(
        id: 'mdi:home',
        name: 'Home',
        set: 'mdi',
        category: 'Actions',
        tags: [],
        svgUrl: 'https://api.iconify.design/mdi:home.svg',
      );

      final card = CardModel(
        id: 'test-id',
        frontText: 'das Haus',
        backText: 'the house',
        language: 'de',
        category: 'Vocabulary',
        tags: ['building', 'home'],
        icon: icon,
        germanArticle: 'das',
        isFavorite: true,
        difficulty: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(card.frontText, 'das Haus');
      expect(card.backText, 'the house');
      expect(card.language, 'de');
      expect(card.category, 'Vocabulary');
      expect(card.tags, ['building', 'home']);
      expect(card.icon, icon);
      expect(card.germanArticle, 'das');
      expect(card.isFavorite, true);
      expect(card.difficulty, 2);
    });

    test('should calculate success rate correctly', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      ).copyWith(
        reviewCount: 10,
        correctCount: 7,
      );

      expect(card.successRate, 0.7);
    });

    test('should return 0 success rate when no reviews', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );

      expect(card.successRate, 0.0);
    });

    test('should determine if card is due for review', () {
      final now = DateTime.now();
      
      // Card with no next review date should be due
      final newCard = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );
      expect(newCard.isDue, true);

      // Card with future next review date should not be due
      final futureCard = newCard.copyWith(
        nextReview: now.add(const Duration(days: 1)),
      );
      expect(futureCard.isDue, false);

      // Card with past next review date should be due
      final pastCard = newCard.copyWith(
        nextReview: now.subtract(const Duration(days: 1)),
      );
      expect(pastCard.isDue, true);
    });

    test('should process correct answer', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );

      final updatedCard = card.processAnswer(CardAnswer.correct);

      expect(updatedCard.reviewCount, card.reviewCount + 1);
      expect(updatedCard.correctCount, card.correctCount + 1);
      expect(updatedCard.lastReviewed, isA<DateTime>());
      expect(updatedCard.nextReview, isA<DateTime>());
      expect(updatedCard.nextReview!.isAfter(DateTime.now()), true);
    });

    test('should process incorrect answer', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );

      final updatedCard = card.processAnswer(CardAnswer.incorrect);

      expect(updatedCard.reviewCount, card.reviewCount + 1);
      expect(updatedCard.correctCount, card.correctCount);
      expect(updatedCard.lastReviewed, isA<DateTime>());
      expect(updatedCard.nextReview, isA<DateTime>());
      // Incorrect answers should have shorter intervals
    });

    test('should process partial answer', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );

      final updatedCard = card.processAnswer(CardAnswer.skip);

      expect(updatedCard.reviewCount, card.reviewCount + 1);
      expect(updatedCard.correctCount, card.correctCount);
      expect(updatedCard.lastReviewed, isA<DateTime>());
      expect(updatedCard.nextReview, isA<DateTime>());
    });

    test('should serialize to and from JSON', () {
      final original = CardModel.create(
        frontText: 'Hello',
        backText: 'Hola',
        language: 'es',
        category: 'Greetings',
        tags: ['greeting', 'basic'],
      );

      final json = original.toJson();
      final deserialized = CardModel.fromJson(json);

      expect(deserialized.frontText, original.frontText);
      expect(deserialized.backText, original.backText);
      expect(deserialized.language, original.language);
      expect(deserialized.category, original.category);
      expect(deserialized.tags, original.tags);
      expect(deserialized.id, original.id);
    });

    test('should handle equality correctly', () {
      final card1 = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );

      final card2 = card1.copyWith();
      final card3 = CardModel.create(
        frontText: 'Different',
        backText: 'Diferente',
        language: 'es',
        category: 'Test',
      );

      expect(card1, equals(card2));
      expect(card1, isNot(equals(card3)));
    });

    test('should copy with new values', () {
      final original = CardModel.create(
        frontText: 'Original',
        backText: 'Original',
        language: 'es',
        category: 'Test',
      );

      final copied = original.copyWith(
        frontText: 'Updated',
        isFavorite: true,
      );

      expect(copied.frontText, 'Updated');
      expect(copied.backText, 'Original'); // Unchanged
      expect(copied.isFavorite, true);
      expect(copied.id, original.id); // ID should remain the same
    });
  });
}
