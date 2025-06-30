import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lingua_flutter/screens/card_creation_screen.dart';
import 'package:lingua_flutter/providers/card_provider.dart';
import 'package:lingua_flutter/providers/icon_provider.dart';

void main() {
  group('CardCreationScreen Widget', () {
    late CardProvider mockCardProvider;
    late IconProvider mockIconProvider;

    setUp(() {
      mockCardProvider = CardProvider();
      mockIconProvider = IconProvider();
    });

    Widget createTestWidget({Widget? child}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<CardProvider>.value(value: mockCardProvider),
            ChangeNotifierProvider<IconProvider>.value(value: mockIconProvider),
          ],
          child: child ?? const CardCreationScreen(),
        ),
      );
    }

    testWidgets('should render card creation screen', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Create Card'), findsOneWidget);
      expect(find.text('CREATE'), findsOneWidget);
      expect(find.text('Icon (Optional)'), findsOneWidget);
      expect(find.text('Select Icon'), findsOneWidget);
    });

    testWidgets('should show form fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsAtLeastNWidgets(4));
      expect(find.text('Front Text (English)'), findsOneWidget);
      expect(find.text('Back Text (Spanish)'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Tags (Optional)'), findsOneWidget);
    });

    testWidgets('should show language dropdowns', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Front Language'), findsOneWidget);
      expect(find.text('Back Language'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('should show form validation errors', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to create card without filling required fields
      await tester.tap(find.text('CREATE'));
      await tester.pump();

      expect(find.text('Please enter front text'), findsOneWidget);
      expect(find.text('Please enter back text'), findsOneWidget);
      expect(find.text('Please enter a category'), findsOneWidget);
    });

    testWidgets('should fill form fields correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Fill front text
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter the word or phrase to learn'),
        'Hello',
      );

      // Fill back text
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter the translation or definition'),
        'Hola',
      );

      // Fill category
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., Vocabulary, Phrases, Grammar'),
        'Greetings',
      );

      // Fill tags
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Separate tags with commas'),
        'basic, common',
      );

      await tester.pump();

      // Verify the text was entered
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hola'), findsOneWidget);
      expect(find.text('Greetings'), findsOneWidget);
      expect(find.text('basic, common'), findsOneWidget);
    });

    testWidgets('should show icon selection button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Select Icon'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    // Note: More complex tests like actual card creation, icon selection navigation,
    // and provider interactions would require more sophisticated mocking and setup.
    // These tests cover the basic UI rendering and form interaction functionality.
  });
}
