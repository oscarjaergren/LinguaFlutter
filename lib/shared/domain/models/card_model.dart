import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'icon_model.dart';
import 'exercise_type.dart';
import 'exercise_score.dart';

part 'card_model.g.dart';

/// Model representing a language learning card
@JsonSerializable()
class CardModel {
  /// Unique identifier for the card
  final String id;
  
  /// Front text of the card (usually the term to learn)
  final String frontText;
  
  /// Back text of the card (usually the translation/definition)
  final String backText;
  
  /// Optional icon associated with the card
  final IconModel? icon;
  
  /// Language code for this card (e.g., 'de', 'es', 'fr')
  final String language;
  
  /// Category or deck this card belongs to
  final String category;
  
  /// Tags for organizing cards
  final List<String> tags;
  
  /// Difficulty level (1-5, where 1 is easiest)
  final int difficulty;
  
  /// German article for nouns (der, die, das) - only used for German language cards
  final String? germanArticle;
  
  /// Number of times this card has been reviewed
  final int reviewCount;
  
  /// Number of times this card was answered correctly
  final int correctCount;
  
  /// Last review date
  final DateTime? lastReviewed;
  
  /// Next review date (for spaced repetition)
  final DateTime? nextReview;
  
  /// Creation date
  final DateTime createdAt;
  
  /// Last modification date
  final DateTime updatedAt;
  
  /// Whether this card is marked as favorite
  final bool isFavorite;
  
  /// Whether this card is archived
  final bool isArchived;
  
  /// Exercise-specific scores for different practice types
  /// Maps ExerciseType to ExerciseScore tracking performance
  final Map<ExerciseType, ExerciseScore> exerciseScores;

  const CardModel({
    required this.id,
    required this.frontText,
    required this.backText,
    this.icon,
    required this.language,
    required this.category,
    this.tags = const [],
    this.difficulty = 1,
    this.germanArticle,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.lastReviewed,
    this.nextReview,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isArchived = false,
    this.exerciseScores = const {},
  });

  /// Create a new card with generated ID and timestamps
  factory CardModel.create({
    required String frontText,
    required String backText,
    IconModel? icon,
    required String language,
    required String category,
    List<String> tags = const [],
    int difficulty = 1,
    String? germanArticle,
  }) {
    final now = DateTime.now();
    // Use UUID v4 for proper unique IDs instead of timestamp-based IDs
    final id = const Uuid().v4();
    
    // Initialize exercise scores for all implemented exercise types
    final exerciseScores = <ExerciseType, ExerciseScore>{};
    for (final type in ExerciseType.values) {
      if (type.isImplemented) {
        exerciseScores[type] = ExerciseScore.initial(type);
      }
    }
    
    return CardModel(
      id: id,
      frontText: frontText,
      backText: backText,
      icon: icon,
      language: language,
      category: category,
      tags: tags,
      difficulty: difficulty,
      germanArticle: germanArticle,
      createdAt: now,
      updatedAt: now,
      exerciseScores: exerciseScores,
    );
  }

  /// Calculate success rate as a percentage
  double get successRate {
    if (reviewCount == 0) return 0.0;
    return (correctCount / reviewCount) * 100;
  }
  
  /// Check if this card is due for review
  bool get isDueForReview {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }
  
  /// Get the current mastery level based on success rate and review count
  String get masteryLevel {
    if (reviewCount < 3) return 'New';
    
    final rate = successRate;
    if (rate >= 90) return 'Mastered';
    if (rate >= 70) return 'Good';
    if (rate >= 50) return 'Learning';
    return 'Difficult';
  }
  
  /// Get the score for a specific exercise type
  ExerciseScore? getExerciseScore(ExerciseType type) {
    return exerciseScores[type];
  }
  
  /// Get overall mastery across all exercise types
  String get overallMasteryLevel {
    if (exerciseScores.isEmpty) return masteryLevel;
    
    final totalAttempts = exerciseScores.values
        .fold<int>(0, (sum, score) => sum + score.totalAttempts);
    
    if (totalAttempts < 5) return 'New';
    
    final totalCorrect = exerciseScores.values
        .fold<int>(0, (sum, score) => sum + score.correctCount);
    
    final overallRate = (totalCorrect / totalAttempts) * 100;
    
    if (overallRate >= 90) return 'Mastered';
    if (overallRate >= 70) return 'Good';
    if (overallRate >= 50) return 'Learning';
    return 'Difficult';
  }
  
  /// Check if a specific exercise type is due for review
  bool isExerciseDue(ExerciseType type) {
    final score = exerciseScores[type];
    return score?.isDueForReview ?? true;
  }
  
  /// Get list of exercise types that are due for review
  List<ExerciseType> get dueExerciseTypes {
    return exerciseScores.entries
        .where((entry) => entry.value.isDueForReview)
        .map((entry) => entry.key)
        .toList();
  }

  /// Create a copy of this card with updated review data
  CardModel copyWithReview({
    required bool wasCorrect,
    DateTime? nextReviewDate,
  }) {
    return copyWith(
      reviewCount: reviewCount + 1,
      correctCount: wasCorrect ? correctCount + 1 : correctCount,
      lastReviewed: DateTime.now(),
      nextReview: nextReviewDate,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a copy with updated exercise score for a specific type
  CardModel copyWithExerciseResult({
    required ExerciseType exerciseType,
    required bool wasCorrect,
  }) {
    final currentScore = exerciseScores[exerciseType] ?? 
        ExerciseScore.initial(exerciseType);
    
    final updatedScore = wasCorrect 
        ? currentScore.recordCorrect() 
        : currentScore.recordIncorrect();
    
    final newScores = Map<ExerciseType, ExerciseScore>.from(exerciseScores);
    newScores[exerciseType] = updatedScore;
    
    // Also update legacy fields for backward compatibility
    return copyWith(
      exerciseScores: newScores,
      reviewCount: reviewCount + 1,
      correctCount: wasCorrect ? correctCount + 1 : correctCount,
      lastReviewed: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy of this card with updated properties
  CardModel copyWith({
    String? id,
    String? frontText,
    String? backText,
    IconModel? icon,
    String? language,
    String? category,
    List<String>? tags,
    int? difficulty,
    String? germanArticle,
    int? reviewCount,
    int? correctCount,
    DateTime? lastReviewed,
    DateTime? nextReview,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isArchived,
    Map<ExerciseType, ExerciseScore>? exerciseScores,
  }) {
    return CardModel(
      id: id ?? this.id,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      icon: icon ?? this.icon,
      language: language ?? this.language,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      germanArticle: germanArticle ?? this.germanArticle,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      exerciseScores: exerciseScores ?? this.exerciseScores,
    );
  }

  /// Convert this card to JSON
  Map<String, dynamic> toJson() => _$CardModelToJson(this);

  /// Create a card from JSON
  factory CardModel.fromJson(Map<String, dynamic> json) => _$CardModelFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Convenience getters for backward compatibility
  String get front => frontText;
  String get back => backText;
  bool get isDue => isDueForReview;

  /// Process a card answer and return updated card with spaced repetition logic
  CardModel processAnswer(CardAnswer answer) {
    final wasCorrect = answer == CardAnswer.correct;
    DateTime? nextReviewDate;
    
    if (wasCorrect) {
      // Spaced repetition: increase interval based on difficulty and success
      final baseInterval = switch (difficulty) {
        1 => 1, // 1 day
        2 => 3, // 3 days  
        3 => 7, // 1 week
        4 => 14, // 2 weeks
        5 => 30, // 1 month
        _ => 1,
      };
      
      final multiplier = (correctCount / (reviewCount + 1)) + 1;
      final intervalDays = (baseInterval * multiplier).round();
      nextReviewDate = DateTime.now().add(Duration(days: intervalDays));
    } else {
      // If incorrect, review again tomorrow
      nextReviewDate = DateTime.now().add(const Duration(days: 1));
    }
    
    return copyWithReview(
      wasCorrect: wasCorrect,
      nextReviewDate: nextReviewDate,
    );
  }

  @override
  String toString() {
    return 'CardModel(id: $id, frontText: $frontText, backText: $backText, category: $category)';
  }
}

/// Enum for card review answers
enum CardAnswer {
  correct,
  incorrect,
  skip,
}
