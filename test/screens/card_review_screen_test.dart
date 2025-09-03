// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:provider/provider.dart';
// import 'package:lingua_flutter/screens/card_review_screen.dart';
// import 'package:lingua_flutter/providers/card_provider.dart';
// import 'package:lingua_flutter/providers/language_provider.dart';
// import 'package:lingua_flutter/models/card_model.dart';
// import 'package:lingua_flutter/services/animation_service.dart';

// void main() {
//   group('CardReviewScreen', () {
//     late CardProvider cardProvider;
//     late LanguageProvider languageProvider;

//     setUp(() {
//       languageProvider = LanguageProvider();
//       cardProvider = CardProvider(languageProvider: languageProvider);
//     });

//     testWidgets('displays card front initially', (WidgetTester tester) async {
//       final testCard = CardModel.create(
//         frontText: 'Hello',
//         backText: 'Hola',
//         language: 'es',
//         category: 'Greetings',
//       );

//       await tester.pumpWidget(
//         MultiProvider(
//           providers: [
//             ChangeNotifierProvider.value(value: languageProvider),
//             ChangeNotifierProvider.value(value: cardProvider),
//           ],
//           child: MaterialApp(
//             home: CardReviewScreen(
//               initialCards: [testCard],
//               animationService: const TestAnimationService(),
//             ),
//           ),
//         ),
//       );

//       // Verify card front is displayed
//       expect(find.text('Hello'), findsOneWidget);
//       expect(find.text('Tap to reveal answer'), findsOneWidget);
//       expect(find.text('Hola'), findsNothing);
//     });

//     testWidgets('flips card when tapped', (WidgetTester tester) async {
//       final testCard = CardModel.create(
//         frontText: 'Hello',
//         backText: 'Hola',
//         language: 'es',
//         category: 'Greetings',
//       );

//       await tester.pumpWidget(
//         MultiProvider(
//           providers: [
//             ChangeNotifierProvider.value(value: languageProvider),
//             ChangeNotifierProvider.value(value: cardProvider),
//           ],
//           child: MaterialApp(
//             home: CardReviewScreen(
//               initialCards: [testCard],
//               animationService: const TestAnimationService(),
//             ),
//           ),
//         ),
//       );

//       // Tap the card
//       await tester.tap(find.byType(GestureDetector));
//       await tester.pumpAndSettle();

//       // Verify card back is displayed
//       expect(find.text('Hola'), findsOneWidget);
//       expect(find.text('Swipe left (don\'t know) or right (know)'), findsOneWidget);
//     });

//     testWidgets('shows answer buttons when card is flipped', (WidgetTester tester) async {
//       final testCard = CardModel.create(
//         frontText: 'Hello',
//         backText: 'Hola',
//         language: 'es',
//         category: 'Greetings',
//       );

//       await tester.pumpWidget(
//         MultiProvider(
//           providers: [
//             ChangeNotifierProvider.value(value: languageProvider),
//             ChangeNotifierProvider.value(value: cardProvider),
//           ],
//           child: MaterialApp(
//             home: CardReviewScreen(
//               initialCards: [testCard],
//               animationService: const TestAnimationService(),
//             ),
//           ),
//         ),
//       );

//       // Tap to flip card
//       await tester.tap(find.byType(GestureDetector));
//       await tester.pumpAndSettle();

//       // Verify answer buttons are shown
//       expect(find.text('Again'), findsOneWidget);
//       expect(find.text('Hard'), findsOneWidget);
//       expect(find.text('Good'), findsOneWidget);
//       expect(find.text('Easy'), findsOneWidget);
//     });

//     testWidgets('shows completion screen when session is complete', (WidgetTester tester) async {
//       final testCard = CardModel.create(
//         frontText: 'Hello',
//         backText: 'Hola',
//         language: 'es',
//         category: 'Greetings',
//       );

//       await tester.pumpWidget(
//         MultiProvider(
//           providers: [
//             ChangeNotifierProvider.value(value: languageProvider),
//             ChangeNotifierProvider.value(value: cardProvider),
//           ],
//           child: MaterialApp(
//             home: CardReviewScreen(
//               initialCards: [testCard],
//               animationService: const TestAnimationService(),
//             ),
//           ),
//         ),
//       );

//       // Flip card and answer it
//       await tester.tap(find.byType(GestureDetector));
//       await tester.pumpAndSettle();
      
//       await tester.tap(find.text('Good'));
//       await tester.pumpAndSettle();

//       // Verify completion screen
//       expect(find.text('Review Complete!'), findsOneWidget);
//       expect(find.text('You reviewed 1 cards'), findsOneWidget);
//     });
//   });
// }
//       final cardProvider = CardProvider(languageProvider: languageProvider);
//       cardProvider.startReviewSession(cards: [testCard1, testCard2]);

//       await pumpCardReviewScreen(tester, cardProvider, 
//           animationService: ProductionAnimationService());

//       // Verify initial state
//       expect(find.text('Hello'), findsOneWidget);
//       expect(find.text('World'), findsNothing);

//       // Tap to reveal answer
//       final showAnswerButton = find.text('Show Answer');
//       await tester.tap(showAnswerButton);
//       await tester.pumpAndSettle();

//       // Verify answer is visible and card is centered
//       expect(find.text('World'), findsOneWidget);
      
//       // Get the card's position to ensure it's centered
//       final cardFinder = find.ancestor(
//         of: find.text('World'),
//         matching: find.byType(Container),
//       ).first;
//       final cardRenderBox = tester.renderObject(cardFinder) as RenderBox;
//       final cardPosition = cardRenderBox.localToGlobal(Offset.zero);
//       final screenSize = tester.binding.window.physicalSize / tester.binding.window.devicePixelRatio;
      
//       print('Card position after flip: $cardPosition');
//       print('Screen size: $screenSize');
      
//       // Card should be roughly centered horizontally
//       expect(cardPosition.dx, greaterThan(-50), 
//              reason: 'Card should not be slid off screen to the left');
//       expect(cardPosition.dx, lessThan(screenSize.width - 50),
//              reason: 'Card should not be slid off screen to the right');

//       // Now answer the card and verify next card is also centered
//       final correctButton = find.text('Correct');
//       await tester.tap(correctButton);
//       await tester.pumpAndSettle();

//       // Verify next card is visible and centered
//       expect(find.text('Goodbye'), findsOneWidget);
      
//       final nextCardFinder = find.ancestor(
//         of: find.text('Goodbye'),
//         matching: find.byType(Container),
//       ).first;
//       final nextCardRenderBox = tester.renderObject(nextCardFinder) as RenderBox;
//       final nextCardPosition = nextCardRenderBox.localToGlobal(Offset.zero);
      
//       print('Next card position after answer: $nextCardPosition');
      
//       // Next card should also be centered
//       expect(nextCardPosition.dx, greaterThan(-50), 
//              reason: 'Next card should not be slid off screen to the left');
//       expect(nextCardPosition.dx, lessThan(screenSize.width - 50),
//              reason: 'Next card should not be slid off screen to the right');
//     });

//     testWidgets('SlideTransition is used during swipe gestures', (
//       WidgetTester tester,
//     ) async {
//       // Setup with PRODUCTION animation service
//       final languageProvider = LanguageProvider();
//       final cardProvider = CardProvider(languageProvider: languageProvider);
//       cardProvider.startReviewSession(cards: [testCard1, testCard2]);

//       await pumpCardReviewScreen(tester, cardProvider, 
//           animationService: ProductionAnimationService());

//       // Flip card first to show answer
//       final showAnswerButton = find.text('Show Answer');
//       await tester.tap(showAnswerButton);
//       await tester.pumpAndSettle();
//       expect(find.text('World'), findsOneWidget);

//       // Start a swipe gesture
//       final cardGestureDetector = find.ancestor(
//         of: find.text('World'),
//         matching: find.byType(GestureDetector),
//       );
      
//       // Start dragging with actual movement to trigger _onPanStart and _onPanUpdate
//       final gesture = await tester.startGesture(tester.getCenter(cardGestureDetector));
//       await tester.pump();
      
//       // Move the gesture to trigger drag state
//       await gesture.moveBy(const Offset(50, 0));
//       await tester.pump();
      
//       // During drag, SlideTransition should be present
//       final duringDragSlideTransitions = find.byType(SlideTransition);
//       print('SlideTransitions during drag: ${duringDragSlideTransitions.evaluate().length}');
      
//       // CRITICAL: SlideTransition should be used during swipe gestures
//       expect(duringDragSlideTransitions.evaluate().length, equals(1),
//              reason: 'SlideTransition should be applied during swipe gestures');
             
//       // Clean up the gesture
//       await gesture.up();
//       await tester.pumpAndSettle();
//     });

//     testWidgets('multiple card flips and answers work correctly', (
//       WidgetTester tester,
//     ) async {
//       // Setup with multiple cards
//       final languageProvider = LanguageProvider();
//       final cardProvider = CardProvider(languageProvider: languageProvider);
//       final cards = [
//         testCard1,
//         testCard2,
//         CardModel.create(
//           frontText: 'Thank you',
//           backText: 'Danke',
//           language: 'de',
//           category: 'Greetings',
//         ),
//       ];
//       cardProvider.startReviewSession(cards: cards);

//       await pumpCardReviewScreen(tester, cardProvider);


//       // Test first card
//       expect(find.text('Hello'), findsOneWidget);
//       expect(find.text('World'), findsNothing);

//       // Flip first card
//       final firstCardGestureDetector = find.ancestor(
//         of: find.text('Hello'),
//         matching: find.byType(GestureDetector),
//       );
//       await tester.tap(firstCardGestureDetector);
//       await tester.pumpAndSettle();

//       // Verify back text is visible
//       expect(find.text('World'), findsOneWidget);

//       // Answer first card correctly
//       final correctButton = find.text('Correct');
//       await tester.tap(correctButton);
//       await tester.pumpAndSettle();

//       // Wait for widget rebuild after card progression
//       await tester.pump();
//       await tester.pumpAndSettle();

//       // Test second card
//       expect(find.text('Goodbye'), findsOneWidget);
//       expect(find.text('Auf Wiedersehen'), findsNothing);

//       // Flip second card
//       final secondCardGestureDetector = find.ancestor(
//         of: find.text('Goodbye'),
//         matching: find.byType(GestureDetector),
//       );
//       await tester.tap(secondCardGestureDetector);
//       await tester.pumpAndSettle();

//       // Verify back text is visible
//       expect(find.text('Auf Wiedersehen'), findsOneWidget);

//       // Answer second card correctly
//       await tester.tap(correctButton);
//       await tester.pumpAndSettle();

//       // Test third card
//       expect(find.text('Thank you'), findsOneWidget);
//       expect(find.text('Danke'), findsNothing);

//       // Flip third card
//       final thirdCardGestureDetector = find.ancestor(
//         of: find.text('Thank you'),
//         matching: find.byType(GestureDetector),
//       );
//       await tester.tap(thirdCardGestureDetector);
//       await tester.pumpAndSettle();

//       // Verify back text is visible
//       expect(find.text('Danke'), findsOneWidget);
//       // With the fix, there should be no SlideTransition after answering via button
//       final slideTransitions = find.byType(SlideTransition);
//       expect(slideTransitions.evaluate().length, equals(0),
//              reason: 'No SlideTransition should be present after answering via button');
//     });
//   });
// }
