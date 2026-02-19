import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_score.dart';
import 'package:lingua_flutter/shared/domain/models/word_data.dart';

void main() {
  group('PracticeSessionProvider Filtering', () {
    late PracticeSessionProvider provider;
    late List<CardModel> testCards;
    late List<CardModel> allCards;

    setUp(() {
      // Create test cards with different capabilities
      testCards = [
        // Card with examples (for sentence building)
        CardModel.create(
          frontText: 'Hund',
          backText: 'dog',
          language: 'de',

        ).copyWith(examples: ['Der Hund ist groß']),

        // Card with verb data (for conjugation)
        CardModel.create(
          frontText: 'gehen',
          backText: 'to go',
          language: 'de',

        ).copyWith(
          wordData: WordData.verb(
            isRegular: false,
            isSeparable: false,
            auxiliary: 'sein',
            presentDu: 'gehst',
            presentEr: 'geht',
            pastSimple: 'ging',
            pastParticiple: 'gegangen',
          ),
        ),

        // Card with article (for article selection)
        CardModel.create(
          frontText: 'der Tisch',
          backText: 'table',
          language: 'de',

        ),

        // Basic card (only basic exercises)
        CardModel.create(
          frontText: 'Katze',
          backText: 'cat',
          language: 'de',

        ),
      ];

      allCards = List.from(testCards);

      provider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => allCards,
        updateCard: (card) async {},
      );
    });

    test('startSession with preferences filters exercise types', () async {
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition},
      );

      provider.startSession(preferences: prefs);

      expect(provider.isSessionActive, true);
      expect(provider.totalCount, greaterThan(0));

      // All exercises should be reading recognition
      for (var i = 0; i < provider.totalCount; i++) {
        expect(provider.currentExerciseType, ExerciseType.readingRecognition);
        if (i < provider.totalCount - 1) {
          await provider.confirmAnswerAndAdvance(markedCorrect: true);
        }
      }
    });

    test('updateExercisePreferences rebuilds queue mid-session', () {
      // Start with all types
      provider.startSession(preferences: ExercisePreferences.defaults());

      // Update to only one type
      final newPrefs = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition},
      );
      provider.updateExercisePreferences(newPrefs, rebuildQueue: true);

      // Queue should be rebuilt
      expect(provider.isSessionActive, true);
      expect(provider.exercisePreferences.enabledTypes.length, 1);
    });

    test('sentence building only appears for cards with examples', () {
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.sentenceBuilding},
      );

      provider.startSession(preferences: prefs);

      // Should only have 1 card (the one with examples)
      expect(provider.totalCount, 1);
      expect(provider.currentExerciseType, ExerciseType.sentenceBuilding);
      expect(provider.currentCard?.examples.isNotEmpty, true);
    });

    test('conjugation practice only appears for cards with word data', () {
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.conjugationPractice},
      );

      provider.startSession(preferences: prefs);

      // Should only have 1 card (the one with verb data)
      expect(provider.totalCount, 1);
      expect(provider.currentExerciseType, ExerciseType.conjugationPractice);
      expect(provider.currentCard?.wordData, isNotNull);
    });

    test('article selection only appears for cards with articles', () {
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.articleSelection},
      );

      provider.startSession(preferences: prefs);

      // Should only have 1 card (the one with "der" in front text)
      expect(provider.totalCount, 1);
      expect(provider.currentExerciseType, ExerciseType.articleSelection);
      expect(
        provider.currentCard?.frontText.toLowerCase().startsWith('der '),
        true,
      );
    });

    test('multiple choice skipped when not enough cards', () {
      // Only 2 cards, need 4 for multiple choice
      testCards = [
        CardModel.create(
          frontText: 'Hund',
          backText: 'dog',
          language: 'de',

        ),
        CardModel.create(
          frontText: 'Katze',
          backText: 'cat',
          language: 'de',

        ),
      ];
      allCards = List.from(testCards);

      provider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => allCards,
        updateCard: (card) async {},
      );

      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.multipleChoiceText},
      );

      provider.startSession(preferences: prefs);

      // Should have no exercises since not enough cards
      expect(provider.totalCount, 0);
      expect(provider.isSessionActive, false);
    });

    test('prioritize weaknesses sorts by success rate', () {
      // Create card with different success rates per exercise
      final card =
          CardModel.create(
            frontText: 'test',
            backText: 'test',
            language: 'de',
  
          ).copyWith(
            exerciseScores: {
              ExerciseType.readingRecognition:
                  ExerciseScore.initial(
                    ExerciseType.readingRecognition,
                  ).copyWith(
                    correctCount: 8,
                    incorrectCount: 2,
                    lastPracticed: DateTime.now(),
                  ),
              ExerciseType.writingTranslation:
                  ExerciseScore.initial(
                    ExerciseType.writingTranslation,
                  ).copyWith(
                    correctCount: 3,
                    incorrectCount: 7,
                    lastPracticed: DateTime.now(),
                  ),
            },
          );

      testCards = [card];
      allCards = [card];

      provider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => allCards,
        updateCard: (card) async {},
      );

      final prefs = ExercisePreferences(
        enabledTypes: {
          ExerciseType.readingRecognition,
          ExerciseType.writingTranslation,
        },
        prioritizeWeaknesses: true,
      );

      provider.startSession(preferences: prefs);

      // First exercise should be the weaker one (writing translation)
      expect(provider.currentExerciseType, ExerciseType.writingTranslation);
    });

    test('disabling all types results in no session', () {
      final prefs = ExercisePreferences(enabledTypes: {});

      provider.startSession(preferences: prefs);

      expect(provider.isSessionActive, false);
      expect(provider.totalCount, 0);
    });

    test('enabling category enables all types in category', () async {
      final prefs = ExercisePreferences(
        enabledTypes: ExerciseCategory.recognition.exerciseTypes.toSet(),
      );

      provider.startSession(preferences: prefs);

      expect(provider.isSessionActive, true);

      // All exercises should be recognition types
      final recognitionTypes = ExerciseCategory.recognition.exerciseTypes;
      for (var i = 0; i < provider.totalCount; i++) {
        expect(recognitionTypes.contains(provider.currentExerciseType), true);
        if (i < provider.totalCount - 1) {
          await provider.confirmAnswerAndAdvance(markedCorrect: true);
        }
      }
    });
  });
}
