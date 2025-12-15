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
      AiProvider.anthropic => 'claude-3-haiku-20240307',
      AiProvider.openRouter => 'openai/gpt-4o-mini',
      AiProvider.gemini => 'gemini-1.5-flash',
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
