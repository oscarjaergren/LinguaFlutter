import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../openai_client.dart';
import '../anthropic_client.dart';
import '../gemini_client.dart';
import '../openrouter_client.dart';
import '../ai_provider_client.dart';

void main() {
  group('OpenAiClient', () {
    test('has correct default model', () {
      final client = OpenAiClient();
      expect(client.defaultModel, 'gpt-4o-mini');
    });

    test('complete sends correct request and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.openai.com/v1/chat/completions',
        );
        expect(request.headers['Authorization'], 'Bearer test-key');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'gpt-4o-mini');
        expect(body['messages'], isA<List>());
        expect(body['temperature'], 0.3);

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"wordType": "noun", "translation": "test"}',
                },
              },
            ],
          }),
          200,
        );
      });

      final client = OpenAiClient(client: mockClient);
      final response = await client.complete(
        prompt: 'Test prompt',
        apiKey: 'test-key',
      );

      expect(response, '{"wordType": "noun", "translation": "test"}');
    });

    test('parseResponse extracts content from choices', () {
      final client = OpenAiClient();
      final result = client.parseResponse({
        'choices': [
          {
            'message': {'content': 'test content'},
          },
        ],
      });
      expect(result, 'test content');
    });

    test('throws AiProviderException on error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Invalid API key"}', 401);
      });

      final client = OpenAiClient(client: mockClient);

      expect(
        () => client.complete(prompt: 'Test', apiKey: 'bad-key'),
        throwsA(isA<AiProviderException>()),
      );
    });
  });

  group('AnthropicClient', () {
    test('has correct default model', () {
      final client = AnthropicClient();
      expect(client.defaultModel, 'claude-3-haiku-20240307');
    });

    test('complete sends correct request with x-api-key header', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.anthropic.com/v1/messages');
        expect(request.headers['x-api-key'], 'test-key');
        expect(request.headers['anthropic-version'], '2023-06-01');

        return http.Response(
          jsonEncode({
            'content': [
              {'text': '{"wordType": "verb"}'},
            ],
          }),
          200,
        );
      });

      final client = AnthropicClient(client: mockClient);
      final response = await client.complete(
        prompt: 'Test prompt',
        apiKey: 'test-key',
      );

      expect(response, '{"wordType": "verb"}');
    });

    test('parseResponse extracts text from content array', () {
      final client = AnthropicClient();
      final result = client.parseResponse({
        'content': [
          {'text': 'anthropic response'},
        ],
      });
      expect(result, 'anthropic response');
    });
  });

  group('GeminiClient', () {
    test('has correct default model', () {
      final client = GeminiClient();
      expect(client.defaultModel, 'gemini-2.5-flash-lite');
    });

    test('complete sends correct request with key in URL', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=test-key',
        );
        expect(request.headers['Authorization'], isNull);

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['contents'], isA<List>());
        expect(body['generationConfig']['temperature'], 0.3);

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '{"wordType": "adjective"}'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final client = GeminiClient(client: mockClient);
      final response = await client.complete(
        prompt: 'Test prompt',
        apiKey: 'test-key',
      );

      expect(response, '{"wordType": "adjective"}');
    });

    test('parseResponse extracts text from candidates', () {
      final client = GeminiClient();
      final result = client.parseResponse({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'gemini response'},
              ],
            },
          },
        ],
      });
      expect(result, 'gemini response');
    });
  });

  group('OpenRouterClient', () {
    test('has correct default model', () {
      final client = OpenRouterClient();
      expect(client.defaultModel, 'openai/gpt-4o-mini');
    });

    test('complete sends correct request to openrouter', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://openrouter.ai/api/v1/chat/completions',
        );
        expect(request.headers['Authorization'], 'Bearer test-key');

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': '{"wordType": "adverb"}'},
              },
            ],
          }),
          200,
        );
      });

      final client = OpenRouterClient(client: mockClient);
      final response = await client.complete(
        prompt: 'Test prompt',
        apiKey: 'test-key',
      );

      expect(response, '{"wordType": "adverb"}');
    });
  });

  group('AiProviderException', () {
    test('toString returns message', () {
      final exception = AiProviderException('Test error');
      expect(exception.toString(), 'Test error');
    });

    test('toString includes details when provided', () {
      final exception = AiProviderException('Test error', 'More details');
      expect(exception.toString(), 'Test error\nMore details');
    });
  });
}
