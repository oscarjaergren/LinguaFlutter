import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/swipeable_exercise_card.dart';

void main() {
  group('SwipeableExerciseCard', () {
    late bool swipedRight;
    late bool swipedLeft;

    setUp(() {
      swipedRight = false;
      swipedLeft = false;
    });

    Widget buildTestWidget({bool canSwipe = true, Widget? child}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SwipeableExerciseCard(
              canSwipe: canSwipe,
              onSwipeRight: () => swipedRight = true,
              onSwipeLeft: () => swipedLeft = true,
              child:
                  child ??
                  const SizedBox(
                    width: 300,
                    height: 400,
                    child: Center(child: Text('Test Content')),
                  ),
            ),
          ),
        ),
      );
    }

    testWidgets('should render child content', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(child: const Text('Exercise Content')),
      );

      expect(find.text('Exercise Content'), findsOneWidget);
    });

    testWidgets('should have card styling', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Should have a container with decoration
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should respond to tap when onTap provided', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableExerciseCard(
              canSwipe: true,
              onSwipeRight: () {},
              onSwipeLeft: () {},
              onTap: () => tapped = true,
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SwipeableExerciseCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should not swipe when canSwipe is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(canSwipe: false));

      // Try to swipe right
      await tester.drag(
        find.byType(SwipeableExerciseCard),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();

      expect(swipedRight, false);
      expect(swipedLeft, false);
    });

    testWidgets('should trigger onSwipeRight on significant right swipe', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(canSwipe: true));

      // Perform a significant right swipe
      await tester.fling(
        find.byType(SwipeableExerciseCard),
        const Offset(300, 0),
        1000,
      );
      // Allow animation to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(swipedRight, true);
      expect(swipedLeft, false);
    });

    testWidgets('should trigger onSwipeLeft on significant left swipe', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(canSwipe: true));

      // Perform a significant left swipe
      await tester.fling(
        find.byType(SwipeableExerciseCard),
        const Offset(-300, 0),
        1000,
      );
      // Allow animation to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(swipedRight, false);
      expect(swipedLeft, true);
    });

    testWidgets('should not trigger swipe on small drag', (tester) async {
      await tester.pumpWidget(buildTestWidget(canSwipe: true));

      // Perform a small drag that shouldn't trigger swipe
      await tester.drag(
        find.byType(SwipeableExerciseCard),
        const Offset(50, 0),
      );
      await tester.pumpAndSettle();

      expect(swipedRight, false);
      expect(swipedLeft, false);
    });

    testWidgets('should apply custom background color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableExerciseCard(
              canSwipe: true,
              onSwipeRight: () {},
              onSwipeLeft: () {},
              backgroundColor: Colors.blue,
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );

      // Widget should build without errors
      expect(find.byType(SwipeableExerciseCard), findsOneWidget);
    });

    testWidgets('should show swipe indicators during drag when canSwipe', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(canSwipe: true));

      // Start dragging right
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SwipeableExerciseCard)),
      );
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();

      // Should show CORRECT indicator
      expect(find.text('CORRECT'), findsOneWidget);

      await gesture.cancel();
    });

    testWidgets('should show INCORRECT indicator on left drag', (tester) async {
      await tester.pumpWidget(buildTestWidget(canSwipe: true));

      // Start dragging left
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SwipeableExerciseCard)),
      );
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      // Should show INCORRECT indicator
      expect(find.text('INCORRECT'), findsOneWidget);

      await gesture.cancel();
    });

    testWidgets('should expose handleKeyboardSwipe via state', (tester) async {
      final key = GlobalKey<SwipeableExerciseCardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableExerciseCard(
              key: key,
              canSwipe: true,
              onSwipeRight: () => swipedRight = true,
              onSwipeLeft: () => swipedLeft = true,
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );

      // Trigger keyboard swipe via state
      key.currentState?.handleKeyboardSwipe(true);
      // Allow animation to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(swipedRight, true);
    });
  });
}
