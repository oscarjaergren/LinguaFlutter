import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/card_model_extensions.dart';
import '../models/exercise_preferences.dart';

/// Extension methods for CardModel and `List<CardModel>` to provide filtering utilities
extension CardFilterExtensions on CardModel {
  /// Filters cards based on exercise preferences, language, and archived status
  /// This is the shared filtering logic used across due cards calculation and practice sessions
  static List<CardModel> filterForPractice(
    List<CardModel> cards,
    ExercisePreferences exercisePreferences,
    String activeLanguage,
  ) {
    return cards
        .where((c) => c.isDueForAnyExercise(exercisePreferences))
        .where((c) => !c.isArchived)
        .where((c) => activeLanguage.isEmpty || c.language == activeLanguage)
        .toList();
  }

  /// Checks if there are enough cards for multiple choice exercises
  /// Returns true if there are at least 4 cards (1 correct + 3 wrong answers)
  static bool hasEnoughForMultipleChoice(List<CardModel> cards) {
    return cards.length >= 4;
  }

  /// Filters cards that can be used as wrong answers for multiple choice
  /// Excludes the current card and ensures back text is different and not empty
  List<CardModel> filterWrongAnswerCards(List<CardModel> allCards) {
    return allCards
        .where((c) => c.id != id && c.backText != backText)
        .where((c) => c.backText.isNotEmpty)
        .toList();
  }
}

/// Extension on `List<CardModel>` for collection-level operations
extension CardListExtensions on List<CardModel> {
  /// Filters this list of cards based on exercise preferences, language, and archived status
  List<CardModel> filterForPractice(
    ExercisePreferences exercisePreferences,
    String activeLanguage,
  ) {
    return CardFilterExtensions.filterForPractice(
      this,
      exercisePreferences,
      activeLanguage,
    );
  }

  /// Checks if this list has enough cards for multiple choice exercises
  bool hasEnoughForMultipleChoice() {
    return CardFilterExtensions.hasEnoughForMultipleChoice(this);
  }
}
