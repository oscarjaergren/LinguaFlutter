import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lingua_flutter/screens/icon_search_screen.dart';
import 'package:lingua_flutter/providers/icon_provider.dart';
import 'package:lingua_flutter/models/icon_model.dart';

void main() {
  group('IconSearchScreen Widget', () {
    late IconProvider mockProvider;

    setUp(() {
      mockProvider = IconProvider();
    });

    testWidgets('should render search screen with search bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<IconProvider>.value(
            value: mockProvider,
            child: const IconSearchScreen(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Search Icons'), findsOneWidget);
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('Search for icons...'), findsOneWidget);
    });

    testWidgets('should display selected icon when one is selected', (tester) async {
      const selectedIcon = IconModel(
        id: 'mdi:home',
        name: 'Home',
        set: 'mdi',
        category: 'Actions',
        tags: ['house'],
        svgUrl: 'https://api.iconify.design/mdi:home.svg',
      );

      mockProvider.selectIcon(selectedIcon);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<IconProvider>.value(
            value: mockProvider,
            child: const IconSearchScreen(),
          ),
        ),
      );

      expect(find.text('Selected: Home'), findsOneWidget);
      expect(find.text('Set: mdi'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should clear selection when close button is tapped', (tester) async {
      const selectedIcon = IconModel(
        id: 'mdi:home',
        name: 'Home',
        set: 'mdi',
        category: 'Actions',
        tags: ['house'],
        svgUrl: 'https://api.iconify.design/mdi:home.svg',
      );

      mockProvider.selectIcon(selectedIcon);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<IconProvider>.value(
            value: mockProvider,
            child: const IconSearchScreen(),
          ),
        ),
      );

      expect(mockProvider.selectedIcon, isNotNull);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(mockProvider.selectedIcon, isNull);
    });

    testWidgets('should clear search when clear button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<IconProvider>.value(
            value: mockProvider,
            child: const IconSearchScreen(),
          ),
        ),
      );

      // Type in search field
      await tester.enterText(find.byType(SearchBar), 'test');
      await tester.pump();

      // Should show clear button
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Search field should be cleared
      expect(find.text('test'), findsNothing);
    });

    testWidgets('should navigate back when app bar back button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(tester.element(find.byType(ElevatedButton))).push(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider<IconProvider>.value(
                      value: mockProvider,
                      child: const IconSearchScreen(),
                    ),
                  ),
                );
              },
              child: const Text('Go to Search'),
            ),
          ),
        ),
      );

      // Navigate to search screen
      await tester.tap(find.text('Go to Search'));
      await tester.pumpAndSettle();

      expect(find.text('Search Icons'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Go to Search'), findsOneWidget);
    });
  });
}
