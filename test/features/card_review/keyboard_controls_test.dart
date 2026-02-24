import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_review/presentation/screens/practice_screen.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

@GenerateMocks([PracticeSessionNotifier])
import 'keyboard_controls_test.mocks.dart';

void main() {
  group('PracticeScreen Keyboard Controls', () {
    late MockPracticeSessionNotifier mockNotifier;
    late PracticeSessionState testState;

    setUp(() {
      mockNotifier = MockPracticeSessionNotifier();
      testState = const PracticeSessionState(
        isSessionActive: true,
        answerState: AnswerState.pending,
        currentIndex: 0,
        sessionQueue: [
          PracticeItem(
            card: CardModel(
              id: 'test-1',
              frontText: 'Front',
              backText: 'Back',
              language: 'de',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            exerciseType: ExerciseType.readingRecognition,
          ),
        ],
      );

      // Default mock setup
      when(mockNotifier.state).thenReturn(testState);
      when(mockNotifier.canSwipe).thenReturn(false);
      when(
        mockNotifier.currentCard,
      ).thenReturn(testState.sessionQueue.first.card);
      when(
        mockNotifier.currentExerciseType,
      ).thenReturn(ExerciseType.readingRecognition);

      // Stub async methods
      when(
        mockNotifier.confirmAnswerAndAdvance(
          markedCorrect: anyNamed('markedCorrect'),
        ),
      ).thenAnswer((_) async {});
      when(
        mockNotifier.checkAnswer(isCorrect: anyNamed('isCorrect')),
      ).thenReturn(null);
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          practiceSessionNotifierProvider.overrideWith(() => mockNotifier),
          exercisePreferencesNotifierProvider.overrideWith(
            () => ExercisePreferencesNotifier(),
          ),
        ],
        child: const MaterialApp(home: PracticeScreen()),
      );
    }

    testWidgets('Space key should NOT advance exercise after answer', (
      tester,
    ) async {
      // Setup: Answer has been checked
      when(mockNotifier.canSwipe).thenReturn(true);
      testState = testState.copyWith(currentAnswerCorrect: true);
      when(mockNotifier.state).thenReturn(testState);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate Space key press
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Verify that confirmAnswerAndAdvance was NOT called
      verifyNever(
        mockNotifier.confirmAnswerAndAdvance(
          markedCorrect: anyNamed('markedCorrect'),
        ),
      );
    });

    testWidgets('Space key should NOT reveal answer before checking', (
      tester,
    ) async {
      // Setup: Answer not yet checked
      when(mockNotifier.canSwipe).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate Space key press
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      // Verify that no action was taken
      verifyNever(mockNotifier.checkAnswer(isCorrect: anyNamed('isCorrect')));
    });

    testWidgets('Enter key is handled when answer is checked', (tester) async {
      // Setup: Answer has been checked
      when(mockNotifier.canSwipe).thenReturn(true);
      testState = testState.copyWith(currentAnswerCorrect: true);
      when(mockNotifier.state).thenReturn(testState);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate Enter key press
      final result = await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify the key was handled
      expect(result, isTrue);
    });

    testWidgets('Enter key SHOULD reveal answer before checking', (
      tester,
    ) async {
      // Setup: Answer not yet checked
      when(mockNotifier.canSwipe).thenReturn(false);
      testState = testState.copyWith(answerState: AnswerState.pending);
      when(mockNotifier.state).thenReturn(testState);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate Enter key press
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify that checkAnswer was called
      verify(mockNotifier.checkAnswer(isCorrect: true)).called(1);
    });

    testWidgets('Arrow keys are handled when answer is checked', (
      tester,
    ) async {
      // Setup: Answer has been checked
      when(mockNotifier.canSwipe).thenReturn(true);
      testState = testState.copyWith(currentAnswerCorrect: true);
      when(mockNotifier.state).thenReturn(testState);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Test right arrow
      final result = await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('Left arrow key is handled when answer is checked', (
      tester,
    ) async {
      // Setup: Answer has been checked
      when(mockNotifier.canSwipe).thenReturn(true);
      testState = testState.copyWith(currentAnswerCorrect: false);
      when(mockNotifier.state).thenReturn(testState);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final result = await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('Number keys are handled for multiple choice', (tester) async {
      // Setup: Multiple choice exercise
      when(mockNotifier.canSwipe).thenReturn(false);
      when(
        mockNotifier.currentExerciseType,
      ).thenReturn(ExerciseType.multipleChoiceText);

      testState = testState.copyWith(
        multipleChoiceOptions: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
      );
      when(mockNotifier.state).thenReturn(testState);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      verify(
        mockNotifier.checkAnswer(isCorrect: anyNamed('isCorrect')),
      ).called(1);
    });

    group('Regression tests for Space key removal', () {
      testWidgets('Space key does not interfere with text input', (
        tester,
      ) async {
        // This test verifies that Space key is ignored by keyboard handler
        // allowing it to be used in text fields for multi-word answers

        when(mockNotifier.canSwipe).thenReturn(false);
        when(
          mockNotifier.currentExerciseType,
        ).thenReturn(ExerciseType.reverseTranslation);

        await tester.pumpWidget(createTestWidget());

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Simulate Space key press - should be ignored by keyboard handler
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        // Verify that Space key did NOT trigger any navigation
        verifyNever(
          mockNotifier.confirmAnswerAndAdvance(
            markedCorrect: anyNamed('markedCorrect'),
          ),
        );
        verifyNever(mockNotifier.checkAnswer(isCorrect: anyNamed('isCorrect')));
      });

      testWidgets('Space key is not handled by keyboard event handler', (
        tester,
      ) async {
        // This test verifies the keyboard handler ignores Space key
        // The actual UI hints are implementation details that may change

        when(mockNotifier.canSwipe).thenReturn(false);

        await tester.pumpWidget(createTestWidget());

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Send Space key - should be completely ignored
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        // Verify Space key triggered no provider methods
        verifyNever(
          mockNotifier.confirmAnswerAndAdvance(
            markedCorrect: anyNamed('markedCorrect'),
          ),
        );
        verifyNever(mockNotifier.checkAnswer(isCorrect: anyNamed('isCorrect')));
      });
    });
  });
}
