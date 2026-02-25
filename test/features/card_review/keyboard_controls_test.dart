import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_review/presentation/screens/practice_screen.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_types.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_state.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

class _TestExercisePreferencesNotifier extends ExercisePreferencesNotifier {
  @override
  ExercisePreferencesState build() => ExercisePreferencesState(
    preferences: ExercisePreferences.defaults(),
    isInitialized: true,
  );
}

class _TestPracticeSessionNotifier extends PracticeSessionNotifier {
  _TestPracticeSessionNotifier(this.initialState);

  final PracticeSessionState initialState;
  final List<bool> confirmedAnswers = [];
  final List<bool> checkedAnswers = [];

  @override
  PracticeSessionState build() => initialState;

  @override
  void checkAnswer({required bool isCorrect}) {
    checkedAnswers.add(isCorrect);
    state = state.copyWith(
      answerState: AnswerState.answered,
      currentAnswerCorrect: isCorrect,
    );
  }

  @override
  void confirmAnswerAndAdvance({required bool markedCorrect}) {
    confirmedAnswers.add(markedCorrect);
  }
}

void main() {
  setUpAll(() {
    LoggerService.initialize();
  });

  group('PracticeScreen Keyboard Controls', () {
    late _TestPracticeSessionNotifier testNotifier;
    late PracticeSessionState testState;

    setUp(() {
      testState = PracticeSessionState(
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
      testNotifier = _TestPracticeSessionNotifier(testState);
    });

    Widget createTestWidget() {
      testNotifier = _TestPracticeSessionNotifier(testState);
      return ProviderScope(
        overrides: [
          practiceSessionNotifierProvider.overrideWith(() => testNotifier),
          exercisePreferencesNotifierProvider.overrideWith(
            () => _TestExercisePreferencesNotifier(),
          ),
        ],
        child: const MaterialApp(home: PracticeScreen()),
      );
    }

    testWidgets('Space key should NOT advance exercise after answer', (
      tester,
    ) async {
      // Setup: Answer has been checked
      testState = testState.copyWith(
        answerState: AnswerState.answered,
        currentAnswerCorrect: true,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate Space key press
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Verify that confirmAnswerAndAdvance was NOT called
      expect(testNotifier.confirmedAnswers, isEmpty);
    });

    testWidgets('Space key should NOT reveal answer before checking', (
      tester,
    ) async {
      // Setup: Answer not yet checked
      testState = testState.copyWith(answerState: AnswerState.pending);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate Space key press
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      // Verify that no action was taken
      expect(testNotifier.checkedAnswers, isEmpty);
    });

    testWidgets('Enter key is handled when answer is checked', (tester) async {
      // Setup: Answer has been checked
      testState = testState.copyWith(
        answerState: AnswerState.answered,
        currentAnswerCorrect: true,
      );

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
      testState = testState.copyWith(answerState: AnswerState.pending);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate Enter key press
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify that checkAnswer was called
      expect(testNotifier.checkedAnswers, contains(true));
    });

    testWidgets('Arrow keys are handled when answer is checked', (
      tester,
    ) async {
      // Setup: Answer has been checked
      testState = testState.copyWith(
        answerState: AnswerState.answered,
        currentAnswerCorrect: true,
      );

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
      testState = testState.copyWith(
        answerState: AnswerState.answered,
        currentAnswerCorrect: false,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final result = await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('Number keys are handled for multiple choice', (tester) async {
      // Setup: Multiple choice exercise
      testState = testState.copyWith(
        answerState: AnswerState.pending,
        sessionQueue: [
          PracticeItem(
            card: testState.sessionQueue.first.card,
            exerciseType: ExerciseType.multipleChoiceText,
          ),
        ],
        multipleChoiceOptions: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();

      expect(testNotifier.checkedAnswers.length, 1);
    });

    group('Regression tests for Space key removal', () {
      testWidgets('Space key does not interfere with text input', (
        tester,
      ) async {
        // This test verifies that Space key is ignored by keyboard handler
        // allowing it to be used in text fields for multi-word answers
        testState = testState.copyWith(
          answerState: AnswerState.pending,
          sessionQueue: [
            PracticeItem(
              card: testState.sessionQueue.first.card,
              exerciseType: ExerciseType.reverseTranslation,
            ),
          ],
        );

        await tester.pumpWidget(createTestWidget());

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Simulate Space key press - should be ignored by keyboard handler
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        // Verify that Space key did NOT trigger any navigation
        expect(testNotifier.confirmedAnswers, isEmpty);
        expect(testNotifier.checkedAnswers, isEmpty);
      });

      testWidgets('Space key is not handled by keyboard event handler', (
        tester,
      ) async {
        // This test verifies the keyboard handler ignores Space key
        // The actual UI hints are implementation details that may change
        testState = testState.copyWith(answerState: AnswerState.pending);

        await tester.pumpWidget(createTestWidget());

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Send Space key - should be completely ignored
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        // Verify Space key triggered no provider methods
        expect(testNotifier.confirmedAnswers, isEmpty);
        expect(testNotifier.checkedAnswers, isEmpty);
      });
    });
  });
}
