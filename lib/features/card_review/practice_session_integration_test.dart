@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_state.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/card_review/presentation/screens/practice_screen.dart';
import 'package:lingua_flutter/features/language/domain/language_notifier.dart';
import 'package:lingua_flutter/features/language/domain/language_state.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

class _TestCardManagementNotifier extends CardManagementNotifier {
  _TestCardManagementNotifier(this.cards);

  final List<CardModel> cards;

  @override
  CardManagementState build() {
    // Apply filters to simulate real behavior
    final filtered = cards.where((c) => !c.isArchived).toList();
    return CardManagementState(allCards: cards, filteredCards: filtered);
  }
}

class _TestLanguageNotifier extends LanguageNotifier {
  _TestLanguageNotifier(this.activeLanguageCode);

  final String activeLanguageCode;

  @override
  LanguageState build() => LanguageState(activeLanguage: activeLanguageCode);
}

class _TestExercisePreferencesNotifier extends ExercisePreferencesNotifier {
  @override
  ExercisePreferencesState build() => ExercisePreferencesState(
    preferences: ExercisePreferences.defaults(),
    isInitialized: true,
  );
}

void main() {
  setUpAll(() {
    LoggerService.initialize();
  });

  group('Practice Session Integration', () {
    late List<CardModel> dueCards;
    late List<CardModel> notDueCards;

    setUp(() {
      final now = DateTime.now();
      dueCards = [
        CardModel.create(
          frontText: 'Hund',
          backText: 'dog',
          language: 'de',
        ).copyWith(nextReview: now.subtract(const Duration(days: 1))),
        CardModel.create(
          frontText: 'Katze',
          backText: 'cat',
          language: 'de',
        ).copyWith(nextReview: now.subtract(const Duration(hours: 1))),
      ];

      notDueCards = [
        CardModel.create(
          frontText: 'Baum',
          backText: 'tree',
          language: 'de',
        ).copyWith(nextReview: now.add(const Duration(days: 1))),
      ];
    });

    testWidgets(
      'PracticeScreen auto-starts session with due cards when opened',
      (tester) async {
        final allCards = [...dueCards, ...notDueCards];
        final container = ProviderContainer(
          overrides: [
            cardManagementNotifierProvider.overrideWith(
              () => _TestCardManagementNotifier(allCards),
            ),
            languageNotifierProvider.overrideWith(
              () => _TestLanguageNotifier('de'),
            ),
            exercisePreferencesNotifierProvider.overrideWith(
              () => _TestExercisePreferencesNotifier(),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/practice',
                    builder: (context, state) => const PracticeScreen(),
                  ),
                ],
                initialLocation: '/practice',
              ),
            ),
          ),
        );

        // Wait for post-frame callback to execute
        await tester.pumpAndSettle();

        final sessionState = container.read(practiceSessionNotifierProvider);
        expect(
          sessionState.isSessionActive,
          isTrue,
          reason: 'Session should auto-start when PracticeScreen opens',
        );
        expect(
          sessionState.sessionQueue.length,
          greaterThan(0),
          reason: 'Session should have practice items for due cards',
        );
        expect(
          sessionState.currentIndex,
          0,
          reason: 'Should start at first card',
        );

        container.dispose();
      },
    );

    testWidgets('PracticeScreen shows message when no due cards available', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          cardManagementNotifierProvider.overrideWith(
            () => _TestCardManagementNotifier(notDueCards),
          ),
          languageNotifierProvider.overrideWith(
            () => _TestLanguageNotifier('de'),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/practice',
                  builder: (context, state) => const PracticeScreen(),
                ),
              ],
              initialLocation: '/practice',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final sessionState = container.read(practiceSessionNotifierProvider);
      expect(
        sessionState.isSessionActive,
        isFalse,
        reason: 'Session should not start when no cards are due',
      );

      // Should show message about starting from card list
      expect(find.text('Start a session from the card list'), findsOneWidget);

      container.dispose();
    });

    testWidgets(
      'PracticeScreen auto-starts when navigated to from external source',
      (tester) async {
        final allCards = [...dueCards, ...notDueCards];
        final container = ProviderContainer(
          overrides: [
            cardManagementNotifierProvider.overrideWith(
              () => _TestCardManagementNotifier(allCards),
            ),
            languageNotifierProvider.overrideWith(
              () => _TestLanguageNotifier('de'),
            ),
            exercisePreferencesNotifierProvider.overrideWith(
              () => _TestExercisePreferencesNotifier(),
            ),
          ],
        );

        // Simulate navigation to practice screen (like from dashboard button)
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/practice',
                    builder: (context, state) => const PracticeScreen(),
                  ),
                ],
                initialLocation: '/practice',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Session should be active with due cards
        final sessionState = container.read(practiceSessionNotifierProvider);
        expect(
          sessionState.isSessionActive,
          isTrue,
          reason:
              'Session should auto-start when PracticeScreen is navigated to',
        );
        expect(
          sessionState.sessionQueue.length,
          greaterThan(0),
          reason: 'Session should have practice items for due cards',
        );

        container.dispose();
      },
    );
  });
}
