import 'ai_config.dart';
import 'ai_provider_factory.dart';

/// Generic AI completion service
class AiService {
  /// Complete a prompt using the configured AI provider
  Future<String> complete({
    required String prompt,
    required AiConfig config,
  }) async {
    if (!config.isConfigured) {
      throw AiServiceException(
        'AI is not configured. Please add your API key.',
      );
    }

    final client = AiProviderFactory.getClient(config.provider);

    return client.complete(
      prompt: prompt,
      apiKey: config.apiKey!,
      model: config.model,
    );
  }

  void dispose() {
    AiProviderFactory.disposeAll();
  }
}

/// Exception thrown by the AI service
class AiServiceException implements Exception {
  final String message;

  AiServiceException(this.message);

  @override
  String toString() => message;
}
