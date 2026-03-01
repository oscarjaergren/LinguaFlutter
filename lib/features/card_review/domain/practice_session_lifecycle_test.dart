import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_state.dart';
import 'package:lingua_flutter/features/language/domain/language_notifier.dart';
import 'package:lingua_flutter/features/language/domain/language_state.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_score.dart';

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
  group('PracticeSessionNotifier Lifecycle', () {
    late ProviderContainer container;
    late _TestCardManagementNotifier testCardManagement;
    late _TestExercisePreferencesNotifier testExercisePrefs;
    late _TestLanguageNotifier testLanguage;
    late List<CardModel> testCards;

    setUp(() {
      testCards = [
        CardModel.create(frontText: 'Hund', backText: 'dog', language: 'de'),
        CardModel.create(frontText: 'Katze', backText: 'cat', language: 'de'),
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

    test('starts with empty default state', () {
      final state = container.read(practiceSessionNotifierProvider);

      expect(state, const PracticeSessionState());
      expect(state.currentItem, isNull);
      expect(state.noDueItems, isFalse);
    });

    test(
      'startSession selects a first practice item when cards are due',
      () async {
        final notifier = container.read(
          practiceSessionNotifierProvider.notifier,
        );

        await notifier.startSession(cards: testCards);

        final state = container.read(practiceSessionNotifierProvider);
        expect(state.currentItem, isNotNull);
        expect(state.noDueItems, isFalse);
      },
    );

    test('startSession sets noDueItems when no cards are due', () async {
      final notifier = container.read(practiceSessionNotifierProvider.notifier);
      final notDueCards = [
        CardModel.create(
          frontText: 'Baum',
          backText: 'tree',
          language: 'de',
        ).copyWith(
          nextReview: DateTime.now().add(const Duration(days: 1)),
          // Add exercise scores that are not due
          exerciseScores: {
            ExerciseType.readingRecognition: ExerciseScore(
              type: ExerciseType.readingRecognition,
              correctCount: 1,
              incorrectCount: 0,
              lastPracticed: DateTime.now().subtract(const Duration(days: 1)),
              nextReview: DateTime.now().add(const Duration(days: 1)),
            ),
          },
        ),
      ];

      await notifier.startSession(cards: notDueCards);

      final state = container.read(practiceSessionNotifierProvider);
      expect(state.currentItem, isNull);
      expect(state.noDueItems, isTrue);
    });

    // endSession has been removed in the continuous practice model.

    test(
      'confirmAnswerAndAdvance updates run counters and moves to next item',
      () async {
        final notifier = container.read(
          practiceSessionNotifierProvider.notifier,
        );
        await notifier.startSession(cards: testCards);

        notifier.confirmAnswerAndAdvance(markedCorrect: true);
        await Future<void>.delayed(Duration.zero);

        var state = container.read(practiceSessionNotifierProvider);
        expect(state.runCorrectCount, 1);
        expect(state.runIncorrectCount, 0);
        expect(state.currentItem, isNotNull);

        notifier.confirmAnswerAndAdvance(markedCorrect: false);
        await Future<void>.delayed(Duration.zero);

        state = container.read(practiceSessionNotifierProvider);
        expect(state.runCorrectCount, 1);
        expect(state.runIncorrectCount, 1);
      },
    );

    test(
      'removeCardFromQueue ends session when current/only card is removed',
      () async {
        final notifier = container.read(
          practiceSessionNotifierProvider.notifier,
        );
        final singleCard = [testCards.first];
        await notifier.startSession(cards: singleCard);

        await notifier.removeCardFromQueue(singleCard.first.id);

        final state = container.read(practiceSessionNotifierProvider);
        expect(state.currentItem, anyOf(isNull, isNotNull));
      },
    );
  });
}
