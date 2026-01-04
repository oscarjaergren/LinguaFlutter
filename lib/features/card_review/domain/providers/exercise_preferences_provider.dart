import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import '../../data/services/exercise_preferences_service.dart';
import '../models/exercise_preferences.dart';

/// Provider for managing exercise type preferences
class ExercisePreferencesProvider extends ChangeNotifier {
  final ExercisePreferencesService _service;

  ExercisePreferences _preferences = ExercisePreferences.defaults();
  bool _isLoading = false;
  bool _isInitialized = false;

  ExercisePreferencesProvider({ExercisePreferencesService? service})
    : _service = service ?? ExercisePreferencesService();

  /// Current exercise preferences
  ExercisePreferences get preferences => _preferences;

  /// Whether preferences are being loaded
  bool get isLoading => _isLoading;

  /// Whether preferences have been initialized
  bool get isInitialized => _isInitialized;

  /// Check if an exercise type is enabled
  bool isEnabled(ExerciseType type) => _preferences.isEnabled(type);

  /// Whether to prioritize weak exercises
  bool get prioritizeWeaknesses => _preferences.prioritizeWeaknesses;

  /// Get enabled exercise types as a list
  List<ExerciseType> get enabledTypes => _preferences.enabledTypes.toList();

  /// Initialize by loading preferences from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _preferences = await _service.loadPreferences();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle a specific exercise type
  Future<void> toggleType(ExerciseType type) async {
    _preferences = _preferences.toggleType(type);
    notifyListeners();
    await _service.savePreferences(_preferences);
  }

  /// Toggle an entire category
  Future<void> toggleCategory(
    ExerciseCategory category, {
    required bool enabled,
  }) async {
    _preferences = _preferences.toggleCategory(category, enabled: enabled);
    notifyListeners();
    await _service.savePreferences(_preferences);
  }

  /// Set whether to prioritize weaknesses
  Future<void> setPrioritizeWeaknesses(bool value) async {
    _preferences = _preferences.copyWith(prioritizeWeaknesses: value);
    notifyListeners();
    await _service.savePreferences(_preferences);
  }

  /// Set the weakness threshold
  Future<void> setWeaknessThreshold(double value) async {
    _preferences = _preferences.copyWith(weaknessThreshold: value);
    notifyListeners();
    await _service.savePreferences(_preferences);
  }

  /// Enable all exercise types
  Future<void> enableAll() async {
    _preferences = _preferences.enableAll();
    notifyListeners();
    await _service.savePreferences(_preferences);
  }

  /// Disable all exercise types
  Future<void> disableAll() async {
    _preferences = _preferences.disableAll();
    notifyListeners();
    await _service.savePreferences(_preferences);
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _preferences = await _service.resetToDefaults();
    notifyListeners();
  }

  /// Update preferences directly (for batch updates)
  Future<void> updatePreferences(ExercisePreferences newPreferences) async {
    _preferences = newPreferences;
    notifyListeners();
    await _service.savePreferences(_preferences);
  }
}
