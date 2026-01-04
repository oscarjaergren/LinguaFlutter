import 'dart:convert';
import 'ai_provider_client.dart';

/// OpenRouter API client implementation (OpenAI-compatible)
class OpenRouterClient extends BaseAiProviderClient {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  OpenRouterClient({super.client});

  @override
  String get defaultModel => 'openai/gpt-4o-mini';

  @override
  Future<String> complete({
    required String prompt,
    required String apiKey,
    String? model,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/completions');

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: {
        'model': model ?? defaultModel,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return parseResponse(data);
  }

  @override
  String parseResponse(Map<String, dynamic> data) {
    final choices = data['choices'] as List<dynamic>;
    final message = choices.first['message'] as Map<String, dynamic>;
    return message['content'] as String;
  }
}
