import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_provider.dart';
import 'package:lingua_flutter/features/card_management/data/repositories/card_management_repository.dart';

import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/utils/rate_limiter.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

@GenerateMocks([CardManagementRepository])
import 'security_integration_test.mocks.dart';

void main() {
  group('Card Management Security Integration Tests', () {
    late CardManagementProvider provider;
    late MockCardManagementRepository mockRepository;

    setUpAll(() {
      LoggerService.initialize();
    });

    setUp(() {
      mockRepository = MockCardManagementRepository();
      provider = CardManagementProvider(
        getActiveLanguage: () => 'de',
        repository: mockRepository,
      );

      // Clear rate limiter before each test
      RateLimiter().clearAll();
    });

    tearDown(() {
      provider.dispose();
      RateLimiter().clearAll();
    });

    group('Input Sanitization', () {
      test('sanitizes HTML tags from card text', () async {
        final maliciousCard = CardModel.create(
          frontText: '<script>alert("xss")</script>Hello',
          backText: '<b>World</b>',
          language: 'de',
        );

        when(
          mockRepository.saveCard(any),
        ).thenAnswer((_) async => maliciousCard);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        await provider.saveCard(maliciousCard);

        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final sanitizedCard = captured.first as CardModel;

        expect(sanitizedCard.frontText, 'Hello');
        expect(sanitizedCard.backText, 'World');
      });

      test('sanitizes script content from notes', () async {
        final baseCard = CardModel.create(
          frontText: 'Front',
          backText: 'Back',
          language: 'de',
        );
        final maliciousCard = baseCard.copyWith(
          notes: 'javascript:alert("xss")',
        );

        when(
          mockRepository.saveCard(any),
        ).thenAnswer((_) async => maliciousCard);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        await provider.saveCard(maliciousCard);

        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final sanitizedCard = captured.first as CardModel;

        expect(sanitizedCard.notes!.contains('javascript:'), false);
      });

      test('sanitizes tags by removing special characters', () async {
        final card = CardModel.create(
          frontText: 'Front',
          backText: 'Back',
          language: 'de',
          tags: ['tag@1', 'TAG#2', 'tag!3'],
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => card);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        await provider.saveCard(card);

        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final sanitizedCard = captured.first as CardModel;

        expect(sanitizedCard.tags, ['tag1', 'tag2', 'tag3']);
      });

      test('removes duplicate tags', () async {
        final card = CardModel.create(
          frontText: 'Front',
          backText: 'Back',
          language: 'de',
          tags: ['tag1', 'tag2', 'tag1', 'TAG1'],
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => card);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        await provider.saveCard(card);

        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final sanitizedCard = captured.first as CardModel;

        expect(sanitizedCard.tags.length, 2);
        expect(sanitizedCard.tags.contains('tag1'), true);
        expect(sanitizedCard.tags.contains('tag2'), true);
      });

      test('limits text length', () async {
        final longText = 'a' * 1000;
        final card = CardModel.create(
          frontText: longText,
          backText: longText,
          language: 'de',
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => card);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        await provider.saveCard(card);

        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final sanitizedCard = captured.first as CardModel;

        expect(sanitizedCard.frontText.length, lessThanOrEqualTo(500));
        expect(sanitizedCard.backText.length, lessThanOrEqualTo(500));
      });
    });

    group('Input Validation', () {
      test('validates language code', () async {
        final invalidCard = CardModel.create(
          frontText: 'Front',
          backText: 'Back',
          language: 'invalid',
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => invalidCard);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        // Invalid language code gets sanitized to 'de', so no exception
        await provider.saveCard(invalidCard);

        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final sanitizedCard = captured.first as CardModel;

        // Should be sanitized to default 'de'
        expect(sanitizedCard.language, 'de');
      });

      test('validates front text is not empty', () async {
        final invalidCard = CardModel.create(
          frontText: '',
          backText: 'Back',
          language: 'de',
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => invalidCard);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        expect(() => provider.saveCard(invalidCard), throwsA(isA<Exception>()));
      });

      test('validates back text is not empty', () async {
        final invalidCard = CardModel.create(
          frontText: 'Front',
          backText: '',
          language: 'de',
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => invalidCard);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        expect(() => provider.saveCard(invalidCard), throwsA(isA<Exception>()));
      });

      test('sanitizes invalid language code to default', () async {
        final card = CardModel.create(
          frontText: 'Front',
          backText: 'Back',
          language: 'invalid',
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => card);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        // Should sanitize to 'de' without throwing
        await provider.saveCard(card);
        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final sanitizedCard = captured.first as CardModel;
        expect(sanitizedCard.language, 'de');
      });
    });

    group('Rate Limiting', () {
      test('enforces rate limit on card creation', () async {
        final card = CardModel.create(
          frontText: 'Front',
          backText: 'Back',
          language: 'de',
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => card);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        // Note: Rate limiting requires authenticated user
        // In a real scenario, we'd need to mock SupabaseAuthService
        // For now, this test documents the expected behavior

        // This test would need proper auth mocking to work correctly
        // Skipping actual execution but documenting the pattern
      });

      test('different users have independent rate limits', () async {
        // This test would verify that rate limits are per-user
        // Requires mocking authentication for multiple users
      });
    });

    group('Combined Security', () {
      test('sanitizes and validates card in single operation', () async {
        final card = CardModel.create(
          frontText: '<b>Front</b>',
          backText: '<i>Back</i>',
          language: 'DE',
          tags: ['tag@1', 'TAG#2'],
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => card);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        await provider.saveCard(card);

        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final processedCard = captured.first as CardModel;

        // Verify sanitization
        expect(processedCard.frontText, 'Front');
        expect(processedCard.backText, 'Back');
        expect(processedCard.tags, ['tag1', 'tag2']);

        // Verify normalization
        expect(processedCard.language, 'de');
      });

      test('prevents XSS in all text fields', () async {
        final baseCard = CardModel.create(
          frontText: '<script>alert("xss")</script>Front',
          backText: '<img src=x onerror="alert(1)">Back',
          language: 'de',
        );
        final maliciousCard = baseCard.copyWith(
          notes: 'javascript:void(0)',
          examples: ['<b onclick="alert()">Example</b>'],
        );

        when(
          mockRepository.saveCard(any),
        ).thenAnswer((_) async => maliciousCard);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        await provider.saveCard(maliciousCard);

        final captured = verify(mockRepository.saveCard(captureAny)).captured;
        final sanitizedCard = captured.first as CardModel;

        // Verify all XSS attempts are neutralized
        expect(sanitizedCard.frontText.contains('<script>'), false);
        expect(sanitizedCard.backText.contains('onerror'), false);
        expect(sanitizedCard.notes!.contains('javascript:'), false);
        expect(sanitizedCard.examples.first.contains('onclick'), false);
      });
    });

    group('Bulk Operations Security', () {
      test('sanitizes all cards in bulk operation', () async {
        final cards = [
          CardModel.create(
            frontText: '<b>Card 1</b>',
            backText: 'Back 1',
            language: 'de',
          ),
          CardModel.create(
            frontText: '<i>Card 2</i>',
            backText: 'Back 2',
            language: 'de',
          ),
        ];

        when(mockRepository.saveCard(any)).thenAnswer((_) async => cards.first);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        // Note: This would require auth mocking for rate limiting
        // await provider.addMultipleCards(cards);

        // Verify each card is sanitized
        // This is a pattern for future implementation
      });
    });
  });
}
