import '../../../../shared/domain/models/card_model.dart';

/// Strategies for detecting duplicates
enum DuplicateMatchStrategy {
  /// Exact match on front and back text
  exactMatch,
  
  /// Case-insensitive match
  caseInsensitive,
  
  /// Match ignoring whitespace differences
  normalizedWhitespace,
  
  /// Fuzzy matching using similarity algorithms
  fuzzyMatch,
  
  /// Same front text, different back (potential inconsistency)
  sameFrontDifferentBack,
  
  /// Same back text, different front (potential synonym)
  sameBackDifferentFront,
}

/// Represents a duplicate match with similarity information
class DuplicateMatch {
  /// The card that is a duplicate
  final CardModel duplicateCard;
  
  /// Similarity score (0.0 to 1.0)
  final double similarityScore;
  
  /// Which strategy detected this duplicate
  final DuplicateMatchStrategy strategy;
  
  /// Human-readable reason for the match
  final String reason;

  const DuplicateMatch({
    required this.duplicateCard,
    required this.similarityScore,
    required this.strategy,
    required this.reason,
  });
}

/// Configuration for duplicate detection
class DuplicateDetectionConfig {
  /// Minimum similarity score to consider a fuzzy match (0.0 to 1.0)
  final double fuzzyThreshold;
  
  /// Whether to check for exact matches
  final bool checkExactMatch;
  
  /// Whether to check case-insensitive matches
  final bool checkCaseInsensitive;
  
  /// Whether to check normalized whitespace matches
  final bool checkNormalizedWhitespace;
  
  /// Whether to check fuzzy matches
  final bool checkFuzzyMatch;
  
  /// Whether to flag same front with different back
  final bool checkSameFrontDifferentBack;
  
  /// Whether to flag same back with different front
  final bool checkSameBackDifferentFront;
  
  /// Only compare cards within the same language
  final bool sameLanguageOnly;

  const DuplicateDetectionConfig({
    this.fuzzyThreshold = 0.85,
    this.checkExactMatch = true,
    this.checkCaseInsensitive = true,
    this.checkNormalizedWhitespace = true,
    this.checkFuzzyMatch = true,
    this.checkSameFrontDifferentBack = true,
    this.checkSameBackDifferentFront = false,
    this.sameLanguageOnly = true,
  });
  
  /// Default configuration for standard duplicate detection
  static const standard = DuplicateDetectionConfig();
  
  /// Strict configuration that catches more potential duplicates
  static const strict = DuplicateDetectionConfig(
    fuzzyThreshold: 0.75,
    checkSameBackDifferentFront: true,
  );
  
  /// Loose configuration for basic duplicate detection only
  static const loose = DuplicateDetectionConfig(
    checkFuzzyMatch: false,
    checkSameFrontDifferentBack: false,
    checkSameBackDifferentFront: false,
  );
}
