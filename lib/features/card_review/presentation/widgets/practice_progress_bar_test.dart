import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/practice_progress_bar.dart';

void main() {
  group('PracticeProgressBar', () {
    Widget buildTestWidget({
      double progress = 0.5,
      int correctCount = 5,
      int incorrectCount = 3,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PracticeProgressBar(
            progress: progress,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
          ),
        ),
      );
    }

    testWidgets('should render progress bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display correct count', (tester) async {
      await tester.pumpWidget(buildTestWidget(correctCount: 10));

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('should display incorrect count', (tester) async {
      await tester.pumpWidget(buildTestWidget(incorrectCount: 7));

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('should show check icon for correct', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show cancel icon for incorrect', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('should handle zero counts', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(correctCount: 0, incorrectCount: 0),
      );

      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('should handle full progress', (tester) async {
      await tester.pumpWidget(buildTestWidget(progress: 1.0));

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 1.0);
    });

    testWidgets('should handle zero progress', (tester) async {
      await tester.pumpWidget(buildTestWidget(progress: 0.0));

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.0);
    });

    testWidgets('should use green color for correct count', (tester) async {
      await tester.pumpWidget(buildTestWidget(correctCount: 5));

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, Colors.green);
    });

    testWidgets('should use red color for incorrect count', (tester) async {
      await tester.pumpWidget(buildTestWidget(incorrectCount: 3));

      final icon = tester.widget<Icon>(find.byIcon(Icons.cancel));
      expect(icon.color, Colors.red);
    });
  });
}
