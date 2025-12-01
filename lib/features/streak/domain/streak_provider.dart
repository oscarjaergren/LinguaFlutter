import 'package:flutter/foundation.dart';
import 'models/streak_model.dart';
import '../data/streak_service.dart';

/// Provider for managing streak state and operations
class StreakProvider extends ChangeNotifier {
  final StreakService _streakService = StreakService();
  
  StreakModel _streak = StreakModel.initial();
  bool _isLoading = false;
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
  
  /// Load streak data from storage
  Future<void> loadStreak() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      _streak = await _streakService.loadStreak();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load streak data: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Update streak with a review session
  Future<void> updateStreakWithReview({
    required int cardsReviewed,
    DateTime? reviewDate,
  }) async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Check for new milestones before updating
      final newMilestones = await _streakService.checkNewMilestones(cardsReviewed);
      _newMilestones = newMilestones;
      
      // Update streak
      _streak = await _streakService.updateStreakWithReview(
        cardsReviewed: cardsReviewed,
        reviewDate: reviewDate,
      );
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update streak: $e');
    } finally {
      _setLoading(false);
    }
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
  
  /// Reset session state (call when screen is reopened)
  void resetSession() {
    // Session reset functionality if needed
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
    _errorMessage = null;
  }
  
  @override
  void dispose() {
    _streakService.dispose();
    super.dispose();
  }
}
