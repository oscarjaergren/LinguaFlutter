import '../models/card_model.dart';
import '../models/exercise_type.dart';
import '../../../features/card_review/domain/models/exercise_preferences.dart';

/// Extension methods for CardModel to provide common card-related operations
extension CardModelExtensions on CardModel {
  /// Check if this card has any due exercises based on user preferences.
  ///
  /// This method checks all implemented exercise types that are enabled in the user's
  /// preferences and returns true if any of them are due for review.
  ///
  /// Parameters:
  /// - [preferences]: The user's exercise preferences to filter by
  ///
  /// Returns:
  /// - true if the card has at least one due exercise that matches the preferences
  /// - false if no exercises are due or no matching exercises are found
  bool isDueForAnyExercise(ExercisePreferences preferences) {
    final enabledTypes = ExerciseType.values.where(
      (t) => t.isImplemented && preferences.isEnabled(t),
    );

    return enabledTypes.any((type) => isExerciseDue(type));
  }
}
