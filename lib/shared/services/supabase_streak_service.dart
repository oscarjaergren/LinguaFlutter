import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/streak/domain/models/streak_model.dart';
import '../../features/streak/data/services/streak_service.dart';
import 'supabase_service.dart';
import 'logger_service.dart';

/// Supabase implementation of [StreakService].
/// 
/// Manages streak data persistence in Supabase database.
class SupabaseStreakService implements StreakService {
  static const String _tableName = 'streaks';

  /// Get the Supabase client
  SupabaseClient get _client => SupabaseService.client;

  /// Get current user ID or throw if not authenticated
  String get _userId {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => SupabaseService.isAuthenticated;

  @override
  Future<StreakModel> loadStreak() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', _userId)
          .maybeSingle();

      if (response == null) {
        // Create initial streak record for new user
        return await _createInitialStreak();
      }

      return _streakFromSupabase(response);
    } catch (e) {
      LoggerService.error('Failed to load streak from Supabase', e);
      // Return initial streak on error
      return StreakModel.initial();
    }
  }

  @override
  Future<void> saveStreak(StreakModel streak) async {
    try {
      final data = _streakToSupabase(streak);
      
      await _client
          .from(_tableName)
          .upsert(data);

      LoggerService.debug('Streak saved to Supabase');
    } catch (e) {
      LoggerService.error('Failed to save streak to Supabase', e);
      rethrow;
    }
  }

  @override
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

  @override
  Future<void> resetStreak() async {
    final currentStreak = await loadStreak();
    final resetStreak = currentStreak.resetStreak();
    await saveStreak(resetStreak);
  }

  @override
  Future<void> clearStreakData() async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('user_id', _userId);

      LoggerService.debug('Streak data cleared from Supabase');
    } catch (e) {
      LoggerService.error('Failed to clear streak from Supabase', e);
      rethrow;
    }
  }

  /// Create initial streak record for new user
  Future<StreakModel> _createInitialStreak() async {
    final initial = StreakModel.initial();
    await saveStreak(initial);
    return initial;
  }

  /// Convert StreakModel to Supabase row format
  Map<String, dynamic> _streakToSupabase(StreakModel streak) {
    return {
      'user_id': _userId,
      'current_streak': streak.currentStreak,
      'best_streak': streak.bestStreak,
      'total_cards_reviewed': streak.totalCardsReviewed,
      'total_review_sessions': streak.totalReviewSessions,
      'last_review_date': streak.lastReviewDate?.toIso8601String().split('T')[0],
      'daily_review_counts': streak.dailyReviewCounts,
      'achieved_milestones': streak.achievedMilestones,
    };
  }

  /// Convert Supabase row to StreakModel
  StreakModel _streakFromSupabase(Map<String, dynamic> json) {
    // Parse daily review counts
    final dailyReviewCounts = <String, int>{};
    if (json['daily_review_counts'] != null) {
      final counts = json['daily_review_counts'] as Map<String, dynamic>;
      counts.forEach((key, value) {
        dailyReviewCounts[key] = value as int;
      });
    }

    // Parse achieved milestones
    final achievedMilestones = (json['achieved_milestones'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList() ?? [];

    // Parse last review date
    DateTime? lastReviewDate;
    if (json['last_review_date'] != null) {
      lastReviewDate = DateTime.parse(json['last_review_date'] as String);
    }

    return StreakModel(
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      lastReviewDate: lastReviewDate,
      totalReviewSessions: json['total_review_sessions'] as int? ?? 0,
      totalCardsReviewed: json['total_cards_reviewed'] as int? ?? 0,
      dailyReviewCounts: dailyReviewCounts,
      achievedMilestones: achievedMilestones,
    );
  }

  @override
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

  @override
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

  /// Format date as string key
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
