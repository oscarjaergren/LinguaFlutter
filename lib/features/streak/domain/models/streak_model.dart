import 'package:json_annotation/json_annotation.dart';

part 'streak_model.g.dart';

/// Model representing user's learning streak data
@JsonSerializable()
class StreakModel {
  /// Current active streak in days
  final int currentStreak;

  /// Best streak ever achieved
  final int bestStreak;

  /// Last review date (to calculate if streak is broken)
  final DateTime? lastReviewDate;

  /// Total number of review sessions
  final int totalReviewSessions;

  /// Total cards reviewed across all sessions
  final int totalCardsReviewed;

  /// Map of date strings to number of cards reviewed that day
  final Map<String, int> dailyReviewCounts;

  /// Streak milestones achieved (e.g., [7, 14, 30, 50, 100])
  final List<int> achievedMilestones;

  /// Date when the streak was started
  final DateTime? streakStartDate;

  /// Date when the best streak was achieved
  final DateTime? bestStreakDate;

  const StreakModel({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastReviewDate,
    this.totalReviewSessions = 0,
    this.totalCardsReviewed = 0,
    this.dailyReviewCounts = const {},
    this.achievedMilestones = const [],
    this.streakStartDate,
    this.bestStreakDate,
  });

  /// Create initial streak model
  factory StreakModel.initial() {
    return const StreakModel();
  }

  /// Check if the streak is currently active (reviewed today or yesterday)
  bool get isStreakActive {
    if (lastReviewDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReview = DateTime(
      lastReviewDate!.year,
      lastReviewDate!.month,
      lastReviewDate!.day,
    );

    final daysDiff = today.difference(lastReview).inDays;

    // Streak is active if reviewed today (0 days) or yesterday (1 day)
    return daysDiff <= 1;
  }

  /// Check if user needs to review today to maintain streak
  bool get needsReviewToday {
    if (lastReviewDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReview = DateTime(
      lastReviewDate!.year,
      lastReviewDate!.month,
      lastReviewDate!.day,
    );

    return today.isAfter(lastReview);
  }

  /// Get number of cards reviewed today
  int get cardsReviewedToday {
    final today = _formatDate(DateTime.now());
    return dailyReviewCounts[today] ?? 0;
  }

  /// Get average cards per day for current streak.
  ///
  /// Anchors to [lastReviewDate] so the window is correct even when the user
  /// hasn't reviewed yet today (streak is still active via the 1-day grace).
  double get averageCardsPerDay {
    if (currentStreak == 0 || lastReviewDate == null) return 0.0;

    final anchor = DateTime(
      lastReviewDate!.year,
      lastReviewDate!.month,
      lastReviewDate!.day,
    );
    final streakDays = <String>[];

    for (int i = 0; i < currentStreak; i++) {
      final date = anchor.subtract(Duration(days: i));
      streakDays.add(_formatDate(date));
    }

    final totalCards = streakDays
        .map((date) => dailyReviewCounts[date] ?? 0)
        .fold(0, (sum, count) => sum + count);

    return totalCards / currentStreak;
  }

  /// Get new milestones achieved for this streak level
  List<int> getNewMilestones(int previousStreak) {
    const milestones = [3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365];

    return milestones
        .where(
          (milestone) =>
              currentStreak >= milestone &&
              previousStreak < milestone &&
              !achievedMilestones.contains(milestone),
        )
        .toList();
  }

  /// Reset streak (for testing or manual reset)
  StreakModel resetStreak() {
    return copyWith(
      currentStreak: 0,
      clearLastReviewDate: true,
      clearStreakStartDate: true,
    );
  }

  /// Get streak status message
  String get statusMessage {
    if (currentStreak == 0) {
      return "Start your streak today!";
    } else if (needsReviewToday && isStreakActive) {
      return "Keep your $currentStreak-day streak alive!";
    } else if (!isStreakActive) {
      return "Your streak ended. Start a new one!";
    } else {
      return "$currentStreak-day streak! Great job!";
    }
  }

  /// Get motivation message based on streak level
  String get motivationMessage {
    if (currentStreak == 0) {
      return "Every journey begins with a single step!";
    } else if (currentStreak < 7) {
      return "Building momentum! Keep going!";
    } else if (currentStreak < 30) {
      return "Habit is forming! You're doing great!";
    } else if (currentStreak < 100) {
      return "Incredible dedication! You're unstoppable!";
    } else {
      return "LEGENDARY! You're a learning machine!";
    }
  }

  /// Returns a stats map for display or persistence.
  Map<String, dynamic> toStatsMap() => {
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'totalSessions': totalReviewSessions,
    'totalCards': totalCardsReviewed,
    'cardsToday': cardsReviewedToday,
    'averageCardsPerDay': averageCardsPerDay,
    'milestones': achievedMilestones,
    'isActive': isStreakActive,
    'needsReview': needsReviewToday,
  };

  /// Returns daily review counts for the last [days] days.
  Map<String, int> dailyReviewDataForDays(int days) {
    final now = DateTime.now();
    final data = <String, int>{};

    for (int i = 0; i < days; i++) {
      final dateKey = _formatDate(now.subtract(Duration(days: i)));
      data[dateKey] = dailyReviewCounts[dateKey] ?? 0;
    }

    return data;
  }

  /// Format date as string key
  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Create a copy with updated properties
  StreakModel copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastReviewDate,
    int? totalReviewSessions,
    int? totalCardsReviewed,
    Map<String, int>? dailyReviewCounts,
    List<int>? achievedMilestones,
    DateTime? streakStartDate,
    DateTime? bestStreakDate,
    bool clearLastReviewDate = false,
    bool clearStreakStartDate = false,
    bool clearBestStreakDate = false,
  }) {
    return StreakModel(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastReviewDate: clearLastReviewDate
          ? null
          : (lastReviewDate ?? this.lastReviewDate),
      totalReviewSessions: totalReviewSessions ?? this.totalReviewSessions,
      totalCardsReviewed: totalCardsReviewed ?? this.totalCardsReviewed,
      dailyReviewCounts: dailyReviewCounts ?? this.dailyReviewCounts,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
      streakStartDate: clearStreakStartDate
          ? null
          : (streakStartDate ?? this.streakStartDate),
      bestStreakDate: clearBestStreakDate
          ? null
          : (bestStreakDate ?? this.bestStreakDate),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$StreakModelToJson(this);

  /// Create from JSON
  factory StreakModel.fromJson(Map<String, dynamic> json) =>
      _$StreakModelFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreakModel &&
        other.currentStreak == currentStreak &&
        other.bestStreak == bestStreak &&
        other.lastReviewDate == lastReviewDate &&
        other.totalReviewSessions == totalReviewSessions &&
        other.totalCardsReviewed == totalCardsReviewed;
  }

  @override
  int get hashCode => Object.hash(
    currentStreak,
    bestStreak,
    lastReviewDate,
    totalReviewSessions,
    totalCardsReviewed,
  );

  @override
  String toString() {
    return 'StreakModel(currentStreak: $currentStreak, bestStreak: $bestStreak, totalSessions: $totalReviewSessions)';
  }
}
