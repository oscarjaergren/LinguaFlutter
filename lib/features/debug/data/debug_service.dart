import '../../../models/card_model.dart';

/// Service for debug functionality and test data generation
class DebugService {
  /// Get all available debug card sets
  static Map<String, List<CardModel> Function()> getDebugCardSets() {
    return {
      'German Basic Vocabulary (10 cards)': createGermanBasicCards,
      'Spanish Phrases (8 cards)': createSpanishPhraseCards,
      'French Food Terms (12 cards)': createFrenchFoodCards,
      'Italian Travel Words (10 cards)': createItalianTravelCards,
      'Mixed Language Sample (15 cards)': createMixedLanguageCards,
    };
  }

  /// Create cards that are due for review (for testing review functionality)
  static List<CardModel> createDueForReviewCards() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    return [
      CardModel.create(
        frontText: 'Hallo',
        backText: 'Hello',
        language: 'de',
        category: 'Greetings',
      ).copyWith(
        nextReview: yesterday,
        lastReviewed: yesterday,
      ),
      CardModel.create(
        frontText: 'Danke',
        backText: 'Thank you',
        language: 'de',
        category: 'Greetings',
      ).copyWith(
        nextReview: yesterday,
        lastReviewed: yesterday,
      ),
      CardModel.create(
        frontText: 'Guten Morgen',
        backText: 'Good morning',
        language: 'de',
        category: 'Greetings',
      ).copyWith(
        nextReview: yesterday,
      ),
      CardModel.create(
        frontText: 'Auf Wiedersehen',
        backText: 'Goodbye',
        language: 'de',
        category: 'Greetings',
      ).copyWith(
        nextReview: yesterday,
        lastReviewed: yesterday,
      ),
      CardModel.create(
        frontText: 'Bitte',
        backText: 'Please',
        language: 'de',
        category: 'Greetings',
      ).copyWith(
        nextReview: yesterday,
      ),
    ];
  }

  /// Create German basic vocabulary cards
  static List<CardModel> createGermanBasicCards() {
    return [
      CardModel.create(
        frontText: 'Haus',
        backText: 'House',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'das',
        tags: ['noun', 'building'],
      ),
      CardModel.create(
        frontText: 'Auto',
        backText: 'Car',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'das',
        tags: ['noun', 'transport'],
      ),
      CardModel.create(
        frontText: 'Wasser',
        backText: 'Water',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'das',
        tags: ['noun', 'drink'],
      ),
      CardModel.create(
        frontText: 'Buch',
        backText: 'Book',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'das',
        tags: ['noun', 'education'],
      ),
      CardModel.create(
        frontText: 'Katze',
        backText: 'Cat',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'die',
        tags: ['noun', 'animal'],
      ),
      CardModel.create(
        frontText: 'Hund',
        backText: 'Dog',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'der',
        tags: ['noun', 'animal'],
      ),
      CardModel.create(
        frontText: 'Baum',
        backText: 'Tree',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'der',
        tags: ['noun', 'nature'],
      ),
      CardModel.create(
        frontText: 'Sonne',
        backText: 'Sun',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'die',
        tags: ['noun', 'nature'],
      ),
      CardModel.create(
        frontText: 'Mond',
        backText: 'Moon',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'der',
        tags: ['noun', 'nature'],
      ),
      CardModel.create(
        frontText: 'Stern',
        backText: 'Star',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'der',
        tags: ['noun', 'nature'],
      ),
    ];
  }

  /// Create Spanish phrase cards
  static List<CardModel> createSpanishPhraseCards() {
    return [
      CardModel.create(
        frontText: '¿Cómo estás?',
        backText: 'How are you?',
        language: 'es',
        category: 'Phrases',
        tags: ['greeting', 'question'],
      ),
      CardModel.create(
        frontText: 'Me llamo...',
        backText: 'My name is...',
        language: 'es',
        category: 'Phrases',
        tags: ['introduction'],
      ),
      CardModel.create(
        frontText: '¿Dónde está el baño?',
        backText: 'Where is the bathroom?',
        language: 'es',
        category: 'Phrases',
        tags: ['question', 'travel'],
      ),
      CardModel.create(
        frontText: 'No hablo español',
        backText: 'I don\'t speak Spanish',
        language: 'es',
        category: 'Phrases',
        tags: ['communication'],
      ),
      CardModel.create(
        frontText: '¿Cuánto cuesta?',
        backText: 'How much does it cost?',
        language: 'es',
        category: 'Phrases',
        tags: ['shopping', 'question'],
      ),
      CardModel.create(
        frontText: 'La cuenta, por favor',
        backText: 'The check, please',
        language: 'es',
        category: 'Phrases',
        tags: ['restaurant'],
      ),
      CardModel.create(
        frontText: 'Disculpe',
        backText: 'Excuse me',
        language: 'es',
        category: 'Phrases',
        tags: ['politeness'],
      ),
      CardModel.create(
        frontText: 'Con permiso',
        backText: 'With your permission',
        language: 'es',
        category: 'Phrases',
        tags: ['politeness'],
      ),
    ];
  }

  /// Create French food term cards
  static List<CardModel> createFrenchFoodCards() {
    return [
      CardModel.create(
        frontText: 'le pain',
        backText: 'bread',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'bakery'],
      ),
      CardModel.create(
        frontText: 'le fromage',
        backText: 'cheese',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'dairy'],
      ),
      CardModel.create(
        frontText: 'la pomme',
        backText: 'apple',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'fruit'],
      ),
      CardModel.create(
        frontText: 'la viande',
        backText: 'meat',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'protein'],
      ),
      CardModel.create(
        frontText: 'le poisson',
        backText: 'fish',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'protein'],
      ),
      CardModel.create(
        frontText: 'les légumes',
        backText: 'vegetables',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'healthy'],
      ),
      CardModel.create(
        frontText: 'le vin',
        backText: 'wine',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'drink'],
      ),
      CardModel.create(
        frontText: 'l\'eau',
        backText: 'water',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'drink'],
      ),
      CardModel.create(
        frontText: 'le café',
        backText: 'coffee',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'drink'],
      ),
      CardModel.create(
        frontText: 'le thé',
        backText: 'tea',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'drink'],
      ),
      CardModel.create(
        frontText: 'le chocolat',
        backText: 'chocolate',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'dessert'],
      ),
      CardModel.create(
        frontText: 'la glace',
        backText: 'ice cream',
        language: 'fr',
        category: 'Food',
        tags: ['noun', 'dessert'],
      ),
    ];
  }

  /// Create Italian travel word cards
  static List<CardModel> createItalianTravelCards() {
    return [
      CardModel.create(
        frontText: 'l\'aeroporto',
        backText: 'airport',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'transport'],
      ),
      CardModel.create(
        frontText: 'l\'albergo',
        backText: 'hotel',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'accommodation'],
      ),
      CardModel.create(
        frontText: 'la stazione',
        backText: 'station',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'transport'],
      ),
      CardModel.create(
        frontText: 'il biglietto',
        backText: 'ticket',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'transport'],
      ),
      CardModel.create(
        frontText: 'la valigia',
        backText: 'suitcase',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'luggage'],
      ),
      CardModel.create(
        frontText: 'il passaporto',
        backText: 'passport',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'document'],
      ),
      CardModel.create(
        frontText: 'la mappa',
        backText: 'map',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'navigation'],
      ),
      CardModel.create(
        frontText: 'il ristorante',
        backText: 'restaurant',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'food'],
      ),
      CardModel.create(
        frontText: 'il museo',
        backText: 'museum',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'culture'],
      ),
      CardModel.create(
        frontText: 'la spiaggia',
        backText: 'beach',
        language: 'it',
        category: 'Travel',
        tags: ['noun', 'leisure'],
      ),
    ];
  }

  /// Create mixed language sample cards
  static List<CardModel> createMixedLanguageCards() {
    return [
      // German
      CardModel.create(
        frontText: 'Guten Tag',
        backText: 'Good day',
        language: 'de',
        category: 'Greetings',
        tags: ['greeting'],
      ),
      CardModel.create(
        frontText: 'Entschuldigung',
        backText: 'Excuse me / Sorry',
        language: 'de',
        category: 'Phrases',
        tags: ['politeness'],
      ),
      CardModel.create(
        frontText: 'Schule',
        backText: 'School',
        language: 'de',
        category: 'Vocabulary',
        germanArticle: 'die',
        tags: ['noun', 'education'],
      ),
      
      // Spanish
      CardModel.create(
        frontText: 'Buenos días',
        backText: 'Good morning',
        language: 'es',
        category: 'Greetings',
        tags: ['greeting'],
      ),
      CardModel.create(
        frontText: 'Por favor',
        backText: 'Please',
        language: 'es',
        category: 'Phrases',
        tags: ['politeness'],
      ),
      CardModel.create(
        frontText: 'la escuela',
        backText: 'school',
        language: 'es',
        category: 'Vocabulary',
        tags: ['noun', 'education'],
      ),
      
      // French
      CardModel.create(
        frontText: 'Bonjour',
        backText: 'Hello / Good day',
        language: 'fr',
        category: 'Greetings',
        tags: ['greeting'],
      ),
      CardModel.create(
        frontText: 'S\'il vous plaît',
        backText: 'Please',
        language: 'fr',
        category: 'Phrases',
        tags: ['politeness'],
      ),
      CardModel.create(
        frontText: 'l\'école',
        backText: 'school',
        language: 'fr',
        category: 'Vocabulary',
        tags: ['noun', 'education'],
      ),
      
      // Italian
      CardModel.create(
        frontText: 'Buongiorno',
        backText: 'Good morning',
        language: 'it',
        category: 'Greetings',
        tags: ['greeting'],
      ),
      CardModel.create(
        frontText: 'Per favore',
        backText: 'Please',
        language: 'it',
        category: 'Phrases',
        tags: ['politeness'],
      ),
      CardModel.create(
        frontText: 'la scuola',
        backText: 'school',
        language: 'it',
        category: 'Vocabulary',
        tags: ['noun', 'education'],
      ),
      
      // Portuguese
      CardModel.create(
        frontText: 'Bom dia',
        backText: 'Good morning',
        language: 'pt',
        category: 'Greetings',
        tags: ['greeting'],
      ),
      CardModel.create(
        frontText: 'Por favor',
        backText: 'Please',
        language: 'pt',
        category: 'Phrases',
        tags: ['politeness'],
      ),
      CardModel.create(
        frontText: 'a escola',
        backText: 'school',
        language: 'pt',
        category: 'Vocabulary',
        tags: ['noun', 'education'],
      ),
    ];
  }
}
