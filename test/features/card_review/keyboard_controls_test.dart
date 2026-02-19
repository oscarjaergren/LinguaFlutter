import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:lingua_flutter/features/card_review/presentation/screens/practice_screen.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_provider.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

@GenerateMocks([PracticeSessionProvider, ExercisePreferencesProvider])
import 'keyboard_controls_test.mocks.dart';

void main() {
  group('PracticeScreen Keyboard Controls', () {
    late MockPracticeSessionProvider mockProvider;
    late MockExercisePreferencesProvider mockPrefsProvider;

    setUp(() {
      mockProvider = MockPracticeSessionProvider();
      mockPrefsProvider = MockExercisePreferencesProvider();

      // Setup preferences provider mock
      when(
        mockPrefsProvider.preferences,
      ).thenReturn(ExercisePreferences.defaults());
      when(mockPrefsProvider.addListener(any)).thenReturn(null);
      when(mockPrefsProvider.removeListener(any)).thenReturn(null);
      when(mockPrefsProvider.updatePreferences(any)).thenAnswer((_) async {});

      // Default mock setup
      when(mockProvider.isSessionActive).thenReturn(true);
      when(mockProvider.canSwipe).thenReturn(false);
      when(mockProvider.currentAnswerCorrect).thenReturn(null);
      when(mockProvider.currentCard).thenReturn(null);
      when(
        mockProvider.currentExerciseType,
      ).thenReturn(ExerciseType.readingRecognition);
      when(mockProvider.multipleChoiceOptions).thenReturn([]);
      when(mockProvider.answerState).thenReturn(AnswerState.pending);
      when(mockProvider.currentIndex).thenReturn(0);
      when(mockProvider.totalCount).thenReturn(1);
      when(mockProvider.progress).thenReturn(0.0);
      when(mockProvider.remainingCount).thenReturn(0);
      when(mockProvider.correctCount).thenReturn(0);
      when(mockProvider.incorrectCount).thenReturn(0);
      when(mockProvider.accuracy).thenReturn(0.0);
      when(mockProvider.sessionDuration).thenReturn(Duration.zero);
      when(mockProvider.userInput).thenReturn(null);
      when(mockProvider.addListener(any)).thenReturn(null);
      when(mockProvider.removeListener(any)).thenReturn(null);

      // Stub async methods
      when(
        mockProvider.confirmAnswerAndAdvance(
          markedCorrect: anyNamed('markedCorrect'),
        ),
      ).thenAnswer((_) async {});
      when(
        mockProvider.checkAnswer(isCorrect: anyNamed('isCorrect')),
      ).thenReturn(null);
    });

    testWidgets('Space key should NOT advance exercise after answer', (
      tester,
    ) async {
      // Setup: Answer has been checked
      when(mockProvider.canSwipe).thenReturn(true);
      when(mockProvider.currentAnswerCorrect).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<PracticeSessionProvider>.value(
                value: mockProvider,
              ),
              ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                value: mockPrefsProvider,
              ),
            ],
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate Space key press
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      // Verify that confirmAnswerAndAdvance was NOT called (Space should be ignored)
      verifyNever(
        mockProvider.confirmAnswerAndAdvance(
          markedCorrect: anyNamed('markedCorrect'),
        ),
      );
    });

    testWidgets('Space key should NOT reveal answer before checking', (
      tester,
    ) async {
      // Setup: Answer not yet checked
      when(mockProvider.canSwipe).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<PracticeSessionProvider>.value(
                value: mockProvider,
              ),
              ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                value: mockPrefsProvider,
              ),
            ],
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate Space key press
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      // Verify that no action was taken (Space should be ignored)
      verifyNever(mockProvider.checkAnswer(isCorrect: anyNamed('isCorrect')));
    });

    testWidgets('Enter key is handled when answer is checked', (tester) async {
      // Setup: Answer has been checked
      when(mockProvider.canSwipe).thenReturn(true);
      when(mockProvider.currentAnswerCorrect).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<PracticeSessionProvider>.value(
                value: mockProvider,
              ),
              ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                value: mockPrefsProvider,
              ),
            ],
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate Enter key press - should be handled
      final result = await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Verify the key was handled
      expect(result, isTrue);
    });

    testWidgets('Enter key SHOULD reveal answer before checking', (
      tester,
    ) async {
      // Setup: Answer not yet checked
      when(mockProvider.canSwipe).thenReturn(false);
      when(mockProvider.answerState).thenReturn(AnswerState.pending);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<PracticeSessionProvider>.value(
                value: mockProvider,
              ),
              ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                value: mockPrefsProvider,
              ),
            ],
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate Enter key press - reveals answer for reading recognition
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Verify that checkAnswer was called to reveal answer
      verify(mockProvider.checkAnswer(isCorrect: true)).called(1);
    });

    testWidgets('Arrow keys are handled when answer is checked', (
      tester,
    ) async {
      // Setup: Answer has been checked
      when(mockProvider.canSwipe).thenReturn(true);
      when(mockProvider.currentAnswerCorrect).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<PracticeSessionProvider>.value(
                value: mockProvider,
              ),
              ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                value: mockPrefsProvider,
              ),
            ],
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Test right arrow - should be handled by keyboard handler
      final result = await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // Verify the key was handled
      expect(result, isTrue);
    });

    testWidgets('Left arrow key is handled when answer is checked', (
      tester,
    ) async {
      // Setup: Answer has been checked
      when(mockProvider.canSwipe).thenReturn(true);
      when(mockProvider.currentAnswerCorrect).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<PracticeSessionProvider>.value(
                value: mockProvider,
              ),
              ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                value: mockPrefsProvider,
              ),
            ],
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Send left arrow key event
      final result = await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Verify the key was handled
      expect(result, isTrue);
    });

    testWidgets('Number keys are handled for multiple choice', (tester) async {
      // Setup: Multiple choice exercise with options
      when(mockProvider.canSwipe).thenReturn(false);
      when(
        mockProvider.currentExerciseType,
      ).thenReturn(ExerciseType.multipleChoiceText);
      when(
        mockProvider.multipleChoiceOptions,
      ).thenReturn(['Option 1', 'Option 2', 'Option 3', 'Option 4']);
      when(mockProvider.currentCard).thenReturn(
        CardModel(
          id: 'test-1',
          frontText: 'Test',
          backText: 'Option 1',
          language: 'en',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<PracticeSessionProvider>.value(
                value: mockProvider,
              ),
              ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                value: mockPrefsProvider,
              ),
            ],
            child: const PracticeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Send number key 1 - should trigger checkAnswer
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);

      // Verify checkAnswer was called
      verify(
        mockProvider.checkAnswer(isCorrect: anyNamed('isCorrect')),
      ).called(1);
    }, skip: true);

    group('Regression tests for Space key removal', () {
      testWidgets('Space key does not interfere with text input', (
        tester,
      ) async {
        // This test verifies that Space key is ignored by keyboard handler
        // allowing it to be used in text fields for multi-word answers

        when(mockProvider.canSwipe).thenReturn(false);
        when(
          mockProvider.currentExerciseType,
        ).thenReturn(ExerciseType.writingTranslation);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<PracticeSessionProvider>.value(
                  value: mockProvider,
                ),
                ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                  value: mockPrefsProvider,
                ),
              ],
              child: const PracticeScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Simulate Space key press - should be ignored by keyboard handler
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        // Verify that Space key did NOT trigger any navigation
        verifyNever(
          mockProvider.confirmAnswerAndAdvance(
            markedCorrect: anyNamed('markedCorrect'),
          ),
        );
        verifyNever(mockProvider.checkAnswer(isCorrect: anyNamed('isCorrect')));
      });

      testWidgets('Space key is not handled by keyboard event handler', (
        tester,
      ) async {
        // This test verifies the keyboard handler ignores Space key
        // The actual UI hints are implementation details that may change

        when(mockProvider.canSwipe).thenReturn(false);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<PracticeSessionProvider>.value(
                  value: mockProvider,
                ),
                ChangeNotifierProvider<ExercisePreferencesProvider>.value(
                  value: mockPrefsProvider,
                ),
              ],
              child: const PracticeScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Send Space key - should be completely ignored
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        // Verify Space key triggered no provider methods
        verifyNever(
          mockProvider.confirmAnswerAndAdvance(
            markedCorrect: anyNamed('markedCorrect'),
          ),
        );
        verifyNever(mockProvider.checkAnswer(isCorrect: anyNamed('isCorrect')));
      });
    });
  });
}
