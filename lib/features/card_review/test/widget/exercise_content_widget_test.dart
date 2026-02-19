import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/exercises/exercise_content_widget.dart';

void main() {
  // Initialize logger for tests that use SpeakerButton
  setUpAll(() {
    LoggerService.initialize();
  });

  group('ExerciseContentWidget', () {
    late CardModel testCard;
    late bool checkAnswerCalled;
    late bool? lastCheckAnswerValue;
    late bool overrideAnswerCalled;
    late bool? lastOverrideAnswerValue;

    setUp(() {
      testCard = CardModel(
        id: 'test-card',
        frontText: 'Hallo',
        backText: 'Hello',
        language: 'de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      checkAnswerCalled = false;
      lastCheckAnswerValue = null;
      overrideAnswerCalled = false;
      lastOverrideAnswerValue = null;
    });

    Widget buildTestWidget({
      required ExerciseType exerciseType,
      List<String>? multipleChoiceOptions,
      AnswerState answerState = AnswerState.pending,
      bool? currentAnswerCorrect,
      CardModel? card,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: ExerciseContentWidget(
              card: card ?? testCard,
              exerciseType: exerciseType,
              multipleChoiceOptions: multipleChoiceOptions,
              answerState: answerState,
              currentAnswerCorrect: currentAnswerCorrect,
              onCheckAnswer: (isCorrect) {
                checkAnswerCalled = true;
                lastCheckAnswerValue = isCorrect;
              },
              onOverrideAnswer: (isCorrect) {
                overrideAnswerCalled = true;
                lastOverrideAnswerValue = isCorrect;
              },
            ),
          ),
        ),
      );
    }

    group('Multiple Choice Text', () {
      testWidgets('should display instruction text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
          ),
        );

        expect(find.text('Select the correct translation:'), findsOneWidget);
      });

      testWidgets('should display front text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
          ),
        );

        expect(find.text('Hallo'), findsOneWidget);
      });

      testWidgets('should display all options', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
          ),
        );

        expect(find.text('Hello'), findsOneWidget);
        expect(find.text('World'), findsOneWidget);
        expect(find.text('Thanks'), findsOneWidget);
        expect(find.text('Goodbye'), findsOneWidget);
      });

      testWidgets(
        'should not show Check Answer button (auto-checks on selection)',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              exerciseType: ExerciseType.multipleChoiceText,
              multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
            ),
          );

          // Multiple choice auto-checks on selection, no button needed
          expect(find.text('Check Answer'), findsNothing);
        },
      );

      testWidgets('should auto-check correct answer on selection', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
          ),
        );

        // Tap correct answer - should immediately check
        await tester.tap(find.text('Hello'));
        await tester.pump();

        expect(checkAnswerCalled, true);
        expect(lastCheckAnswerValue, true);
      });

      testWidgets('should auto-check incorrect answer on selection', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
          ),
        );

        // Tap incorrect answer - should immediately check
        await tester.tap(find.text('World'));
        await tester.pump();

        expect(checkAnswerCalled, true);
        expect(lastCheckAnswerValue, false);
      });

      testWidgets('should show override buttons after answer checked', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
            answerState: AnswerState.answered,
            currentAnswerCorrect: true,
          ),
        );

        expect(find.text('Mark Wrong'), findsOneWidget);
        expect(find.text('Mark Correct'), findsOneWidget);
      });

      testWidgets('should call onOverrideAnswer when Mark Wrong tapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
            answerState: AnswerState.answered,
            currentAnswerCorrect: true,
          ),
        );

        await tester.tap(find.text('Mark Wrong'));
        await tester.pump();

        expect(overrideAnswerCalled, true);
        expect(lastOverrideAnswerValue, false);
      });

      testWidgets('should call onOverrideAnswer when Mark Correct tapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['Hello', 'World', 'Thanks', 'Goodbye'],
            answerState: AnswerState.answered,
            currentAnswerCorrect: false,
          ),
        );

        await tester.tap(find.text('Mark Correct'));
        await tester.pump();

        expect(overrideAnswerCalled, true);
        expect(lastOverrideAnswerValue, true);
      });
    });

    group('Reading Recognition', () {
      testWidgets('should display instruction text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.readingRecognition),
        );

        expect(find.text('What does this word mean?'), findsOneWidget);
      });

      testWidgets('should show tap-to-reveal card before answer', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.readingRecognition),
        );

        expect(find.text('Tap to reveal the answer'), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });

      testWidgets('should show answer after reveal', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.readingRecognition,
            answerState: AnswerState.answered,
            currentAnswerCorrect: true,
          ),
        );

        expect(find.text('Hello'), findsOneWidget);
        expect(find.byIcon(Icons.lightbulb), findsOneWidget);
      });
    });

    group('Writing Translation', () {
      testWidgets('should display instruction text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.writingTranslation),
        );

        expect(find.text('Type the translation:'), findsOneWidget);
      });

      testWidgets('should have text input field', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.writingTranslation),
        );

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('should disable Check Answer when input empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.writingTranslation),
        );

        // Tap Check Answer without typing anything
        await tester.tap(find.text('Check Answer'));
        await tester.pump();

        // Callback should not have been called
        expect(checkAnswerCalled, false);
      });

      testWidgets('should enable Check Answer after typing', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.writingTranslation),
        );

        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.pump();

        // Tap Check Answer
        await tester.tap(find.text('Check Answer'));
        await tester.pump();

        // Callback should have been called
        expect(checkAnswerCalled, true);
      });

      testWidgets('should validate correct answer', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.writingTranslation),
        );

        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.pump();

        await tester.tap(find.text('Check Answer'));
        await tester.pump();

        expect(checkAnswerCalled, true);
        expect(lastCheckAnswerValue, true);
      });

      testWidgets('should validate incorrect answer', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.writingTranslation),
        );

        await tester.enterText(find.byType(TextField), 'Wrong');
        await tester.pump();

        await tester.tap(find.text('Check Answer'));
        await tester.pump();

        expect(checkAnswerCalled, true);
        expect(lastCheckAnswerValue, false);
      });

      testWidgets('should be case insensitive', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.writingTranslation),
        );

        await tester.enterText(find.byType(TextField), 'HELLO');
        await tester.pump();

        await tester.tap(find.text('Check Answer'));
        await tester.pump();

        expect(lastCheckAnswerValue, true);
      });

      testWidgets('should show correct answer after checking', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.writingTranslation,
            answerState: AnswerState.answered,
            currentAnswerCorrect: false,
          ),
        );

        expect(find.text('Correct answer:'), findsOneWidget);
        expect(find.text('Hello'), findsOneWidget);
      });
    });

    group('Reverse Translation', () {
      testWidgets('should display instruction text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.reverseTranslation),
        );

        expect(find.text('Translate to the target language:'), findsOneWidget);
      });

      testWidgets('should display back text as prompt', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.reverseTranslation),
        );

        // Should show the English word to translate
        expect(find.text('Hello'), findsOneWidget);
      });

      testWidgets('should validate against front text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.reverseTranslation),
        );

        await tester.enterText(find.byType(TextField), 'Hallo');
        await tester.pump();

        await tester.tap(find.text('Check Answer'));
        await tester.pump();

        expect(checkAnswerCalled, true);
        expect(lastCheckAnswerValue, true);
      });
    });

    group('German Article', () {
      testWidgets('should display German article when present', (tester) async {
        final cardWithArticle = CardModel(
          id: 'test',
          frontText: 'Haus',
          backText: 'House',
          language: 'de',
          germanArticle: 'das',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.multipleChoiceText,
            multipleChoiceOptions: ['House', 'Car', 'Tree', 'Dog'],
            card: cardWithArticle,
          ),
        );

        expect(find.text('das'), findsOneWidget);
      });
    });

    group('State Reset', () {
      testWidgets('should reset state when card changes', (tester) async {
        // Use writing exercise to test state reset (has Check Answer button)
        await tester.pumpWidget(
          buildTestWidget(exerciseType: ExerciseType.writingTranslation),
        );

        // Type something
        await tester.enterText(find.byType(TextField), 'test input');
        await tester.pump();

        // Rebuild with different card
        final newCard = CardModel(
          id: 'new-card',
          frontText: 'Welt',
          backText: 'World',
          language: 'de',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          buildTestWidget(
            exerciseType: ExerciseType.writingTranslation,
            card: newCard,
          ),
        );

        // Text field should be cleared after card change
        expect(find.text('test input'), findsNothing);
      });
    });
  });
}
