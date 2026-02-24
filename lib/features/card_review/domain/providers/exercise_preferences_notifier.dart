import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/exercise_preferences_service.dart';
import '../models/exercise_preferences.dart';
import '../../../../shared/domain/models/exercise_type.dart';
import 'exercise_preferences_state.dart';

final exercisePreferencesNotifierProvider =
    NotifierProvider<ExercisePreferencesNotifier, ExercisePreferencesState>(
      () => ExercisePreferencesNotifier(),
    );

class ExercisePreferencesNotifier extends Notifier<ExercisePreferencesState> {
  late final ExercisePreferencesService _service;

  /// Optional factory for testing.
  static ExercisePreferencesService Function()? serviceFactory;

  @override
  ExercisePreferencesState build() {
    _service = serviceFactory != null
        ? serviceFactory!()
        : ExercisePreferencesService();
    // Initialize asynchronously after build completes
    Future.microtask(initialize);
    return const ExercisePreferencesState();
  }

  Future<void> initialize() async {
    if (state.isInitialized) return;
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await _service.loadPreferences();
      state = state.copyWith(
        preferences: prefs,
        isInitialized: true,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, isInitialized: true);
    }
  }

  Future<void> toggleType(ExerciseType type) async {
    final newPrefs = state.preferences.toggleType(type);
    state = state.copyWith(preferences: newPrefs);
    await _service.savePreferences(newPrefs);
  }

  Future<void> toggleCategory(
    ExerciseCategory category, {
    required bool enabled,
  }) async {
    final newPrefs = state.preferences.toggleCategory(
      category,
      enabled: enabled,
    );
    state = state.copyWith(preferences: newPrefs);
    await _service.savePreferences(newPrefs);
  }

  Future<void> setPrioritizeWeaknesses(bool value) async {
    final newPrefs = state.preferences.copyWith(prioritizeWeaknesses: value);
    state = state.copyWith(preferences: newPrefs);
    await _service.savePreferences(newPrefs);
  }

  Future<void> setWeaknessThreshold(double value) async {
    final newPrefs = state.preferences.copyWith(weaknessThreshold: value);
    state = state.copyWith(preferences: newPrefs);
    await _service.savePreferences(newPrefs);
  }

  Future<void> enableAll() async {
    final newPrefs = state.preferences.enableAll();
    state = state.copyWith(preferences: newPrefs);
    await _service.savePreferences(newPrefs);
  }

  Future<void> disableAll() async {
    final newPrefs = state.preferences.disableAll();
    state = state.copyWith(preferences: newPrefs);
    await _service.savePreferences(newPrefs);
  }

  Future<void> resetToDefaults() async {
    final newPrefs = await _service.resetToDefaults();
    state = state.copyWith(preferences: newPrefs);
  }

  Future<void> updatePreferences(ExercisePreferences newPreferences) async {
    state = state.copyWith(preferences: newPreferences);
    await _service.savePreferences(newPreferences);
  }
}
