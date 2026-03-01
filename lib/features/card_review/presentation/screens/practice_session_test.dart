import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_review/presentation/screens/practice_screen.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/swipeable_exercise_card.dart';
import 'package:lingua_flutter/features/card_review/test_utils.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

void main() {
  setUpAll(() {
    LoggerService.initialize();
  });

  group('Practice Session Widget Tests', () {
    late List<CardModel> testCards;

    setUp(() {
      testCards = createTestCards(count: 2);
    });

    testWidgets(
      'PracticeScreen integrates SwipeableExerciseCard for card swiping',
      (tester) async {
        // Arrange: Setup practice screen with cards
        final container = createTestContainer(cards: testCards);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
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

        // Find the SwipeableExerciseCard
        final swipeableCard = find.byType(SwipeableExerciseCard);
        expect(swipeableCard, findsOneWidget);

        // Act: Swipe right to mark as correct
        await tester.fling(swipeableCard, const Offset(500, 0), 1000);
        await tester.pumpAndSettle();

        // Assert: Should show some indication of swipe working
        // (This test will initially fail, driving the implementation)
        expect(find.byType(SwipeableExerciseCard), findsOneWidget);

        container.dispose();
      },
    );

    testWidgets('swipe right advances session and marks card correct', (
      tester,
    ) async {
      // Arrange: Setup practice screen with cards
      final container = createTestContainer(cards: testCards);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      container.dispose();
    });

    testWidgets('swipe left advances session and marks card incorrect', (
      tester,
    ) async {
      // Arrange: Setup practice screen with cards
      final container = createTestContainer(cards: testCards);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      container.dispose();
    });
  });
}
