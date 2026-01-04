import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/exercises/conjugation_practice_exercise.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/word_data.dart';

void main() {
  group('ConjugationPracticeExercise Widget', () {
    late CardModel verbCard;
    late CardModel nounCard;

    setUp(() {
      verbCard =
          CardModel.create(
            frontText: 'gehen',
            backText: 'to go',
            language: 'de',
            category: 'vocabulary',
          ).copyWith(
            wordData: WordData.verb(
              isRegular: false,
              isSeparable: false,
              auxiliary: 'sein',
              presentDu: 'gehst',
              presentEr: 'geht',
              pastSimple: 'ging',
              pastParticiple: 'gegangen',
            ),
          );

      nounCard =
          CardModel.create(
            frontText: 'der Hund',
            backText: 'dog',
            language: 'de',
            category: 'vocabulary',
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

    testWidgets('works with noun data', (tester) async {
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
      expect(find.byType(TextField), findsOneWidget);
    });

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
