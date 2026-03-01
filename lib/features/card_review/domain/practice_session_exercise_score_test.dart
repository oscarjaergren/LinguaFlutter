import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_state.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/features/language/domain/language_notifier.dart';
import 'package:lingua_flutter/features/language/domain/language_state.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

class _TestCardManagementNotifier extends CardManagementNotifier {
  _TestCardManagementNotifier(this.cards);

  final List<CardModel> cards;
  CardModel? lastUpdatedCard;

  @override
  CardManagementState build() => CardManagementState(allCards: cards);

  @override
  Future<void> updateCard(CardModel card) async {
    lastUpdatedCard = card;
    state = state.copyWith(
      allCards: [
        for (final existing in state.allCards)
          if (existing.id == card.id) card else existing,
      ],
    );
  }
}

class _TestExercisePreferencesNotifier extends ExercisePreferencesNotifier {
  _TestExercisePreferencesNotifier(this.initialPreferences);

  final ExercisePreferences initialPreferences;

  @override
  ExercisePreferencesState build() => ExercisePreferencesState(
    preferences: initialPreferences,
    isInitialized: true,
  );
}

class _TestLanguageNotifier extends LanguageNotifier {
  _TestLanguageNotifier(this.activeLanguageCode);

  final String activeLanguageCode;

  @override
  LanguageState build() => LanguageState(activeLanguage: activeLanguageCode);
}

void main() {
  group('PracticeSessionNotifier Exercise Score Updates', () {
    late ProviderContainer container;
    late _TestCardManagementNotifier testCardManagement;
    late _TestExercisePreferencesNotifier testExercisePrefs;
    late _TestLanguageNotifier testLanguage;
    late List<CardModel> testCards;

    setUp(() {
      testCards = [
        CardModel.create(frontText: 'Hund', backText: 'dog', language: 'de'),
      ];

      testCardManagement = _TestCardManagementNotifier(testCards);
      testExercisePrefs = _TestExercisePreferencesNotifier(
        const ExercisePreferences(
          enabledTypes: {ExerciseType.reverseTranslation},
        ),
      );
      testLanguage = _TestLanguageNotifier('de');

      container = ProviderContainer(
        overrides: [
          cardManagementNotifierProvider.overrideWith(() => testCardManagement),
          exercisePreferencesNotifierProvider.overrideWith(
            () => testExercisePrefs,
          ),
          languageNotifierProvider.overrideWith(() => testLanguage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'writing translation exercise score updates on correct answer',
      () async {
        final notifier = container.read(
          practiceSessionNotifierProvider.notifier,
        );

        await notifier.startSession(cards: testCards);

        final state = container.read(practiceSessionNotifierProvider);
        expect(state.currentItem, isNotNull);
        expect(notifier.currentExerciseType, ExerciseType.reverseTranslation);

        final initialCard = notifier.currentCard!;
        final initialScore = initialCard.getExerciseScore(
          ExerciseType.reverseTranslation,
        );

        expect(initialScore, isNotNull);
        expect(initialScore!.totalAttempts, 0);

        notifier.confirmAnswerAndAdvance(markedCorrect: true);
        await Future.delayed(Duration.zero); // Let async operations complete

        expect(testCardManagement.lastUpdatedCard, isNotNull);

        final updatedScore = testCardManagement.lastUpdatedCard!
            .getExerciseScore(ExerciseType.reverseTranslation);
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
        final notifier = container.read(
          practiceSessionNotifierProvider.notifier,
        );

        await notifier.startSession(cards: testCards);

        notifier.confirmAnswerAndAdvance(markedCorrect: false);
        await Future.delayed(Duration.zero); // Let async operations complete

        expect(testCardManagement.lastUpdatedCard, isNotNull);

        final updatedScore = testCardManagement.lastUpdatedCard!
            .getExerciseScore(ExerciseType.reverseTranslation);
        expect(updatedScore, isNotNull);
        expect(updatedScore!.correctCount, 0);
        expect(updatedScore.incorrectCount, 1);
        expect(updatedScore.totalAttempts, 1);
        expect(updatedScore.successRate, 0.0);
        expect(updatedScore.currentChain, 0);
        expect(updatedScore.masteryLevel, 'Difficult');
      },
    );

    test('prioritizes weakness when enabled', () async {
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

    test('different exercise types maintain separate scores', () {
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
  });
}
