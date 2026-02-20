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
  Future<void> _operationQueue = Future<void>.value();
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  List<int> _newMilestones = [];

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

  /// Load streak data from storage.
  Future<void> loadStreak() async {
    return _runStreakOperation(() async {
      _streak = await _streakService.loadStreak();
      _notifyIfAlive();
    }, errorPrefix: 'Failed to load streak data');
  }

  /// Update streak with a review session.
  Future<void> updateStreakWithReview({
    required int cardsReviewed,
    DateTime? reviewDate,
  }) async {
    return _runStreakOperation(() async {
      final previousStreak = _streak.currentStreak;
      _streak = await _streakService.updateStreakWithReview(
        cardsReviewed: cardsReviewed,
        reviewDate: reviewDate,
      );
      _newMilestones = _streak.getNewMilestones(previousStreak);
      _notifyIfAlive();
    }, errorPrefix: 'Failed to update streak');
  }

  /// Reset streak (but keep stats)
  Future<void> resetStreak() async {
    return _runStreakOperation(() async {
      await _streakService.resetStreak();
      _streak = await _streakService.loadStreak();
      _notifyIfAlive();
    }, errorPrefix: 'Failed to reset streak');
  }

  /// Clear all streak data
  Future<void> clearStreakData() async {
    return _runStreakOperation(() async {
      await _streakService.clearStreakData();
      _streak = StreakModel.initial();
      _notifyIfAlive();
    }, errorPrefix: 'Failed to clear streak data');
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
    _notifyIfAlive();
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
  Future<void> _runStreakOperation(
    Future<void> Function() action, {
    required String errorPrefix,
  }) {
    final future = _operationQueue.then((_) async {
      _clearError();
      _setLoading(true);

      try {
        await action();
      } catch (e) {
        _setError('$errorPrefix: $e');
      } finally {
        _setLoading(false);
      }
    });

    _operationQueue = future.catchError((_) {});
    return future;
  }

  void _setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    _notifyIfAlive();
  }

  void _setError(String error) {
    if (_isDisposed) return;
    _errorMessage = error;
    _notifyIfAlive();
  }

  void _clearError() {
    if (_isDisposed) return;
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
