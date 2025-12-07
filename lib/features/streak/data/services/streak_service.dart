import '../../domain/models/streak_model.dart';

/// Abstract interface for streak data operations.
/// 
/// This allows for different implementations (Supabase, local storage, mock)
/// and enables proper dependency injection for testing.
abstract class StreakService {
  /// Load streak data for current user
  Future<StreakModel> loadStreak();

  /// Save streak data
  Future<void> saveStreak(StreakModel streak);

  /// Update streak with a review session
  Future<StreakModel> updateStreakWithReview({
    required int cardsReviewed,
    DateTime? reviewDate,
  });

  /// Reset streak data (but keep stats)
  Future<void> resetStreak();

  /// Clear all streak data for current user
  Future<void> clearStreakData();

  /// Get daily review data for charts
  Future<Map<String, int>> getDailyReviewData({int days = 30});

  /// Get comprehensive streak statistics
  Future<Map<String, dynamic>> getStreakStats();
}
