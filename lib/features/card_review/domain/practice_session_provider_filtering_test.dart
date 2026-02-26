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
import 'package:lingua_flutter/shared/domain/models/word_data.dart';

class _TestCardManagementNotifier extends CardManagementNotifier {
  _TestCardManagementNotifier(this.cards);

  final List<CardModel> cards;

  @override
  CardManagementState build() => CardManagementState(allCards: cards);
}

class _TestExercisePreferencesNotifier extends ExercisePreferencesNotifier {
  _TestExercisePreferencesNotifier(this.initialPreferences);

  final ExercisePreferences initialPreferences;

  @override
  ExercisePreferencesState build() => ExercisePreferencesState(
    preferences: initialPreferences,
    isInitialized: true,
  );

  void setPreferences(ExercisePreferences preferences) {
    state = ExercisePreferencesState(
      preferences: preferences,
      isInitialized: true,
    );
  }
}

class _TestLanguageNotifier extends LanguageNotifier {
  _TestLanguageNotifier(this.activeLanguageCode);

  final String activeLanguageCode;

  @override
  LanguageState build() => LanguageState(activeLanguage: activeLanguageCode);
}

void main() {
  group('PracticeSessionNotifier Filtering', () {
    late ProviderContainer container;
    late _TestCardManagementNotifier testCardManagement;
    late _TestExercisePreferencesNotifier testExercisePrefs;
    late _TestLanguageNotifier testLanguage;
    late List<CardModel> testCards;

    setUp(() {
      testCards = [
        CardModel.create(
          frontText: 'Hund',
          backText: 'dog',
          language: 'de',
        ).copyWith(examples: ['Der Hund ist groß']),

        CardModel.create(
          frontText: 'gehen',
          backText: 'to go',
          language: 'de',
        ).copyWith(
          wordData: WordData.verb(
            isRegular: false,
            isSeparable: false,
            auxiliary: 'sein',
            presentSecondPerson: 'gehst',
            presentThirdPerson: 'geht',
            pastSimple: 'ging',
            pastParticiple: 'gegangen',
          ),
        ),

        CardModel.create(
          frontText: 'der Tisch',
          backText: 'table',
          language: 'de',
        ),

        CardModel.create(
          frontText: 'schnell',
          backText: 'fast',
          language: 'de',
        ),
      ];

      testCardManagement = _TestCardManagementNotifier(testCards);
      testExercisePrefs = _TestExercisePreferencesNotifier(
        ExercisePreferences.defaults(),
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

    test('only includes enabled exercise types', () {
      (container.read(exercisePreferencesNotifierProvider.notifier)
              as _TestExercisePreferencesNotifier)
          .setPreferences(
            const ExercisePreferences(
              enabledTypes: {ExerciseType.reverseTranslation},
            ),
          );

      final notifier = container.read(practiceSessionNotifierProvider.notifier);
      notifier.startSession(cards: testCards);

      final state = container.read(practiceSessionNotifierProvider);
      for (final item in state.sessionQueue) {
        expect(item.exerciseType, ExerciseType.reverseTranslation);
      }
    });

    test('filters out cards without required features for exercise type', () {
      (container.read(exercisePreferencesNotifierProvider.notifier)
              as _TestExercisePreferencesNotifier)
          .setPreferences(
            const ExercisePreferences(
              enabledTypes: {ExerciseType.sentenceBuilding},
            ),
          );

      final notifier = container.read(practiceSessionNotifierProvider.notifier);
      notifier.startSession(cards: testCards);

      final state = container.read(practiceSessionNotifierProvider);
      expect(state.sessionQueue.length, greaterThan(0));

      for (final item in state.sessionQueue) {
        expect(item.card.examples.isNotEmpty, true);
        expect(item.exerciseType, ExerciseType.sentenceBuilding);
      }
    });

    test('builds practice queue with available exercise types', () {
      final notifier = container.read(practiceSessionNotifierProvider.notifier);

      notifier.startSession(cards: testCards);

      final state = container.read(practiceSessionNotifierProvider);
      expect(state.isSessionActive, true);
      expect(state.sessionQueue.isNotEmpty, true);

      for (final item in state.sessionQueue) {
        expect(
          item.exerciseType.canUse(
            item.card,
            hasEnoughCardsForMultipleChoice: true,
          ),
          true,
        );
      }
    });

    test('includes multiple exercise types per card when enabled', () {
      (container.read(exercisePreferencesNotifierProvider.notifier)
              as _TestExercisePreferencesNotifier)
          .setPreferences(
            const ExercisePreferences(
              enabledTypes: {
                ExerciseType.reverseTranslation,
                ExerciseType.readingRecognition,
              },
              prioritizeWeaknesses: false,
            ),
          );

      final notifier = container.read(practiceSessionNotifierProvider.notifier);
      notifier.startSession(cards: testCards);

      final state = container.read(practiceSessionNotifierProvider);
      expect(state.sessionQueue.length, greaterThan(testCards.length));
    });

    test('respects exercise category filtering', () {
      final recognitionTypes = ExerciseCategory.recognition.exerciseTypes;
      (container.read(exercisePreferencesNotifierProvider.notifier)
              as _TestExercisePreferencesNotifier)
          .setPreferences(
            ExercisePreferences(enabledTypes: recognitionTypes.toSet()),
          );

      final notifier = container.read(practiceSessionNotifierProvider.notifier);
      notifier.startSession(cards: testCards);

      final state = container.read(practiceSessionNotifierProvider);

      for (final item in state.sessionQueue) {
        expect(recognitionTypes.contains(item.exerciseType), true);
      }
    });
  });
}
