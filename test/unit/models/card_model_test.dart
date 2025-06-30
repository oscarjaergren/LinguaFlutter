import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/models/card_model.dart';
import 'package:lingua_flutter/models/icon_model.dart';

void main() {
  group('CardModel', () {
    const testIcon = IconModel(
      id: 'mdi:heart',
      name: 'Heart',
      set: 'mdi',
      category: 'Emotions',
      tags: ['love'],
      svgUrl: 'https://api.iconify.design/mdi:heart.svg',
    );

    test('should create CardModel from factory constructor', () {
      final card = CardModel.create(
        frontText: 'Hello',
        backText: 'Hola',
        icon: testIcon,
        frontLanguage: 'en',
        backLanguage: 'es',
        category: 'Greetings',
        tags: ['basic', 'common'],
        difficulty: 2,
      );

      expect(card.frontText, 'Hello');
      expect(card.backText, 'Hola');
      expect(card.icon, testIcon);
      expect(card.frontLanguage, 'en');
      expect(card.backLanguage, 'es');
      expect(card.category, 'Greetings');
      expect(card.tags, ['basic', 'common']);
      expect(card.difficulty, 2);
      expect(card.reviewCount, 0);
      expect(card.correctCount, 0);
      expect(card.isFavorite, false);
      expect(card.isArchived, false);
      expect(card.id, isNotEmpty);
      expect(card.createdAt, isNotNull);
      expect(card.updatedAt, isNotNull);
    });

    test('should calculate success rate correctly', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        frontLanguage: 'en',
        backLanguage: 'es',
        category: 'Test',
      );

      // No reviews yet
      expect(card.successRate, 0.0);

      // 3 out of 5 correct
      final reviewedCard = card.copyWith(
        reviewCount: 5,
        correctCount: 3,
      );
      expect(reviewedCard.successRate, 60.0);

      // Perfect score
      final perfectCard = card.copyWith(
        reviewCount: 10,
        correctCount: 10,
      );
      expect(perfectCard.successRate, 100.0);
    });

    test('should determine mastery level correctly', () {
      final baseCard = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        frontLanguage: 'en',
        backLanguage: 'es',
        category: 'Test',
      );

      // New card (less than 3 reviews)
      expect(baseCard.masteryLevel, 'New');

      final cardWith2Reviews = baseCard.copyWith(reviewCount: 2, correctCount: 2);
      expect(cardWith2Reviews.masteryLevel, 'New');

      // Mastered (90%+ success rate with 3+ reviews)
      final masteredCard = baseCard.copyWith(reviewCount: 10, correctCount: 9);
      expect(masteredCard.masteryLevel, 'Mastered');

      // Good (70-89% success rate)
      final goodCard = baseCard.copyWith(reviewCount: 10, correctCount: 8);
      expect(goodCard.masteryLevel, 'Good');

      // Learning (50-69% success rate)
      final learningCard = baseCard.copyWith(reviewCount: 10, correctCount: 6);
      expect(learningCard.masteryLevel, 'Learning');

      // Difficult (less than 50% success rate)
      final difficultCard = baseCard.copyWith(reviewCount: 10, correctCount: 4);
      expect(difficultCard.masteryLevel, 'Difficult');
    });

    test('should determine if card is due for review', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        frontLanguage: 'en',
        backLanguage: 'es',
        category: 'Test',
      );

      // New card is due for review
      expect(card.isDueForReview, true);

      // Card with future review date is not due
      final futureCard = card.copyWith(
        nextReview: DateTime.now().add(const Duration(days: 1)),
      );
      expect(futureCard.isDueForReview, false);

      // Card with past review date is due
      final pastCard = card.copyWith(
        nextReview: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(pastCard.isDueForReview, true);
    });

    test('should copy with review correctly', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        frontLanguage: 'en',
        backLanguage: 'es',
        category: 'Test',
      );

      final nextReviewDate = DateTime.now().add(const Duration(days: 2));
      final reviewedCard = card.copyWithReview(
        wasCorrect: true,
        nextReviewDate: nextReviewDate,
      );

      expect(reviewedCard.reviewCount, 1);
      expect(reviewedCard.correctCount, 1);
      expect(reviewedCard.lastReviewed, isNotNull);
      expect(reviewedCard.nextReview, nextReviewDate);
      expect(reviewedCard.updatedAt.isAfter(card.updatedAt) || reviewedCard.updatedAt.isAtSameMomentAs(card.updatedAt), true);

      // Incorrect answer
      final incorrectCard = reviewedCard.copyWithReview(
        wasCorrect: false,
        nextReviewDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(incorrectCard.reviewCount, 2);
      expect(incorrectCard.correctCount, 1); // Still 1 correct
    });

    test('should convert to and from JSON', () {
      final card = CardModel.create(
        frontText: 'Hello',
        backText: 'Hola',
        frontLanguage: 'en',
        backLanguage: 'es',
        category: 'Greetings',
        tags: ['basic', 'common'],
        difficulty: 3,
      );

      final json = card.toJson();
      final reconstructedCard = CardModel.fromJson(json);

      expect(reconstructedCard.id, card.id);
      expect(reconstructedCard.frontText, card.frontText);
      expect(reconstructedCard.backText, card.backText);
      expect(reconstructedCard.frontLanguage, card.frontLanguage);
      expect(reconstructedCard.backLanguage, card.backLanguage);
      expect(reconstructedCard.category, card.category);
      expect(reconstructedCard.tags, card.tags);
      expect(reconstructedCard.difficulty, card.difficulty);
      expect(reconstructedCard.createdAt, card.createdAt);
      expect(reconstructedCard.updatedAt, card.updatedAt);
    });

    test('should handle equality correctly', () {
      final card1 = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        frontLanguage: 'en',
        backLanguage: 'es',
        category: 'Test',
      );

      final card2 = card1.copyWith(frontText: 'Different text');
      final card3 = CardModel.fromJson(card1.toJson());

      expect(card1 == card2, true); // Same ID, so should be equal
      expect(card1 == card3, true);  // Same ID
      expect(card1.hashCode, card3.hashCode);
    });

    test('should create copy with updated properties', () {
      final originalCard = CardModel.create(
        frontText: 'Original',
        backText: 'Original Back',
        frontLanguage: 'en',
        backLanguage: 'es',
        category: 'Original Category',
        difficulty: 1,
      );

      final updatedCard = originalCard.copyWith(
        frontText: 'Updated',
        backText: 'Updated Back',
        category: 'Updated Category',
        difficulty: 3,
        isFavorite: true,
      );

      expect(updatedCard.id, originalCard.id); // ID should remain same
      expect(updatedCard.frontText, 'Updated');
      expect(updatedCard.backText, 'Updated Back');
      expect(updatedCard.category, 'Updated Category');
      expect(updatedCard.difficulty, 3);
      expect(updatedCard.isFavorite, true);
      expect(updatedCard.frontLanguage, originalCard.frontLanguage); // Unchanged
      expect(updatedCard.backLanguage, originalCard.backLanguage); // Unchanged
    });
  });
}
