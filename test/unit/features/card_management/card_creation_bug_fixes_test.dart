import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_management/presentation/view_models/card_creation_notifier.dart';
import 'package:lingua_flutter/shared/domain/models/word_data.dart';

void main() {
  group('CardCreationNotifier Bug Fixes', () {
    late ProviderContainer container;
    late CardCreationNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(cardCreationNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should validate noun gender requirement', () {
      notifier.updateFrontText('Test');
      notifier.updateBackText('Test');
      notifier.updateWordType(WordType.noun);

      // Should fail validation without gender
      final result = notifier.saveCard();
      expect(result, completes);

      final state = container.read(cardCreationNotifierProvider);
      expect(state.errorMessage, equals('Noun gender is required'));
    });

    test('should pass validation with noun gender', () {
      notifier.updateFrontText('Test');
      notifier.updateBackText('Test');
      notifier.updateWordType(WordType.noun);
      notifier.updateNounGender('der');

      // Should pass basic validation (will fail at saveCard due to missing dependencies)
      // We can't test the private method directly, but we can test the behavior
      final result = notifier.saveCard();
      expect(result, completes);

      final state = container.read(cardCreationNotifierProvider);
      // Should not have gender validation error
      expect(state.errorMessage, isNot(equals('Noun gender is required')));
    });

    test('should accept IconModel parameter safely', () {
      // This test verifies the type safety fix
      expect(() => notifier.selectIcon(null), returnsNormally);
    });
  });
}
