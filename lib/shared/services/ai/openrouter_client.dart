import 'ai_provider_client.dart';

/// OpenRouter API client implementation (OpenAI-compatible)
class OpenRouterClient extends OpenAiCompatibleClient {
  @override
  String get baseUrl => 'https://openrouter.ai/api/v1';

  OpenRouterClient({super.client});

  @override
  String get defaultModel => 'openai/gpt-4o-mini';
}
