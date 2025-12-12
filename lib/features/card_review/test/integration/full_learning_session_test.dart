/// Full Learning Session Test
///
/// Tests the complete daily learning flow end-to-end:
/// 1. User has cards due for review
/// 2. User starts a practice session
/// 3. User completes all exercises (mix of correct/incorrect)
/// 4. Cards are updated with review data
/// 5. Streak is updated
/// 6. Statistics are accurate
///
/// Run with: flutter test lib/features/card_review/test/integration/
///
/// Note: This test uses mocked services to test the full flow logic.
/// For true database integration tests, see the card_management and streak
/// integration tests which run against Docker.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_model.dart';
import 'package:lingua_flutter/features/streak/domain/streak_provider.dart';
import 'package:lingua_flutter/features/streak/data/services/streak_service.dart';

void main() {
  group('Full Learning Session Flow', () {
    late List<CardModel> testCards;
    late List<CardModel> updatedCards;
    late PracticeSessionProvider practiceProvider;
    late MockStreakService mockStreakService;
    late StreakProvider streakProvider;

    CardModel createTestCard({
      required String id,
      required String frontText,
      required String backText,
    }) {
      return CardModel(
        id: id,
        frontText: frontText,
        backText: backText,
        language: 'de',
        category: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    setUp(() async {
      // Create test cards
      testCards = [
        createTestCard(id: '1', frontText: 'Hallo', backText: 'Hello'),
        createTestCard(id: '2', frontText: 'Welt', backText: 'World'),
        createTestCard(id: '3', frontText: 'Danke', backText: 'Thanks'),
        createTestCard(id: '4', frontText: 'Bitte', backText: 'Please'),
        createTestCard(id: '5', frontText: 'Ja', backText: 'Yes'),
      ];
      updatedCards = [];

      // Create practice provider with mock card storage
      practiceProvider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => testCards,
        updateCard: (card) async {
          updatedCards.add(card);
        },
      );

      // Create mock streak service and provider
      mockStreakService = MockStreakService();
      streakProvider = StreakProvider(streakService: mockStreakService);
      await streakProvider.loadStreak();
    });

    test('complete daily session: cards → exercises → streak update', () async {
      // === PHASE 1: Verify Initial State ===
      expect(testCards.length, 5);

      // Load initial streak (should be empty/zero)
      expect(streakProvider.currentStreak, 0);
      expect(streakProvider.totalCardsReviewed, 0);
      expect(streakProvider.totalReviewSessions, 0);

      // === PHASE 2: Create Practice Session ===
      practiceProvider.startSession();
      expect(practiceProvider.isSessionActive, true);
      expect(practiceProvider.totalCount, greaterThan(0));

      final totalExercises = practiceProvider.totalCount;

      // === PHASE 3: Complete All Exercises ===
      int exercisesCompleted = 0;
      int correctAnswers = 0;
      int incorrectAnswers = 0;

      while (practiceProvider.isSessionActive) {
        // Simulate answering - alternate pattern for realistic mix
        final isCorrect = exercisesCompleted % 3 != 2; // ~67% correct

        // Check answer
        practiceProvider.checkAnswer(isCorrect: isCorrect);
        expect(practiceProvider.answerState, AnswerState.answered);

        // Confirm and advance
        await practiceProvider.confirmAnswerAndAdvance(markedCorrect: isCorrect);

        if (isCorrect) {
          correctAnswers++;
        } else {
          incorrectAnswers++;
        }
        exercisesCompleted++;
      }

      // === PHASE 4: Verify Session Completed ===
      expect(practiceProvider.isSessionActive, false);
      expect(exercisesCompleted, totalExercises);
      expect(practiceProvider.correctCount, correctAnswers);
      expect(practiceProvider.incorrectCount, incorrectAnswers);

      // Verify accuracy calculation
      final expectedAccuracy = correctAnswers / exercisesCompleted;
      expect(practiceProvider.accuracy, closeTo(expectedAccuracy, 0.01));

      // === PHASE 5: Update Streak ===
      await streakProvider.updateStreakWithReview(cardsReviewed: exercisesCompleted);

      // Verify streak updated
      expect(streakProvider.currentStreak, greaterThanOrEqualTo(1));
      expect(streakProvider.totalCardsReviewed, exercisesCompleted);
      expect(streakProvider.totalReviewSessions, 1);

      // === PHASE 6: Verify Cards Were Updated ===
      expect(updatedCards, isNotEmpty);
    });

    test('multiple sessions in same day increment cards reviewed but not streak', () async {
      await streakProvider.loadStreak();

      // First session
      await streakProvider.updateStreakWithReview(cardsReviewed: 5);
      expect(streakProvider.currentStreak, 1);
      expect(streakProvider.totalCardsReviewed, 5);
      expect(streakProvider.totalReviewSessions, 1);

      // Second session same day
      await streakProvider.updateStreakWithReview(cardsReviewed: 3);
      expect(streakProvider.currentStreak, 1); // Still 1, same day
      expect(streakProvider.totalCardsReviewed, 8); // Accumulated
      expect(streakProvider.totalReviewSessions, 2);
    });

    test('session with all correct answers achieves 100% accuracy', () async {
      practiceProvider.startSession();

      // Complete all exercises correctly
      while (practiceProvider.isSessionActive) {
        practiceProvider.checkAnswer(isCorrect: true);
        await practiceProvider.confirmAnswerAndAdvance(markedCorrect: true);
      }

      expect(practiceProvider.accuracy, 1.0);
      expect(practiceProvider.incorrectCount, 0);
    });

    test('session with all incorrect answers achieves 0% accuracy', () async {
      practiceProvider.startSession();

      // Complete all exercises incorrectly
      while (practiceProvider.isSessionActive) {
        practiceProvider.checkAnswer(isCorrect: false);
        await practiceProvider.confirmAnswerAndAdvance(markedCorrect: false);
      }

      expect(practiceProvider.accuracy, 0.0);
      expect(practiceProvider.correctCount, 0);
    });

    test('card review data is updated after session', () async {
      practiceProvider.startSession();

      // Complete one exercise
      practiceProvider.checkAnswer(isCorrect: true);
      await practiceProvider.confirmAnswerAndAdvance(markedCorrect: true);

      // Verify card was updated
      expect(updatedCards, isNotEmpty);
      final updatedCard = updatedCards.first;
      expect(updatedCard.reviewCount, greaterThan(0));
    });

    test('empty card list results in no active session', () async {
      final emptyProvider = PracticeSessionProvider(
        getReviewCards: () => [], // No cards
        getAllCards: () => [],
        updateCard: (card) async {},
      );

      emptyProvider.startSession();

      expect(emptyProvider.isSessionActive, false);
      expect(emptyProvider.totalCount, 0);
    });

    test('session restart resets statistics', () async {
      practiceProvider.startSession();

      // Complete some exercises
      practiceProvider.checkAnswer(isCorrect: true);
      await practiceProvider.confirmAnswerAndAdvance(markedCorrect: true);
      practiceProvider.checkAnswer(isCorrect: false);
      await practiceProvider.confirmAnswerAndAdvance(markedCorrect: false);

      final correctBefore = practiceProvider.correctCount;
      final incorrectBefore = practiceProvider.incorrectCount;
      expect(correctBefore, 1);
      expect(incorrectBefore, 1);

      // Restart session
      practiceProvider.restartSession();

      // Statistics should be reset
      expect(practiceProvider.correctCount, 0);
      expect(practiceProvider.incorrectCount, 0);
      expect(practiceProvider.isSessionActive, true);
    });
  });
}

/// Mock implementation of StreakService for testing
class MockStreakService implements StreakService {
  StreakModel _streak = const StreakModel();

  @override
  Future<StreakModel> loadStreak() async {
    return _streak;
  }

  @override
  Future<void> saveStreak(StreakModel streak) async {
    _streak = streak;
  }

  @override
  Future<StreakModel> updateStreakWithReview({
    required int cardsReviewed,
    DateTime? reviewDate,
  }) async {
    _streak = _streak.updateWithReview(
      cardsReviewed: cardsReviewed,
      reviewDate: reviewDate,
    );
    return _streak;
  }

  @override
  Future<void> resetStreak() async {
    _streak = const StreakModel();
  }

  @override
  Future<void> clearStreakData() async {
    _streak = const StreakModel();
  }

  @override
  Future<Map<String, int>> getDailyReviewData({int days = 30}) async {
    return _streak.dailyReviewCounts;
  }

  @override
  Future<Map<String, dynamic>> getStreakStats() async {
    return {
      'currentStreak': _streak.currentStreak,
      'bestStreak': _streak.bestStreak,
      'totalCardsReviewed': _streak.totalCardsReviewed,
      'totalReviewSessions': _streak.totalReviewSessions,
    };
  }
}
