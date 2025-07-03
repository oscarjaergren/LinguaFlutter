import '../models/card_model.dart';

/// Service for creating debug/test data
class DebugService {
  /// Create a set of German vocabulary cards for testing
  static List<CardModel> createGermanVocabularyCards() {
    return [
      CardModel.create(
        frontText: 'Haus',
        backText: 'House',
        language: 'de',
        category: 'Vocabulary - Buildings',
        germanArticle: 'das',
        tags: ['buildings', 'basic'],
      ),
      CardModel.create(
        frontText: 'Auto',
        backText: 'Car',
        language: 'de',
        category: 'Vocabulary - Transportation',
        germanArticle: 'das',
        tags: ['transportation', 'vehicles'],
      ),
      CardModel.create(
        frontText: 'Katze',
        backText: 'Cat',
        language: 'de',
        category: 'Vocabulary - Animals',
        germanArticle: 'die',
        tags: ['animals', 'pets'],
      ),
      CardModel.create(
        frontText: 'Hund',
        backText: 'Dog',
        language: 'de',
        category: 'Vocabulary - Animals',
        germanArticle: 'der',
        tags: ['animals', 'pets'],
      ),
      CardModel.create(
        frontText: 'Buch',
        backText: 'Book',
        language: 'de',
        category: 'Vocabulary - Objects',
        germanArticle: 'das',
        tags: ['objects', 'education'],
      ),
      CardModel.create(
        frontText: 'Wasser',
        backText: 'Water',
        language: 'de',
        category: 'Vocabulary - Food & Drink',
        germanArticle: 'das',
        tags: ['drinks', 'basic'],
      ),
      CardModel.create(
        frontText: 'Freund',
        backText: 'Friend (male)',
        language: 'de',
        category: 'Vocabulary - People',
        germanArticle: 'der',
        tags: ['people', 'relationships'],
      ),
      CardModel.create(
        frontText: 'Freundin',
        backText: 'Friend (female)',
        language: 'de',
        category: 'Vocabulary - People',
        germanArticle: 'die',
        tags: ['people', 'relationships'],
      ),
    ];
  }

  /// Create a set of Spanish vocabulary cards for testing
  static List<CardModel> createSpanishVocabularyCards() {
    return [
      CardModel.create(
        frontText: 'Casa',
        backText: 'House',
        language: 'es',
        category: 'Vocabulary - Buildings',
        tags: ['buildings', 'basic'],
      ),
      CardModel.create(
        frontText: 'Coche',
        backText: 'Car',
        language: 'es',
        category: 'Vocabulary - Transportation',
        tags: ['transportation', 'vehicles'],
      ),
      CardModel.create(
        frontText: 'Gato',
        backText: 'Cat',
        language: 'es',
        category: 'Vocabulary - Animals',
        tags: ['animals', 'pets'],
      ),
      CardModel.create(
        frontText: 'Perro',
        backText: 'Dog',
        language: 'es',
        category: 'Vocabulary - Animals',
        tags: ['animals', 'pets'],
      ),
      CardModel.create(
        frontText: 'Libro',
        backText: 'Book',
        language: 'es',
        category: 'Vocabulary - Objects',
        tags: ['objects', 'education'],
      ),
      CardModel.create(
        frontText: 'Agua',
        backText: 'Water',
        language: 'es',
        category: 'Vocabulary - Food & Drink',
        tags: ['drinks', 'basic'],
      ),
    ];
  }

  /// Create a set of French vocabulary cards for testing
  static List<CardModel> createFrenchVocabularyCards() {
    return [
      CardModel.create(
        frontText: 'Maison',
        backText: 'House',
        language: 'fr',
        category: 'Vocabulary - Buildings',
        tags: ['buildings', 'basic'],
      ),
      CardModel.create(
        frontText: 'Voiture',
        backText: 'Car',
        language: 'fr',
        category: 'Vocabulary - Transportation',
        tags: ['transportation', 'vehicles'],
      ),
      CardModel.create(
        frontText: 'Chat',
        backText: 'Cat',
        language: 'fr',
        category: 'Vocabulary - Animals',
        tags: ['animals', 'pets'],
      ),
      CardModel.create(
        frontText: 'Chien',
        backText: 'Dog',
        language: 'fr',
        category: 'Vocabulary - Animals',
        tags: ['animals', 'pets'],
      ),
      CardModel.create(
        frontText: 'Livre',
        backText: 'Book',
        language: 'fr',
        category: 'Vocabulary - Objects',
        tags: ['objects', 'education'],
      ),
    ];
  }

  /// Create cards with various review states for testing spaced repetition
  static List<CardModel> createReviewTestCards() {
    final now = DateTime.now();
    
    return [
      // New card (never reviewed)
      CardModel.create(
        frontText: 'Test New Card',
        backText: 'This is a new card',
        language: 'en',
        category: 'Debug - Review States',
        tags: ['debug', 'new'],
      ),
      
      // Card due for review
      CardModel.create(
        frontText: 'Test Due Card',
        backText: 'This card is due for review',
        language: 'en',
        category: 'Debug - Review States',
        tags: ['debug', 'due'],
      ).copyWith(
        reviewCount: 3,
        correctCount: 2,
        lastReviewed: now.subtract(const Duration(days: 2)),
        nextReview: now.subtract(const Duration(hours: 1)),
      ),
      
      // Card with high success rate (mastered)
      CardModel.create(
        frontText: 'Test Mastered Card',
        backText: 'This card is mastered',
        language: 'en',
        category: 'Debug - Review States',
        tags: ['debug', 'mastered'],
      ).copyWith(
        reviewCount: 10,
        correctCount: 9,
        lastReviewed: now.subtract(const Duration(days: 1)),
        nextReview: now.add(const Duration(days: 7)),
      ),
      
      // Card with low success rate (difficult)
      CardModel.create(
        frontText: 'Test Difficult Card',
        backText: 'This card is difficult',
        language: 'en',
        category: 'Debug - Review States',
        tags: ['debug', 'difficult'],
      ).copyWith(
        reviewCount: 8,
        correctCount: 3,
        lastReviewed: now.subtract(const Duration(hours: 6)),
        nextReview: now.add(const Duration(hours: 2)),
      ),
    ];
  }

  /// Get all available debug card sets
  static Map<String, List<CardModel> Function()> getDebugCardSets() {
    return {
      'German Vocabulary (8 cards)': createGermanVocabularyCards,
      'Spanish Vocabulary (6 cards)': createSpanishVocabularyCards,
      'French Vocabulary (5 cards)': createFrenchVocabularyCards,
      'Review Test Cards (4 cards)': createReviewTestCards,
    };
  }
}
