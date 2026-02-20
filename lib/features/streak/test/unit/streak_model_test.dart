import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_model.dart';

void main() {
  group('StreakModel', () {
    String formatDate(DateTime date) {
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

      final activeStreak = StreakModel(currentStreak: 5, lastReviewDate: today);
      expect(activeStreak.isStreakActive, isTrue);

      final yesterdayStreak = StreakModel(
        currentStreak: 5,
        lastReviewDate: yesterday,
      );
      expect(yesterdayStreak.isStreakActive, isTrue);

      final inactiveStreak = StreakModel(
        currentStreak: 0,
        lastReviewDate: today.subtract(const Duration(days: 2)),
      );
      expect(inactiveStreak.isStreakActive, isFalse);

      const noStreak = StreakModel();
      expect(noStreak.isStreakActive, isFalse);
    });

    test('should check if needs review today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final reviewedToday = StreakModel(lastReviewDate: today);
      expect(reviewedToday.needsReviewToday, isFalse);

      final reviewedYesterday = StreakModel(lastReviewDate: yesterday);
      expect(reviewedYesterday.needsReviewToday, isTrue);

      const neverReviewed = StreakModel();
      expect(neverReviewed.needsReviewToday, isTrue);
    });

    test('should get cards reviewed today', () {
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final streak = StreakModel(
        dailyReviewCounts: {todayKey: 15, '2024-01-01': 10},
      );

      expect(streak.cardsReviewedToday, equals(15));
    });

    test('should calculate average cards per day', () {
      final now = DateTime.now();
      final today = formatDate(now);
      final yesterday = formatDate(now.subtract(const Duration(days: 1)));
      final twoDaysAgo = formatDate(now.subtract(const Duration(days: 2)));

      final streak = StreakModel(
        currentStreak: 3,
        lastReviewDate: now,
        dailyReviewCounts: {today: 15, yesterday: 10, twoDaysAgo: 5},
      );

      expect(streak.averageCardsPerDay, closeTo(10.0, 0.1));
    });

    test('should get new milestones', () {
      const streak = StreakModel(currentStreak: 7, achievedMilestones: [3]);

      final newMilestones = streak.getNewMilestones(5);
      expect(newMilestones, contains(7));
      expect(newMilestones, isNot(contains(3)));
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
      expect(resetStreak.bestStreak, equals(15));
      expect(resetStreak.totalReviewSessions, equals(20));
      expect(resetStreak.totalCardsReviewed, equals(100));
    });

    test('should provide correct status messages', () {
      const noStreak = StreakModel();
      expect(noStreak.statusMessage, equals('Start your streak today!'));

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activeStreak = StreakModel(currentStreak: 5, lastReviewDate: today);
      expect(activeStreak.statusMessage, equals('5-day streak! Great job!'));

      final needsReview = StreakModel(
        currentStreak: 3,
        lastReviewDate: today.subtract(const Duration(days: 1)),
      );
      expect(
        needsReview.statusMessage,
        equals('Keep your 3-day streak alive!'),
      );
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
      expect(copied.bestStreak, equals(10));
      expect(copied.totalReviewSessions, equals(15));
      expect(copied.totalCardsReviewed, equals(100));
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
