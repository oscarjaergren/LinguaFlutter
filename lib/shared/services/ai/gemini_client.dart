import 'dart:convert';
import 'ai_provider_client.dart';

/// Google Gemini API client implementation
class GeminiClient extends BaseAiProviderClient {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  GeminiClient({super.client});

  @override
  String get defaultModel => 'gemini-1.5-flash';

  @override
  Future<String> complete({
    required String prompt,
    required String apiKey,
    String? model,
  }) async {
    final effectiveModel = model ?? defaultModel;
    final uri = Uri.parse('$_baseUrl/models/$effectiveModel:generateContent?key=$apiKey');

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 1000,
        },
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return parseResponse(data);
  }

  @override
  String parseResponse(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List<dynamic>;
    final content = candidates.first['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    return parts.first['text'] as String;
  }
}
