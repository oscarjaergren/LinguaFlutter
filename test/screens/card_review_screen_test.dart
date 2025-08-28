import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/models/card_model.dart';
import 'package:lingua_flutter/providers/card_provider.dart';
import 'package:lingua_flutter/screens/card_review_screen.dart';
import 'package:provider/provider.dart';

void main() {
  // Create a reusable function to pump the widget with necessary providers
  Future<void> pumpCardReviewScreen(WidgetTester tester, CardProvider cardProvider) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cardProvider),
        ],
        child: const MaterialApp(
          home: CardReviewScreen(),
        ),
      ),
    );
  }

  // Create a sample card for testing
  final testCard = CardModel.create(
    frontText: 'Hello',
    backText: 'World',
    language: 'en',
    category: 'Greetings',
  );

  testWidgets('tapping a card flips it to show the back', (WidgetTester tester) async {
    // 1. Setup
    final cardProvider = CardProvider();
    
    // Manually initialize the provider with test data
    cardProvider.startReviewSession(cards: [testCard]);

    // Build the widget
    await pumpCardReviewScreen(tester, cardProvider);

    // 2. Initial State Verification
    // Verify the front text is visible
    expect(find.text('Hello'), findsOneWidget);
    // Verify the back text is NOT visible
    expect(find.text('World'), findsNothing);

    // 3. Action
    // Find the main GestureDetector for the card and tap it
    // Find the specific GestureDetector that wraps the card content.
    final cardGestureDetector = find.ancestor(
      of: find.text('Hello'), 
      matching: find.byType(GestureDetector)
    );
    expect(cardGestureDetector, findsOneWidget);
    await tester.tap(cardGestureDetector);

    // Let the animations run to completion
    // We use pumpAndSettle to wait for all animations to finish.
    // It might time out if animations are continuous, but for a flip it should work.
    await tester.pumpAndSettle();

    // 4. Verification
    // Verify the back text is now visible
    expect(find.text('World'), findsOneWidget);
    // The front text might still be in the tree depending on the build logic,
    // but the important part is that the back is now visible.
  });
}
