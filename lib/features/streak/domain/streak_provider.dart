import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/streak_model.dart';
import 'models/streak_state.dart';
import '../data/services/streak_service.dart';
import '../data/services/supabase_streak_service.dart';
import '../../../shared/services/logger_service.dart';

/// Riverpod provider — override in tests to inject a mock [StreakService].
final streakServiceProvider = Provider<StreakService>(
  (ref) => SupabaseStreakService(),
);

final streakNotifierProvider = NotifierProvider<StreakNotifier, StreakState>(
  StreakNotifier.new,
);

/// Manages streak state using Riverpod [Notifier].
///
/// Loading/error state lives in [StreakState] — no manual
/// `_setLoading`/`_setError` boilerplate needed.
class StreakNotifier extends Notifier<StreakState> {
  StreakService get _service => ref.read(streakServiceProvider);

  Future<void> _operationQueue = Future<void>.value();

  @override
  StreakState build() => StreakState.initial();

  /// Load streak data from storage.
  Future<void> loadStreak() => _enqueue('Failed to load streak data', () async {
    final streak = await _service.loadStreak();
    state = state.copyWith(streak: streak);
  });

  /// Update streak with a review session.
  Future<void> updateStreakWithReview({
    required int cardsReviewed,
    DateTime? reviewDate,
  }) => _enqueue('Failed to update streak', () async {
    final previousStreak = state.streak.currentStreak;
    final updated = await _service.updateStreakWithReview(
      cardsReviewed: cardsReviewed,
      reviewDate: reviewDate,
    );
    state = state.copyWith(
      streak: updated,
      newMilestones: updated.getNewMilestones(previousStreak),
    );
  });

  /// Reset streak (but keep stats).
  Future<void> resetStreak() => _enqueue('Failed to reset streak', () async {
    await _service.resetStreak();
    final streak = await _service.loadStreak();
    state = state.copyWith(streak: streak);
  });

  /// Clear all streak data.
  Future<void> clearStreakData() =>
      _enqueue('Failed to clear streak data', () async {
        await _service.clearStreakData();
        state = state.copyWith(streak: StreakModel.initial());
      });

  /// Get daily review data for charts.
  Future<Map<String, int>> getDailyReviewData({int days = 30}) async {
    try {
      return await _service.getDailyReviewData(days: days);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to get daily review data', e, stackTrace);
      state = state.copyWith(
        errorMessage: 'Failed to get daily review data: $e',
      );
      return {};
    }
  }

  /// Get comprehensive streak statistics.
  Future<Map<String, dynamic>> getStreakStats() async {
    try {
      return await _service.getStreakStats();
    } catch (e, stackTrace) {
      LoggerService.error('Failed to get streak stats', e, stackTrace);
      state = state.copyWith(errorMessage: 'Failed to get streak stats: $e');
      return {};
    }
  }

  /// Clear new milestones after showing them to the user.
  void clearNewMilestones() {
    state = state.copyWith(newMilestones: []);
  }

  /// Record a single card review.
  Future<void> recordCardReview() => updateStreakWithReview(cardsReviewed: 1);

  /// Get streak status color.
  String getStreakStatusColor() {
    final current = state.streak.currentStreak;
    if (current == 0) return 'grey';
    if (current < 7) return 'blue';
    if (current < 30) return 'green';
    if (current < 100) return 'orange';
    return 'purple';
  }

  /// Check if a milestone was recently achieved.
  bool isNewMilestone(int milestone) => state.newMilestones.contains(milestone);

  // Serializes operations so concurrent calls don't race.
  Future<void> _enqueue(String errorPrefix, Future<void> Function() action) {
    final future = _operationQueue.then((_) async {
      state = state.copyWith(isLoading: true, errorMessage: null);
      try {
        await action();
      } catch (e, stackTrace) {
        LoggerService.error(errorPrefix, e, stackTrace);
        state = state.copyWith(errorMessage: '$errorPrefix: $e');
      } finally {
        state = state.copyWith(isLoading: false);
      }
    });

    _operationQueue = future.catchError((_) {});
    return future;
  }
}
