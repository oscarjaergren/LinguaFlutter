import 'package:json_annotation/json_annotation.dart';
import 'icon_model.dart';

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
    final id = 'card_${now.millisecondsSinceEpoch}';
    
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

  @override
  String toString() {
    return 'CardModel(id: $id, frontText: $frontText, backText: $backText, category: $category)';
  }
}
