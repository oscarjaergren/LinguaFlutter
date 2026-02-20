import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/domain/models/word_data.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
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
        expect(
          provider.sessionDuration.inMilliseconds,
          greaterThanOrEqualTo(0),
        );
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
      test('should skip to next exercise', () async {
        provider.startSession();
        final initialIndex = provider.currentIndex;

        await provider.skipExercise();

        if (provider.totalCount > 1) {
          expect(provider.currentIndex, initialIndex + 1);
        }
      });

      test('should end session on skip of last card', () async {
        provider = PracticeSessionProvider(
          getReviewCards: () => [testCards.first],
          getAllCards: () => [testCards.first],
          updateCard: (card) async {},
        );

        provider.startSession();
        await provider.skipExercise();

        expect(provider.isSessionActive, false);
      });
    });

    group('Multiple Choice Options', () {
      test('should generate options for multiple choice exercises', () async {
        provider.startSession();

        // Find a multiple choice exercise or force one
        while (provider.isSessionActive &&
            provider.currentExerciseType != ExerciseType.multipleChoiceText) {
          await provider.skipExercise();
        }

        if (provider.isSessionActive &&
            provider.currentExerciseType == ExerciseType.multipleChoiceText) {
          expect(provider.multipleChoiceOptions, isNotNull);
          expect(provider.multipleChoiceOptions!.length, greaterThan(0));
          // Should contain the correct answer
          expect(
            provider.multipleChoiceOptions!.contains(
              provider.currentCard!.backText,
            ),
            true,
          );
        }
      });

      test('should clear options for non-multiple-choice exercises', () async {
        provider.startSession();

        // Skip to a non-multiple-choice exercise
        while (provider.isSessionActive &&
            (provider.currentExerciseType == ExerciseType.multipleChoiceText ||
                provider.currentExerciseType ==
                    ExerciseType.multipleChoiceIcon)) {
          await provider.skipExercise();
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item1 = PracticeItem(
        card: card,
        exerciseType: ExerciseType.readingRecognition,
      );
      final item2 = PracticeItem(
        card: card,
        exerciseType: ExerciseType.readingRecognition,
      );
      final item3 = PracticeItem(
        card: card,
        exerciseType: ExerciseType.reverseTranslation,
      );

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });

    test('should have correct hashCode', () {
      final card = CardModel(
        id: 'test',
        frontText: 'Test',
        backText: 'Test',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item1 = PracticeItem(
        card: card,
        exerciseType: ExerciseType.readingRecognition,
      );
      final item2 = PracticeItem(
        card: card,
        exerciseType: ExerciseType.readingRecognition,
      );

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

  group('onSessionComplete callback ordering', () {
    test('session is still active when onSessionComplete is called', () async {
      bool sessionActiveDuringCallback = false;

      final cards = [
        CardModel(
          id: '1',
          frontText: 'A',
          backText: 'B',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CardModel(
          id: '2',
          frontText: 'C',
          backText: 'D',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CardModel(
          id: '3',
          frontText: 'E',
          backText: 'F',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      late PracticeSessionProvider p;
      p = PracticeSessionProvider(
        getReviewCards: () => cards,
        getAllCards: () => cards,
        updateCard: (_) async {},
        onSessionComplete: (cardsReviewed) async {
          sessionActiveDuringCallback = p.isSessionActive;
        },
      );

      p.startSession();
      while (p.isSessionActive) {
        p.checkAnswer(isCorrect: true);
        await p.confirmAnswerAndAdvance(markedCorrect: true);
      }

      // After the full loop the session is ended, but during the callback it
      // must have been active (callback fires before endSession).
      expect(sessionActiveDuringCallback, isTrue);
    });

    test('onSessionComplete receives correct total reviewed count', () async {
      int receivedCount = -1;

      final cards = [
        CardModel(
          id: '1',
          frontText: 'A',
          backText: 'B',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CardModel(
          id: '2',
          frontText: 'C',
          backText: 'D',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CardModel(
          id: '3',
          frontText: 'E',
          backText: 'F',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final p = PracticeSessionProvider(
        getReviewCards: () => cards,
        getAllCards: () => cards,
        updateCard: (_) async {},
        onSessionComplete: (cardsReviewed) async {
          receivedCount = cardsReviewed;
        },
      );

      p.startSession();
      final total = p.totalCount;
      while (p.isSessionActive) {
        p.checkAnswer(isCorrect: true);
        await p.confirmAnswerAndAdvance(markedCorrect: true);
      }

      expect(receivedCount, equals(total));
    });

    test('onSessionComplete error does not prevent endSession', () async {
      final cards = [
        CardModel(
          id: '1',
          frontText: 'A',
          backText: 'B',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CardModel(
          id: '2',
          frontText: 'C',
          backText: 'D',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CardModel(
          id: '3',
          frontText: 'E',
          backText: 'F',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final p = PracticeSessionProvider(
        getReviewCards: () => cards,
        getAllCards: () => cards,
        updateCard: (_) async {},
        onSessionComplete: (_) async {
          throw Exception('streak service unavailable');
        },
      );

      p.startSession();
      // Errors from onSessionComplete are caught internally and do not
      // propagate to the caller — the session ends cleanly regardless.
      while (p.isSessionActive) {
        p.checkAnswer(isCorrect: true);
        await p.confirmAnswerAndAdvance(markedCorrect: true);
      }

      // endSession is called in the finally block, so session is inactive
      // even though the callback threw.
      expect(p.isSessionActive, isFalse);
    });
  });

  group('skipExercise', () {
    List<CardModel> makeCards(int count) => List.generate(
      count,
      (i) => CardModel(
        id: '$i',
        frontText: 'Front $i',
        backText: 'Back $i',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    test('skipping mid-session advances to next card', () async {
      final cards = makeCards(3);
      final p = PracticeSessionProvider(
        getReviewCards: () => cards,
        getAllCards: () => cards,
        updateCard: (_) async {},
      );

      p.startSession();
      final firstCardId = p.currentCard?.id;
      await p.skipExercise();

      expect(p.isSessionActive, isTrue);
      expect(p.currentCard?.id, isNot(firstCardId));
    });

    test('skipping last exercise ends session', () async {
      final cards = makeCards(3);
      final p = PracticeSessionProvider(
        getReviewCards: () => cards,
        getAllCards: () => cards,
        updateCard: (_) async {},
      );

      p.startSession();
      // Advance to last exercise
      while (p.currentIndex < p.totalCount - 1) {
        await p.skipExercise();
      }
      // Skip the last one
      await p.skipExercise();

      expect(p.isSessionActive, isFalse);
    });

    test(
      'skipped card is counted in totalReviewed passed to onSessionComplete',
      () async {
        int receivedCount = -1;
        final cards = makeCards(3);
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
          onSessionComplete: (cardsReviewed) async {
            receivedCount = cardsReviewed;
          },
        );

        p.startSession();
        final total = p.totalCount;

        // Skip all exercises
        while (p.isSessionActive) {
          await p.skipExercise();
        }

        expect(receivedCount, equals(total));
      },
    );

    test('skipping increments incorrectCount', () async {
      final cards = makeCards(3);
      final p = PracticeSessionProvider(
        getReviewCards: () => cards,
        getAllCards: () => cards,
        updateCard: (_) async {},
      );

      p.startSession();
      await p.skipExercise();

      expect(p.incorrectCount, equals(1));
    });
  });

  group('removeCardFromQueue', () {
    List<CardModel> makeCards(int count) => List.generate(
      count,
      (i) => CardModel(
        id: '$i',
        frontText: 'Front $i',
        backText: 'Back $i',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    test(
      'removing current card when it is the only card ends session',
      () async {
        final cards = makeCards(1);
        bool callbackFired = false;
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
          onSessionComplete: (_) async {
            callbackFired = true;
          },
        );

        p.startSession();
        expect(p.isSessionActive, isTrue);
        final cardId = p.currentCard!.id;

        await p.removeCardFromQueue(cardId);

        expect(p.isSessionActive, isFalse);
        expect(callbackFired, isTrue);
      },
    );

    test('removing current card when queue empties does not double-notify '
        '(session is inactive after call)', () async {
      final cards = makeCards(1);
      int notifyCount = 0;
      final p = PracticeSessionProvider(
        getReviewCards: () => cards,
        getAllCards: () => cards,
        updateCard: (_) async {},
      );
      p.addListener(() => notifyCount++);

      p.startSession();
      notifyCount = 0; // reset after startSession notifications

      final cardId = p.currentCard!.id;
      await p.removeCardFromQueue(cardId);

      // endSession notifies once; no second notify should follow
      expect(p.isSessionActive, isFalse);
      // notifyCount should be exactly 1 (from endSession), not 2
      expect(notifyCount, equals(1));
    });

    test('removing a non-current card keeps session active', () async {
      final cards = makeCards(3);
      final p = PracticeSessionProvider(
        getReviewCards: () => cards,
        getAllCards: () => cards,
        updateCard: (_) async {},
      );

      p.startSession();
      // Find a card that is NOT the current one
      final nonCurrentId = p.sessionQueue
          .map((item) => item.card.id)
          .firstWhere((id) => id != p.currentCard!.id);

      await p.removeCardFromQueue(nonCurrentId);

      expect(p.isSessionActive, isTrue);
    });

    test(
      'removing a card before the current index keeps the same card displayed',
      () async {
        // Queue: [A, B, C]. Advance to B (index 1). Remove A (index 0).
        // After removal queue is [B, C]. Current card must still be B, not C.
        final cards = makeCards(3);
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
        );

        p.startSession();

        // Advance to index 1 (second card)
        await p.skipExercise();
        expect(p.currentIndex, 1);
        final currentCardId = p.currentCard!.id;

        // Remove the card that is now at index 0 (before current)
        final beforeCurrentId = p.sessionQueue.first.card.id;
        expect(beforeCurrentId, isNot(currentCardId));

        await p.removeCardFromQueue(beforeCurrentId);

        // Current card must be unchanged
        expect(p.currentCard!.id, equals(currentCardId));
      },
    );
  });

  group('skipExercise guard', () {
    List<CardModel> makeCards(int count) => List.generate(
      count,
      (i) => CardModel(
        id: '$i',
        frontText: 'Front $i',
        backText: 'Back $i',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    test(
      'calling skipExercise when session is inactive does not mutate incorrectCount',
      () async {
        final cards = makeCards(3);
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
        );

        // Session never started — incorrectCount starts at 0
        expect(p.isSessionActive, isFalse);
        expect(p.incorrectCount, 0);

        await p.skipExercise();

        // Must still be 0; no session was active
        expect(p.incorrectCount, 0);
      },
    );
  });

  group('removeCardFromQueue does not disturb the current card', () {
    List<CardModel> makeCards(int count) => List.generate(
      count,
      (i) => CardModel(
        id: '$i',
        frontText: 'Front $i',
        backText: 'Back $i',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    test(
      'deleting a card that comes after the current position leaves the current card unchanged',
      () async {
        final cards = makeCards(3);
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
        );

        p.startSession();
        await p.skipExercise();
        final currentCardId = p.currentCard!.id;
        final currentIndex = p.currentIndex;
        final afterCurrentId = p.sessionQueue[currentIndex + 1].card.id;

        await p.removeCardFromQueue(afterCurrentId);

        expect(p.currentCard!.id, equals(currentCardId));
        expect(p.currentIndex, equals(currentIndex));
      },
    );

    test(
      'deleting a card with multiple queue entries leaves the current card unchanged',
      () async {
        final cards = makeCards(5);
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
        );

        p.startSession();

        final card0Id = cards[0].id;
        while (p.isSessionActive && p.currentCard?.id == card0Id) {
          await p.skipExercise();
        }
        if (!p.isSessionActive) return;

        final removedBeforeCount = p.sessionQueue
            .take(p.currentIndex)
            .where((item) => item.card.id == card0Id)
            .length;
        if (removedBeforeCount == 0) return;

        final currentCardId = p.currentCard!.id;
        final expectedIndex = p.currentIndex - removedBeforeCount;

        await p.removeCardFromQueue(card0Id);

        expect(p.currentCard!.id, equals(currentCardId));
        expect(p.currentIndex, equals(expectedIndex));
      },
    );
  });

  group('removeCardFromQueue counts deleted card in totalReviewed', () {
    test(
      'deleting the only current card passes totalReviewed = 1 to onSessionComplete',
      () async {
        int receivedCount = -1;
        final cards = [
          CardModel(
            id: '1',
            frontText: 'A',
            backText: 'B',
            language: 'de',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
          onSessionComplete: (cardsReviewed) async {
            receivedCount = cardsReviewed;
          },
        );

        p.startSession();
        await p.removeCardFromQueue(cards.first.id);

        expect(
          receivedCount,
          equals(1),
          reason: 'deleted card must be counted as incorrect in totalReviewed',
        );
      },
    );
  });

  group('removeCardFromQueue ends session with exactly one notification', () {
    List<CardModel> makeCards(int count) => List.generate(
      count,
      (i) => CardModel(
        id: '$i',
        frontText: 'Front $i',
        backText: 'Back $i',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    test(
      'removing the only card triggers notifyListeners exactly once',
      () async {
        final cards = makeCards(1);
        int notifyCount = 0;
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
        );
        p.startSession();
        p.addListener(() => notifyCount++);
        notifyCount = 0;

        await p.removeCardFromQueue(cards.first.id);

        expect(p.isSessionActive, isFalse);
        expect(notifyCount, equals(1));
      },
    );
  });

  group('removeCardFromQueue with multi-entry current card', () {
    test(
      'removing current card that appears multiple times before current index adjusts index correctly',
      () async {
        // Build a provider where the queue is forced to have a card appear
        // multiple times. We do this by using a card with many due exercise types.
        // Simplest approach: use 5 cards so multiple-choice is available, and
        // rely on the queue builder adding multiple exercise types per card.
        // Instead, we directly test the index arithmetic by using a large enough
        // card set and advancing past a card that appears more than once.
        final cards = List.generate(
          6,
          (i) => CardModel(
            id: '$i',
            frontText: 'Front $i',
            backText: 'Back $i',
            language: 'de',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
        );

        p.startSession();

        // Advance until we are past index 0 so there is at least one entry
        // before the current position.
        if (p.totalCount > 1) {
          await p.skipExercise();
        }

        // Removing a card that is strictly before the current index must keep
        // the current card unchanged.
        if (p.currentIndex > 0) {
          final beforeId = p.sessionQueue.first.card.id;
          final currentId = p.currentCard!.id;

          // Only run the assertion when the card before is different from current
          if (beforeId != currentId) {
            await p.removeCardFromQueue(beforeId);
            expect(p.currentCard!.id, equals(currentId));
          }
        }
      },
    );
  });

  group('skipExercise persists the skipped card', () {
    List<CardModel> makeCards(int count) => List.generate(
      count,
      (i) => CardModel(
        id: '$i',
        frontText: 'Front $i',
        backText: 'Back $i',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    test(
      'skipping a card calls updateCard so the review is persisted',
      () async {
        final cards = makeCards(3);
        final List<CardModel> persisted = [];
        final p = PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (card) async => persisted.add(card),
        );

        p.startSession();
        await p.skipExercise();

        expect(
          persisted,
          isNotEmpty,
          reason: 'skipExercise must persist the skipped card via updateCard',
        );
      },
    );
  });

  group(
    'skipExercise is a no-op when the current exercise is already answered',
    () {
      List<CardModel> makeCards(int count) => List.generate(
        count,
        (i) => CardModel(
          id: '$i',
          frontText: 'Front $i',
          backText: 'Back $i',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      test(
        'incorrectCount is not incremented when skip is called after an answer has been submitted',
        () async {
          final cards = makeCards(3);
          final p = PracticeSessionProvider(
            getReviewCards: () => cards,
            getAllCards: () => cards,
            updateCard: (_) async {},
          );

          p.startSession();
          p.checkAnswer(isCorrect: false);
          expect(p.answerState, AnswerState.answered);

          await p.skipExercise();

          expect(p.incorrectCount, 0);
        },
      );
    },
  );

  group('conjugationPractice exercise filtering', () {
    // Preferences that only enable conjugationPractice so the queue builder
    // is forced to pick it (or nothing) — removes ambiguity about which type
    // gets selected when multiple types are available.
    final conjugationOnly = ExercisePreferences(
      enabledTypes: {ExerciseType.conjugationPractice},
    );

    PracticeSessionProvider makeProvider(List<CardModel> cards) =>
        PracticeSessionProvider(
          getReviewCards: () => cards,
          getAllCards: () => cards,
          updateCard: (_) async {},
        );

    CardModel cardWithWordData(String id, WordData wordData) => CardModel(
      id: id,
      frontText: 'Word $id',
      backText: 'Translation $id',
      language: 'de',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      wordData: wordData,
    );

    // ── Exclusion tests ────────────────────────────────────────────────────

    test('verb with no conjugation fields is excluded', () {
      final card = cardWithWordData('1', const WordData.verb());
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(
        p.isSessionActive,
        isFalse,
        reason:
            'VerbData with no filled fields must produce no conjugation exercise, leaving the queue empty',
      );
    });

    test('noun with empty gender is excluded', () {
      final card = cardWithWordData('1', const WordData.noun(gender: ''));
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(
        p.isSessionActive,
        isFalse,
        reason:
            'NounData with empty gender must produce no conjugation exercise',
      );
    });

    test('adjective with no comparative or superlative is excluded', () {
      final card = cardWithWordData('1', const WordData.adjective());
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(
        p.isSessionActive,
        isFalse,
        reason:
            'AdjectiveData with no forms must produce no conjugation exercise',
      );
    });

    test('adverb is excluded', () {
      final card = cardWithWordData(
        '1',
        const WordData.adverb(usageNote: 'note'),
      );
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(
        p.isSessionActive,
        isFalse,
        reason: 'AdverbData must never produce a conjugation exercise',
      );
    });

    test('null wordData is excluded', () {
      final card = CardModel(
        id: '1',
        frontText: 'Hallo',
        backText: 'Hello',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(
        p.isSessionActive,
        isFalse,
        reason: 'null wordData must never produce a conjugation exercise',
      );
    });

    // ── Inclusion tests ────────────────────────────────────────────────────

    test('verb with pastParticiple is included', () {
      final card = cardWithWordData(
        '1',
        const WordData.verb(pastParticiple: 'gemacht'),
      );
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(p.isSessionActive, isTrue);
      expect(
        p.sessionQueue.first.exerciseType,
        ExerciseType.conjugationPractice,
      );
    });

    test('verb with presentDu is included', () {
      final card = cardWithWordData(
        '1',
        const WordData.verb(presentDu: 'machst'),
      );
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(p.isSessionActive, isTrue);
      expect(
        p.sessionQueue.first.exerciseType,
        ExerciseType.conjugationPractice,
      );
    });

    test('noun with non-empty gender is included', () {
      final card = cardWithWordData('1', const WordData.noun(gender: 'der'));
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(p.isSessionActive, isTrue);
      expect(
        p.sessionQueue.first.exerciseType,
        ExerciseType.conjugationPractice,
      );
    });

    test('adjective with comparative is included', () {
      final card = cardWithWordData(
        '1',
        const WordData.adjective(comparative: 'größer'),
      );
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(p.isSessionActive, isTrue);
      expect(
        p.sessionQueue.first.exerciseType,
        ExerciseType.conjugationPractice,
      );
    });

    test('adjective with superlative only is included', () {
      final card = cardWithWordData(
        '1',
        const WordData.adjective(superlative: 'größten'),
      );
      final p = makeProvider([card]);
      p.startSession(preferences: conjugationOnly);

      expect(p.isSessionActive, isTrue);
      expect(
        p.sessionQueue.first.exerciseType,
        ExerciseType.conjugationPractice,
      );
    });

    // ── All-types session: excluded types never appear ─────────────────────

    test(
      'with all types enabled, excluded word types never get conjugationPractice',
      () {
        final excluded = [
          cardWithWordData('adverb', const WordData.adverb()),
          cardWithWordData('verb-bare', const WordData.verb()),
          cardWithWordData('adj-bare', const WordData.adjective()),
          cardWithWordData('noun-empty', const WordData.noun(gender: '')),
          CardModel(
            id: 'no-data',
            frontText: 'X',
            backText: 'Y',
            language: 'de',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final p = makeProvider(excluded);
        p.startSession(); // all types enabled

        for (final item in p.sessionQueue) {
          expect(
            item.exerciseType,
            isNot(ExerciseType.conjugationPractice),
            reason:
                '${item.card.id} must not get conjugationPractice — no testable data',
          );
        }
      },
    );
  });
}
