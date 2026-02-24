import '../models/exercise_preferences.dart';

/// Immutable state for exercise preferences
class ExercisePreferencesState {
  final ExercisePreferences preferences;
  final bool isLoading;
  final bool isInitialized;

  const ExercisePreferencesState({
    ExercisePreferences? preferences,
    this.isLoading = false,
    this.isInitialized = false,
  }) : preferences = preferences ?? const _DefaultPreferences();

  ExercisePreferencesState copyWith({
    ExercisePreferences? preferences,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return ExercisePreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Const placeholder that resolves defaults lazily
class _DefaultPreferences implements ExercisePreferences {
  const _DefaultPreferences();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Delegate to a real instance
    return ExercisePreferences.defaults();
  }
}
