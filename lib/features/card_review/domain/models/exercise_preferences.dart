import '../../../../shared/domain/models/exercise_type.dart';

/// Categories for grouping exercise types
enum ExerciseCategory {
  /// Recognition exercises - passive recall
  recognition,
  /// Production exercises - active recall/output
  production,
}

/// Extension to add grouping to ExerciseType
extension ExerciseTypeGrouping on ExerciseType {
  /// Get the category this exercise type belongs to
  ExerciseCategory get category {
    switch (this) {
      case ExerciseType.readingRecognition:
      case ExerciseType.multipleChoiceText:
      case ExerciseType.multipleChoiceIcon:
      case ExerciseType.listeningRecognition:
      case ExerciseType.articleSelection:
        return ExerciseCategory.recognition;
      case ExerciseType.writingTranslation:
      case ExerciseType.reverseTranslation:
      case ExerciseType.speakingPronunciation:
      case ExerciseType.sentenceFill:
      case ExerciseType.sentenceBuilding:
      case ExerciseType.conjugationPractice:
        return ExerciseCategory.production;
    }
  }

  /// Whether this is a recognition exercise
  bool get isRecognition => category == ExerciseCategory.recognition;

  /// Whether this is a production exercise
  bool get isProduction => category == ExerciseCategory.production;
}

/// Extension for ExerciseCategory display
extension ExerciseCategoryExtension on ExerciseCategory {
  String get displayName {
    switch (this) {
      case ExerciseCategory.recognition:
        return 'Recognition';
      case ExerciseCategory.production:
        return 'Production';
    }
  }

  String get description {
    switch (this) {
      case ExerciseCategory.recognition:
        return 'See or hear, then identify the meaning';
      case ExerciseCategory.production:
        return 'Actively produce the translation';
    }
  }

  /// Get all exercise types in this category
  List<ExerciseType> get exerciseTypes {
    return ExerciseType.values
        .where((t) => t.category == this && t.isImplemented)
        .toList();
  }
}

/// User preferences for exercise type selection
class ExercisePreferences {
  /// Set of enabled exercise types
  final Set<ExerciseType> enabledTypes;

  /// Whether to prioritize weak exercise types
  final bool prioritizeWeaknesses;

  /// Weakness threshold - exercise types below this success rate are considered weak
  final double weaknessThreshold;

  const ExercisePreferences({
    required this.enabledTypes,
    this.prioritizeWeaknesses = true,
    this.weaknessThreshold = 70.0,
  });

  /// Create default preferences with all implemented types enabled
  factory ExercisePreferences.defaults() {
    return ExercisePreferences(
      enabledTypes: ExerciseType.values
          .where((t) => t.isImplemented)
          .toSet(),
    );
  }

  /// Check if an exercise type is enabled
  bool isEnabled(ExerciseType type) => enabledTypes.contains(type);

  /// Check if a category is fully enabled
  bool isCategoryFullyEnabled(ExerciseCategory category) {
    final typesInCategory = category.exerciseTypes;
    return typesInCategory.every((t) => enabledTypes.contains(t));
  }

  /// Check if a category is partially enabled
  bool isCategoryPartiallyEnabled(ExerciseCategory category) {
    final typesInCategory = category.exerciseTypes;
    final enabledInCategory = typesInCategory.where((t) => enabledTypes.contains(t));
    return enabledInCategory.isNotEmpty && enabledInCategory.length < typesInCategory.length;
  }

  /// Check if any exercise type is enabled
  bool get hasAnyEnabled => enabledTypes.isNotEmpty;

  /// Get count of enabled types
  int get enabledCount => enabledTypes.length;

  /// Create a copy with a type toggled
  ExercisePreferences toggleType(ExerciseType type) {
    final newSet = Set<ExerciseType>.from(enabledTypes);
    if (newSet.contains(type)) {
      newSet.remove(type);
    } else {
      newSet.add(type);
    }
    return copyWith(enabledTypes: newSet);
  }

  /// Create a copy with a category enabled/disabled
  ExercisePreferences toggleCategory(ExerciseCategory category, {required bool enabled}) {
    final newSet = Set<ExerciseType>.from(enabledTypes);
    for (final type in category.exerciseTypes) {
      if (enabled) {
        newSet.add(type);
      } else {
        newSet.remove(type);
      }
    }
    return copyWith(enabledTypes: newSet);
  }

  /// Create a copy with all types enabled
  ExercisePreferences enableAll() {
    return copyWith(
      enabledTypes: ExerciseType.values.where((t) => t.isImplemented).toSet(),
    );
  }

  /// Create a copy with all types disabled
  ExercisePreferences disableAll() {
    return copyWith(enabledTypes: <ExerciseType>{});
  }

  /// Create a copy with updated fields
  ExercisePreferences copyWith({
    Set<ExerciseType>? enabledTypes,
    bool? prioritizeWeaknesses,
    double? weaknessThreshold,
  }) {
    return ExercisePreferences(
      enabledTypes: enabledTypes ?? this.enabledTypes,
      prioritizeWeaknesses: prioritizeWeaknesses ?? this.prioritizeWeaknesses,
      weaknessThreshold: weaknessThreshold ?? this.weaknessThreshold,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'enabledTypes': enabledTypes.map((t) => t.name).toList(),
      'prioritizeWeaknesses': prioritizeWeaknesses,
      'weaknessThreshold': weaknessThreshold,
    };
  }

  /// Create from JSON
  factory ExercisePreferences.fromJson(Map<String, dynamic> json) {
    final enabledTypeNames = (json['enabledTypes'] as List<dynamic>?)
        ?.cast<String>() ?? [];
    
    final enabledTypes = <ExerciseType>{};
    for (final name in enabledTypeNames) {
      try {
        final type = ExerciseType.values.firstWhere((t) => t.name == name);
        if (type.isImplemented) {
          enabledTypes.add(type);
        }
      } catch (_) {
        // Ignore unknown types
      }
    }

    return ExercisePreferences(
      enabledTypes: enabledTypes,
      prioritizeWeaknesses: json['prioritizeWeaknesses'] as bool? ?? true,
      weaknessThreshold: (json['weaknessThreshold'] as num?)?.toDouble() ?? 70.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExercisePreferences &&
        other.enabledTypes.length == enabledTypes.length &&
        other.enabledTypes.containsAll(enabledTypes) &&
        other.prioritizeWeaknesses == prioritizeWeaknesses &&
        other.weaknessThreshold == weaknessThreshold;
  }

  @override
  int get hashCode =>
      enabledTypes.hashCode ^
      prioritizeWeaknesses.hashCode ^
      weaknessThreshold.hashCode;
}
