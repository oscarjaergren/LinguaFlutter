import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/providers/icon_provider.dart';
import 'package:lingua_flutter/models/icon_model.dart';

void main() {
  group('IconProvider', () {
    late IconProvider provider;

    setUp(() {
      provider = IconProvider();
      // Note: We would need to modify IconProvider to accept a custom service
      // for proper testing. For now, these tests demonstrate the testing approach.
    });

    test('should have initial state', () {
      expect(provider.searchResults, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.searchQuery, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.selectedIcon, isNull);
    });

    test('should clear search properly', () {
      // Set some initial state
      provider.selectIcon(const IconModel(
        id: 'test:icon',
        name: 'Test',
        set: 'test',
        category: 'Test',
        tags: [],
        svgUrl: 'test.svg',
      ));

      provider.clearSearch();

      expect(provider.searchResults, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
      // Note: clearSearch doesn't clear selectedIcon, which is correct behavior
    });

    test('should select and clear icon', () {
      const icon = IconModel(
        id: 'mdi:home',
        name: 'Home',
        set: 'mdi',
        category: 'Actions',
        tags: ['house'],
        svgUrl: 'https://api.iconify.design/mdi:home.svg',
      );

      provider.selectIcon(icon);
      expect(provider.selectedIcon, icon);

      provider.clearSelection();
      expect(provider.selectedIcon, isNull);
    });

    test('should handle empty search query', () async {
      await provider.searchIcons('');
      
      expect(provider.searchResults, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('should handle whitespace-only search query', () async {
      await provider.searchIcons('   ');
      
      expect(provider.searchResults, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    // Note: The following tests would require dependency injection
    // to properly test the async behavior with mocked services
    
    test('should update search query when searching', () async {
      // This test demonstrates how we'd test if we had proper DI
      const query = 'home';
      await provider.searchIcons(query);
      
      expect(provider.searchQuery, query);
    });

    test('should notify listeners when state changes', () {
      var notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      const icon = IconModel(
        id: 'test:icon',
        name: 'Test',
        set: 'test',
        category: 'Test',
        tags: [],
        svgUrl: 'test.svg',
      );

      provider.selectIcon(icon);
      expect(notificationCount, 1);

      provider.clearSelection();
      expect(notificationCount, 2);

      provider.clearSearch();
      expect(notificationCount, 3);
    });

    tearDown(() {
      provider.dispose();
    });
  });
}
