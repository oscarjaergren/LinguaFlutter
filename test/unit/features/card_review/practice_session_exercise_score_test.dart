import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_score.dart';

void main() {
  group('PracticeSessionProvider Exercise Score Updates', () {
    late PracticeSessionProvider provider;
    late List<CardModel> testCards;
    late CardModel? lastUpdatedCard;

    setUp(() {
      lastUpdatedCard = null;

      testCards = [
        CardModel.create(frontText: 'Hund', backText: 'dog', language: 'de'),
      ];

      provider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => testCards,
        updateCard: (card) async {
          lastUpdatedCard = card;
        },
      );
    });

    test(
      'writing translation exercise score updates on correct answer',
      () async {
        final prefs = ExercisePreferences(
          enabledTypes: {ExerciseType.reverseTranslation},
        );

        provider.startSession(preferences: prefs);

        expect(provider.isSessionActive, true);
        expect(provider.currentExerciseType, ExerciseType.reverseTranslation);

        final initialCard = provider.currentCard!;
        final initialScore = initialCard.getExerciseScore(
          ExerciseType.reverseTranslation,
        );

        expect(initialScore, isNotNull);
        expect(initialScore!.totalAttempts, 0);

        await provider.confirmAnswerAndAdvance(markedCorrect: true);

        expect(lastUpdatedCard, isNotNull);

        final updatedScore = lastUpdatedCard!.getExerciseScore(
          ExerciseType.reverseTranslation,
        );
        expect(updatedScore, isNotNull);
        expect(updatedScore!.correctCount, 1);
        expect(updatedScore.incorrectCount, 0);
        expect(updatedScore.totalAttempts, 1);
        expect(updatedScore.successRate, 100.0);
        expect(updatedScore.currentChain, 1);
        expect(updatedScore.masteryLevel, 'Learning');
      },
    );

    test(
      'writing translation exercise score updates on incorrect answer',
      () async {
        final prefs = ExercisePreferences(
          enabledTypes: {ExerciseType.reverseTranslation},
        );

        provider.startSession(preferences: prefs);

        await provider.confirmAnswerAndAdvance(markedCorrect: false);

        expect(lastUpdatedCard, isNotNull);

        final updatedScore = lastUpdatedCard!.getExerciseScore(
          ExerciseType.reverseTranslation,
        );
        expect(updatedScore, isNotNull);
        expect(updatedScore!.correctCount, 0);
        expect(updatedScore.incorrectCount, 1);
        expect(updatedScore.totalAttempts, 1);
        expect(updatedScore.successRate, 0.0);
        expect(updatedScore.currentChain, 0);
        expect(updatedScore.masteryLevel, 'Difficult');
      },
    );

    test('writing translation mastery level progresses correctly', () async {
      var card = CardModel.create(
        frontText: 'Hund',
        backText: 'dog',
        language: 'de',
      );

      var initialScore = card.getExerciseScore(ExerciseType.reverseTranslation);
      expect(initialScore, isNotNull);
      expect(initialScore!.totalAttempts, 0);

      card = card.copyWithExerciseResult(
        exerciseType: ExerciseType.reverseTranslation,
        wasCorrect: true,
      );
      var score = card.getExerciseScore(ExerciseType.reverseTranslation)!;
      expect(score.correctCount, 1);
      expect(score.currentChain, 1);
      expect(score.masteryLevel, 'Learning');

      card = card.copyWithExerciseResult(
        exerciseType: ExerciseType.reverseTranslation,
        wasCorrect: true,
      );
      score = card.getExerciseScore(ExerciseType.reverseTranslation)!;
      expect(score.correctCount, 2);
      expect(score.currentChain, 2);
      expect(score.masteryLevel, 'Learning');

      card = card.copyWithExerciseResult(
        exerciseType: ExerciseType.reverseTranslation,
        wasCorrect: true,
      );
      score = card.getExerciseScore(ExerciseType.reverseTranslation)!;
      expect(score.correctCount, 3);
      expect(score.currentChain, 3);
      expect(score.totalAttempts, 3);
      expect(score.successRate, 100.0);
      expect(score.masteryLevel, 'Good');

      card = card.copyWithExerciseResult(
        exerciseType: ExerciseType.reverseTranslation,
        wasCorrect: false,
      );
      score = card.getExerciseScore(ExerciseType.reverseTranslation)!;
      expect(score.correctCount, 3);
      expect(score.incorrectCount, 1);
      expect(score.currentChain, 2);
      expect(score.totalAttempts, 4);
      expect(score.successRate, 75.0);
      expect(score.masteryLevel, 'Learning');
    });

    test('different exercise types maintain separate scores', () async {
      var card = CardModel.create(
        frontText: 'Hund',
        backText: 'dog',
        language: 'de',
      );

      card = card.copyWithExerciseResult(
        exerciseType: ExerciseType.reverseTranslation,
        wasCorrect: true,
      );

      card = card.copyWithExerciseResult(
        exerciseType: ExerciseType.readingRecognition,
        wasCorrect: false,
      );

      final writingScore = card.getExerciseScore(
        ExerciseType.reverseTranslation,
      )!;
      expect(writingScore.correctCount, 1);
      expect(writingScore.incorrectCount, 0);

      final readingScore = card.getExerciseScore(
        ExerciseType.readingRecognition,
      )!;
      expect(readingScore.correctCount, 0);
      expect(readingScore.incorrectCount, 1);
    });

    test('exercise score persists across multiple practice sessions', () async {
      var cardWithHistory =
          CardModel.create(
            frontText: 'Hund',
            backText: 'dog',
            language: 'de',
          ).copyWith(
            exerciseScores: {
              ExerciseType.reverseTranslation:
                  ExerciseScore.initial(
                    ExerciseType.reverseTranslation,
                  ).copyWith(
                    correctCount: 5,
                    incorrectCount: 2,
                    lastPracticed: DateTime.now(),
                  ),
            },
          );

      testCards = [cardWithHistory];

      provider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => testCards,
        updateCard: (card) async {
          lastUpdatedCard = card;
        },
      );

      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.reverseTranslation},
      );

      provider.startSession(preferences: prefs);

      final initialScore = provider.currentCard!.getExerciseScore(
        ExerciseType.reverseTranslation,
      )!;
      expect(initialScore.correctCount, 5);
      expect(initialScore.incorrectCount, 2);
      expect(initialScore.currentChain, 0);
      expect(initialScore.totalAttempts, 7);
      expect(initialScore.successRate, closeTo(71.4, 0.1));
      expect(initialScore.masteryLevel, 'Difficult');

      await provider.confirmAnswerAndAdvance(markedCorrect: true);

      final updatedScore = lastUpdatedCard!.getExerciseScore(
        ExerciseType.reverseTranslation,
      )!;
      expect(updatedScore.correctCount, 6);
      expect(updatedScore.incorrectCount, 2);
      expect(updatedScore.currentChain, 1);
      expect(updatedScore.totalAttempts, 8);
      expect(updatedScore.successRate, 75.0);
      expect(updatedScore.masteryLevel, 'Learning');
    });

    test('reading recognition exercise score updates correctly', () async {
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition},
      );

      provider.startSession(preferences: prefs);

      expect(provider.currentExerciseType, ExerciseType.readingRecognition);

      await provider.confirmAnswerAndAdvance(markedCorrect: true);

      final updatedScore = lastUpdatedCard!.getExerciseScore(
        ExerciseType.readingRecognition,
      );
      expect(updatedScore, isNotNull);
      expect(updatedScore!.correctCount, 1);
      expect(updatedScore.type, ExerciseType.readingRecognition);
    });

    test('multiple choice text exercise score updates correctly', () async {
      testCards = List.generate(
        5,
        (i) => CardModel.create(
          frontText: 'word$i',
          backText: 'translation$i',
          language: 'de',
        ),
      );

      provider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => testCards,
        updateCard: (card) async {
          lastUpdatedCard = card;
        },
      );

      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.multipleChoiceText},
      );

      provider.startSession(preferences: prefs);

      expect(provider.currentExerciseType, ExerciseType.multipleChoiceText);

      await provider.confirmAnswerAndAdvance(markedCorrect: true);

      final updatedScore = lastUpdatedCard!.getExerciseScore(
        ExerciseType.multipleChoiceText,
      );
      expect(updatedScore, isNotNull);
      expect(updatedScore!.correctCount, 1);
      expect(updatedScore.type, ExerciseType.multipleChoiceText);
    });

    test('reverse translation exercise score updates correctly', () async {
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.reverseTranslation},
      );

      provider.startSession(preferences: prefs);

      expect(provider.currentExerciseType, ExerciseType.reverseTranslation);

      await provider.confirmAnswerAndAdvance(markedCorrect: false);

      final updatedScore = lastUpdatedCard!.getExerciseScore(
        ExerciseType.reverseTranslation,
      );
      expect(updatedScore, isNotNull);
      expect(updatedScore!.incorrectCount, 1);
      expect(updatedScore.type, ExerciseType.reverseTranslation);
    });
  });
}
