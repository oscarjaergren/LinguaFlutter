import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:lingua_flutter/features/icon_search/domain/icon_provider.dart';
import 'package:lingua_flutter/features/icon_search/data/iconify_service.dart';
import 'package:lingua_flutter/shared/domain/models/icon_model.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

@GenerateMocks([IconifyService])
import 'icon_provider_test.mocks.dart';

void main() {
  setUpAll(() {
    LoggerService.initialize();
  });

  group('IconProvider', () {
    late IconProvider provider;
    late MockIconifyService mockService;

    setUp(() {
      mockService = MockIconifyService();
      provider = IconProvider(iconifyService: mockService);

      // Default stubs
      when(mockService.searchIcons(any)).thenAnswer((_) async => <IconModel>[]);
    });

    tearDown(() {
      provider.dispose();
    });

    test('should have initial state', () {
      expect(provider.searchResults, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.searchQuery, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.selectedIcon, isNull);
    });

    test('should clear search properly', () {
      provider.selectIcon(
        const IconModel(
          id: 'test:icon',
          name: 'Test',
          set: 'test',
          category: 'Test',
          tags: [],
          svgUrl: 'test.svg',
        ),
      );

      provider.clearSearch();

      expect(provider.searchResults, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
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
      verifyNever(mockService.searchIcons(any));
    });

    test('should handle whitespace-only search query', () async {
      await provider.searchIcons('   ');

      expect(provider.searchResults, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.errorMessage, isNull);
      verifyNever(mockService.searchIcons(any));
    });

    test('should search icons via service', () async {
      const testIcons = [
        IconModel(
          id: 'mdi:home',
          name: 'Home',
          set: 'mdi',
          category: 'Actions',
          tags: ['house'],
          svgUrl: 'https://api.iconify.design/mdi:home.svg',
        ),
      ];
      when(mockService.searchIcons('home')).thenAnswer((_) async => testIcons);

      await provider.searchIcons('home');

      verify(mockService.searchIcons('home')).called(1);
      expect(provider.searchQuery, 'home');
      expect(provider.searchResults, testIcons);
      expect(provider.errorMessage, isNull);
    });

    test('should handle search error', () async {
      when(
        mockService.searchIcons('error'),
      ).thenThrow(Exception('Network error'));

      await provider.searchIcons('error');

      expect(provider.searchResults, isEmpty);
      expect(provider.errorMessage, contains('Error searching icons'));
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
  });
}
