import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/language/domain/language_provider.dart';

void main() {
  group('LanguageProvider', () {
    late LanguageProvider provider;

    setUp(() {
      provider = LanguageProvider();
    });

    test('should have German as default active language', () {
      expect(provider.activeLanguage, 'de');
    });

    test('should have available languages', () {
      expect(provider.availableLanguages, isNotEmpty);
      expect(provider.availableLanguages.containsKey('de'), true);
      expect(provider.availableLanguages.containsKey('es'), true);
      expect(provider.availableLanguages.containsKey('fr'), true);
    });

    test('should set active language', () {
      provider.setActiveLanguage('es');
      expect(provider.activeLanguage, 'es');

      provider.setActiveLanguage('fr');
      expect(provider.activeLanguage, 'fr');
    });

    test('should not set invalid language', () {
      provider.setActiveLanguage('invalid');
      expect(provider.activeLanguage, 'de'); // Should remain default
    });

    test('should get language details', () {
      final details = provider.getLanguageDetails('de');
      
      expect(details, isNotNull);
      expect(details!['name'], 'German');
      expect(details['nativeName'], 'Deutsch');
      expect(details['flag'], '🇩🇪');
      expect(details['hasArticles'], true);
    });

    test('should return null for invalid language details', () {
      final details = provider.getLanguageDetails('invalid');
      expect(details, isNull);
    });

    test('should get language color', () {
      final color = provider.getLanguageColor('de');
      expect(color, isA<Color>());
    });

    test('should return default color for invalid language', () {
      final color = provider.getLanguageColor('invalid');
      expect(color, const Color(0xFF2196F3));
    });

    test('should check if language has articles', () {
      expect(provider.languageHasArticles('de'), true);
      expect(provider.languageHasArticles('es'), false);
      expect(provider.languageHasArticles('invalid'), false);
    });

    test('should get language articles', () {
      final articles = provider.getLanguageArticles('de');
      expect(articles, ['der', 'die', 'das']);

      final noArticles = provider.getLanguageArticles('es');
      expect(noArticles, isEmpty);
    });

    test('should notify listeners when language changes', () {
      var notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      provider.setActiveLanguage('es');
      expect(notificationCount, 1);

      provider.setActiveLanguage('fr');
      expect(notificationCount, 2);
    });

    test('should not notify listeners for invalid language', () {
      var notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      provider.setActiveLanguage('invalid');
      expect(notificationCount, 0);
    });
  });
}
