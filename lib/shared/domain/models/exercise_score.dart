import 'package:json_annotation/json_annotation.dart';
import 'exercise_type.dart';

part 'exercise_score.g.dart';

/// Tracks performance statistics for a specific exercise type on a card
@JsonSerializable()
class ExerciseScore {
  /// The type of exercise this score tracks
  final ExerciseType type;

  /// Number of correct answers for this exercise type
  final int correctCount;

  /// Number of incorrect answers for this exercise type
  final int incorrectCount;

  /// Current streak of consecutive correct answers
  final int currentStreak;

  /// Best streak achieved for this exercise
  final int bestStreak;

  /// Last time this exercise was practiced
  final DateTime? lastPracticed;

  /// Next scheduled review for this exercise type
  final DateTime? nextReview;

  const ExerciseScore({
    required this.type,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastPracticed,
    this.nextReview,
  });

  /// Create a new exercise score with zero values
  factory ExerciseScore.initial(ExerciseType type) {
    return ExerciseScore(type: type);
  }

  /// Total number of attempts for this exercise type
  int get totalAttempts => correctCount + incorrectCount;

  /// Success rate as a percentage (0-100)
  double get successRate {
    if (totalAttempts == 0) return 0.0;
    return (correctCount / totalAttempts) * 100;
  }

  /// Whether this exercise is due for review
  bool get isDueForReview {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }

  /// Mastery level for this specific exercise type
  /// Based on current streak: 5+ correct in a row = Mastered
  String get masteryLevel {
    if (currentStreak >= 5) return 'Mastered';
    if (totalAttempts == 0) return 'New';
    if (currentStreak >= 3) return 'Good';
    if (currentStreak >= 1) return 'Learning';
    return 'Difficult';
  }

  /// Progress toward mastery (0.0 to 1.0)
  /// Shows how close to achieving 5-streak mastery
  double get masteryProgress {
    return (currentStreak / 5.0).clamp(0.0, 1.0);
  }

  /// Number of correct answers needed to reach mastery
  int get answersToMastery {
    return (5 - currentStreak).clamp(0, 5);
  }

  /// Net score (correct - incorrect)
  int get netScore => correctCount - incorrectCount;

  /// Record a correct answer and return updated score
  ExerciseScore recordCorrect() {
    final now = DateTime.now();
    final newStreak = currentStreak + 1;
    final newBestStreak = newStreak > bestStreak ? newStreak : bestStreak;

    // Calculate next review using spaced repetition
    // Use currentStreak for progressive intervals, not overall correctCount
    final streakMultiplier = (currentStreak + 1) / 1.0;
    final baseDays = 1;
    final intervalDays = (baseDays * (1 + streakMultiplier * 2)).round();
    final nextReviewDate = now.add(Duration(days: intervalDays));

    return copyWith(
      correctCount: correctCount + 1,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      lastPracticed: now,
      nextReview: nextReviewDate,
    );
  }

  /// Record an incorrect answer and return updated score
  /// Wrong answer decreases streak by 1 (minimum 0)
  ExerciseScore recordIncorrect() {
    final now = DateTime.now();

    // Review again tomorrow if incorrect
    final nextReviewDate = now.add(const Duration(days: 1));

    return copyWith(
      incorrectCount: incorrectCount + 1,
      currentStreak: currentStreak - 1,
      lastPracticed: now,
      nextReview: nextReviewDate,
    );
  }

  /// Create a copy with updated fields
  /// Ensures currentStreak never goes below 0
  /// bestStreak has no upper limit and can grow indefinitely
  ExerciseScore copyWith({
    ExerciseType? type,
    int? correctCount,
    int? incorrectCount,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastPracticed,
    DateTime? nextReview,
  }) {
    final newStreak = currentStreak ?? this.currentStreak;
    return ExerciseScore(
      type: type ?? this.type,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      currentStreak: newStreak < 0 ? 0 : newStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      nextReview: nextReview ?? this.nextReview,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ExerciseScoreToJson(this);

  /// Create from JSON
  factory ExerciseScore.fromJson(Map<String, dynamic> json) =>
      _$ExerciseScoreFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseScore && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() {
    return 'ExerciseScore(type: ${type.displayName}, correct: $correctCount, incorrect: $incorrectCount, streak: $currentStreak/$bestStreak, rate: ${successRate.toStringAsFixed(1)}%)';
  }
}
