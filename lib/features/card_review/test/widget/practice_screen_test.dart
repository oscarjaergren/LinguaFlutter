import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_provider.dart';
import 'package:lingua_flutter/features/card_review/presentation/screens/practice_screen.dart';
import 'package:lingua_flutter/features/card_review/presentation/widgets/swipeable_exercise_card.dart';

void main() {
  setUpAll(() {
    LoggerService.initialize();
  });

  group('PracticeScreen Integration Tests', () {
    late List<CardModel> testCards;
    late List<CardModel> updatedCards;
    late PracticeSessionProvider provider;

    CardModel createTestCard({
      required String id,
      required String frontText,
      required String backText,
    }) {
      return CardModel(
        id: id,
        frontText: frontText,
        backText: backText,
        language: 'de',
        category: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    setUp(() {
      testCards = [
        createTestCard(id: '1', frontText: 'Hallo', backText: 'Hello'),
        createTestCard(id: '2', frontText: 'Welt', backText: 'World'),
        createTestCard(id: '3', frontText: 'Danke', backText: 'Thanks'),
      ];
      updatedCards = [];

      provider = PracticeSessionProvider(
        getReviewCards: () => testCards,
        getAllCards: () => testCards,
        updateCard: (card) async {
          updatedCards.add(card);
        },
      );
    });

    Widget buildTestApp() {
      return MaterialApp(
        home: ChangeNotifierProvider<PracticeSessionProvider>.value(
          value: provider,
          child: const PracticeScreen(),
        ),
      );
    }

    group('Session Lifecycle', () {
      testWidgets('should start session with cards', (tester) async {
        // Start session before building widget
        provider.startSession();
        
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(provider.isSessionActive, true);
        expect(provider.currentCard, isNotNull);
        expect(provider.totalCount, greaterThan(0));
      });

      testWidgets('should show progress indicator', (tester) async {
        provider.startSession();
        
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should display current card content', (tester) async {
        provider.startSession();
        
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Should show the front text of the current card
        expect(find.text(provider.currentCard!.frontText), findsOneWidget);
      });
    });

    group('Exercise Completion Flow', () {
      testWidgets('should complete exercise and update stats', (tester) async {
        provider.startSession();
        
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        final initialCorrectCount = provider.correctCount;
        final initialIndex = provider.currentIndex;

        // Check answer - handle different exercise types
        final tapToReveal = find.text('Tap to reveal the answer');
        final checkButton = find.text('Check Answer');
        
        if (tapToReveal.evaluate().isNotEmpty) {
          // Reading recognition - tap to reveal
          await tester.tap(tapToReveal);
          await tester.pump();
        } else if (provider.multipleChoiceOptions != null) {
          // Multiple choice - auto-checks on selection
          await tester.tap(find.text(provider.currentCard!.backText));
          await tester.pump();
        } else if (checkButton.evaluate().isNotEmpty) {
          // Writing exercise
          if (find.byType(TextField).evaluate().isNotEmpty) {
            await tester.enterText(find.byType(TextField), provider.currentCard!.backText);
            await tester.pump();
          }
          await tester.tap(checkButton);
          await tester.pump();
        }

        // Verify answer state changed
        expect(provider.answerState, AnswerState.answered);

        // Swipe right to confirm correct
        final swipeCard = find.byType(SwipeableExerciseCard);
        await tester.fling(swipeCard, const Offset(300, 0), 1000);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Stats should update
        expect(provider.correctCount, initialCorrectCount + 1);
        
        // Should advance or complete
        if (provider.isSessionActive) {
          expect(provider.currentIndex, initialIndex + 1);
        }
      });

      testWidgets('should persist card update after answer', (tester) async {
        provider.startSession();
        
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(updatedCards, isEmpty);

        // Complete one exercise - handle different exercise types
        final tapToReveal = find.text('Tap to reveal the answer');
        final checkButton = find.text('Check Answer');
        
        if (tapToReveal.evaluate().isNotEmpty) {
          // Reading recognition - tap to reveal
          await tester.tap(tapToReveal);
          await tester.pump();
        } else if (provider.multipleChoiceOptions != null) {
          // Multiple choice - auto-checks on selection
          await tester.tap(find.text(provider.currentCard!.backText));
          await tester.pump();
        } else if (checkButton.evaluate().isNotEmpty) {
          // Writing exercise
          if (find.byType(TextField).evaluate().isNotEmpty) {
            await tester.enterText(find.byType(TextField), provider.currentCard!.backText);
            await tester.pump();
          }
          await tester.tap(checkButton);
          await tester.pump();
        }

        // Swipe to confirm
        await tester.fling(find.byType(SwipeableExerciseCard), const Offset(300, 0), 1000);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Card should be updated
        expect(updatedCards.length, 1);
      });
    });

    group('Answer Override', () {
      testWidgets('should allow overriding answer', (tester) async {
        provider.startSession();
        
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Complete answer check - handle different exercise types
        final tapToReveal = find.text('Tap to reveal the answer');
        final checkButton = find.text('Check Answer');
        
        if (tapToReveal.evaluate().isNotEmpty) {
          // Reading recognition - tap to reveal
          await tester.tap(tapToReveal);
          await tester.pump();
        } else if (provider.multipleChoiceOptions != null) {
          // Multiple choice - auto-checks on selection
          await tester.tap(find.text(provider.currentCard!.backText));
          await tester.pump();
        } else if (checkButton.evaluate().isNotEmpty) {
          // Writing exercise
          if (find.byType(TextField).evaluate().isNotEmpty) {
            await tester.enterText(find.byType(TextField), provider.currentCard!.backText);
            await tester.pump();
          }
          await tester.tap(checkButton);
          await tester.pump();
        }

        // Should show override buttons
        expect(find.text('Mark Wrong'), findsOneWidget);
        expect(find.text('Mark Correct'), findsOneWidget);

        // Override to wrong
        await tester.ensureVisible(find.text('Mark Wrong'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Wrong'));
        await tester.pump();
        expect(provider.currentAnswerCorrect, false);

        // Override back to correct
        await tester.tap(find.text('Mark Correct'));
        await tester.pump();
        expect(provider.currentAnswerCorrect, true);
      });
    });

    group('Session Completion', () {
      testWidgets('should end session after completing all exercises', (tester) async {
        // Use single card for quick completion
        final singleCardProvider = PracticeSessionProvider(
          getReviewCards: () => [testCards.first],
          getAllCards: () => [testCards.first],
          updateCard: (card) async {},
        );
        singleCardProvider.startSession();
        
        expect(singleCardProvider.isSessionActive, true);
        expect(singleCardProvider.totalCount, 1);

        // Complete via provider directly (avoids UI layout issues)
        singleCardProvider.checkAnswer(isCorrect: true);
        await singleCardProvider.confirmAnswerAndAdvance(markedCorrect: true);

        // Session should be complete
        expect(singleCardProvider.isSessionActive, false);
        expect(singleCardProvider.correctCount, 1);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('should have keyboard focus', (tester) async {
        provider.startSession();
        
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // The screen should have a Focus widget
        expect(find.byType(Focus), findsWidgets);
      });
    });
  });
}
