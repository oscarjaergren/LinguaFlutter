import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences prefs;
  static const String _themeModeKey = 'themeMode';

  ThemeMode _themeMode;

  ThemeProvider({required this.prefs}) : _themeMode = _loadThemeMode(prefs);

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final theme = prefs.getString(_themeModeKey);
    if (theme == 'dark') return ThemeMode.dark;
    if (theme == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    switch (mode) {
      case ThemeMode.dark:
        await prefs.setString(_themeModeKey, 'dark');
        break;
      case ThemeMode.light:
        await prefs.setString(_themeModeKey, 'light');
        break;
      case ThemeMode.system:
        await prefs.remove(_themeModeKey);
        break;
    }
  }

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
