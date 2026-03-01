import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/language/domain/language_notifier.dart';
import 'package:lingua_flutter/features/language/domain/language_state.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_score.dart';

/// Integration test to verify practice session behavior with real card due dates
void main() {
  group('PracticeSession Due Cards Integration', () {
    late ProviderContainer container;
    late List<CardModel> testCards;

    setUp(() {
      // Create cards with different due date scenarios
      final now = DateTime.now();
      testCards = [
        // New card - should be due (nextReview is null)
        CardModel.create(frontText: 'Hund', backText: 'dog', language: 'de'),

        // Card due in past - should be due
        CardModel.create(
          frontText: 'Katze',
          backText: 'cat',
          language: 'de',
        ).copyWith(nextReview: now.subtract(const Duration(days: 1))),

        // Card due in future - should NOT be due
        CardModel.create(
          frontText: 'Baum',
          backText: 'tree',
          language: 'de',
        ).copyWith(nextReview: now.add(const Duration(days: 1))),

        // Card with nextReview set to null explicitly - should be due
        CardModel.create(
          frontText: 'Wasser',
          backText: 'water',
          language: 'de',
        ).copyWith(nextReview: null),
      ];

      container = ProviderContainer(
        overrides: [
          cardManagementNotifierProvider.overrideWith(
            () => _TestCardManagementNotifier(testCards),
          ),
          exercisePreferencesNotifierProvider.overrideWith(
            () => _TestExercisePreferencesNotifier(),
          ),
          languageNotifierProvider.overrideWith(
            () => _TestLanguageNotifier(''),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('practice flow only selects due cards', () async {
      final notifier = container.read(practiceSessionNotifierProvider.notifier);

      // Start practice with all cards
      await notifier.startSession(cards: testCards);

      final state = container.read(practiceSessionNotifierProvider);

      // The currently selected item should be one of the due cards
      expect(state.currentItem, isNotNull);
      final currentFront = state.currentItem!.card.frontText;
      expect(currentFront, isIn(['Hund', 'Katze', 'Wasser']));
      expect(currentFront, isNot('Baum')); // Future card excluded
    });

    test(
      'practice flow reports no due items when all cards are future-dated',
      () async {
        final futureCards = [
          CardModel.create(
            frontText: 'Zukunft',
            backText: 'future',
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

        final testContainer = ProviderContainer(
          overrides: [
            cardManagementNotifierProvider.overrideWith(
              () => _TestCardManagementNotifier(futureCards),
            ),
            exercisePreferencesNotifierProvider.overrideWith(
              () => _TestExercisePreferencesNotifier(),
            ),
            languageNotifierProvider.overrideWith(
              () => _TestLanguageNotifier(''),
            ),
          ],
        );

        final notifier = testContainer.read(
          practiceSessionNotifierProvider.notifier,
        );
        await notifier.startSession(cards: futureCards);

        final state = testContainer.read(practiceSessionNotifierProvider);

        expect(state.currentItem, isNull);
        expect(state.noDueItems, isTrue);

        testContainer.dispose();
      },
    );

    test(
      'practice flow reports no due items for many future-dated cards',
      () async {
        // This test reproduces the user's issue:
        // 47 cards exist but none are due for review

        final manyFutureCards = List.generate(
          47,
          (index) =>
              CardModel.create(
                frontText: 'Card $index',
                backText: 'Translation $index',
                language: 'de',
              ).copyWith(
                nextReview: DateTime.now().add(const Duration(days: 1)),
                // Add exercise scores that are not due
                exerciseScores: {
                  ExerciseType.readingRecognition: ExerciseScore(
                    type: ExerciseType.readingRecognition,
                    correctCount: 1,
                    incorrectCount: 0,
                    lastPracticed: DateTime.now().subtract(
                      const Duration(days: 1),
                    ),
                    nextReview: DateTime.now().add(const Duration(days: 1)),
                  ),
                },
              ),
        );

        final testContainer = ProviderContainer(
          overrides: [
            cardManagementNotifierProvider.overrideWith(
              () => _TestCardManagementNotifier(manyFutureCards),
            ),
            exercisePreferencesNotifierProvider.overrideWith(
              () => _TestExercisePreferencesNotifier(),
            ),
            languageNotifierProvider.overrideWith(
              () => _TestLanguageNotifier(''),
            ),
          ],
        );

        final notifier = testContainer.read(
          practiceSessionNotifierProvider.notifier,
        );
        await notifier.startSession(cards: manyFutureCards);

        final state = testContainer.read(practiceSessionNotifierProvider);

        // 47 cards exist but none are due - practice should report no due items
        expect(manyFutureCards.length, 47);
        expect(state.currentItem, isNull);
        expect(state.noDueItems, isTrue);

        testContainer.dispose();
      },
    );
  });
}

class _TestCardManagementNotifier extends CardManagementNotifier {
  _TestCardManagementNotifier(this.cards);

  final List<CardModel> cards;

  @override
  CardManagementState build() => CardManagementState(allCards: cards);
}

class _TestExercisePreferencesNotifier extends ExercisePreferencesNotifier {
  @override
  ExercisePreferencesState build() => ExercisePreferencesState(
    preferences: const ExercisePreferences(
      enabledTypes: {
        ExerciseType.reverseTranslation,
        ExerciseType.readingRecognition,
      },
    ),
    isInitialized: true,
  );
}

class _TestLanguageNotifier extends LanguageNotifier {
  _TestLanguageNotifier(this.activeLanguageCode);

  final String activeLanguageCode;

  @override
  LanguageState build() => LanguageState(activeLanguage: activeLanguageCode);
}
