import 'ai_provider_client.dart';

/// OpenAI API client implementation
class OpenAiClient extends OpenAiCompatibleClient {
  @override
  String get baseUrl => 'https://api.openai.com/v1';

  OpenAiClient({super.client});

  @override
  String get defaultModel => 'gpt-4o-mini';
}
