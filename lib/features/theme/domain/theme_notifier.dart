import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/logger_service.dart';
import 'theme_state.dart';

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeState> {
  static const String _themeModeKey = 'themeMode';
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  ThemeState build() {
    return const ThemeState();
  }

  Future<void> initialize() async {
    final theme = await _prefs.getString(_themeModeKey);
    LoggerService.debug('ThemeNotifier: loaded theme from storage: "$theme"');
    
    ThemeMode mode;
    if (theme == 'dark') {
      mode = ThemeMode.dark;
    } else if (theme == 'light') {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.system;
    }
    
    LoggerService.debug('ThemeNotifier: initialized with mode: $mode');
    state = state.copyWith(
      themeMode: mode,
      isInitialized: true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    LoggerService.debug('ThemeNotifier: setting mode to $mode');
    state = state.copyWith(themeMode: mode);
    
    switch (mode) {
      case ThemeMode.dark:
        await _prefs.setString(_themeModeKey, 'dark');
        LoggerService.debug('ThemeNotifier: saved "dark" to storage');
        break;
      case ThemeMode.light:
        await _prefs.setString(_themeModeKey, 'light');
        LoggerService.debug('ThemeNotifier: saved "light" to storage');
        break;
      case ThemeMode.system:
        await _prefs.remove(_themeModeKey);
        LoggerService.debug('ThemeNotifier: removed theme from storage (system)');
        break;
    }
  }

  Future<void> toggleTheme({Brightness? currentBrightness}) async {
    final ThemeMode newMode;

    if (state.themeMode == ThemeMode.system && currentBrightness != null) {
      // When in system mode, toggle based on what's actually displayed
      newMode = currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    } else {
      // Otherwise toggle based on stored mode
      newMode = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }

    await setThemeMode(newMode);
  }

  bool get isDarkMode => state.themeMode == ThemeMode.dark;

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
