import 'ai_config.dart';
import 'ai_provider_client.dart';
import 'anthropic_client.dart';
import 'gemini_client.dart';
import 'openai_client.dart';
import 'openrouter_client.dart';

/// Factory for creating AI provider clients based on configuration
class AiProviderFactory {
  static final Map<AiProvider, AiProviderClient> _clients = {};

  /// Gets or creates a client for the specified provider
  static AiProviderClient getClient(AiProvider provider) {
    return _clients.putIfAbsent(provider, () => _createClient(provider));
  }

  static AiProviderClient _createClient(AiProvider provider) {
    return switch (provider) {
      AiProvider.openai => OpenAiClient(),
      AiProvider.anthropic => AnthropicClient(),
      AiProvider.gemini => GeminiClient(),
      AiProvider.openRouter => OpenRouterClient(),
    };
  }

  /// Disposes all cached clients
  static void disposeAll() {
    for (final client in _clients.values) {
      if (client is BaseAiProviderClient) {
        client.dispose();
      }
    }
    _clients.clear();
  }
}
