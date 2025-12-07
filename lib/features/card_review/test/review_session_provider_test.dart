import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/review_session_provider.dart';

void main() {
  group('ReviewSessionProvider', () {
    late ReviewSessionProvider provider;
    List<CardModel> updatedCards = [];

    setUp(() {
      updatedCards = [];
      provider = ReviewSessionProvider(
        updateCard: (card) async {
          updatedCards.add(card);
        },
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('should have initial state', () {
      expect(provider.sessionCards, isEmpty);
      expect(provider.currentIndex, 0);
      expect(provider.showingBack, false);
      expect(provider.isSessionActive, false);
      expect(provider.currentCard, isNull);
      expect(provider.progress, 0.0);
      expect(provider.cardsReviewed, 0);
      expect(provider.correctAnswers, 0);
      expect(provider.accuracy, 0.0);
    });

    test('should start session with cards', () {
      final cards = _createTestCards(3);

      provider.startSession(cards);

      expect(provider.isSessionActive, true);
      expect(provider.sessionCards.length, 3);
      expect(provider.currentIndex, 0);
      expect(provider.currentCard, cards[0]);
      expect(provider.progress, 1.0 / 3.0);
      expect(provider.sessionStartTime, isNotNull);
    });

    test('should end session', () {
      final cards = _createTestCards(2);
      provider.startSession(cards);

      provider.endSession();

      expect(provider.isSessionActive, false);
      expect(provider.sessionCards, isEmpty);
      expect(provider.currentIndex, 0);
      expect(provider.currentCard, isNull);
      expect(provider.progress, 0.0);
    });

    test('should flip card', () {
      final cards = _createTestCards(1);
      provider.startSession(cards);

      expect(provider.showingBack, false);

      provider.flipCard();

      expect(provider.showingBack, true);
    });

    test('should not flip when already showing back', () {
      final cards = _createTestCards(1);
      provider.startSession(cards);
      provider.flipCard();

      provider.flipCard(); // Try to flip again

      expect(provider.showingBack, true);
    });

    test('should navigate to next card', () {
      final cards = _createTestCards(3);
      provider.startSession(cards);

      expect(provider.currentCard, cards[0]);
      expect(provider.hasNextCard, true);

      provider.nextCard();

      expect(provider.currentCard, cards[1]);
      expect(provider.currentIndex, 1);
      expect(provider.showingBack, false);
    });

    test('should navigate to previous card', () {
      final cards = _createTestCards(3);
      provider.startSession(cards);
      provider.nextCard();

      expect(provider.currentCard, cards[1]);
      expect(provider.hasPreviousCard, true);

      provider.previousCard();

      expect(provider.currentCard, cards[0]);
      expect(provider.currentIndex, 0);
    });

    test('should not navigate past last card', () {
      final cards = _createTestCards(2);
      provider.startSession(cards);
      provider.nextCard();

      expect(provider.hasNextCard, false);

      provider.nextCard(); // Try to go past last

      expect(provider.currentIndex, 1);
    });

    test('should not navigate before first card', () {
      final cards = _createTestCards(2);
      provider.startSession(cards);

      expect(provider.hasPreviousCard, false);

      provider.previousCard(); // Try to go before first

      expect(provider.currentIndex, 0);
    });

    test('should answer card correctly', () async {
      final cards = _createTestCards(2);
      provider.startSession(cards);

      await provider.answerCard(CardAnswer.correct);

      expect(provider.cardsReviewed, 1);
      expect(provider.correctAnswers, 1);
      expect(provider.accuracy, 1.0);
      expect(updatedCards.length, 1);
    });

    test('should answer card incorrectly', () async {
      final cards = _createTestCards(2);
      provider.startSession(cards);

      await provider.answerCard(CardAnswer.incorrect);

      expect(provider.cardsReviewed, 1);
      expect(provider.correctAnswers, 0);
      expect(provider.accuracy, 0.0);
    });

    test('should move to next card after answer', () async {
      final cards = _createTestCards(3);
      provider.startSession(cards);

      await provider.answerCard(CardAnswer.correct);

      expect(provider.currentIndex, 1);
      expect(provider.currentCard, cards[1]);
    });

    test('should end session after last card answered', () async {
      final cards = _createTestCards(1);
      provider.startSession(cards);

      await provider.answerCard(CardAnswer.correct);

      expect(provider.isSessionActive, false);
    });

    test('should calculate progress correctly', () {
      final cards = _createTestCards(4);
      provider.startSession(cards);

      expect(provider.progress, 0.25); // 1/4

      provider.nextCard();
      expect(provider.progress, 0.5); // 2/4

      provider.nextCard();
      expect(provider.progress, 0.75); // 3/4

      provider.nextCard();
      expect(provider.progress, 1.0); // 4/4
    });

    test('should reset card view', () {
      final cards = _createTestCards(1);
      provider.startSession(cards);
      provider.flipCard();

      expect(provider.showingBack, true);

      provider.resetCardView();

      expect(provider.showingBack, false);
    });

    test('should provide session stats', () async {
      final cards = _createTestCards(3);
      provider.startSession(cards);

      await provider.answerCard(CardAnswer.correct);
      await provider.answerCard(CardAnswer.incorrect);

      final stats = provider.sessionStats;

      expect(stats['totalCards'], 3);
      expect(stats['cardsReviewed'], 2);
      expect(stats['correctAnswers'], 1);
      expect(stats['accuracy'], 0.5);
      expect(stats['isComplete'], false);
    });

    test('should track session duration', () async {
      final cards = _createTestCards(1);
      provider.startSession(cards);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.sessionDuration.inMilliseconds, greaterThan(0));
    });
  });
}

/// Helper to create test cards
List<CardModel> _createTestCards(int count) {
  return List.generate(
    count,
    (i) => CardModel.create(
      frontText: 'Front $i',
      backText: 'Back $i',
      language: 'es',
      category: 'Test',
    ),
  );
}
