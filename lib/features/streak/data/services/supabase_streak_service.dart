import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lingua_flutter/features/auth/data/services/supabase_auth_service.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_model.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';
import 'streak_service.dart';

/// Supabase implementation of [StreakService].
///
/// Manages streak data persistence in Supabase database.
class SupabaseStreakService implements StreakService {
  static const String _tableName = 'streaks';
  static const String _atomicUpdateRpc = 'update_streak_with_review_atomic';

  final SupabaseClient Function()? _clientProvider;
  final bool Function()? _isAuthenticatedProvider;
  final String? Function()? _userIdProvider;

  SupabaseStreakService({
    SupabaseClient Function()? clientProvider,
    bool Function()? isAuthenticatedProvider,
    String? Function()? userIdProvider,
  }) : _clientProvider = clientProvider,
       _isAuthenticatedProvider = isAuthenticatedProvider,
       _userIdProvider = userIdProvider;

  /// Get the Supabase client
  SupabaseClient get _client =>
      _clientProvider?.call() ?? SupabaseAuthService.client;

  /// Get current user ID or throw if not authenticated
  String get _userId {
    final userId = _userIdProvider?.call() ?? SupabaseAuthService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  /// Check if user is authenticated
  bool get isAuthenticated =>
      _isAuthenticatedProvider?.call() ?? SupabaseAuthService.isAuthenticated;

  @override
  Future<StreakModel> loadStreak() async {
    // Guard: return initial streak if not authenticated
    if (!isAuthenticated) {
      LoggerService.debug('Not authenticated, returning initial streak');
      return StreakModel.initial();
    }

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
      // Expected on first load or stale session - return initial streak
      LoggerService.warning('Could not load streak, using initial: $e');
      return StreakModel.initial();
    }
  }

  @override
  Future<void> saveStreak(StreakModel streak) async {
    // Guard: skip save if not authenticated
    if (!isAuthenticated) {
      LoggerService.debug('Not authenticated, skipping streak save');
      return;
    }

    try {
      final data = _streakToSupabase(streak);

      await _client.from(_tableName).upsert(data);

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
    // Guard: no-op if not authenticated to match existing behavior.
    if (!isAuthenticated) {
      LoggerService.debug('Not authenticated, returning initial streak');
      return StreakModel.initial();
    }

    final params = <String, dynamic>{
      'p_cards_reviewed': cardsReviewed,
      'p_review_date': reviewDate?.toIso8601String().split('T').first,
    };

    try {
      final response = await _client.rpc(_atomicUpdateRpc, params: params);
      return _streakFromSupabase(_extractSingleRow(response));
    } catch (e) {
      LoggerService.error('Failed to atomically update streak', e);
      rethrow;
    }
  }

  Map<String, dynamic> _extractSingleRow(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    }

    throw StateError('Unexpected RPC response shape for $_atomicUpdateRpc');
  }

  @override
  Future<void> resetStreak() async {
    if (!isAuthenticated) return;
    try {
      await _client
          .from(_tableName)
          .update({'current_streak': 0, 'last_review_date': null})
          .eq('user_id', _userId);
      LoggerService.debug('Streak reset in Supabase');
    } catch (e) {
      LoggerService.error('Failed to reset streak in Supabase', e);
      rethrow;
    }
  }

  @override
  Future<void> clearStreakData() async {
    try {
      await _client.from(_tableName).delete().eq('user_id', _userId);

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
      'last_review_date': streak.lastReviewDate?.toIso8601String().split(
        'T',
      )[0],
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
    final achievedMilestones =
        (json['achieved_milestones'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        [];

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
    return streak.toStatsMap();
  }

  @override
  Future<Map<String, int>> getDailyReviewData({int days = 30}) async {
    final streak = await loadStreak();
    return streak.dailyReviewDataForDays(days);
  }
}
