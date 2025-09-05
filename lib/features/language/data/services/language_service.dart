import 'package:shared_preferences/shared_preferences.dart';

/// Service for language management and persistence
class LanguageService {
  static const String _activeLanguageKey = 'active_language';
  static const String _supportedLanguagesKey = 'supported_languages';
  
  /// Default supported languages
  static const List<String> _defaultLanguages = [
    'en', // English
    'de', // German
    'es', // Spanish
    'fr', // French
    'it', // Italian
    'pt', // Portuguese
    'nl', // Dutch
    'sv', // Swedish
    'no', // Norwegian
    'da', // Danish
  ];

  /// Get the currently active language
  Future<String> getActiveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeLanguageKey) ?? '';
  }

  /// Set the active language
  Future<void> setActiveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeLanguageKey, languageCode);
  }

  /// Get supported languages
  Future<List<String>> getSupportedLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_supportedLanguagesKey);
    return saved ?? List.from(_defaultLanguages);
  }

  /// Add a new supported language
  Future<void> addSupportedLanguage(String languageCode) async {
    final languages = await getSupportedLanguages();
    if (!languages.contains(languageCode)) {
      languages.add(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_supportedLanguagesKey, languages);
    }
  }

  /// Remove a supported language
  Future<void> removeSupportedLanguage(String languageCode) async {
    final languages = await getSupportedLanguages();
    if (languages.contains(languageCode)) {
      languages.remove(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_supportedLanguagesKey, languages);
    }
  }

  /// Get language display name
  String getLanguageDisplayName(String languageCode) {
    return switch (languageCode) {
      'en' => 'English',
      'de' => 'Deutsch',
      'es' => 'Español',
      'fr' => 'Français',
      'it' => 'Italiano',
      'pt' => 'Português',
      'nl' => 'Nederlands',
      'sv' => 'Svenska',
      'no' => 'Norsk',
      'da' => 'Dansk',
      _ => languageCode.toUpperCase(),
    };
  }

  /// Get language flag emoji
  String getLanguageFlag(String languageCode) {
    return switch (languageCode) {
      'en' => '🇺🇸',
      'de' => '🇩🇪',
      'es' => '🇪🇸',
      'fr' => '🇫🇷',
      'it' => '🇮🇹',
      'pt' => '🇵🇹',
      'nl' => '🇳🇱',
      'sv' => '🇸🇪',
      'no' => '🇳🇴',
      'da' => '🇩🇰',
      _ => '🌐',
    };
  }

  /// Validate language code format
  bool isValidLanguageCode(String languageCode) {
    return RegExp(r'^[a-z]{2}$').hasMatch(languageCode);
  }

  /// Reset to default languages
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeLanguageKey);
    await prefs.remove(_supportedLanguagesKey);
  }

  /// Get language statistics
  Future<Map<String, dynamic>> getLanguageStats() async {
    return {
      'activeLanguage': await getActiveLanguage(),
      'supportedLanguages': await getSupportedLanguages(),
      'totalSupported': (await getSupportedLanguages()).length,
    };
  }
}
