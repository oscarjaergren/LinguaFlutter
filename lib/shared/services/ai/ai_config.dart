import 'package:json_annotation/json_annotation.dart';

part 'ai_config.g.dart';

/// Supported AI providers
enum AiProvider {
  @JsonValue('openai')
  openai,
  @JsonValue('anthropic')
  anthropic,
  @JsonValue('openrouter')
  openRouter,
  @JsonValue('gemini')
  gemini,
}

extension AiProviderExtension on AiProvider {
  String get displayName {
    return switch (this) {
      AiProvider.openai => 'OpenAI',
      AiProvider.anthropic => 'Anthropic',
      AiProvider.openRouter => 'OpenRouter',
      AiProvider.gemini => 'Google Gemini',
    };
  }

  String get baseUrl {
    return switch (this) {
      AiProvider.openai => 'https://api.openai.com/v1',
      AiProvider.anthropic => 'https://api.anthropic.com/v1',
      AiProvider.openRouter => 'https://openrouter.ai/api/v1',
      AiProvider.gemini => 'https://generativelanguage.googleapis.com/v1beta',
    };
  }

  String get defaultModel {
    return switch (this) {
      AiProvider.openai => 'gpt-4o-mini',
      AiProvider.anthropic => 'claude-3-5-haiku-latest',
      AiProvider.openRouter => 'openai/gpt-4o-mini',
      AiProvider.gemini => 'gemini-2.5-flash-lite', // Best free tier availability
    };
  }

  /// Available models for this provider (commonly used ones)
  List<String> get availableModels {
    return switch (this) {
      AiProvider.openai => [
        'gpt-4o-mini',
        'gpt-4o',
        'gpt-4-turbo',
        'gpt-3.5-turbo',
      ],
      AiProvider.anthropic => [
        'claude-3-5-haiku-latest',
        'claude-3-5-sonnet-latest',
        'claude-3-opus-latest',
      ],
      AiProvider.openRouter => [
        'openai/gpt-4o-mini',
        'openai/gpt-4o',
        'anthropic/claude-3.5-sonnet',
        'google/gemini-2.0-flash-exp:free',
        'meta-llama/llama-3.1-8b-instruct:free',
      ],
      AiProvider.gemini => [
        'gemini-2.5-flash-lite',
        'gemini-flash-latest',
        'gemini-flash-lite-latest',
        'gemini-2.5-flash',
        'gemini-2.5-pro',
      ],
    };
  }
}

/// Configuration for AI services
@JsonSerializable()
class AiConfig {
  final AiProvider provider;
  final String? apiKey;
  final String? model;
  final bool isEnabled;

  const AiConfig({
    this.provider = AiProvider.openai,
    this.apiKey,
    this.model,
    this.isEnabled = false,
  });

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  String get effectiveModel => model ?? provider.defaultModel;

  AiConfig copyWith({
    AiProvider? provider,
    String? apiKey,
    String? model,
    bool? isEnabled,
  }) {
    return AiConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  factory AiConfig.fromJson(Map<String, dynamic> json) => _$AiConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AiConfigToJson(this);
}
