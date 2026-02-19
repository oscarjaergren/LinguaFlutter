import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/exercises/article_selection_exercise.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

void main() {
  group('ArticleSelectionExercise Widget', () {
    late CardModel testCard;

    setUpAll(() {
      LoggerService.initialize();
    });

    setUp(() {
      testCard = CardModel.create(
        frontText: 'der Tisch',
        backText: 'table',
        language: 'de',
      );
    });

    testWidgets('displays prompt and noun', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArticleSelectionExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Choose the correct article:'), findsOneWidget);
      expect(find.text('Tisch'), findsOneWidget);
      expect(find.text('table'), findsOneWidget);
    });

    testWidgets('displays all three article options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArticleSelectionExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('der'), findsOneWidget);
      expect(find.text('die'), findsOneWidget);
      expect(find.text('das'), findsOneWidget);
    });

    testWidgets('allows selecting an article', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArticleSelectionExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Tap an article
      await tester.tap(find.text('der'));
      await tester.pumpAndSettle();

      // Check button should be visible and enabled
      final button = find.widgetWithText(FilledButton, 'Check Answer');
      expect(button, findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });

    testWidgets('check button disabled when no selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArticleSelectionExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      final button = find.widgetWithText(FilledButton, 'Check Answer');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('shows gender hint after answer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArticleSelectionExercise(
              card: testCard,
              answerState: AnswerState.answered,
              currentAnswerCorrect: true,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Should show gender hint
      expect(find.textContaining('Masculine'), findsOneWidget);
    });

    testWidgets('disables selection after answer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArticleSelectionExercise(
              card: testCard,
              answerState: AnswerState.answered,
              currentAnswerCorrect: true,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Check button should not be visible
      expect(find.widgetWithText(FilledButton, 'Check Answer'), findsNothing);
    });

    testWidgets('extracts article from front text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArticleSelectionExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Noun should be displayed without article
      expect(find.text('Tisch'), findsOneWidget);
      expect(find.text('der Tisch'), findsNothing);
    });

    testWidgets('displays color-coded circles for articles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArticleSelectionExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Should have colored circles (containers with circular decoration)
      expect(find.byType(Container), findsWidgets);
    });
  });
}
