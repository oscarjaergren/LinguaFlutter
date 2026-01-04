import 'package:shared_preferences/shared_preferences.dart';

/// Service for theme management and persistence
class ThemeService {
  static const String _themeKey = 'app_theme';
  static const String _colorSchemeKey = 'color_scheme';
  static const String _fontSizeKey = 'font_size';

  /// Get the current theme mode
  Future<AppThemeMode> getCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == themeString,
      orElse: () => AppThemeMode.system,
    );
  }

  /// Save the theme mode
  Future<void> saveTheme(AppThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }

  /// Get the current color scheme
  Future<AppColorScheme> getCurrentColorScheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorSchemeString = prefs.getString(_colorSchemeKey);
    return AppColorScheme.values.firstWhere(
      (scheme) => scheme.name == colorSchemeString,
      orElse: () => AppColorScheme.blue,
    );
  }

  /// Save the color scheme
  Future<void> saveColorScheme(AppColorScheme colorScheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, colorScheme.name);
  }

  /// Get the current font size scale
  Future<double> getCurrentFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 1.0;
  }

  /// Save the font size scale
  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
  }

  /// Reset all theme settings to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    await prefs.remove(_colorSchemeKey);
    await prefs.remove(_fontSizeKey);
  }

  /// Get all theme settings as a map
  Future<Map<String, dynamic>> getAllThemeSettings() async {
    return {
      'theme': await getCurrentTheme(),
      'colorScheme': await getCurrentColorScheme(),
      'fontSize': await getCurrentFontSize(),
    };
  }
}

/// Enum for theme modes
enum AppThemeMode { light, dark, system }

/// Enum for color schemes
enum AppColorScheme { blue, green, purple, orange, red }
