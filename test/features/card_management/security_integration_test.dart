import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/data/repositories/card_management_repository.dart';
import 'package:lingua_flutter/features/language/language.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/utils/rate_limiter.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

@GenerateMocks([CardManagementRepository])
import 'security_integration_test.mocks.dart';

void main() {
  group('Card Management Security Integration Tests', () {
    late MockCardManagementRepository mockRepository;
    late ProviderContainer container;

    setUpAll(() {
      LoggerService.initialize();
    });

    setUp(() {
      mockRepository = MockCardManagementRepository();

      // Setup mock language notifier state
      final mockLanguageNotifier = LanguageNotifier();

      container = ProviderContainer(
        overrides: [
          cardManagementRepositoryProvider.overrideWithValue(mockRepository),
          languageNotifierProvider.overrideWith(() => mockLanguageNotifier),
        ],
      );

      // Clear rate limiter before each test
      RateLimiter().clearAll();
    });

    tearDown(() {
      container.dispose();
      RateLimiter().clearAll();
    });

    CardManagementNotifier getNotifier() =>
        container.read(cardManagementNotifierProvider.notifier);

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

        await getNotifier().saveCard(maliciousCard);

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

        await getNotifier().saveCard(maliciousCard);

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

        await getNotifier().saveCard(card);

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

        await getNotifier().saveCard(card);

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

        await getNotifier().saveCard(card);

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
        await getNotifier().saveCard(invalidCard);

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

        expect(
          () => getNotifier().saveCard(invalidCard),
          throwsA(isA<Exception>()),
        );
      });

      test('validates back text is not empty', () async {
        final invalidCard = CardModel.create(
          frontText: 'Front',
          backText: '',
          language: 'de',
        );

        when(mockRepository.saveCard(any)).thenAnswer((_) async => invalidCard);
        when(mockRepository.getAllCards()).thenAnswer((_) async => []);

        expect(
          () => getNotifier().saveCard(invalidCard),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
