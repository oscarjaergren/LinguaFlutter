import '../../../shared/domain/models/card_model.dart';

/// Service for debug functionality and test data generation
class DebugService {
  /// Create basic vocabulary cards for testing
  static List<CardModel> createBasicCards(String language, int count) {
    // Sample vocabulary data that can be used for any language
    final samples = [
      ['hello', 'greeting'],
      ['goodbye', 'greeting'],
      ['please', 'politeness'],
      ['thank you', 'politeness'],
      ['yes', 'basic'],
      ['no', 'basic'],
      ['water', 'food'],
      ['food', 'food'],
      ['house', 'places'],
      ['car', 'transport'],
      ['book', 'objects'],
      ['school', 'places'],
      ['friend', 'people'],
      ['family', 'people'],
      ['morning', 'time'],
      ['night', 'time'],
      ['good', 'adjectives'],
      ['bad', 'adjectives'],
      ['big', 'adjectives'],
      ['small', 'adjectives'],
      ['one', 'numbers'],
      ['two', 'numbers'],
      ['three', 'numbers'],
      ['four', 'numbers'],
      ['five', 'numbers'],
      ['red', 'colors'],
      ['blue', 'colors'],
      ['green', 'colors'],
      ['yellow', 'colors'],
      ['black', 'colors'],
    ];

    final cards = <CardModel>[];
    for (var i = 0; i < count && i < samples.length; i++) {
      cards.add(
        CardModel.create(
          frontText: 'Word ${i + 1} (${samples[i][0]})',
          backText: 'Translation of "${samples[i][0]}"',
          language: language,
          category: samples[i][1],
          tags: ['test', 'debug', samples[i][1]],
        ),
      );
    }
    return cards;
  }

  /// Create cards that are due for review (for testing review functionality)
  static List<CardModel> createDueForReviewCards(String language, int count) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final cards = createBasicCards(language, count);
    
    // Make all cards due for review
    return cards.map((card) => card.copyWith(
      nextReview: yesterday,
      lastReviewed: yesterday,
    )).toList();
  }

}
