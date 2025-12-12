import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/icon_model.dart';

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

      expect(card.successRate, 70.0);
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
      
      final newCard = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );
      expect(newCard.isDue, true);

      final futureCard = newCard.copyWith(
        nextReview: now.add(const Duration(days: 1)),
      );
      expect(futureCard.isDue, false);

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
      expect(copied.backText, 'Original');
      expect(copied.isFavorite, true);
      expect(copied.id, original.id);
    });

    test('should return correct mastery level string', () {
      final newCard = CardModel.create(
        frontText: 'Test',
        backText: 'Test',
        language: 'de',
        category: 'Test',
      );
      expect(newCard.masteryLevel, 'New');

      final difficultCard = newCard.copyWith(reviewCount: 10, correctCount: 3);
      expect(difficultCard.masteryLevel, 'Difficult');

      final learningCard = newCard.copyWith(reviewCount: 10, correctCount: 5);
      expect(learningCard.masteryLevel, 'Learning');

      final goodCard = newCard.copyWith(reviewCount: 10, correctCount: 7);
      expect(goodCard.masteryLevel, 'Good');

      final masteredCard = newCard.copyWith(reviewCount: 10, correctCount: 9);
      expect(masteredCard.masteryLevel, 'Mastered');
    });
  });
}
