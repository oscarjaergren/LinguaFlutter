import '../../../../shared/domain/models/card_model.dart';
import '../../domain/models/duplicate_match.dart';

/// Service for detecting duplicate cards
/// 
/// This service uses multiple strategies to identify potential duplicates:
/// - Exact matching
/// - Case-insensitive matching
/// - Normalized whitespace matching
/// - Fuzzy string matching (Levenshtein-based)
/// - Same front/different back detection
/// 
/// The service is designed to be extensible - new strategies can be added
/// by implementing additional check methods and adding them to the strategy enum.
class DuplicateDetectionService {
  static final _whitespacePattern = RegExp(r'\s+');
  
  final DuplicateDetectionConfig config;
  
  DuplicateDetectionService({
    this.config = DuplicateDetectionConfig.standard,
  });
  
  /// Find all duplicates for a given card within a list of cards
  List<DuplicateMatch> findDuplicates(CardModel card, List<CardModel> allCards) {
    final duplicates = <DuplicateMatch>[];
    
    for (final otherCard in allCards) {
      // Skip comparing card with itself
      if (otherCard.id == card.id) continue;
      
      // Skip cards from different languages if configured
      if (config.sameLanguageOnly && otherCard.language != card.language) {
        continue;
      }
      
      final match = _findBestMatch(card, otherCard);
      if (match != null) {
        duplicates.add(match);
      }
    }
    
    // Sort by similarity score (highest first)
    duplicates.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    
    return duplicates;
  }
  
  /// Find all duplicate groups in a list of cards
  /// Returns a map where each card ID maps to its list of duplicates
  Map<String, List<DuplicateMatch>> findAllDuplicates(List<CardModel> cards) {
    final duplicateMap = <String, List<DuplicateMatch>>{};
    
    for (final card in cards) {
      final duplicates = findDuplicates(card, cards);
      if (duplicates.isNotEmpty) {
        duplicateMap[card.id] = duplicates;
      }
    }
    
    return duplicateMap;
  }
  
  /// Check if a card has any duplicates
  bool hasDuplicates(CardModel card, List<CardModel> allCards) {
    return findDuplicates(card, allCards).isNotEmpty;
  }
  
  /// Get cards that have duplicates
  List<CardModel> getCardsWithDuplicates(List<CardModel> cards) {
    final duplicateMap = findAllDuplicates(cards);
    return cards.where((card) => duplicateMap.containsKey(card.id)).toList();
  }
  
  /// Find the best matching strategy for two cards
  DuplicateMatch? _findBestMatch(CardModel card1, CardModel card2) {
    DuplicateMatch? bestMatch;
    
    // Check strategies in order of priority (most specific first)
    
    // 1. Exact match (highest priority)
    if (config.checkExactMatch) {
      final match = _checkExactMatch(card1, card2);
      if (match != null) return match; // Exact match is definitive
    }
    
    // 2. Case-insensitive match
    if (config.checkCaseInsensitive) {
      final match = _checkCaseInsensitiveMatch(card1, card2);
      if (match != null && _isBetterMatch(match, bestMatch)) {
        bestMatch = match;
      }
    }
    
    // 3. Normalized whitespace match
    if (config.checkNormalizedWhitespace) {
      final match = _checkNormalizedWhitespaceMatch(card1, card2);
      if (match != null && _isBetterMatch(match, bestMatch)) {
        bestMatch = match;
      }
    }
    
    // 4. Same front, different back (potential inconsistency)
    if (config.checkSameFrontDifferentBack) {
      final match = _checkSameFrontDifferentBack(card1, card2);
      if (match != null && _isBetterMatch(match, bestMatch)) {
        bestMatch = match;
      }
    }
    
    // 5. Same back, different front (potential synonym)
    if (config.checkSameBackDifferentFront) {
      final match = _checkSameBackDifferentFront(card1, card2);
      if (match != null && _isBetterMatch(match, bestMatch)) {
        bestMatch = match;
      }
    }
    
    // 6. Fuzzy match (lowest priority, catches near-duplicates)
    if (config.checkFuzzyMatch && bestMatch == null) {
      final match = _checkFuzzyMatch(card1, card2);
      if (match != null) {
        bestMatch = match;
      }
    }
    
    return bestMatch;
  }
  
  bool _isBetterMatch(DuplicateMatch newMatch, DuplicateMatch? currentBest) {
    if (currentBest == null) return true;
    return newMatch.similarityScore > currentBest.similarityScore;
  }
  
  // Strategy implementations
  
  DuplicateMatch? _checkExactMatch(CardModel card1, CardModel card2) {
    if (card1.frontText == card2.frontText && card1.backText == card2.backText) {
      return DuplicateMatch(
        duplicateCard: card2,
        similarityScore: 1.0,
        strategy: DuplicateMatchStrategy.exactMatch,
        reason: 'Exact duplicate',
      );
    }
    return null;
  }
  
  DuplicateMatch? _checkCaseInsensitiveMatch(CardModel card1, CardModel card2) {
    final front1 = card1.frontText.toLowerCase();
    final front2 = card2.frontText.toLowerCase();
    final back1 = card1.backText.toLowerCase();
    final back2 = card2.backText.toLowerCase();
    
    if (front1 == front2 && back1 == back2) {
      // Don't report if it's already an exact match
      if (card1.frontText == card2.frontText && card1.backText == card2.backText) {
        return null;
      }
      return DuplicateMatch(
        duplicateCard: card2,
        similarityScore: 0.98,
        strategy: DuplicateMatchStrategy.caseInsensitive,
        reason: 'Same content (case differs)',
      );
    }
    return null;
  }
  
  DuplicateMatch? _checkNormalizedWhitespaceMatch(CardModel card1, CardModel card2) {
    final front1 = _normalizeWhitespace(card1.frontText);
    final front2 = _normalizeWhitespace(card2.frontText);
    final back1 = _normalizeWhitespace(card1.backText);
    final back2 = _normalizeWhitespace(card2.backText);
    
    if (front1 == front2 && back1 == back2) {
      // Don't report if it's already caught by previous checks
      if (card1.frontText.toLowerCase() == card2.frontText.toLowerCase() &&
          card1.backText.toLowerCase() == card2.backText.toLowerCase()) {
        return null;
      }
      return DuplicateMatch(
        duplicateCard: card2,
        similarityScore: 0.95,
        strategy: DuplicateMatchStrategy.normalizedWhitespace,
        reason: 'Same content (whitespace differs)',
      );
    }
    return null;
  }
  
  DuplicateMatch? _checkSameFrontDifferentBack(CardModel card1, CardModel card2) {
    final front1 = _normalizeWhitespace(card1.frontText);
    final front2 = _normalizeWhitespace(card2.frontText);
    
    if (front1 == front2) {
      final back1 = _normalizeWhitespace(card1.backText);
      final back2 = _normalizeWhitespace(card2.backText);
      
      if (back1 != back2) {
        return DuplicateMatch(
          duplicateCard: card2,
          similarityScore: 0.90,
          strategy: DuplicateMatchStrategy.sameFrontDifferentBack,
          reason: 'Same term, different translation',
        );
      }
    }
    return null;
  }
  
  DuplicateMatch? _checkSameBackDifferentFront(CardModel card1, CardModel card2) {
    final back1 = _normalizeWhitespace(card1.backText);
    final back2 = _normalizeWhitespace(card2.backText);
    
    if (back1 == back2) {
      final front1 = _normalizeWhitespace(card1.frontText);
      final front2 = _normalizeWhitespace(card2.frontText);
      
      if (front1 != front2) {
        return DuplicateMatch(
          duplicateCard: card2,
          similarityScore: 0.85,
          strategy: DuplicateMatchStrategy.sameBackDifferentFront,
          reason: 'Same translation, different terms (synonyms?)',
        );
      }
    }
    return null;
  }
  
  DuplicateMatch? _checkFuzzyMatch(CardModel card1, CardModel card2) {
    final front1 = _normalizeWhitespace(card1.frontText);
    final front2 = _normalizeWhitespace(card2.frontText);
    
    final frontSimilarity = _calculateSimilarity(front1, front2);
    
    if (frontSimilarity >= config.fuzzyThreshold) {
      final back1 = _normalizeWhitespace(card1.backText);
      final back2 = _normalizeWhitespace(card2.backText);
      final backSimilarity = _calculateSimilarity(back1, back2);
      
      if (backSimilarity >= config.fuzzyThreshold) {
        final avgSimilarity = (frontSimilarity + backSimilarity) / 2;
        return DuplicateMatch(
          duplicateCard: card2,
          similarityScore: avgSimilarity,
          strategy: DuplicateMatchStrategy.fuzzyMatch,
          reason: 'Similar content (${(avgSimilarity * 100).toStringAsFixed(0)}% match)',
        );
      }
    }
    return null;
  }
  
  // Utility methods
  
  String _normalizeWhitespace(String text) {
    return text.toLowerCase().trim().replaceAll(_whitespacePattern, ' ');
  }
  
  /// Calculate similarity between two strings using Levenshtein distance
  /// Returns a value between 0.0 (completely different) and 1.0 (identical)
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    
    return 1.0 - (distance / maxLength);
  }
  
  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    // Use two rows instead of full matrix for memory efficiency
    List<int> previousRow = List.generate(s2.length + 1, (i) => i);
    List<int> currentRow = List.filled(s2.length + 1, 0);
    
    for (int i = 0; i < s1.length; i++) {
      currentRow[0] = i + 1;
      
      for (int j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        currentRow[j + 1] = [
          currentRow[j] + 1,           // insertion
          previousRow[j + 1] + 1,      // deletion
          previousRow[j] + cost,       // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      
      // Swap rows
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }
    
    return previousRow[s2.length];
  }
}
