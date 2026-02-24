import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_state.freezed.dart';

@freezed
abstract class LanguageState with _$LanguageState {
  const factory LanguageState({
    @Default('de') String activeLanguage,
    @Default({
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
    })
    Map<String, Map<String, dynamic>> availableLanguages,
  }) = _LanguageState;
}
