/// Integration tests for SupabaseStreakService
///
/// These tests run against a real PostgreSQL database via Docker.
/// Ensure the test containers are running before executing:
///   docker-compose -f docker-compose.test.yml up -d
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_model.dart';
import 'package:lingua_flutter/features/streak/data/services/supabase_streak_service.dart';

import 'supabase_test_helper.dart';

void main() {
  late SupabaseStreakService streakService;

  setUpAll(() async {
    await SupabaseTestHelper.initialize();
    await SupabaseTestHelper.waitForDatabase();
    await SupabaseTestHelper.signInTestUser();
  });

  setUp(() async {
    streakService = SupabaseStreakService();
    // Reset streak to initial state
    await streakService.resetStreak();
  });

  tearDownAll(() async {
    await SupabaseTestHelper.dispose();
  });

  group('SupabaseStreakService Integration Tests', () {
    test('should load initial streak for new user', () async {
      // Act
      final streak = await streakService.loadStreak();

      // Assert
      expect(streak, isNotNull);
      expect(streak.currentStreak, equals(0));
      expect(streak.bestStreak, equals(0));
      expect(streak.totalCardsReviewed, equals(0));
    });

    test('should save and load streak', () async {
      // Arrange
      final streak = StreakModel(
        currentStreak: 5,
        bestStreak: 10,
        lastReviewDate: DateTime.now(),
        totalCardsReviewed: 100,
        totalReviewSessions: 20,
        dailyReviewCounts: {'2024-01-01': 10, '2024-01-02': 15},
        achievedMilestones: [7, 14, 30],
      );

      // Act
      await streakService.saveStreak(streak);
      final loadedStreak = await streakService.loadStreak();

      // Assert
      expect(loadedStreak, isNotNull);
      expect(loadedStreak.currentStreak, equals(5));
      expect(loadedStreak.bestStreak, equals(10));
      expect(loadedStreak.totalCardsReviewed, equals(100));
      expect(loadedStreak.totalReviewSessions, equals(20));
      expect(loadedStreak.achievedMilestones, containsAll([7, 14, 30]));
    });

    test('should update streak with review', () async {
      // Arrange
      final initialStreak = await streakService.loadStreak();
      expect(initialStreak.currentStreak, equals(0));

      // Act
      final updatedStreak = await streakService.updateStreakWithReview(
        cardsReviewed: 10,
      );

      // Assert
      expect(updatedStreak.totalCardsReviewed, equals(10));
      expect(updatedStreak.totalReviewSessions, equals(1));
      expect(updatedStreak.currentStreak, greaterThanOrEqualTo(1));
    });

    test('should reset streak', () async {
      // Arrange - create a streak first
      final streak = StreakModel(
        currentStreak: 5,
        bestStreak: 10,
        lastReviewDate: DateTime.now(),
        totalCardsReviewed: 100,
        totalReviewSessions: 20,
      );
      await streakService.saveStreak(streak);

      // Act
      await streakService.resetStreak();
      final loadedStreak = await streakService.loadStreak();

      // Assert
      expect(loadedStreak.currentStreak, equals(0));
      expect(loadedStreak.totalCardsReviewed, equals(0));
    });

    test('should get streak stats', () async {
      // Arrange
      final streak = StreakModel(
        currentStreak: 7,
        bestStreak: 14,
        lastReviewDate: DateTime.now(),
        totalCardsReviewed: 150,
        totalReviewSessions: 30,
        dailyReviewCounts: {
          '2024-01-01': 10,
          '2024-01-02': 15,
          '2024-01-03': 20,
        },
      );
      await streakService.saveStreak(streak);

      // Act
      final stats = await streakService.getStreakStats();

      // Assert
      expect(stats['currentStreak'], equals(7));
      expect(stats['bestStreak'], equals(14));
      expect(stats['totalCardsReviewed'], equals(150));
      expect(stats['totalReviewSessions'], equals(30));
    });

    test('should preserve best streak when current resets', () async {
      // Arrange - set a high best streak
      final streak = StreakModel(
        currentStreak: 30,
        bestStreak: 30,
        lastReviewDate: DateTime.now().subtract(const Duration(days: 2)),
        totalCardsReviewed: 300,
        totalReviewSessions: 30,
      );
      await streakService.saveStreak(streak);

      // Act - update with a new review (streak should reset due to gap)
      final updatedStreak = await streakService.updateStreakWithReview(
        cardsReviewed: 5,
      );

      // Assert - best streak should be preserved
      expect(updatedStreak.bestStreak, equals(30));
      // Current streak resets to 1 (today's review)
      expect(updatedStreak.currentStreak, equals(1));
    });
  });
}
