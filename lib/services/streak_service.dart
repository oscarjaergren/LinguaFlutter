import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_model.dart';

/// Service for managing streak data persistence
class StreakService {
  static const String _streakKey = 'lingua_flutter_streak';
  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load streak data from storage
  Future<StreakModel> loadStreak() async {
    await _ensureInitialized();
    
    try {
      final streakJson = _prefs!.getString(_streakKey);
      if (streakJson == null || streakJson.isEmpty) {
        return StreakModel.initial();
      }
      
      final Map<String, dynamic> streakMap = jsonDecode(streakJson);
      return StreakModel.fromJson(streakMap);
    } catch (e) {
      // If there's an error loading, return initial streak
      return StreakModel.initial();
    }
  }

  /// Save streak data to storage
  Future<void> saveStreak(StreakModel streak) async {
    await _ensureInitialized();
    
    try {
      final streakJson = jsonEncode(streak.toJson());
      await _prefs!.setString(_streakKey, streakJson);
    } catch (e) {
      throw Exception('Failed to save streak data: $e');
    }
  }

  /// Update streak with a review session
  Future<StreakModel> updateStreakWithReview({
    required int cardsReviewed,
    DateTime? reviewDate,
  }) async {
    final currentStreak = await loadStreak();
    final updatedStreak = currentStreak.updateWithReview(
      cardsReviewed: cardsReviewed,
      reviewDate: reviewDate,
    );
    await saveStreak(updatedStreak);
    return updatedStreak;
  }

  /// Reset streak data
  Future<void> resetStreak() async {
    final currentStreak = await loadStreak();
    final resetStreak = currentStreak.resetStreak();
    await saveStreak(resetStreak);
  }

  /// Clear all streak data
  Future<void> clearStreakData() async {
    await _ensureInitialized();
    await _prefs!.remove(_streakKey);
  }

  /// Get streak statistics
  Future<Map<String, dynamic>> getStreakStats() async {
    final streak = await loadStreak();
    
    return {
      'currentStreak': streak.currentStreak,
      'bestStreak': streak.bestStreak,
      'totalSessions': streak.totalReviewSessions,
      'totalCards': streak.totalCardsReviewed,
      'cardsToday': streak.cardsReviewedToday,
      'averageCardsPerDay': streak.averageCardsPerDay,
      'milestones': streak.achievedMilestones,
      'isActive': streak.isStreakActive,
      'needsReview': streak.needsReviewToday,
    };
  }

  /// Get daily review data for charts/graphs
  Future<Map<String, int>> getDailyReviewData({int days = 30}) async {
    final streak = await loadStreak();
    final now = DateTime.now();
    final dailyData = <String, int>{};
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      dailyData[dateKey] = streak.dailyReviewCounts[dateKey] ?? 0;
    }
    
    return dailyData;
  }

  /// Check if user achieved any new milestones
  Future<List<int>> checkNewMilestones(int cardsReviewed) async {
    final currentStreak = await loadStreak();
    final previousStreak = currentStreak.currentStreak;
    
    final updatedStreak = currentStreak.updateWithReview(
      cardsReviewed: cardsReviewed,
    );
    
    return updatedStreak.getNewMilestones(previousStreak);
  }

  /// Get streak freeze/protection status (for future premium features)
  Future<bool> hasStreakProtection() async {
    // For now, return false - this could be implemented as a premium feature
    return false;
  }

  /// Use streak freeze (for future premium features)
  Future<bool> useStreakFreeze() async {
    // For now, return false - this could be implemented as a premium feature
    return false;
  }

  /// Format date as string key
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Dispose of resources
  void dispose() {
    _prefs = null;
  }
}
