import 'package:flutter_test/flutter_test.dart';
import '../../domain/models/word_enrichment_result.dart';
import '../../domain/providers/card_enrichment_provider.dart';
import '../../../../shared/domain/models/word_data.dart';
import '../../../../shared/services/ai/ai.dart';

/// Mock storage for testing
class MockAiConfigStorage implements AiConfigStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }
}

void main() {
  late MockAiConfigStorage mockStorage;

  setUp(() {
    mockStorage = MockAiConfigStorage();
  });

  group('CardEnrichmentProvider', () {
    test('initial state is not configured', () {
      final provider = CardEnrichmentProvider(storage: mockStorage);

      expect(provider.isConfigured, isFalse);
      expect(provider.config.apiKey, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('initialize loads saved configuration', () async {
      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      expect(provider.isInitialized, isTrue);
    });

    test('setApiKey updates config and notifies listeners', () async {
      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setApiKey('test-api-key');

      expect(provider.config.apiKey, 'test-api-key');
      expect(provider.isConfigured, isTrue);
      expect(notified, isTrue);
    });

    test('setProvider updates config provider', () async {
      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      await provider.setProvider(AiProvider.gemini);

      expect(provider.config.provider, AiProvider.gemini);
    });

    test('setModel updates config model', () async {
      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      await provider.setModel('gpt-4');

      expect(provider.config.model, 'gpt-4');
    });

    test('clearError clears error state', () async {
      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      // Trigger error by calling enrichWord without config
      await provider.enrichWord(word: 'test', language: 'de');
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, isNull);
    });

    test('enrichWord returns null when not configured', () async {
      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      final result = await provider.enrichWord(word: 'test', language: 'de');

      expect(result, isNull);
      expect(provider.error, isNotNull);
    });

    test('updateConfig updates entire config', () async {
      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      const newConfig = AiConfig(
        provider: AiProvider.anthropic,
        apiKey: 'test-key',
        model: 'claude-3',
        isEnabled: true,
      );

      await provider.updateConfig(newConfig);

      expect(provider.config.provider, AiProvider.anthropic);
      expect(provider.config.apiKey, 'test-key');
      expect(provider.config.model, 'claude-3');
      expect(provider.config.isEnabled, isTrue);
    });

    test('config persists to storage', () async {
      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      await provider.setApiKey('persisted-key');

      expect(mockStorage._data[CardEnrichmentProvider.configKey], isNotNull);
      expect(
        mockStorage._data[CardEnrichmentProvider.configKey],
        contains('persisted-key'),
      );
    });

    test('initialize loads persisted config', () async {
      // Pre-populate storage
      mockStorage._data[CardEnrichmentProvider.configKey] =
          '{"provider":"gemini","apiKey":"loaded-key","model":null,"isEnabled":true}';

      final provider = CardEnrichmentProvider(storage: mockStorage);
      await provider.initialize();

      expect(provider.config.provider, AiProvider.gemini);
      expect(provider.config.apiKey, 'loaded-key');
      expect(provider.config.isEnabled, isTrue);
    });
  });

  group('WordEnrichmentResult wordType parsing', () {
    test('verb wordType is parsed correctly', () {
      final result = WordEnrichmentResult.fromJson({
        'wordType': 'verb',
        'translation': 'to go',
        'grammar': {
          'isRegular': false,
          'isSeparable': false,
          'auxiliary': 'sein',
          'pastParticiple': 'gegangen',
        },
        'examples': ['Ich gehe nach Hause.'],
      });

      expect(result.wordType, WordType.verb);
      expect(result.wordData, isNotNull);
    });

    test('noun wordType is parsed correctly', () {
      final result = WordEnrichmentResult.fromJson({
        'wordType': 'noun',
        'translation': 'the house',
        'grammar': {'gender': 'das', 'plural': 'Häuser'},
        'examples': [],
      });

      expect(result.wordType, WordType.noun);
      expect(result.wordData, isNotNull);
    });

    test('adjective wordType is parsed correctly', () {
      final result = WordEnrichmentResult.fromJson({
        'wordType': 'adjective',
        'translation': 'fast',
        'grammar': {'comparative': 'schneller', 'superlative': 'am schnellsten'},
        'examples': [],
      });

      expect(result.wordType, WordType.adjective);
      expect(result.wordData, isNotNull);
      expect(result.wordData, isA<AdjectiveData>());
      final adjData = result.wordData as AdjectiveData;
      expect(adjData.comparative, 'schneller');
      expect(adjData.superlative, 'am schnellsten');
    });

    test('unknown wordType string defaults to other', () {
      final result = WordEnrichmentResult.fromJson({
        'wordType': 'pronoun',
        'translation': 'he',
        'examples': [],
      });

      expect(result.wordType, WordType.other);
    });
  });
}
