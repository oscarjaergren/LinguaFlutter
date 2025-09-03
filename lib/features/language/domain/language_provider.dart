import 'package:flutter/material.dart';

/// Provider for managing available languages and current selection
class LanguageProvider extends ChangeNotifier {
  
  // Available languages with their details
  final Map<String, Map<String, dynamic>> _availableLanguages = {
    'de': {
      'name': 'German',
      'nativeName': 'Deutsch',
      'flag': '🇩🇪',
      'color': '0xFF1976D2', // Blue
      'hasArticles': true,
      'articles': ['der', 'die', 'das'],
    },
    'es': {
      'name': 'Spanish',
      'nativeName': 'Español',
      'flag': '🇪🇸',
      'color': '0xFFF44336', // Red
      'hasArticles': false,
    },
    'fr': {
      'name': 'French',
      'nativeName': 'Français',
      'flag': '🇫🇷',
      'color': '0xFF3F51B5', // Indigo
      'hasArticles': false,
    },
    'it': {
      'name': 'Italian',
      'nativeName': 'Italiano',
      'flag': '🇮🇹',
      'color': '0xFF4CAF50', // Green
      'hasArticles': false,
    },
    'pt': {
      'name': 'Portuguese',
      'nativeName': 'Português',
      'flag': '🇵🇹',
      'color': '0xFFFF9800', // Orange
      'hasArticles': false,
    },
    'ja': {
      'name': 'Japanese',
      'nativeName': '日本語',
      'flag': '🇯🇵',
      'color': '0xFF9C27B0', // Purple
      'hasArticles': false,
    },
    'ko': {
      'name': 'Korean',
      'nativeName': '한국어',
      'flag': '🇰🇷',
      'color': '0xFF00BCD4', // Cyan
      'hasArticles': false,
    },
    'zh': {
      'name': 'Chinese',
      'nativeName': '中文',
      'flag': '🇨🇳',
      'color': '0xFFE91E63', // Pink
      'hasArticles': false,
    },
  };
  
  // Currently active language for both filtering cards and creating new cards
  String _activeLanguage = 'de';
  
  // Getters
  String get activeLanguage => _activeLanguage;
  Map<String, Map<String, dynamic>> get availableLanguages => _availableLanguages;
  
  /// Get language details by code
  Map<String, dynamic>? getLanguageDetails(String languageCode) {
    return _availableLanguages[languageCode];
  }
  
  /// Set the active language for filtering/viewing cards and creating new cards
  void setActiveLanguage(String languageCode) {
    if (_availableLanguages.containsKey(languageCode)) {
      _activeLanguage = languageCode;
      notifyListeners();
    }
  }
  
  /// Get the color for a language
  Color getLanguageColor(String languageCode) {
    final details = _availableLanguages[languageCode];
    if (details != null) {
      return Color(int.parse(details['color']));
    }
    return const Color(0xFF2196F3); // Default blue
  }
  
  /// Check if a language has articles (like German)
  bool languageHasArticles(String languageCode) {
    final details = _availableLanguages[languageCode];
    return details?['hasArticles'] ?? false;
  }
  
  /// Get articles for a language (if it has them)
  List<String> getLanguageArticles(String languageCode) {
    final details = _availableLanguages[languageCode];
    return List<String>.from(details?['articles'] ?? []);
  }
}
