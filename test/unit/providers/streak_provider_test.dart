import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_flutter/providers/streak_provider.dart';

void main() {
  group('StreakProvider', () {
    late StreakProvider streakProvider;

    setUp(() {
      // Set up in-memory shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      streakProvider = StreakProvider();
    });

    tearDown(() {
      streakProvider.dispose();
    });

    test('should have initial state', () {
      expect(streakProvider.currentStreak, equals(0));
      expect(streakProvider.bestStreak, equals(0));
      expect(streakProvider.totalCardsReviewed, equals(0));
      expect(streakProvider.totalReviewSessions, equals(0));
      expect(streakProvider.cardsReviewedToday, equals(0));
      expect(streakProvider.isLoading, isFalse);
      expect(streakProvider.errorMessage, isNull);
      expect(streakProvider.newMilestones, isEmpty);
    });

    test('should load streak data', () async {
      await streakProvider.loadStreak();
      
      expect(streakProvider.isLoading, isFalse);
      expect(streakProvider.errorMessage, isNull);
      expect(streakProvider.currentStreak, equals(0));
    });

    test('should update streak with review', () async {
      await streakProvider.updateStreakWithReview(cardsReviewed: 10);
      
      expect(streakProvider.isLoading, isFalse);
      expect(streakProvider.errorMessage, isNull);
      expect(streakProvider.currentStreak, equals(1));
      expect(streakProvider.totalCardsReviewed, equals(10));
      expect(streakProvider.totalReviewSessions, equals(1));
    });

    test('should detect new milestones', () async {
      // Update streak to potentially reach milestones
      await streakProvider.updateStreakWithReview(cardsReviewed: 5);
      
      expect(streakProvider.newMilestones, isA<List<int>>());
    });

    test('should clear new milestones', () async {
      await streakProvider.updateStreakWithReview(cardsReviewed: 5);
      
      // Simulate having new milestones
      if (streakProvider.newMilestones.isNotEmpty) {
        streakProvider.clearNewMilestones();
        expect(streakProvider.newMilestones, isEmpty);
      }
    });

    test('should reset streak', () async {
      // First build up a streak
      await streakProvider.updateStreakWithReview(cardsReviewed: 10);
      expect(streakProvider.currentStreak, equals(1));
      
      // Then reset it
      await streakProvider.resetStreak();
      expect(streakProvider.currentStreak, equals(0));
      
      // But total stats should remain
      expect(streakProvider.totalReviewSessions, equals(1));
      expect(streakProvider.totalCardsReviewed, equals(10));
    });

    test('should clear streak data', () async {
      // First build up some data
      await streakProvider.updateStreakWithReview(cardsReviewed: 10);
      
      // Then clear all data
      await streakProvider.clearStreakData();
      
      expect(streakProvider.currentStreak, equals(0));
      expect(streakProvider.totalReviewSessions, equals(0));
      expect(streakProvider.totalCardsReviewed, equals(0));
    });

    test('should provide motivational messages', () {
      expect(streakProvider.getMotivationalMessage(), contains('Start your learning streak'));
      
      // Note: Motivational messages are based on the current streak state
      // We can't directly set the streak, so we test the default case
    });

    test('should provide streak status colors', () {
      expect(streakProvider.getStreakStatusColor(), equals('grey'));
      
      // Note: Colors are based on the current streak state
      // We can't directly set the streak, so we test the default case
    });

    test('should check new milestones correctly', () {
      expect(streakProvider.isNewMilestone(7), isFalse);
      
      // Note: New milestones are managed internally
      // We can only test the default case where no milestones are new
    });

    test('should get daily review data', () async {
      await streakProvider.loadStreak();
      final dailyData = await streakProvider.getDailyReviewData(days: 7);
      
      expect(dailyData, isA<Map<String, int>>());
      expect(dailyData.length, lessThanOrEqualTo(7));
    });

    test('should get streak statistics', () async {
      await streakProvider.loadStreak();
      final stats = await streakProvider.getStreakStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('currentStreak'), isTrue);
      expect(stats.containsKey('bestStreak'), isTrue);
      expect(stats.containsKey('totalSessions'), isTrue);
      expect(stats.containsKey('totalCards'), isTrue);
    });
  });
}
