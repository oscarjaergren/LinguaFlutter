import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_session_provider.dart';

void main() {
  group('ExerciseSessionProvider', () {
    late ExerciseSessionProvider provider;
    late List<CardModel> reviewCards;
    late List<CardModel> allCards;
    List<CardModel> updatedCards = [];

    setUp(() {
      reviewCards = _createTestCards(3);
      allCards = _createTestCards(10);
      updatedCards = [];
      
      provider = ExerciseSessionProvider(
        getReviewCards: () => reviewCards,
        getAllCards: () => allCards,
        updateCard: (card) async {
          updatedCards.add(card);
        },
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('should have initial state', () {
      expect(provider.sessionQueue, isEmpty);
      expect(provider.currentIndex, 0);
      expect(provider.isSessionActive, false);
      expect(provider.currentExercise, isNull);
      expect(provider.currentCard, isNull);
      expect(provider.currentExerciseType, isNull);
      expect(provider.correctCount, 0);
      expect(provider.incorrectCount, 0);
      expect(provider.progress, 0.0);
    });

    test('should start session with review cards', () {
      provider.startSession();

      expect(provider.isSessionActive, true);
      expect(provider.sessionQueue, isNotEmpty);
      expect(provider.currentExercise, isNotNull);
      expect(provider.sessionStartTime, isNotNull);
    });

    test('should start session with provided cards', () {
      final customCards = _createTestCards(2);
      
      provider.startSession(cards: customCards);

      expect(provider.isSessionActive, true);
      expect(provider.sessionQueue, isNotEmpty);
    });

    test('should end session', () {
      provider.startSession();

      provider.endSession();

      expect(provider.isSessionActive, false);
      expect(provider.sessionQueue, isEmpty);
      expect(provider.currentExercise, isNull);
    });

    test('should show answer', () {
      provider.startSession();

      expect(provider.isAnswerShown, false);

      provider.showAnswer();

      expect(provider.isAnswerShown, true);
    });

    test('should submit correct answer', () async {
      provider.startSession();
      final initialIndex = provider.currentIndex;

      await provider.submitAnswer(isCorrect: true);

      expect(provider.correctCount, 1);
      expect(provider.incorrectCount, 0);
      expect(updatedCards.length, 1);
      
      // Should move to next exercise or end
      if (provider.sessionQueue.length > 1) {
        expect(provider.currentIndex, initialIndex + 1);
      }
    });

    test('should submit incorrect answer', () async {
      provider.startSession();

      await provider.submitAnswer(isCorrect: false);

      expect(provider.correctCount, 0);
      expect(provider.incorrectCount, 1);
    });

    test('should calculate session accuracy', () async {
      provider.startSession();

      await provider.submitAnswer(isCorrect: true);
      await provider.submitAnswer(isCorrect: false);

      expect(provider.sessionAccuracy, 0.5);
    });

    test('should skip exercise', () {
      provider.startSession();
      final initialIndex = provider.currentIndex;

      provider.skipExercise();

      if (provider.sessionQueue.length > 1) {
        expect(provider.currentIndex, initialIndex + 1);
        expect(provider.isAnswerShown, false);
      }
    });

    test('should track remaining count', () {
      provider.startSession();
      final total = provider.totalCount;

      expect(provider.remainingCount, total - 1);

      provider.skipExercise();

      if (total > 1) {
        expect(provider.remainingCount, total - 2);
      }
    });

    test('should calculate progress', () {
      provider.startSession();
      final total = provider.totalCount;

      expect(provider.progress, 1.0 / total);
    });

    test('should restart session', () async {
      provider.startSession();
      
      await provider.submitAnswer(isCorrect: true);
      
      provider.restartSession();

      expect(provider.isSessionActive, true);
      expect(provider.currentIndex, 0);
      expect(provider.correctCount, 0);
      expect(provider.incorrectCount, 0);
    });
  });

  group('ExerciseItem', () {
    test('should create exercise item', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );

      final item = ExerciseItem(
        card: card,
        exerciseType: ExerciseType.readingRecognition,
      );

      expect(item.card, card);
      expect(item.exerciseType, ExerciseType.readingRecognition);
    });

    test('should implement equality', () {
      final card = CardModel.create(
        frontText: 'Test',
        backText: 'Prueba',
        language: 'es',
        category: 'Test',
      );

      final item1 = ExerciseItem(
        card: card,
        exerciseType: ExerciseType.readingRecognition,
      );

      final item2 = ExerciseItem(
        card: card,
        exerciseType: ExerciseType.readingRecognition,
      );

      final item3 = ExerciseItem(
        card: card,
        exerciseType: ExerciseType.writingTranslation,
      );

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
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
