import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:lingua_flutter/features/icon_search/domain/icon_notifier.dart';
import 'package:lingua_flutter/features/icon_search/data/iconify_service.dart';
import 'package:lingua_flutter/shared/domain/models/icon_model.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

@GenerateMocks([IconifyService])
import 'icon_notifier_test.mocks.dart';

void main() {
  setUpAll(() {
    LoggerService.initialize();
  });

  group('IconNotifier', () {
    late ProviderContainer container;
    late MockIconifyService mockService;

    setUp(() {
      mockService = MockIconifyService();

      // Default stubs
      when(mockService.searchIcons(any)).thenAnswer((_) async => <IconModel>[]);
      when(mockService.dispose()).thenReturn(null);

      // Inject the mock via the static factory
      IconNotifier.serviceFactory = () => mockService;

      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      IconNotifier.serviceFactory = null;
    });

    test('should have initial state', () {
      final state = container.read(iconNotifierProvider);
      expect(state.searchResults, isEmpty);
      expect(state.isLoading, false);
      expect(state.searchQuery, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.selectedIcon, isNull);
    });

    test('should clear search properly', () {
      final notifier = container.read(iconNotifierProvider.notifier);
      notifier.selectIcon(
        const IconModel(
          id: 'test:icon',
          name: 'Test',
          set: 'test',
          category: 'Test',
          tags: [],
          svgUrl: 'test.svg',
        ),
      );

      notifier.clearSearch();

      final state = container.read(iconNotifierProvider);
      expect(state.searchResults, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, false);
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

      final notifier = container.read(iconNotifierProvider.notifier);
      notifier.selectIcon(icon);
      expect(container.read(iconNotifierProvider).selectedIcon, icon);

      notifier.clearSelection();
      expect(container.read(iconNotifierProvider).selectedIcon, isNull);
    });

    test('should handle empty search query', () async {
      final notifier = container.read(iconNotifierProvider.notifier);
      await notifier.searchIcons('');

      final state = container.read(iconNotifierProvider);
      expect(state.searchResults, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.errorMessage, isNull);
      verifyNever(mockService.searchIcons(any));
    });

    test('should handle whitespace-only search query', () async {
      final notifier = container.read(iconNotifierProvider.notifier);
      await notifier.searchIcons('   ');

      final state = container.read(iconNotifierProvider);
      expect(state.searchResults, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.errorMessage, isNull);
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

      final notifier = container.read(iconNotifierProvider.notifier);
      await notifier.searchIcons('home');

      verify(mockService.searchIcons('home')).called(1);
      final state = container.read(iconNotifierProvider);
      expect(state.searchQuery, 'home');
      expect(state.searchResults, testIcons);
      expect(state.errorMessage, isNull);
    });

    test('should handle search error', () async {
      when(
        mockService.searchIcons('error'),
      ).thenThrow(Exception('Network error'));

      final notifier = container.read(iconNotifierProvider.notifier);
      await notifier.searchIcons('error');

      final state = container.read(iconNotifierProvider);
      expect(state.searchResults, isEmpty);
      expect(state.errorMessage, contains('Error searching icons'));
    });

    test('should update state reactively on icon selection', () {
      final notifier = container.read(iconNotifierProvider.notifier);

      const icon = IconModel(
        id: 'test:icon',
        name: 'Test',
        set: 'test',
        category: 'Test',
        tags: [],
        svgUrl: 'test.svg',
      );

      expect(container.read(iconNotifierProvider).selectedIcon, isNull);

      notifier.selectIcon(icon);
      expect(container.read(iconNotifierProvider).selectedIcon, icon);

      notifier.clearSelection();
      expect(container.read(iconNotifierProvider).selectedIcon, isNull);

      notifier.clearSearch();
      expect(container.read(iconNotifierProvider).searchResults, isEmpty);
    });
  });
}
