import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../shared/domain/models/card_model.dart';
import '../../../shared/services/logger_service.dart';

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
    return cards
        .map(
          (card) =>
              card.copyWith(nextReview: yesterday, lastReviewed: yesterday),
        )
        .toList();
  }

  /// Load German vocabulary cards from JSON file
  static Future<List<CardModel>> loadGermanWordsFromJson({
    int? limit,
    bool makeAvailableNow = false,
  }) async {
    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/german_words.json',
      );
      final Map<String, dynamic> jsonData =
          json.decode(jsonString) as Map<String, dynamic>;
      final List<dynamic> words = jsonData['words'] as List<dynamic>;

      LoggerService.debug('Loaded ${words.length} words from JSON');

      // Convert to CardModel objects
      final List<CardModel> cards = [];
      final wordsToProcess = limit != null && limit < words.length
          ? words.sublist(0, limit)
          : words;

      LoggerService.debug('Processing ${wordsToProcess.length} words');

      for (var i = 0; i < wordsToProcess.length; i++) {
        final word = wordsToProcess[i] as Map<String, dynamic>;

        // Build example sentences text
        final List<dynamic> examplesList =
            word['examples'] as List<dynamic>? ?? [];
        final String examplesText = examplesList.isNotEmpty
            ? '\n\nExamples:\n${examplesList.map((e) => '• $e').join('\n')}'
            : '';

        // Build plural information if available
        final String pluralInfo =
            word.containsKey('plural') && word['plural'] != null
            ? '\nPlural: ${word['plural']}'
            : '';

        // Calculate next review date based on hours
        final DateTime nextReview;
        if (makeAvailableNow) {
          // Make all cards available immediately for learning
          nextReview = DateTime.now().subtract(const Duration(hours: 1));
        } else {
          final double hoursUntilReview =
              (word['nextReviewHours'] as num?)?.toDouble() ?? 24.0;
          nextReview = DateTime.now().add(
            Duration(
              hours: hoursUntilReview.floor(),
              minutes: ((hoursUntilReview % 1) * 60).floor(),
            ),
          );
        }

        // Create the card
        final card = CardModel.create(
          frontText: word['german'] as String,
          backText: '${word['english']}$pluralInfo$examplesText',
          language: 'de', // German language code
          category: word['category'] as String? ?? 'vocabulary',
          tags: [
            'german',
            'vocabulary',
            word['category'] as String? ?? 'general',
          ],
        ).copyWith(nextReview: nextReview);

        cards.add(card);

        if ((i + 1) % 50 == 0) {
          LoggerService.debug('Processed ${i + 1} cards');
        }
      }

      LoggerService.debug('Successfully created ${cards.length} card objects');
      return cards;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load German words', e, stackTrace);
      throw Exception('Failed to load German words from JSON: $e');
    }
  }
}
