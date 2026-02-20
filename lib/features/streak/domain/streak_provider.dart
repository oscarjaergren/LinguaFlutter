import 'package:flutter/foundation.dart';
import 'models/streak_model.dart';
import '../data/services/streak_service.dart';
import '../data/services/supabase_streak_service.dart';

/// Provider for managing streak state and operations.
/// Assumes user is authenticated - callers must ensure this.
class StreakProvider extends ChangeNotifier {
  final StreakService _streakService;

  /// Create a StreakProvider with optional service injection for testing.
  ///
  /// By default uses [SupabaseStreakService]. Pass a mock implementation
  /// for unit testing.
  StreakProvider({StreakService? streakService})
    : _streakService = streakService ?? SupabaseStreakService();

  StreakModel _streak = StreakModel.initial();
  bool _isLoading = false;
  String? _errorMessage;
  List<int> _newMilestones = [];
  int? _pendingCardsReviewed;
  DateTime? _pendingReviewDate;

  // Getters
  StreakModel get streak => _streak;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<int> get newMilestones => _newMilestones;

  // Computed properties
  int get currentStreak => _streak.currentStreak;
  int get bestStreak => _streak.bestStreak;
  int get totalCardsReviewed => _streak.totalCardsReviewed;
  int get totalReviewSessions => _streak.totalReviewSessions;
  int get cardsReviewedToday => _streak.cardsReviewedToday;
  double get averageCardsPerDay => _streak.averageCardsPerDay;
  List<int> get achievedMilestones => _streak.achievedMilestones;
  bool get isStreakActive => _streak.isStreakActive;
  bool get needsReviewToday => _streak.needsReviewToday;
  Map<String, int> get dailyReviewCounts => _streak.dailyReviewCounts;

  /// Load streak data from storage
  Future<void> loadStreak() async {
    if (_isLoading) return;

    _clearError();
    _setLoading(true);

    // Snapshot and clear pending values that existed before this load started.
    // Any concurrent updateStreakWithReview call that arrives during the await
    // below will see _isLoading==true and queue itself into _pendingCardsReviewed
    // fresh — those are "during-load" arrivals, distinct from pendingToFlush.
    final pendingToFlush = _pendingCardsReviewed;
    final pendingDateToFlush = _pendingReviewDate;
    if (pendingToFlush != null) {
      _pendingCardsReviewed = null;
      _pendingReviewDate = null;
    }

    bool loadSucceeded = false;
    try {
      _streak = await _streakService.loadStreak();
      loadSucceeded = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load streak data: $e');
      // Restore pre-load pending so it is not silently lost.
      if (pendingToFlush != null) {
        _pendingCardsReviewed = (_pendingCardsReviewed ?? 0) + pendingToFlush;
        if (pendingDateToFlush != null) {
          final existing = _pendingReviewDate;
          _pendingReviewDate =
              existing == null || pendingDateToFlush.isBefore(existing)
              ? pendingDateToFlush
              : existing;
        }
      }
    } finally {
      // Snapshot concurrent arrivals that queued themselves during the await.
      // Do this before _setLoading(false) so no new call slips through the
      // _isLoading==false window and gets double-counted.
      final duringLoadPending = _pendingCardsReviewed;
      final duringLoadDate = _pendingReviewDate;
      if (duringLoadPending != null) {
        _pendingCardsReviewed = null;
        _pendingReviewDate = null;
      }
      _setLoading(false);

      // On failure, restore during-load arrivals so they are not lost.
      // (Pre-load pending was already restored in the catch block above.)
      if (!loadSucceeded && duringLoadPending != null) {
        _pendingCardsReviewed =
            (_pendingCardsReviewed ?? 0) + duringLoadPending;
        if (duringLoadDate != null) {
          final existing = _pendingReviewDate;
          _pendingReviewDate =
              existing == null || duringLoadDate.isBefore(existing)
              ? duringLoadDate
              : existing;
        }
      }

      // On success, flush all pending in a single call to avoid double-counting.
      if (loadSucceeded) {
        final totalPending = (pendingToFlush ?? 0) + (duringLoadPending ?? 0);
        if (totalPending > 0) {
          DateTime? flushDate;
          if (pendingDateToFlush != null && duringLoadDate != null) {
            flushDate = pendingDateToFlush.isBefore(duringLoadDate)
                ? pendingDateToFlush
                : duringLoadDate;
          } else {
            flushDate = pendingDateToFlush ?? duringLoadDate;
          }
          await updateStreakWithReview(
            cardsReviewed: totalPending,
            reviewDate: flushDate,
          );
        }
      }
    }
  }

  /// Update streak with a review session.
  ///
  /// If a streak operation is already in progress, the [cardsReviewed] count
  /// is accumulated and applied once the current operation completes.
  Future<void> updateStreakWithReview({
    required int cardsReviewed,
    DateTime? reviewDate,
  }) async {
    if (_isLoading) {
      _pendingCardsReviewed = (_pendingCardsReviewed ?? 0) + cardsReviewed;
      // Keep the earliest non-null reviewDate so explicit dates aren't lost.
      final incoming = reviewDate;
      if (incoming != null) {
        final existing = _pendingReviewDate;
        _pendingReviewDate = existing == null || incoming.isBefore(existing)
            ? incoming
            : existing;
      }
      return;
    }

    _clearError();
    _setLoading(true);

    try {
      // Track previous streak for milestone detection
      final previousStreak = _streak.currentStreak;

      _streak = await _streakService.updateStreakWithReview(
        cardsReviewed: cardsReviewed,
        reviewDate: reviewDate,
      );

      // Check for new milestones
      _newMilestones = _streak.getNewMilestones(previousStreak);

      notifyListeners();
    } catch (e) {
      _setError('Failed to update streak: $e');
    } finally {
      _setLoading(false);
    }

    // Flush any update that arrived while we were loading.
    // Only flush when the primary call succeeded; if it failed, keep the
    // pending values so they can be applied via retryPendingUpdate.
    if (_errorMessage == null) {
      final pending = _pendingCardsReviewed;
      final pendingDate = _pendingReviewDate;
      if (pending != null) {
        _pendingCardsReviewed = null;
        _pendingReviewDate = null;
        await updateStreakWithReview(
          cardsReviewed: pending,
          reviewDate: pendingDate,
        );
        // If the flush call itself failed, restore the pending values so they
        // are not silently lost and can be retried via retryPendingUpdate.
        // Only add `pending` when no new concurrent call has already set
        // _pendingCardsReviewed (which would cause double-counting — Bug 6).
        if (_errorMessage != null) {
          _pendingCardsReviewed = (_pendingCardsReviewed ?? 0) + pending;
          if (pendingDate != null) {
            final existing = _pendingReviewDate;
            _pendingReviewDate =
                existing == null || pendingDate.isBefore(existing)
                ? pendingDate
                : existing;
          }
        }
      }
    }
  }

  /// Retry any pending streak update that was queued while a previous call
  /// was in progress but could not be flushed because that call failed.
  ///
  /// Call this after the error has been acknowledged (e.g. the user retries).
  Future<void> retryPendingUpdate() async {
    final pending = _pendingCardsReviewed;
    final pendingDate = _pendingReviewDate;
    if (pending == null) return;
    _pendingCardsReviewed = null;
    _pendingReviewDate = null;
    _clearError();
    await updateStreakWithReview(
      cardsReviewed: pending,
      reviewDate: pendingDate,
    );
  }

  /// Reset streak (but keep stats)
  Future<void> resetStreak() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      await _streakService.resetStreak();
      _streak = await _streakService.loadStreak();
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset streak: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all streak data
  Future<void> clearStreakData() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      await _streakService.clearStreakData();
      _streak = StreakModel.initial();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear streak data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get daily review data for charts
  Future<Map<String, int>> getDailyReviewData({int days = 30}) async {
    try {
      return await _streakService.getDailyReviewData(days: days);
    } catch (e) {
      _setError('Failed to get daily review data: $e');
      return {};
    }
  }

  /// Get comprehensive streak statistics
  Future<Map<String, dynamic>> getStreakStats() async {
    try {
      return await _streakService.getStreakStats();
    } catch (e) {
      _setError('Failed to get streak stats: $e');
      return {};
    }
  }

  /// Clear new milestones (after showing them to user)
  void clearNewMilestones() {
    _newMilestones = [];
    notifyListeners();
  }

  /// Record a card review (for integration with CardManagementProvider)
  Future<void> recordCardReview() async {
    await updateStreakWithReview(cardsReviewed: 1);
  }

  /// Get motivational message based on current streak
  String getMotivationalMessage() {
    if (currentStreak == 0) {
      return "Start your learning streak today! 🚀";
    } else if (currentStreak == 1) {
      return "Great start! Keep the momentum going! 💪";
    } else if (currentStreak < 7) {
      return "You're on fire! $currentStreak days strong! 🔥";
    } else if (currentStreak < 30) {
      return "Amazing! $currentStreak days of consistent learning! ⭐";
    } else if (currentStreak < 100) {
      return "Incredible dedication! $currentStreak days! 🏆";
    } else {
      return "Legendary! $currentStreak days of unstoppable learning! 👑";
    }
  }

  /// Get streak status color
  String getStreakStatusColor() {
    if (currentStreak == 0) return 'grey';
    if (currentStreak < 7) return 'blue';
    if (currentStreak < 30) return 'green';
    if (currentStreak < 100) return 'orange';
    return 'purple';
  }

  /// Check if milestone was recently achieved
  bool isNewMilestone(int milestone) {
    return _newMilestones.contains(milestone);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // No resources to dispose
    super.dispose();
  }
}
