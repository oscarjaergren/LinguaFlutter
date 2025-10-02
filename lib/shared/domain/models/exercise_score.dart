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
  
  /// Last time this exercise was practiced
  final DateTime? lastPracticed;
  
  /// Next scheduled review for this exercise type
  final DateTime? nextReview;

  const ExerciseScore({
    required this.type,
    this.correctCount = 0,
    this.incorrectCount = 0,
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
  String get masteryLevel {
    if (totalAttempts < 3) return 'New';
    
    final rate = successRate;
    if (rate >= 90) return 'Mastered';
    if (rate >= 70) return 'Good';
    if (rate >= 50) return 'Learning';
    return 'Difficult';
  }
  
  /// Net score (correct - incorrect)
  int get netScore => correctCount - incorrectCount;

  /// Record a correct answer and return updated score
  ExerciseScore recordCorrect() {
    final now = DateTime.now();
    
    // Calculate next review using spaced repetition
    final multiplier = (correctCount + 1) / (totalAttempts + 1);
    final baseDays = 1;
    final intervalDays = (baseDays * (1 + multiplier * 2)).round();
    final nextReviewDate = now.add(Duration(days: intervalDays));
    
    return copyWith(
      correctCount: correctCount + 1,
      lastPracticed: now,
      nextReview: nextReviewDate,
    );
  }

  /// Record an incorrect answer and return updated score
  ExerciseScore recordIncorrect() {
    final now = DateTime.now();
    
    // Review again tomorrow if incorrect
    final nextReviewDate = now.add(const Duration(days: 1));
    
    return copyWith(
      incorrectCount: incorrectCount + 1,
      lastPracticed: now,
      nextReview: nextReviewDate,
    );
  }

  /// Create a copy with updated fields
  ExerciseScore copyWith({
    ExerciseType? type,
    int? correctCount,
    int? incorrectCount,
    DateTime? lastPracticed,
    DateTime? nextReview,
  }) {
    return ExerciseScore(
      type: type ?? this.type,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
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
    return 'ExerciseScore(type: ${type.displayName}, correct: $correctCount, incorrect: $incorrectCount, rate: ${successRate.toStringAsFixed(1)}%)';
  }
}
