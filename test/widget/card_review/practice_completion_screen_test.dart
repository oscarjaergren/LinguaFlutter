import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/practice_completion_screen.dart';

void main() {
  group('PracticeCompletionScreen', () {
    late bool restartCalled;
    late bool closeCalled;

    setUp(() {
      restartCalled = false;
      closeCalled = false;
    });

    Widget buildTestWidget({
      int correctCount = 8,
      int incorrectCount = 2,
      Duration duration = const Duration(minutes: 5, seconds: 30),
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PracticeCompletionScreen(
              correctCount: correctCount,
              incorrectCount: incorrectCount,
              duration: duration,
              onRestart: () => restartCalled = true,
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );
    }

    testWidgets('should display "Session Complete!" title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Session Complete!'), findsOneWidget);
    });

    testWidgets('should display trophy icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('should display correct count', (tester) async {
      await tester.pumpWidget(buildTestWidget(correctCount: 15));

      expect(find.text('15'), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('should display incorrect count', (tester) async {
      await tester.pumpWidget(buildTestWidget(incorrectCount: 5));

      expect(find.text('5'), findsOneWidget);
      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('should calculate and display accuracy', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        correctCount: 8,
        incorrectCount: 2,
      ));

      // 8/10 = 80%
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
    });

    testWidgets('should display 100% accuracy when all correct', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        correctCount: 10,
        incorrectCount: 0,
      ));

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('should display 0% accuracy when all incorrect', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        correctCount: 0,
        incorrectCount: 10,
      ));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('should handle zero total (edge case)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        correctCount: 0,
        incorrectCount: 0,
      ));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('should display duration in minutes and seconds', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        duration: const Duration(minutes: 3, seconds: 45),
      ));

      expect(find.textContaining('3 min'), findsOneWidget);
    });

    testWidgets('should display duration in seconds only when under a minute', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        duration: const Duration(seconds: 45),
      ));

      expect(find.textContaining('45 seconds'), findsOneWidget);
    });

    testWidgets('should have Home button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('should have Practice Again button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Practice Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should call onClose when Home button tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Scroll to make button visible
      await tester.ensureVisible(find.text('Home'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Home'));
      await tester.pump();

      expect(closeCalled, true);
    });

    testWidgets('should call onRestart when Practice Again button tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Scroll to make button visible
      await tester.ensureVisible(find.text('Practice Again'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Practice Again'));
      await tester.pump();

      expect(restartCalled, true);
    });

    testWidgets('should show check_circle icon for correct stats', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show cancel icon for incorrect stats', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });
  });
}
