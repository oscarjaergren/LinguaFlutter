import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/services/ai/ai.dart';
import '../models/word_enrichment_result.dart';

// Build-time constant - must be const for String.fromEnvironment
const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Abstract interface for config storage (for testability)
abstract class AiConfigStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

/// Default implementation using SharedPreferencesAsync
class SharedPrefsConfigStorage implements AiConfigStorage {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}

/// Provider for managing AI-powered card enrichment
class CardEnrichmentProvider extends ChangeNotifier {
  static const String configKey = 'ai_config';

  final AiConfigStorage _storage;
  final AiService _service;

  AiConfig _config = const AiConfig();
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  CardEnrichmentProvider({AiConfigStorage? storage, AiService? service})
    : _storage = storage ?? SharedPrefsConfigStorage(),
      _service = service ?? AiService();

  AiConfig get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isConfigured => _config.isConfigured;

  /// Initialize by loading saved configuration or from .env
  Future<void> initialize() async {
    try {
      final jsonStr = await _storage.getString(configKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _config = AiConfig.fromJson(json);
      }
    } catch (e) {
      debugPrint('Failed to load AI config: $e');
    }

    // Auto-load from build-time env var if not configured
    if (!_config.isConfigured && _geminiApiKey.isNotEmpty) {
      _config = _config.copyWith(
        apiKey: _geminiApiKey,
        provider: AiProvider.gemini,
      );
      debugPrint('Loaded Gemini API key from environment');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Update the AI configuration
  Future<void> updateConfig(AiConfig newConfig) async {
    _config = newConfig;
    await _saveConfig();
    notifyListeners();
  }

  /// Set the API key
  Future<void> setApiKey(String? apiKey) async {
    _config = _config.copyWith(apiKey: apiKey);
    await _saveConfig();
    notifyListeners();
  }

  /// Set the AI provider
  Future<void> setProvider(AiProvider provider) async {
    _config = _config.copyWith(provider: provider, model: null);
    await _saveConfig();
    notifyListeners();
  }

  /// Set a custom model
  Future<void> setModel(String? model) async {
    _config = _config.copyWith(model: model);
    await _saveConfig();
    notifyListeners();
  }

  /// Enrich a word with AI-generated grammar data
  Future<WordEnrichmentResult?> enrichWord({
    required String word,
    required String language,
  }) async {
    if (!_config.isConfigured) {
      _error = 'AI not configured. Please add your API key.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prompt = _buildPrompt(word, language);
      debugPrint('Enriching word: $word');
      final response = await _service.complete(prompt: prompt, config: _config);
      debugPrint(
        'AI response for $word: ${response.substring(0, response.length.clamp(0, 200))}...',
      );

      final result = _parseResponse(response);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e, stackTrace) {
      _isLoading = false;
      _error = e.toString();
      debugPrint('Error enriching $word: $e');
      debugPrint('Stack trace: $stackTrace');
      notifyListeners();
      return null;
    }
  }

  String _buildPrompt(String word, String language) {
    final languageName = _getLanguageName(language);

    return '''Analyze the $languageName word "$word" and provide grammatical information.

Return a JSON object with these fields:
- "wordType": one of "verb", "noun", "adjective", "adverb", "phrase", "other"
- "translation": English translation
- "grammar": object with type-specific fields:
  - For verbs: {"isRegular": bool, "isSeparable": bool, "separablePrefix": string or null, "auxiliary": "haben" or "sein", "presentDu": string or null, "presentEr": string or null, "pastSimple": string or null, "pastParticiple": string}
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

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _saveConfig() async {
    try {
      final jsonStr = jsonEncode(_config.toJson());
      await _storage.setString(configKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to save AI config: $e');
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
