import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:lingua_flutter/features/card_review/presentation/screens/practice_screen.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

@GenerateMocks([PracticeSessionProvider])
import 'keyboard_controls_test.mocks.dart';

void main() {
  group('PracticeScreen Keyboard Controls', () {
    late MockPracticeSessionProvider mockProvider;

    setUp(() {
      mockProvider = MockPracticeSessionProvider();
      
      // Default mock setup
      when(mockProvider.isSessionActive).thenReturn(true);
      when(mockProvider.canSwipe).thenReturn(false);
      when(mockProvider.currentAnswerCorrect).thenReturn(null);
      when(mockProvider.currentCard).thenReturn(null);
      when(mockProvider.currentExerciseType).thenReturn(ExerciseType.translation);
      when(mockProvider.multipleChoiceOptions).thenReturn([]);
      when(mockProvider.answerState).thenReturn(AnswerState.unanswered);
      when(mockProvider.addListener(any)).thenReturn(null);
      when(mockProvider.removeListener(any)).thenReturn(null);
    });

    testWidgets('Space key should NOT advance exercise after answer', (tester) async {
      // Setup: Answer has been checked
      when(mockProvider.canSwipe).thenReturn(true);
      when(mockProvider.currentAnswerCorrect).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PracticeSessionProvider>.value(
            value: mockProvider,
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate Space key press
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Verify that checkAnswer was NOT called (Space should be ignored)
      verifyNever(mockProvider.checkAnswer(any));
      verifyNever(mockProvider.nextCard(any));
    });

    testWidgets('Space key should NOT reveal answer before checking', (tester) async {
      // Setup: Answer not yet checked
      when(mockProvider.canSwipe).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PracticeSessionProvider>.value(
            value: mockProvider,
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate Space key press
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Verify that no action was taken (Space should be ignored)
      verifyNever(mockProvider.checkAnswer(any));
      verifyNever(mockProvider.revealAnswer());
    });

    testWidgets('Enter key SHOULD advance exercise after answer', (tester) async {
      // Setup: Answer has been checked
      when(mockProvider.canSwipe).thenReturn(true);
      when(mockProvider.currentAnswerCorrect).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PracticeSessionProvider>.value(
            value: mockProvider,
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate Enter key press
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify that nextCard was called with correct answer
      verify(mockProvider.nextCard(true)).called(1);
    });

    testWidgets('Enter key SHOULD reveal answer before checking', (tester) async {
      // Setup: Answer not yet checked
      when(mockProvider.canSwipe).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PracticeSessionProvider>.value(
            value: mockProvider,
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate Enter key press
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify that revealAnswer was called
      verify(mockProvider.revealAnswer()).called(1);
    });

    testWidgets('Arrow keys should work for navigation after answer', (tester) async {
      // Setup: Answer has been checked
      when(mockProvider.canSwipe).thenReturn(true);
      when(mockProvider.currentAnswerCorrect).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PracticeSessionProvider>.value(
            value: mockProvider,
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test right arrow (correct)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      verify(mockProvider.nextCard(true)).called(1);

      // Test left arrow (wrong)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      verify(mockProvider.nextCard(false)).called(1);
    });

    testWidgets('Number keys should work for multiple choice', (tester) async {
      // Setup: Multiple choice exercise
      when(mockProvider.canSwipe).thenReturn(false);
      when(mockProvider.currentExerciseType).thenReturn(ExerciseType.multipleChoice);
      when(mockProvider.multipleChoiceOptions).thenReturn(['Option 1', 'Option 2', 'Option 3', 'Option 4']);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PracticeSessionProvider>.value(
            value: mockProvider,
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test number key 1
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      verify(mockProvider.checkAnswer('Option 1')).called(1);

      // Test number key 2
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      verify(mockProvider.checkAnswer('Option 2')).called(1);
    });

    group('Regression tests for Space key removal', () {
      testWidgets('Space key does not interfere with text input', (tester) async {
        // This test documents that Space key should be available for typing
        // multi-word answers like "the peasant's war"
        
        when(mockProvider.canSwipe).thenReturn(false);
        when(mockProvider.currentExerciseType).thenReturn(ExerciseType.writing);

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<PracticeSessionProvider>.value(
              value: mockProvider,
              child: const PracticeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the text field
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        // Type a multi-word answer with spaces
        await tester.enterText(textField, "the peasant's war");
        await tester.pumpAndSettle();

        // Verify the text was entered correctly with spaces
        final TextField widget = tester.widget(textField);
        expect(widget.controller?.text, "the peasant's war");

        // Verify that typing spaces did NOT trigger any navigation
        verifyNever(mockProvider.nextCard(any));
        verifyNever(mockProvider.revealAnswer());
      });

      testWidgets('Keyboard hints show Enter only, not Space', (tester) async {
        when(mockProvider.canSwipe).thenReturn(true);

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<PracticeSessionProvider>.value(
              value: mockProvider,
              child: const PracticeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the keyboard hints text
        final hintsText = find.textContaining('Enter');
        expect(hintsText, findsOneWidget);

        // Verify Space is NOT mentioned in hints
        final spaceHints = find.textContaining('Space');
        expect(spaceHints, findsNothing);
      });
    });
  });
}
