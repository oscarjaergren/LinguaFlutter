import 'package:flutter_test/flutter_test.dart';
import '../ai_config.dart';
import '../ai_provider_factory.dart';
import '../openai_client.dart';
import '../anthropic_client.dart';
import '../gemini_client.dart';
import '../openrouter_client.dart';

void main() {
  tearDown(() {
    AiProviderFactory.disposeAll();
  });

  group('AiProviderFactory', () {
    test('getClient returns OpenAiClient for openai provider', () {
      final client = AiProviderFactory.getClient(AiProvider.openai);
      expect(client, isA<OpenAiClient>());
    });

    test('getClient returns AnthropicClient for anthropic provider', () {
      final client = AiProviderFactory.getClient(AiProvider.anthropic);
      expect(client, isA<AnthropicClient>());
    });

    test('getClient returns GeminiClient for gemini provider', () {
      final client = AiProviderFactory.getClient(AiProvider.gemini);
      expect(client, isA<GeminiClient>());
    });

    test('getClient returns OpenRouterClient for openRouter provider', () {
      final client = AiProviderFactory.getClient(AiProvider.openRouter);
      expect(client, isA<OpenRouterClient>());
    });

    test('getClient caches and returns same instance', () {
      final client1 = AiProviderFactory.getClient(AiProvider.openai);
      final client2 = AiProviderFactory.getClient(AiProvider.openai);
      expect(identical(client1, client2), isTrue);
    });

    test('getClient returns different instances for different providers', () {
      final openai = AiProviderFactory.getClient(AiProvider.openai);
      final gemini = AiProviderFactory.getClient(AiProvider.gemini);
      expect(identical(openai, gemini), isFalse);
    });

    test('disposeAll clears cached clients', () {
      final client1 = AiProviderFactory.getClient(AiProvider.openai);
      AiProviderFactory.disposeAll();
      final client2 = AiProviderFactory.getClient(AiProvider.openai);
      expect(identical(client1, client2), isFalse);
    });
  });

  group('AiConfig', () {
    test('isConfigured returns false when apiKey is null', () {
      const config = AiConfig(apiKey: null);
      expect(config.isConfigured, isFalse);
    });

    test('isConfigured returns false when apiKey is empty', () {
      const config = AiConfig(apiKey: '');
      expect(config.isConfigured, isFalse);
    });

    test('isConfigured returns true when apiKey is set', () {
      const config = AiConfig(apiKey: 'test-key');
      expect(config.isConfigured, isTrue);
    });

    test('effectiveModel returns custom model when set', () {
      const config = AiConfig(
        provider: AiProvider.openai,
        model: 'gpt-4',
      );
      expect(config.effectiveModel, 'gpt-4');
    });

    test('effectiveModel returns default model when not set', () {
      const config = AiConfig(provider: AiProvider.openai);
      expect(config.effectiveModel, 'gpt-4o-mini');
    });

    test('copyWith creates new instance with updated values', () {
      const original = AiConfig(
        provider: AiProvider.openai,
        apiKey: 'key1',
      );
      
      final copied = original.copyWith(apiKey: 'key2');
      
      expect(copied.provider, AiProvider.openai);
      expect(copied.apiKey, 'key2');
      expect(original.apiKey, 'key1');
    });
  });

  group('AiProvider extension', () {
    test('displayName returns correct names', () {
      expect(AiProvider.openai.displayName, 'OpenAI');
      expect(AiProvider.anthropic.displayName, 'Anthropic');
      expect(AiProvider.gemini.displayName, 'Google Gemini');
      expect(AiProvider.openRouter.displayName, 'OpenRouter');
    });

    test('baseUrl returns correct URLs', () {
      expect(AiProvider.openai.baseUrl, 'https://api.openai.com/v1');
      expect(AiProvider.anthropic.baseUrl, 'https://api.anthropic.com/v1');
      expect(AiProvider.gemini.baseUrl, 'https://generativelanguage.googleapis.com/v1beta');
      expect(AiProvider.openRouter.baseUrl, 'https://openrouter.ai/api/v1');
    });

    test('defaultModel returns correct models', () {
      expect(AiProvider.openai.defaultModel, 'gpt-4o-mini');
      expect(AiProvider.anthropic.defaultModel, 'claude-3-haiku-20240307');
      expect(AiProvider.gemini.defaultModel, 'gemini-1.5-flash');
      expect(AiProvider.openRouter.defaultModel, 'openai/gpt-4o-mini');
    });
  });
}
