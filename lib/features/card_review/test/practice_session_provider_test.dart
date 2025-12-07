import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';

void main() {
  group('PracticeSessionProvider', () {
    late PracticeSessionProvider provider;
    late List<CardModel> testCards;
    late List<CardModel> updatedCards;

    CardModel createTestCard({
      required String id,
      required String frontText,
      required String backText,
      int reviewCount = 0,
      int correctCount = 0,
    }) {
      return CardModel(
        id: id,
        frontText: frontText,
        backText: backText,
        language: 'de',
        category: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reviewCount: reviewCount,
        correctCount: correctCount,
      );
    }

    setUp(() {
      testCards = [
        createTestCard(id: '1', frontText: 'Hallo', backText: 'Hello'),
        createTestCard(id: '2', frontText: 'Welt', backText: 'World'),
        createTestCard(id: '3', frontText: 'Danke', backText: 'Thanks'),
      ];
      updatedCards = [];

      provider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => testCards,
        updateCard: (card) async {
          updatedCards.add(card);
        },
      );
    });

    group('Session Management', () {
      test('should start with inactive session', () {
        expect(provider.isSessionActive, false);
        expect(provider.currentCard, isNull);
        expect(provider.currentExerciseType, isNull);
        expect(provider.totalCount, 0);
      });

      test('should start session with cards', () {
        provider.startSession();

        expect(provider.isSessionActive, true);
        expect(provider.currentCard, isNotNull);
        expect(provider.currentExerciseType, isNotNull);
        expect(provider.totalCount, greaterThan(0));
        expect(provider.currentIndex, 0);
        expect(provider.sessionStartTime, isNotNull);
      });

      test('should start session with custom cards', () {
        final customCards = [
          createTestCard(id: 'custom1', frontText: 'Test', backText: 'Test'),
        ];

        provider.startSession(cards: customCards);

        expect(provider.isSessionActive, true);
        expect(provider.currentCard?.id, 'custom1');
      });

      test('should not start session with empty cards', () {
        provider = PracticeSessionProvider(
          getReviewCards: () => [],
          getAllCards: () => [],
          updateCard: (card) async {},
        );

        provider.startSession();

        expect(provider.isSessionActive, false);
      });

      test('should end session correctly', () {
        provider.startSession();
        expect(provider.isSessionActive, true);

        provider.endSession();

        expect(provider.isSessionActive, false);
        expect(provider.currentCard, isNull);
        expect(provider.totalCount, 0);
      });

      test('should restart session', () {
        provider.startSession();
        provider.endSession();

        provider.restartSession();

        expect(provider.isSessionActive, true);
        expect(provider.currentIndex, 0);
        expect(provider.correctCount, 0);
        expect(provider.incorrectCount, 0);
      });
    });

    group('Progress Tracking', () {
      test('should calculate progress correctly', () async {
        provider.startSession();
        final total = provider.totalCount;

        expect(provider.progress, 1 / total);

        // Simulate advancing
        provider.checkAnswer(isCorrect: true);
        await provider.confirmAnswerAndAdvance(markedCorrect: true);

        // Progress should increase (if not last card)
        if (total > 1) {
          expect(provider.progress, 2 / total);
        }
      });

      test('should track remaining count', () {
        provider.startSession();
        final total = provider.totalCount;

        expect(provider.remainingCount, total - 1);
      });

      test('should calculate accuracy correctly', () async {
        provider.startSession();

        expect(provider.accuracy, 0.0);

        provider.checkAnswer(isCorrect: true);
        await provider.confirmAnswerAndAdvance(markedCorrect: true);

        expect(provider.accuracy, 1.0);

        if (provider.isSessionActive) {
          provider.checkAnswer(isCorrect: false);
          await provider.confirmAnswerAndAdvance(markedCorrect: false);

          expect(provider.accuracy, 0.5);
        }
      });

      test('should track session duration', () {
        provider.startSession();

        expect(provider.sessionDuration, isA<Duration>());
        expect(provider.sessionDuration.inMilliseconds, greaterThanOrEqualTo(0));
      });
    });

    group('Answer Handling', () {
      test('should start with pending answer state', () {
        provider.startSession();

        expect(provider.answerState, AnswerState.pending);
        expect(provider.currentAnswerCorrect, isNull);
        expect(provider.canSwipe, false);
      });

      test('should transition to answered state on check', () {
        provider.startSession();

        provider.checkAnswer(isCorrect: true);

        expect(provider.answerState, AnswerState.answered);
        expect(provider.currentAnswerCorrect, true);
        expect(provider.canSwipe, true);
      });

      test('should allow answer override', () {
        provider.startSession();
        provider.checkAnswer(isCorrect: true);

        provider.overrideAnswer(isCorrect: false);

        expect(provider.currentAnswerCorrect, false);
      });

      test('should advance on confirm and update card', () async {
        provider.startSession();
        final initialIndex = provider.currentIndex;
        final initialCard = provider.currentCard;

        provider.checkAnswer(isCorrect: true);
        await provider.confirmAnswerAndAdvance(markedCorrect: true);

        // Card should be updated
        expect(updatedCards.length, 1);
        expect(updatedCards.first.id, initialCard?.id);

        // Should advance or end session
        if (provider.totalCount > 1) {
          expect(provider.currentIndex, initialIndex + 1);
          expect(provider.answerState, AnswerState.pending);
        }
      });

      test('should increment correct count on correct answer', () async {
        provider.startSession();

        provider.checkAnswer(isCorrect: true);
        await provider.confirmAnswerAndAdvance(markedCorrect: true);

        expect(provider.correctCount, 1);
        expect(provider.incorrectCount, 0);
      });

      test('should increment incorrect count on incorrect answer', () async {
        provider.startSession();

        provider.checkAnswer(isCorrect: false);
        await provider.confirmAnswerAndAdvance(markedCorrect: false);

        expect(provider.correctCount, 0);
        expect(provider.incorrectCount, 1);
      });

      test('should end session after last card', () async {
        // Create provider with single card
        provider = PracticeSessionProvider(
          getReviewCards: () => [testCards.first],
          getAllCards: () => [testCards.first],
          updateCard: (card) async {},
        );

        provider.startSession();
        provider.checkAnswer(isCorrect: true);
        await provider.confirmAnswerAndAdvance(markedCorrect: true);

        expect(provider.isSessionActive, false);
      });
    });

    group('Skip Functionality', () {
      test('should skip to next exercise', () {
        provider.startSession();
        final initialIndex = provider.currentIndex;

        provider.skipExercise();

        if (provider.totalCount > 1) {
          expect(provider.currentIndex, initialIndex + 1);
        }
      });

      test('should end session on skip of last card', () {
        provider = PracticeSessionProvider(
          getReviewCards: () => [testCards.first],
          getAllCards: () => [testCards.first],
          updateCard: (card) async {},
        );

        provider.startSession();
        provider.skipExercise();

        expect(provider.isSessionActive, false);
      });
    });

    group('Multiple Choice Options', () {
      test('should generate options for multiple choice exercises', () {
        provider.startSession();

        // Find a multiple choice exercise or force one
        while (provider.isSessionActive &&
            provider.currentExerciseType != ExerciseType.multipleChoiceText) {
          provider.skipExercise();
        }

        if (provider.isSessionActive &&
            provider.currentExerciseType == ExerciseType.multipleChoiceText) {
          expect(provider.multipleChoiceOptions, isNotNull);
          expect(provider.multipleChoiceOptions!.length, greaterThan(0));
          // Should contain the correct answer
          expect(
            provider.multipleChoiceOptions!.contains(provider.currentCard!.backText),
            true,
          );
        }
      });

      test('should clear options for non-multiple-choice exercises', () {
        provider.startSession();

        // Skip to a non-multiple-choice exercise
        while (provider.isSessionActive &&
            (provider.currentExerciseType == ExerciseType.multipleChoiceText ||
                provider.currentExerciseType == ExerciseType.multipleChoiceIcon)) {
          provider.skipExercise();
        }

        if (provider.isSessionActive) {
          expect(provider.multipleChoiceOptions, isNull);
        }
      });
    });

    group('User Input', () {
      test('should update user input', () {
        provider.startSession();

        provider.updateUserInput('test input');

        expect(provider.userInput, 'test input');
      });

      test('should clear user input on advance', () async {
        provider.startSession();
        provider.updateUserInput('test input');

        provider.checkAnswer(isCorrect: true);
        await provider.confirmAnswerAndAdvance(markedCorrect: true);

        if (provider.isSessionActive) {
          expect(provider.userInput, isNull);
        }
      });
    });

    group('Session Statistics', () {
      test('should provide session stats', () async {
        provider.startSession();

        provider.checkAnswer(isCorrect: true);
        await provider.confirmAnswerAndAdvance(markedCorrect: true);

        final stats = provider.sessionStats;

        expect(stats['totalCards'], isA<int>());
        expect(stats['completed'], 1);
        expect(stats['correctCount'], 1);
        expect(stats['incorrectCount'], 0);
        expect(stats['accuracy'], 1.0);
        expect(stats['duration'], isA<Duration>());
      });
    });

    group('Exercise Type Filtering', () {
      test('should not include icon exercises for cards without icons', () {
        // All test cards have no icons
        provider.startSession();

        // Check that no multipleChoiceIcon exercises are in the queue
        for (final item in provider.sessionQueue) {
          expect(item.exerciseType, isNot(ExerciseType.multipleChoiceIcon));
        }
      });
    });

    group('ChangeNotifier', () {
      test('should notify listeners on session start', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.startSession();

        expect(notified, true);
      });

      test('should notify listeners on check answer', () {
        provider.startSession();

        var notified = false;
        provider.addListener(() => notified = true);

        provider.checkAnswer(isCorrect: true);

        expect(notified, true);
      });

      test('should notify listeners on session end', () {
        provider.startSession();

        var notified = false;
        provider.addListener(() => notified = true);

        provider.endSession();

        expect(notified, true);
      });
    });
  });

  group('PracticeItem', () {
    test('should have correct equality', () {
      final card = CardModel(
        id: 'test',
        frontText: 'Test',
        backText: 'Test',
        language: 'de',
        category: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item1 = PracticeItem(card: card, exerciseType: ExerciseType.readingRecognition);
      final item2 = PracticeItem(card: card, exerciseType: ExerciseType.readingRecognition);
      final item3 = PracticeItem(card: card, exerciseType: ExerciseType.writingTranslation);

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });

    test('should have correct hashCode', () {
      final card = CardModel(
        id: 'test',
        frontText: 'Test',
        backText: 'Test',
        language: 'de',
        category: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item1 = PracticeItem(card: card, exerciseType: ExerciseType.readingRecognition);
      final item2 = PracticeItem(card: card, exerciseType: ExerciseType.readingRecognition);

      expect(item1.hashCode, equals(item2.hashCode));
    });
  });

  group('AnswerState', () {
    test('should have correct values', () {
      expect(AnswerState.values.length, 2);
      expect(AnswerState.pending.index, 0);
      expect(AnswerState.answered.index, 1);
    });
  });
}
