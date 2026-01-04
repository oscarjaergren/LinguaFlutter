import 'dart:convert';
import 'ai_provider_client.dart';

/// Anthropic Claude API client implementation
class AnthropicClient extends BaseAiProviderClient {
  static const String _baseUrl = 'https://api.anthropic.com/v1';

  AnthropicClient({super.client});

  @override
  String get defaultModel => 'claude-3-haiku-20240307';

  @override
  Future<String> complete({
    required String prompt,
    required String apiKey,
    String? model,
  }) async {
    final uri = Uri.parse('$_baseUrl/messages');

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: {
        'model': model ?? defaultModel,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1000,
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return parseResponse(data);
  }

  @override
  String parseResponse(Map<String, dynamic> data) {
    final content = data['content'] as List<dynamic>;
    return content.first['text'] as String;
  }
}
