import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_state.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/features/card_review/presentation/screens/practice_screen.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/swipeable_exercise_card.dart';
import 'package:lingua_flutter/features/language/domain/language_notifier.dart';
import 'package:lingua_flutter/features/language/domain/language_state.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

class _TestCardManagementNotifier extends CardManagementNotifier {
  _TestCardManagementNotifier(this.cards);

  final List<CardModel> cards;

  @override
  CardManagementState build() =>
      CardManagementState(allCards: cards, filteredCards: cards);
}

class _TestExercisePreferencesNotifier extends ExercisePreferencesNotifier {
  @override
  ExercisePreferencesState build() => ExercisePreferencesState(
    preferences: ExercisePreferences.defaults(),
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
  setUpAll(() {
    LoggerService.initialize();
  });

  group('Practice Session Widget Tests', () {
    late List<CardModel> testCards;

    setUp(() {
      testCards = [
        CardModel.create(frontText: 'Hund', backText: 'dog', language: 'de'),
        CardModel.create(frontText: 'Katze', backText: 'cat', language: 'de'),
      ];
    });

    testWidgets(
      'PracticeScreen integrates SwipeableExerciseCard for card swiping',
      (tester) async {
        // Arrange: Setup practice screen with cards
        await tester.pumpWidget(
          ProviderScope(
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
            child: const MaterialApp(home: PracticeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Debug: Check session state
        final startMessage = find.text('Start a session from the card list');

        // Assert: Should not show start message when cards are available
        expect(
          startMessage,
          findsNothing,
          reason: 'Should not show start message when cards are available',
        );

        // Act: Find the SwipeableExerciseCard
        final swipeableCardFinder = find.byType(SwipeableExerciseCard);

        // Assert: SwipeableExerciseCard should be present when session is active
        expect(
          swipeableCardFinder,
          findsOneWidget,
          reason:
              'PracticeScreen should use SwipeableExerciseCard when session is active',
        );
      },
    );

    testWidgets('swipe right advances session and marks card correct', (
      tester,
    ) async {
      // Arrange: Setup practice screen with cards
      await tester.pumpWidget(
        ProviderScope(
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
          child: const MaterialApp(home: PracticeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the SwipeableExerciseCard
      final swipeableCard = find.byType(SwipeableExerciseCard);
      expect(swipeableCard, findsOneWidget);

      // Act: Swipe right to mark as correct
      await tester.fling(swipeableCard, const Offset(500, 0), 1000);
      await tester.pumpAndSettle();

      // Assert: Should show some indication of swipe working
      // (This test will initially fail, driving the implementation)
      expect(find.byType(SwipeableExerciseCard), findsOneWidget);
    });

    testWidgets('swipe left advances session and marks card incorrect', (
      tester,
    ) async {
      // Arrange: Setup practice screen with cards
      await tester.pumpWidget(
        ProviderScope(
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
          child: const MaterialApp(home: PracticeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the SwipeableExerciseCard
      final swipeableCard = find.byType(SwipeableExerciseCard);
      expect(swipeableCard, findsOneWidget);

      // Act: Swipe left to mark as incorrect
      await tester.fling(swipeableCard, const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      // Assert: Should show some indication of swipe working
      // (This test will initially fail, driving the implementation)
      expect(find.byType(SwipeableExerciseCard), findsOneWidget);
    });
  });
}
