import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/widgets/iconify_icon.dart';
import 'package:lingua_flutter/models/icon_model.dart';

void main() {
  group('IconGridItem Widget', () {
    const testIcon = IconModel(
      id: 'mdi:heart',
      name: 'Heart',
      set: 'mdi',
      category: 'Emotions',
      tags: ['love'],
      svgUrl: 'https://api.iconify.design/mdi:heart.svg',
    );

    testWidgets('should render grid item structure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconGridItem(icon: testIcon),
          ),
        ),
      );

      // Should have the basic widget structure
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle tap events', (tester) async {
      var tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconGridItem(
              icon: testIcon,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('should show tooltip with icon info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconGridItem(icon: testIcon),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Heart (mdi)');
    });

    testWidgets('should show selection state with border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconGridItem(
              icon: testIcon,
              isSelected: true,
            ),
          ),
        ),
      );

      // Wait for the widget to render
      await tester.pump();

      // Find the container with the border decoration
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      expect(containers.isNotEmpty, true);
      
      // Check if any container has a border (indicating selection)
      final hasSelection = containers.any((container) {
        final decoration = container.decoration as BoxDecoration?;
        return decoration?.border != null;
      });
      
      expect(hasSelection, true);
    });
  });
}
