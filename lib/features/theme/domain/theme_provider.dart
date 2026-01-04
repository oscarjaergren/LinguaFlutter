import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/logger_service.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  ThemeMode _themeMode;
  bool _isInitialized = false;

  ThemeProvider() : _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider by loading saved theme from storage
  Future<void> initialize() async {
    final theme = await _prefs.getString(_themeModeKey);
    LoggerService.debug('ThemeProvider: loaded theme from storage: "$theme"');
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    LoggerService.debug('ThemeProvider: initialized with mode: $_themeMode');
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    LoggerService.debug('ThemeProvider: setting mode to $mode');
    _themeMode = mode;
    notifyListeners();
    switch (mode) {
      case ThemeMode.dark:
        await _prefs.setString(_themeModeKey, 'dark');
        LoggerService.debug('ThemeProvider: saved "dark" to storage');
        break;
      case ThemeMode.light:
        await _prefs.setString(_themeModeKey, 'light');
        LoggerService.debug('ThemeProvider: saved "light" to storage');
        break;
      case ThemeMode.system:
        await _prefs.remove(_themeModeKey);
        LoggerService.debug(
          'ThemeProvider: removed theme from storage (system)',
        );
        break;
    }
  }

  /// Toggle between light and dark mode
  /// Pass the current visual brightness to handle ThemeMode.system correctly
  Future<void> toggleTheme({Brightness? currentBrightness}) async {
    final ThemeMode newMode;

    if (_themeMode == ThemeMode.system && currentBrightness != null) {
      // When in system mode, toggle based on what's actually displayed
      newMode = currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    } else {
      // Otherwise toggle based on stored mode
      newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }

    await setThemeMode(newMode);
  }

  /// Whether dark mode is currently active
  bool get isDarkMode => _themeMode == ThemeMode.dark;

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
