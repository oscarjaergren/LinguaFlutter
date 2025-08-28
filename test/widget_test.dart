// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/widgets/mascot_widget.dart';
import 'package:lingua_flutter/services/animation_service.dart';

void main() {

  testWidgets('MascotWidget can be created without errors', (WidgetTester tester) async {
    // Test just the MascotWidget in isolation to avoid production timers
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MascotWidget(
            size: 100,
            message: 'Test message',
            mascotState: MascotState.idle,
            animationService: const TestAnimationService(),
          ),
        ),
      ),
    );

    // Just pump once to build the widget tree
    await tester.pump();

    // Verify the widget was created
    expect(find.byType(MascotWidget), findsOneWidget);
  });
}
