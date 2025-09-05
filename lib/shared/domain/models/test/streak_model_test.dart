import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_model.dart';

void main() {
  group('StreakModel', () {
    
    // Helper function to format dates
    String _formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    test('should create initial streak model', () {
      final streak = StreakModel.initial();
      
      expect(streak.currentStreak, equals(0));
      expect(streak.bestStreak, equals(0));
      expect(streak.lastReviewDate, isNull);
      expect(streak.totalReviewSessions, equals(0));
      expect(streak.totalCardsReviewed, equals(0));
      expect(streak.dailyReviewCounts, isEmpty);
      expect(streak.achievedMilestones, isEmpty);
      expect(streak.streakStartDate, isNull);
      expect(streak.bestStreakDate, isNull);
    });

    test('should check if streak is active', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      // Active streak (reviewed today)
      final activeStreak = StreakModel(
        currentStreak: 5,
        lastReviewDate: today,
      );
      expect(activeStreak.isStreakActive, isTrue);
      
      // Active streak (reviewed yesterday)
      final yesterdayStreak = StreakModel(
        currentStreak: 5,
        lastReviewDate: yesterday,
      );
      expect(yesterdayStreak.isStreakActive, isTrue);
      
      // Inactive streak (reviewed 2 days ago)
      final inactiveStreak = StreakModel(
        currentStreak: 0,
        lastReviewDate: today.subtract(const Duration(days: 2)),
      );
      expect(inactiveStreak.isStreakActive, isFalse);
      
      // No streak
      const noStreak = StreakModel();
      expect(noStreak.isStreakActive, isFalse);
    });

    test('should check if needs review today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      // Reviewed today - doesn't need review
      final reviewedToday = StreakModel(lastReviewDate: today);
      expect(reviewedToday.needsReviewToday, isFalse);
      
      // Reviewed yesterday - needs review
      final reviewedYesterday = StreakModel(lastReviewDate: yesterday);
      expect(reviewedYesterday.needsReviewToday, isTrue);
      
      // Never reviewed - needs review
      const neverReviewed = StreakModel();
      expect(neverReviewed.needsReviewToday, isTrue);
    });

    test('should get cards reviewed today', () {
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final streak = StreakModel(
        dailyReviewCounts: {todayKey: 15, '2024-01-01': 10},
      );
      
      expect(streak.cardsReviewedToday, equals(15));
    });

    test('should calculate average cards per day', () {
      final now = DateTime.now();
      final today = _formatDate(now);
      final yesterday = _formatDate(now.subtract(const Duration(days: 1)));
      final twoDaysAgo = _formatDate(now.subtract(const Duration(days: 2)));
      
      final streak = StreakModel(
        currentStreak: 3,
        dailyReviewCounts: {
          today: 15,
          yesterday: 10,
          twoDaysAgo: 5,
        },
      );
      
      // Average should be calculated based on current streak days
      expect(streak.averageCardsPerDay, closeTo(10.0, 0.1));
    });

    test('should get new milestones', () {
      const streak = StreakModel(
        currentStreak: 7,
        achievedMilestones: [3],
      );
      
      final newMilestones = streak.getNewMilestones(5);
      expect(newMilestones, contains(7));
      expect(newMilestones, isNot(contains(3))); // Already achieved
    });

    test('should update with review on same day', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final streak = StreakModel(
        currentStreak: 5,
        lastReviewDate: today,
        totalReviewSessions: 10,
        totalCardsReviewed: 50,
        streakStartDate: today.subtract(const Duration(days: 4)),
      );
      
      final updatedStreak = streak.updateWithReview(
        cardsReviewed: 10,
        reviewDate: today,
      );
      
      // Same day review should keep streak
      expect(updatedStreak.currentStreak, equals(5));
      expect(updatedStreak.totalReviewSessions, equals(11));
      expect(updatedStreak.totalCardsReviewed, equals(60));
    });

    test('should update with review on next day', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      final streak = StreakModel(
        currentStreak: 5,
        lastReviewDate: yesterday,
        totalReviewSessions: 10,
        totalCardsReviewed: 50,
        streakStartDate: yesterday.subtract(const Duration(days: 4)),
      );
      
      final updatedStreak = streak.updateWithReview(
        cardsReviewed: 10,
        reviewDate: today,
      );
      
      // Next day review should increment streak
      expect(updatedStreak.currentStreak, equals(6));
      expect(updatedStreak.totalReviewSessions, equals(11));
      expect(updatedStreak.totalCardsReviewed, equals(60));
    });

    test('should reset streak when gap in reviews', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      
      final streak = StreakModel(
        currentStreak: 5,
        lastReviewDate: threeDaysAgo,
        totalReviewSessions: 10,
        totalCardsReviewed: 50,
      );
      
      final updatedStreak = streak.updateWithReview(
        cardsReviewed: 10,
        reviewDate: today,
      );
      
      // Gap in reviews should reset streak
      expect(updatedStreak.currentStreak, equals(1));
      expect(updatedStreak.streakStartDate, equals(today));
      expect(updatedStreak.totalReviewSessions, equals(11));
    });

    test('should update best streak', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final streak = StreakModel(
        currentStreak: 5,
        bestStreak: 3,
        lastReviewDate: yesterday,
        streakStartDate: yesterday.subtract(const Duration(days: 4)),
      );
      
      final updatedStreak = streak.updateWithReview(
        cardsReviewed: 10,
        reviewDate: now,
      );
      
      // Should update best streak when current streak exceeds it
      expect(updatedStreak.currentStreak, equals(6)); // Previous streak + 1
      expect(updatedStreak.bestStreak, equals(6)); // New best streak
      expect(updatedStreak.bestStreakDate, isNotNull);
    });

    test('should reset streak correctly', () {
      const streak = StreakModel(
        currentStreak: 10,
        bestStreak: 15,
        lastReviewDate: null,
        totalReviewSessions: 20,
        totalCardsReviewed: 100,
      );
      
      final resetStreak = streak.resetStreak();
      
      expect(resetStreak.currentStreak, equals(0));
      expect(resetStreak.lastReviewDate, isNull);
      expect(resetStreak.streakStartDate, isNull);
      // Other stats should remain
      expect(resetStreak.bestStreak, equals(15));
      expect(resetStreak.totalReviewSessions, equals(20));
      expect(resetStreak.totalCardsReviewed, equals(100));
    });

    test('should provide correct status messages', () {
      // No streak
      const noStreak = StreakModel();
      expect(noStreak.statusMessage, equals('Start your streak today!'));
      
      // Active streak
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activeStreak = StreakModel(
        currentStreak: 5,
        lastReviewDate: today,
      );
      expect(activeStreak.statusMessage, equals('5-day streak! Great job!'));
      
      // Needs review
      final needsReview = StreakModel(
        currentStreak: 3,
        lastReviewDate: today.subtract(const Duration(days: 1)),
      );
      expect(needsReview.statusMessage, equals('Keep your 3-day streak alive!'));
    });

    test('should provide motivational messages', () {
      const noStreak = StreakModel();
      expect(noStreak.motivationMessage, contains('Every journey begins'));
      
      const shortStreak = StreakModel(currentStreak: 5);
      expect(shortStreak.motivationMessage, contains('Building momentum'));
      
      const mediumStreak = StreakModel(currentStreak: 15);
      expect(mediumStreak.motivationMessage, contains('Habit is forming'));
      
      const longStreak = StreakModel(currentStreak: 50);
      expect(longStreak.motivationMessage, contains('Incredible dedication'));
      
      const legendaryStreak = StreakModel(currentStreak: 150);
      expect(legendaryStreak.motivationMessage, contains('LEGENDARY'));
    });

    test('should convert to and from JSON', () {
      final now = DateTime.now();
      final streak = StreakModel(
        currentStreak: 10,
        bestStreak: 15,
        lastReviewDate: now,
        totalReviewSessions: 20,
        totalCardsReviewed: 100,
        dailyReviewCounts: {'2024-01-01': 5},
        achievedMilestones: [3, 7],
        streakStartDate: now.subtract(const Duration(days: 9)),
        bestStreakDate: now.subtract(const Duration(days: 5)),
      );
      
      final json = streak.toJson();
      final fromJson = StreakModel.fromJson(json);
      
      expect(fromJson.currentStreak, equals(streak.currentStreak));
      expect(fromJson.bestStreak, equals(streak.bestStreak));
      expect(fromJson.totalReviewSessions, equals(streak.totalReviewSessions));
      expect(fromJson.totalCardsReviewed, equals(streak.totalCardsReviewed));
      expect(fromJson.dailyReviewCounts, equals(streak.dailyReviewCounts));
      expect(fromJson.achievedMilestones, equals(streak.achievedMilestones));
    });

    test('should implement copyWith correctly', () {
      const original = StreakModel(
        currentStreak: 5,
        bestStreak: 10,
        totalReviewSessions: 15,
      );
      
      final copied = original.copyWith(
        currentStreak: 6,
        totalCardsReviewed: 100,
      );
      
      expect(copied.currentStreak, equals(6));
      expect(copied.bestStreak, equals(10)); // Unchanged
      expect(copied.totalReviewSessions, equals(15)); // Unchanged
      expect(copied.totalCardsReviewed, equals(100)); // Changed
    });

    test('should implement equality correctly', () {
      const streak1 = StreakModel(currentStreak: 5, bestStreak: 10);
      const streak2 = StreakModel(currentStreak: 5, bestStreak: 10);
      const streak3 = StreakModel(currentStreak: 3, bestStreak: 10);
      
      expect(streak1, equals(streak2));
      expect(streak1, isNot(equals(streak3)));
    });
  });
}
