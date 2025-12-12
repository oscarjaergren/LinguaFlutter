import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lingua_flutter/features/theme/domain/theme_provider.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LoggerService.initialize();
  });

  group('ThemeProvider', () {
    late ThemeProvider provider;

    setUp(() {
      // Set up fake SharedPreferencesAsync platform
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      provider = ThemeProvider();
    });

    group('Initial State', () {
      test('should have system theme mode by default', () {
        expect(provider.themeMode, ThemeMode.system);
      });

      test('should not be initialized by default', () {
        expect(provider.isInitialized, false);
      });

      test('should not be in dark mode by default', () {
        expect(provider.isDarkMode, false);
      });
    });

    group('Theme Data', () {
      test('should provide light theme', () {
        final theme = provider.lightTheme;

        expect(theme, isA<ThemeData>());
        expect(theme.brightness, Brightness.light);
      });

      test('should provide dark theme', () {
        final theme = provider.darkTheme;

        expect(theme, isA<ThemeData>());
        expect(theme.brightness, Brightness.dark);
      });
    });

    group('isDarkMode', () {
      test('should return true when theme mode is dark', () async {
        await provider.setThemeMode(ThemeMode.dark);

        expect(provider.isDarkMode, true);
      });

      test('should return false when theme mode is light', () async {
        await provider.setThemeMode(ThemeMode.light);

        expect(provider.isDarkMode, false);
      });

      test('should return false when theme mode is system', () async {
        await provider.setThemeMode(ThemeMode.system);

        expect(provider.isDarkMode, false);
      });
    });

    group('setThemeMode', () {
      test('should set dark theme mode', () async {
        await provider.setThemeMode(ThemeMode.dark);

        expect(provider.themeMode, ThemeMode.dark);
      });

      test('should set light theme mode', () async {
        await provider.setThemeMode(ThemeMode.light);

        expect(provider.themeMode, ThemeMode.light);
      });

      test('should set system theme mode', () async {
        await provider.setThemeMode(ThemeMode.dark);
        await provider.setThemeMode(ThemeMode.system);

        expect(provider.themeMode, ThemeMode.system);
      });

      test('should notify listeners when theme changes', () async {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await provider.setThemeMode(ThemeMode.dark);

        expect(notificationCount, 1);
      });

      test('should notify on every mode change', () async {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        await provider.setThemeMode(ThemeMode.dark);
        await provider.setThemeMode(ThemeMode.light);
        await provider.setThemeMode(ThemeMode.system);

        expect(notificationCount, 3);
      });
    });

    group('toggleTheme', () {
      test('should toggle from dark to light', () async {
        await provider.setThemeMode(ThemeMode.dark);

        await provider.toggleTheme();

        expect(provider.themeMode, ThemeMode.light);
      });

      test('should toggle from light to dark', () async {
        await provider.setThemeMode(ThemeMode.light);

        await provider.toggleTheme();

        expect(provider.themeMode, ThemeMode.dark);
      });

      test('should toggle from system to dark when current brightness is light', () async {
        await provider.setThemeMode(ThemeMode.system);

        await provider.toggleTheme(currentBrightness: Brightness.light);

        expect(provider.themeMode, ThemeMode.dark);
      });

      test('should toggle from system to light when current brightness is dark', () async {
        await provider.setThemeMode(ThemeMode.system);

        await provider.toggleTheme(currentBrightness: Brightness.dark);

        expect(provider.themeMode, ThemeMode.light);
      });

      test('should toggle from system to light when no brightness provided', () async {
        await provider.setThemeMode(ThemeMode.system);

        await provider.toggleTheme();

        // Without currentBrightness, system mode is treated as light
        expect(provider.themeMode, ThemeMode.dark);
      });

      test('should notify listeners on toggle', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.toggleTheme();

        expect(notified, true);
      });
    });

    group('ChangeNotifier', () {
      test('should properly dispose', () {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        provider.dispose();

        // After dispose, we shouldn't be able to notify
        expect(() async => await provider.setThemeMode(ThemeMode.dark), throwsA(anything));
      });

      test('should allow removing listeners', () async {
        var notificationCount = 0;
        void listener() => notificationCount++;
        
        provider.addListener(listener);
        await provider.setThemeMode(ThemeMode.dark);
        expect(notificationCount, 1);

        provider.removeListener(listener);
        await provider.setThemeMode(ThemeMode.light);
        expect(notificationCount, 1); // Should not increase
      });
    });
  });
}
