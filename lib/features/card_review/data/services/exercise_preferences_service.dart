import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/exercise_preferences.dart';

/// Service for persisting exercise preferences to local storage
class ExercisePreferencesService {
  static const String _preferencesKey = 'exercise_preferences';

  /// Load exercise preferences from storage
  Future<ExercisePreferences> loadPreferences() async {
    final prefs = SharedPreferencesAsync();
    final jsonString = await prefs.getString(_preferencesKey);

    if (jsonString == null || jsonString.isEmpty) {
      return ExercisePreferences.defaults();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ExercisePreferences.fromJson(json);
    } catch (e) {
      // If parsing fails, return defaults
      return ExercisePreferences.defaults();
    }
  }

  /// Save exercise preferences to storage
  Future<void> savePreferences(ExercisePreferences preferences) async {
    final prefs = SharedPreferencesAsync();
    final jsonString = jsonEncode(preferences.toJson());
    await prefs.setString(_preferencesKey, jsonString);
  }

  /// Reset preferences to defaults
  Future<ExercisePreferences> resetToDefaults() async {
    final defaults = ExercisePreferences.defaults();
    await savePreferences(defaults);
    return defaults;
  }

  /// Clear all preferences
  Future<void> clearPreferences() async {
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_preferencesKey);
  }
}
