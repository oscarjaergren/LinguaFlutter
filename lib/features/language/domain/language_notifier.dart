import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_state.dart';

final languageNotifierProvider =
    NotifierProvider<LanguageNotifier, LanguageState>(LanguageNotifier.new);

class LanguageNotifier extends Notifier<LanguageState> {
  @override
  LanguageState build() => const LanguageState();

  // Getters for convenience
  String get activeLanguage => state.activeLanguage;
  Map<String, Map<String, dynamic>> get availableLanguages =>
      state.availableLanguages;

  /// Get language details by code
  Map<String, dynamic>? getLanguageDetails(String languageCode) {
    return state.availableLanguages[languageCode];
  }

  /// Set the active language for filtering/viewing cards and creating new cards
  void setActiveLanguage(String languageCode) {
    if (state.availableLanguages.containsKey(languageCode)) {
      state = state.copyWith(activeLanguage: languageCode);
    }
  }

  /// Get the color for a language
  Color getLanguageColor(String languageCode) {
    final details = state.availableLanguages[languageCode];
    if (details != null) {
      return Color(int.parse(details['color']));
    }
    return const Color(0xFF2196F3); // Default blue
  }

  /// Check if a language has articles (like German)
  bool languageHasArticles(String languageCode) {
    final details = state.availableLanguages[languageCode];
    return details?['hasArticles'] ?? false;
  }

  /// Get articles for a language (if it has them)
  List<String> getLanguageArticles(String languageCode) {
    final details = state.availableLanguages[languageCode];
    return List<String>.from(details?['articles'] ?? []);
  }
}
