import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/exercises/sentence_building_exercise.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';

void main() {
  group('SentenceBuildingExercise Widget', () {
    late CardModel testCard;

    setUp(() {
      testCard = CardModel.create(
        frontText: 'Hund',
        backText: 'dog',
        language: 'de',
        category: 'vocabulary',
      ).copyWith(examples: ['Der Hund ist groß']);
    });

    testWidgets('displays prompt and translation hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceBuildingExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.text('Arrange the words to form a correct sentence:'),
        findsOneWidget,
      );
      expect(find.text('dog'), findsOneWidget);
    });

    testWidgets('displays scrambled words', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceBuildingExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Should have all words from the sentence
      expect(find.text('Der'), findsOneWidget);
      expect(find.text('Hund'), findsOneWidget);
      expect(find.text('ist'), findsOneWidget);
      expect(find.text('groß'), findsOneWidget);
    });

    testWidgets('allows selecting words to build sentence', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceBuildingExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Tap a word to select it
      await tester.tap(find.text('Der').first);
      await tester.pumpAndSettle();

      // Word should move to selected area
      expect(find.text('Der'), findsWidgets);
    });

    testWidgets('check button enabled when all words selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceBuildingExercise(
              card: testCard,
              answerState: AnswerState.pending,
              currentAnswerCorrect: null,
              onCheckAnswer: (_) {},
            ),
          ),
        ),
      );

      // Initially button should be disabled
      final button = find.widgetWithText(FilledButton, 'Check Answer');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      // Select all words
      await tester.tap(find.text('Der').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hund').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ist').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('groß').first);
      await tester.pumpAndSettle();

      // Button should now be enabled
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });

    testWidgets('shows correct answer when wrong', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceBuildingExercise(
              card: testCard,
              answerState: AnswerState.answered,
              currentAnswerCorrect: false,
              onCheckAnswer: (correct) {},
            ),
          ),
        ),
      );

      expect(find.text('Correct answer:'), findsOneWidget);
      expect(find.text('Der Hund ist groß'), findsOneWidget);
    });

    testWidgets('disables interaction after answer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceBuildingExercise(
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
  });
}
