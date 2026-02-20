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

  /// Current chain of consecutive correct answers
  final int currentChain;

  /// Best chain achieved for this exercise
  final int bestChain;

  /// Last time this exercise was practiced
  final DateTime? lastPracticed;

  /// Next scheduled review for this exercise type
  final DateTime? nextReview;

  const ExerciseScore({
    required this.type,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.currentChain = 0,
    this.bestChain = 0,
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
  /// Based on current chain: 5+ correct in a row = Mastered
  String get masteryLevel {
    if (currentChain >= 5) return 'Mastered';
    if (totalAttempts == 0) return 'New';
    if (currentChain >= 3) return 'Good';
    if (currentChain >= 1) return 'Learning';
    return 'Difficult';
  }

  /// Progress toward mastery (0.0 to 1.0)
  /// Shows how close to achieving 5-chain mastery
  double get masteryProgress {
    return (currentChain / 5.0).clamp(0.0, 1.0);
  }

  /// Number of correct answers needed to reach mastery
  int get answersToMastery {
    return (5 - currentChain).clamp(0, 5);
  }

  /// Net score (correct - incorrect)
  int get netScore => correctCount - incorrectCount;

  /// Record a correct answer and return updated score
  ExerciseScore recordCorrect() {
    final now = DateTime.now();
    final newChain = currentChain + 1;
    final newBestChain = newChain > bestChain ? newChain : bestChain;

    // Calculate next review using spaced repetition
    // Use currentChain for progressive intervals, not overall correctCount
    final chainMultiplier = (currentChain + 1) / 1.0;
    final baseDays = 1;
    final intervalDays = (baseDays * (1 + chainMultiplier * 2)).round();
    final nextReviewDate = now.add(Duration(days: intervalDays));

    return copyWith(
      correctCount: correctCount + 1,
      currentChain: newChain,
      bestChain: newBestChain,
      lastPracticed: now,
      nextReview: nextReviewDate,
    );
  }

  /// Record an incorrect answer and return updated score
  /// Wrong answer decreases chain by 1 (minimum 0)
  ExerciseScore recordIncorrect() {
    final now = DateTime.now();

    // Review again tomorrow if incorrect
    final nextReviewDate = now.add(const Duration(days: 1));

    return copyWith(
      incorrectCount: incorrectCount + 1,
      currentChain: currentChain - 1,
      lastPracticed: now,
      nextReview: nextReviewDate,
    );
  }

  /// Create a copy with updated fields
  /// Ensures currentChain never goes below 0
  /// bestChain has no upper limit and can grow indefinitely
  ExerciseScore copyWith({
    ExerciseType? type,
    int? correctCount,
    int? incorrectCount,
    int? currentChain,
    int? bestChain,
    DateTime? lastPracticed,
    DateTime? nextReview,
  }) {
    final newChain = currentChain ?? this.currentChain;
    return ExerciseScore(
      type: type ?? this.type,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      currentChain: newChain < 0 ? 0 : newChain,
      bestChain: bestChain ?? this.bestChain,
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
    return other is ExerciseScore &&
        other.type == type &&
        other.correctCount == correctCount &&
        other.incorrectCount == incorrectCount &&
        other.currentChain == currentChain &&
        other.bestChain == bestChain;
  }

  @override
  int get hashCode =>
      Object.hash(type, correctCount, incorrectCount, currentChain, bestChain);

  @override
  String toString() {
    return 'ExerciseScore(type: ${type.displayName}, correct: $correctCount, incorrect: $incorrectCount, chain: $currentChain/$bestChain, rate: ${successRate.toStringAsFixed(1)}%)';
  }
}
