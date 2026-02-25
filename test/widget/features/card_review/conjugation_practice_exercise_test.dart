import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_types.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/exercises/conjugation_practice_exercise.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/word_data.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

void main() {
  group('ConjugationPracticeExercise Widget', () {
    late CardModel verbCard;
    late CardModel nounCard;

    setUpAll(() {
      LoggerService.initialize();
    });

    setUp(() {
      verbCard =
          CardModel.create(
            frontText: 'gehen',
            backText: 'to go',
            language: 'de',
          ).copyWith(
            wordData: WordData.verb(
              isRegular: false,
              isSeparable: false,
              auxiliary: 'sein',
              presentSecondPerson: 'gehst',
              presentThirdPerson: 'geht',
              pastSimple: 'ging',
              pastParticiple: 'gegangen',
            ),
          );

      nounCard =
          CardModel.create(
            frontText: 'der Hund',
            backText: 'dog',
            language: 'de',
          ).copyWith(
            wordData: WordData.noun(
              gender: 'der',
              plural: 'Hunde',
              genitive: 'Hundes',
            ),
          );
    });

    testWidgets('displays prompt and word', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: verbCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Provide the correct form:'), findsOneWidget);
      expect(find.text('gehen'), findsOneWidget);
      expect(find.text('to go'), findsOneWidget);
    });

    testWidgets('displays text input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: verbCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Your answer'), findsOneWidget);
    });

    testWidgets('allows entering text in field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: verbCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'geht');
      await tester.pump();

      // Verify text was entered
      expect(find.text('geht'), findsOneWidget);
    });

    testWidgets('shows correct answer when wrong', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: verbCard,
              answerState: AnswerState.answered,
              currentAnswerCorrect: false,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Correct answer:'), findsOneWidget);
    });

    testWidgets('disables input after answer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: verbCard,
              answerState: AnswerState.answered,
              currentAnswerCorrect: true,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('noun shows article selector instead of text field', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: nounCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('der Hund'), findsOneWidget);
      // Article selector shows der/die/das buttons — no text field
      expect(find.byType(TextField), findsNothing);
      expect(find.text('der'), findsOneWidget);
      expect(find.text('die'), findsOneWidget);
      expect(find.text('das'), findsOneWidget);
    });

    testWidgets(
      'noun with plural "die" still shows article selector not text field',
      (tester) async {
        // Regression test for Bug #2: a noun whose plural is "die" must not
        // accidentally trigger the article-selector for the plural prompt.
        // With the fix, nouns always use the article selector (for gender).
        final nounWithDiePlural =
            CardModel.create(
              frontText: 'die Frau',
              backText: 'woman',
              language: 'de',
            ).copyWith(
              wordData: WordData.noun(
                gender: 'die',
                plural: 'die', // plural happens to equal an article
              ),
            );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConjugationPracticeExercise(
                card: nounWithDiePlural,
                answerState: AnswerState.pending,
                currentAnswerCorrect: null,
                onCheckAnswer: (_) {},
              ),
            ),
          ),
        );

        // Must show article selector (prompt = 'article'), not a text field
        expect(find.byType(TextField), findsNothing);
        expect(find.text('der'), findsOneWidget);
        expect(find.text('die'), findsOneWidget);
        expect(find.text('das'), findsOneWidget);
      },
    );

    testWidgets('article selector state resets when card changes', (
      tester,
    ) async {
      // Regression test for Bug #3: _selectedArticle must clear on card swap.
      bool? lastResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: nounCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (result) => lastResult = result,
            ),
          ),
        ),
      );

      // Select an article on the first card
      await tester.tap(find.text('die'));
      await tester.pump();

      // Swap to a different card (same widget, new card)
      final nounCard2 =
          CardModel.create(
            frontText: 'das Kind',
            backText: 'child',
            language: 'de',
          ).copyWith(
            wordData: WordData.noun(gender: 'das', plural: 'Kinder'),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: nounCard2,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (result) => lastResult = result,
            ),
          ),
        ),
      );

      // Check Answer button should be disabled (no article selected yet)
      final checkButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Check Answer'),
      );
      expect(checkButton.onPressed, isNull);
      expect(lastResult, isNull);
    });

    testWidgets(
      'article selection resets when answerState returns to pending on same card',
      (tester) async {
        // A card can appear for multiple exercise types in one session
        // (e.g. multipleChoiceText then conjugationPractice). When the session
        // advances to the next exercise the parent rebuilds this widget with the
        // same card.id but answerState reset to pending. The previously selected
        // article must not carry over.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConjugationPracticeExercise(
                card: nounCard,
                answerState: AnswerState.pending,
                currentAnswerCorrect: null,
                onCheckAnswer: (_) {},
              ),
            ),
          ),
        );

        // Select an article and submit the answer
        await tester.tap(find.text('die'));
        await tester.pump();

        // Parent marks the answer as answered (same card, same id)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConjugationPracticeExercise(
                card: nounCard,
                answerState: AnswerState.answered,
                currentAnswerCorrect: false,
                onCheckAnswer: (_) {},
              ),
            ),
          ),
        );

        // Session advances to the next exercise on the same card — answerState
        // resets to pending while card.id is unchanged.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConjugationPracticeExercise(
                card: nounCard,
                answerState: AnswerState.pending,
                currentAnswerCorrect: null,
                onCheckAnswer: (_) {},
              ),
            ),
          ),
        );

        // Check Answer must be disabled — the previous selection must be cleared
        final checkButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Check Answer'),
        );
        expect(checkButton.onPressed, isNull);
      },
    );

    testWidgets(
      'a noun whose word data changes to empty gender shows a text field, not the article selector',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConjugationPracticeExercise(
                card: nounCard,
                answerState: AnswerState.pending,
                currentAnswerCorrect: null,
                onCheckAnswer: (_) {},
              ),
            ),
          ),
        );
        expect(find.byType(TextField), findsNothing);

        final updatedCard = nounCard.copyWith(
          wordData: WordData.noun(gender: '', plural: 'Hunde'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConjugationPracticeExercise(
                card: updatedCard,
                answerState: AnswerState.pending,
                currentAnswerCorrect: null,
                onCheckAnswer: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('der'), findsNothing);
        expect(find.text('die'), findsNothing);
        expect(find.text('das'), findsNothing);
      },
    );

    testWidgets('displays form prompt', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeExercise(
              card: verbCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Should show some form prompt (du, er, past, etc.)
      // We can't predict which one since it's random, but there should be parentheses
      expect(find.textContaining('('), findsWidgets);
      expect(find.textContaining(')'), findsWidgets);
    });
  });
}
