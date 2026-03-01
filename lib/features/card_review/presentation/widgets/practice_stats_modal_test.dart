import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_state.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/practice_stats_modal.dart';

void main() {
  group('PracticeStatsModal', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          practiceSessionNotifierProvider.overrideWith(
            () => _TestPracticeSessionNotifier(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('displays correct stats information', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: PracticeStatsModal())),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Check that the modal displays the correct title
      expect(find.text('Practice Stats'), findsOneWidget);

      // Check that stats are displayed
      expect(find.text('5'), findsOneWidget); // correct count
      expect(find.text('3'), findsOneWidget); // incorrect count
      expect(
        find.text('63%'),
        findsOneWidget,
      ); // accuracy (5/8 = 62.5% rounded to 63%)

      // Check labels
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);

      // Check that close button exists
      expect(find.text('Close'), findsOneWidget);

      // Check that time is displayed (session has started)
      expect(find.textContaining('Time:'), findsOneWidget);
    });

    testWidgets('can close the modal', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: PracticeStatsModal())),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Modal should be closed (back to scaffold)
      expect(find.text('Practice Stats'), findsNothing);
    });

    testWidgets('displays zero stats when no practice done', (tester) async {
      // Create a notifier with zero stats
      final zeroStatsContainer = ProviderContainer(
        overrides: [
          practiceSessionNotifierProvider.overrideWith(
            () => _TestPracticeSessionNotifier(withZeroStats: true),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: zeroStatsContainer,
          child: MaterialApp(home: Scaffold(body: PracticeStatsModal())),
        ),
      );

      await tester.pumpAndSettle();

      // Check that zero stats are displayed
      expect(find.text('0'), findsNWidgets(2)); // correct and incorrect
      expect(find.text('0%'), findsOneWidget); // accuracy

      zeroStatsContainer.dispose();
    });
  });
}

class _TestPracticeSessionNotifier extends PracticeSessionNotifier {
  final bool withZeroStats;

  _TestPracticeSessionNotifier({this.withZeroStats = false});

  @override
  PracticeSessionState build() {
    if (withZeroStats) {
      return const PracticeSessionState(
        runCorrectCount: 0,
        runIncorrectCount: 0,
        sessionStartTime: null,
      );
    }

    return PracticeSessionState(
      runCorrectCount: 5,
      runIncorrectCount: 3,
      sessionStartTime: DateTime.now().subtract(const Duration(minutes: 2)),
    );
  }
}
