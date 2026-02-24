import '../../../../shared/services/ai/ai.dart';

/// Immutable state for card enrichment / AI config
class CardEnrichmentState {
  final AiConfig config;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const CardEnrichmentState({
    this.config = const AiConfig(),
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isConfigured => config.isConfigured;

  CardEnrichmentState copyWith({
    AiConfig? config,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isInitialized,
  }) {
    return CardEnrichmentState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
