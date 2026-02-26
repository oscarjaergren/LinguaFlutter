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

    test('practice session only includes due cards', () {
      final notifier = container.read(practiceSessionNotifierProvider.notifier);

      // Start session with all cards
      notifier.startSession(cards: testCards);

      final state = container.read(practiceSessionNotifierProvider);

      // Should only include 3 due cards (Hund, Katze, Wasser)
      expect(state.sessionQueue.length, 3);
      expect(state.isSessionActive, isTrue);

      // Verify the correct cards are included
      final cardFrontTexts = state.sessionQueue
          .map((item) => item.card.frontText)
          .toList();

      expect(cardFrontTexts, contains('Hund'));
      expect(cardFrontTexts, contains('Katze'));
      expect(cardFrontTexts, contains('Wasser'));
      expect(cardFrontTexts, isNot(contains('Baum'))); // Future card excluded
    });

    test('practice session empty when no cards are due', () {
      final futureCards = [
        CardModel.create(
          frontText: 'Zukunft',
          backText: 'future',
          language: 'de',
        ).copyWith(nextReview: DateTime.now().add(const Duration(days: 1))),
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
      notifier.startSession(cards: futureCards);

      final state = testContainer.read(practiceSessionNotifierProvider);

      expect(state.sessionQueue.isEmpty, isTrue);
      expect(state.isSessionActive, isFalse);

      testContainer.dispose();
    });

    test('demonstrates the empty session issue', () {
      // This test reproduces the user's issue:
      // 47 cards exist but none are due for review

      final manyFutureCards = List.generate(
        47,
        (index) => CardModel.create(
          frontText: 'Card $index',
          backText: 'Translation $index',
          language: 'de',
        ).copyWith(nextReview: DateTime.now().add(const Duration(days: 1))),
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
      notifier.startSession(cards: manyFutureCards);

      final state = testContainer.read(practiceSessionNotifierProvider);

      // This is the bug: 47 cards exist but session is empty
      expect(manyFutureCards.length, 47);
      expect(state.sessionQueue.isEmpty, isTrue);
      expect(state.isSessionActive, isFalse);

      testContainer.dispose();
    });
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
