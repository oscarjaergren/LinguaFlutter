import 'dart:convert';
import 'package:http/http.dart' as http;

/// Abstract interface for AI provider clients
abstract class AiProviderClient {
  /// Makes a request to the AI provider and returns the response text
  Future<String> complete({
    required String prompt,
    required String apiKey,
    String? model,
  });

  /// The default model for this provider
  String get defaultModel;

  /// Parses the raw AI response to extract the content text
  String parseResponse(Map<String, dynamic> data);
}

/// Base class with shared HTTP functionality
abstract class BaseAiProviderClient implements AiProviderClient {
  final http.Client _client;

  BaseAiProviderClient({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> post(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final errorMessage = switch (response.statusCode) {
        429 => 'Rate limit exceeded. Please wait a moment and try again.',
        401 => 'Invalid API key. Please check your credentials.',
        403 => 'Access denied. Your API key may not have access to this model.',
        404 => 'Model not found. Please check the model name.',
        500 || 502 || 503 => 'AI service temporarily unavailable. Please try again.',
        _ => 'API error: ${response.statusCode}',
      };
      throw AiProviderException(errorMessage, response.body);
    }

    return response;
  }

  /// Helper method to decode JSON response body
  Map<String, dynamic> decodeResponseBody(http.Response response) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() {
    _client.close();
  }
}

/// Base class for OpenAI-compatible API clients (OpenAI, OpenRouter, etc.)
abstract class OpenAiCompatibleClient extends BaseAiProviderClient {
  /// The base URL for the API endpoint
  String get baseUrl;

  OpenAiCompatibleClient({super.client});

  @override
  Future<String> complete({
    required String prompt,
    required String apiKey,
    String? model,
  }) async {
    final uri = Uri.parse('$baseUrl/chat/completions');

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: {
        'model': model ?? defaultModel,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      },
    );

    final data = decodeResponseBody(response);
    return parseResponse(data);
  }

  @override
  String parseResponse(Map<String, dynamic> data) {
    final choices = data['choices'] as List<dynamic>;
    final message = choices.first['message'] as Map<String, dynamic>;
    return message['content'] as String;
  }
}

/// Exception thrown by AI provider clients
class AiProviderException implements Exception {
  final String message;
  final String? details;

  AiProviderException(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return '$message\n$details';
    }
    return message;
  }
}
