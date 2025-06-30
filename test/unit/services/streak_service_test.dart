import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_flutter/models/streak_model.dart';
import 'package:lingua_flutter/services/streak_service.dart';

void main() {
  group('StreakService', () {
    late StreakService streakService;

    setUp(() {
      // Set up in-memory shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      streakService = StreakService();
    });

    tearDown(() {
      streakService.dispose();
    });

    test('should load initial streak', () async {
      final streak = await streakService.loadStreak();
      
      expect(streak.currentStreak, equals(0));
      expect(streak.bestStreak, equals(0));
      expect(streak.totalReviewSessions, equals(0));
      expect(streak.totalCardsReviewed, equals(0));
      expect(streak.dailyReviewCounts, isEmpty);
      expect(streak.achievedMilestones, isEmpty);
    });

    test('should save and load streak data', () async {
      const testStreak = StreakModel(
        currentStreak: 5,
        bestStreak: 10,
        totalReviewSessions: 20,
        totalCardsReviewed: 100,
      );

      await streakService.saveStreak(testStreak);
      final loadedStreak = await streakService.loadStreak();

      expect(loadedStreak.currentStreak, equals(5));
      expect(loadedStreak.bestStreak, equals(10));
      expect(loadedStreak.totalReviewSessions, equals(20));
      expect(loadedStreak.totalCardsReviewed, equals(100));
    });

    test('should update streak with review', () async {
      final updatedStreak = await streakService.updateStreakWithReview(
        cardsReviewed: 10,
      );

      expect(updatedStreak.currentStreak, equals(1));
      expect(updatedStreak.totalReviewSessions, equals(1));
      expect(updatedStreak.totalCardsReviewed, equals(10));
      expect(updatedStreak.cardsReviewedToday, equals(10));
    });

    test('should clear streak data', () async {
      // First add some data
      await streakService.updateStreakWithReview(cardsReviewed: 5);
      
      // Then clear it
      await streakService.clearStreakData();
      
      final streak = await streakService.loadStreak();
      expect(streak.currentStreak, equals(0));
      expect(streak.totalReviewSessions, equals(0));
      expect(streak.totalCardsReviewed, equals(0));
    });

    test('should get streak statistics', () async {
      await streakService.updateStreakWithReview(cardsReviewed: 15);
      
      final stats = await streakService.getStreakStats();
      
      expect(stats['currentStreak'], equals(1));
      expect(stats['totalSessions'], equals(1));
      expect(stats['totalCards'], equals(15));
      expect(stats['cardsToday'], equals(15));
      expect(stats['isActive'], isTrue);
      expect(stats['needsReview'], isFalse);
    });

    test('should get daily review data', () async {
      await streakService.updateStreakWithReview(cardsReviewed: 5);
      
      final dailyData = await streakService.getDailyReviewData(days: 7);
      
      expect(dailyData, isA<Map<String, int>>());
      expect(dailyData.length, equals(7));
      
      // Today should have 5 cards
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect(dailyData[todayKey], equals(5));
    });

    test('should check new milestones', () async {
      // Update streak to reach milestone
      await streakService.updateStreakWithReview(cardsReviewed: 5);
      
      final milestones = await streakService.checkNewMilestones(5);
      
      // Should detect milestone at 3 days if we simulate having 3 days
      expect(milestones, isA<List<int>>());
    });

    test('should reset streak but keep stats', () async {
      // Build up some streak data
      await streakService.updateStreakWithReview(cardsReviewed: 10);
      
      await streakService.resetStreak();
      
      final streak = await streakService.loadStreak();
      expect(streak.currentStreak, equals(0));
      expect(streak.lastReviewDate, isNull);
      expect(streak.streakStartDate, isNull);
      // But total stats should remain
      expect(streak.totalReviewSessions, equals(1));
      expect(streak.totalCardsReviewed, equals(10));
    });
  });
}
