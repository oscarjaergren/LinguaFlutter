import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/services/ai/ai.dart';
import '../models/word_enrichment_result.dart';
import 'card_enrichment_state.dart';

// Build-time constant - must be const for String.fromEnvironment
const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

final cardEnrichmentNotifierProvider =
    NotifierProvider<CardEnrichmentNotifier, CardEnrichmentState>(
      () => CardEnrichmentNotifier(),
    );

class CardEnrichmentNotifier extends Notifier<CardEnrichmentState> {
  static const String configKey = 'ai_config';

  late final AiConfigStorage _storage;
  late final AiService _service;

  /// Optional factories for testing.
  static AiConfigStorage Function()? storageFactory;
  static AiService Function()? aiServiceFactory;

  @override
  CardEnrichmentState build() {
    _storage = storageFactory != null
        ? storageFactory!()
        : SharedPrefsConfigStorage();
    _service = aiServiceFactory != null ? aiServiceFactory!() : AiService();
    ref.onDispose(() => _service.dispose());
    Future.microtask(initialize);
    return const CardEnrichmentState();
  }

  Future<void> initialize() async {
    try {
      final jsonStr = await _storage.getString(configKey);
      AiConfig config = const AiConfig();
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        config = AiConfig.fromJson(json);
      }

      // Auto-load from build-time env var if not configured
      if (!config.isConfigured && _geminiApiKey.isNotEmpty) {
        config = config.copyWith(
          apiKey: _geminiApiKey,
          provider: AiProvider.gemini,
        );
      }

      state = state.copyWith(config: config, isInitialized: true);
    } catch (e) {
      debugPrint('Failed to load AI config: $e');
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> updateConfig(AiConfig newConfig) async {
    state = state.copyWith(config: newConfig);
    await _saveConfig(newConfig);
  }

  Future<void> setApiKey(String? apiKey) async {
    final newConfig = state.config.copyWith(apiKey: apiKey);
    state = state.copyWith(config: newConfig);
    await _saveConfig(newConfig);
  }

  Future<void> setProvider(AiProvider provider) async {
    final newConfig = state.config.copyWith(provider: provider, model: null);
    state = state.copyWith(config: newConfig);
    await _saveConfig(newConfig);
  }

  Future<void> setModel(String? model) async {
    final newConfig = state.config.copyWith(model: model);
    state = state.copyWith(config: newConfig);
    await _saveConfig(newConfig);
  }

  Future<WordEnrichmentResult?> enrichWord({
    required String word,
    required String language,
  }) async {
    if (!state.config.isConfigured) {
      state = state.copyWith(
        error: 'AI not configured. Please add your API key.',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final prompt = _buildPrompt(word, language);
      final response = await _service.complete(
        prompt: prompt,
        config: state.config,
      );
      final result = _parseResponse(response);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error enriching $word: $e\n$stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> _saveConfig(AiConfig config) async {
    try {
      final jsonStr = jsonEncode(config.toJson());
      await _storage.setString(configKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to save AI config: $e');
    }
  }

  String _buildPrompt(String word, String language) {
    final languageName = _getLanguageName(language);
    return '''Analyze the $languageName word "$word" and provide grammatical information.

Return a JSON object with these fields:
- "wordType": one of "verb", "noun", "adjective", "adverb", "phrase", "other"
- "translation": English translation
- "grammar": object with type-specific fields:
  - For verbs: {"isRegular": bool, "isSeparable": bool, "separablePrefix": string or null, "auxiliary": "haben" or "sein", "presentSecondPerson": string or null, "presentThirdPerson": string or null, "pastSimple": string or null, "pastParticiple": string}
  - For nouns: {"gender": "der"/"die"/"das" for German or "masculine"/"feminine"/"neuter", "plural": string, "genitive": string or null}
  - For adjectives: {"comparative": string, "superlative": string}
  - For adverbs: {"usageNote": string or null}
- "examples": array of 2-3 example sentences using the word
- "notes": optional usage notes or tips

Only return valid JSON, no markdown or explanation.''';
  }

  String _getLanguageName(String code) {
    return switch (code) {
      'de' => 'German',
      'es' => 'Spanish',
      'fr' => 'French',
      'it' => 'Italian',
      'pt' => 'Portuguese',
      'nl' => 'Dutch',
      'pl' => 'Polish',
      'ru' => 'Russian',
      'ja' => 'Japanese',
      'zh' => 'Chinese',
      'ko' => 'Korean',
      _ => code,
    };
  }

  WordEnrichmentResult _parseResponse(String response) {
    final cleaned = _cleanJsonResponse(response);
    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return WordEnrichmentResult.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }

  String _cleanJsonResponse(String response) {
    var cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}

/// Abstract storage for AI configuration
abstract class AiConfigStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

/// Implementation using SharedPreferences
class SharedPrefsConfigStorage implements AiConfigStorage {
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
