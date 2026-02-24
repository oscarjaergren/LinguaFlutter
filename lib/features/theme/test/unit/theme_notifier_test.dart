import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lingua_flutter/features/theme/domain/theme_notifier.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LoggerService.initialize();
  });

  group('ThemeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have system theme mode by default', () {
        final state = container.read(themeNotifierProvider);
        expect(state.themeMode, ThemeMode.system);
      });

      test('should not be initialized by default', () {
        final state = container.read(themeNotifierProvider);
        expect(state.isInitialized, false);
      });

      test('should not be in dark mode by default', () {
        final notifier = container.read(themeNotifierProvider.notifier);
        expect(notifier.isDarkMode, false);
      });
    });

    group('Theme Data', () {
      test('should provide light theme', () {
        final notifier = container.read(themeNotifierProvider.notifier);
        final theme = notifier.lightTheme;

        expect(theme, isA<ThemeData>());
        expect(theme.brightness, Brightness.light);
      });

      test('should provide dark theme', () {
        final notifier = container.read(themeNotifierProvider.notifier);
        final theme = notifier.darkTheme;

        expect(theme, isA<ThemeData>());
        expect(theme.brightness, Brightness.dark);
      });
    });

    group('isDarkMode', () {
      test('should return true when theme mode is dark', () async {
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        expect(container.read(themeNotifierProvider.notifier).isDarkMode, true);
      });

      test('should return false when theme mode is light', () async {
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.light);
        expect(
          container.read(themeNotifierProvider.notifier).isDarkMode,
          false,
        );
      });

      test('should return false when theme mode is system', () async {
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.system);
        expect(
          container.read(themeNotifierProvider.notifier).isDarkMode,
          false,
        );
      });
    });

    group('setThemeMode', () {
      test('should set dark theme mode', () async {
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        expect(container.read(themeNotifierProvider).themeMode, ThemeMode.dark);
      });

      test('should set light theme mode', () async {
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.light);
        expect(
          container.read(themeNotifierProvider).themeMode,
          ThemeMode.light,
        );
      });

      test('should set system theme mode', () async {
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.system);
        expect(
          container.read(themeNotifierProvider).themeMode,
          ThemeMode.system,
        );
      });

      test('should notify listeners when theme changes', () async {
        var notificationCount = 0;
        container.listen(themeNotifierProvider, (_, __) => notificationCount++);

        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        expect(notificationCount, 1);
      });

      test('should notify on every mode change', () async {
        var notificationCount = 0;
        container.listen(themeNotifierProvider, (_, __) => notificationCount++);

        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.light);
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.system);

        expect(notificationCount, 3);
      });
    });

    group('toggleTheme', () {
      test('should toggle from dark to light', () async {
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await container.read(themeNotifierProvider.notifier).toggleTheme();
        expect(
          container.read(themeNotifierProvider).themeMode,
          ThemeMode.light,
        );
      });

      test('should toggle from light to dark', () async {
        await container
            .read(themeNotifierProvider.notifier)
            .setThemeMode(ThemeMode.light);
        await container.read(themeNotifierProvider.notifier).toggleTheme();
        expect(container.read(themeNotifierProvider).themeMode, ThemeMode.dark);
      });

      test(
        'should toggle from system to dark when current brightness is light',
        () async {
          await container
              .read(themeNotifierProvider.notifier)
              .setThemeMode(ThemeMode.system);
          await container
              .read(themeNotifierProvider.notifier)
              .toggleTheme(currentBrightness: Brightness.light);
          expect(
            container.read(themeNotifierProvider).themeMode,
            ThemeMode.dark,
          );
        },
      );

      test(
        'should toggle from system to light when current brightness is dark',
        () async {
          await container
              .read(themeNotifierProvider.notifier)
              .setThemeMode(ThemeMode.system);
          await container
              .read(themeNotifierProvider.notifier)
              .toggleTheme(currentBrightness: Brightness.dark);
          expect(
            container.read(themeNotifierProvider).themeMode,
            ThemeMode.light,
          );
        },
      );

      test(
        'should toggle from system to light when no brightness provided',
        () async {
          await container
              .read(themeNotifierProvider.notifier)
              .setThemeMode(ThemeMode.system);
          await container.read(themeNotifierProvider.notifier).toggleTheme();
          // Without currentBrightness, system mode is treated as light, toggles to dark
          expect(
            container.read(themeNotifierProvider).themeMode,
            ThemeMode.dark,
          );
        },
      );
    });
  });
}
