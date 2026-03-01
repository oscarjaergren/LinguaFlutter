import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../card_management/domain/providers/card_management_notifier.dart';
import '../../../language/domain/language_notifier.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../models/exercise_preferences.dart';
import 'exercise_preferences_notifier.dart';
import 'card_filter_utils.dart';

/// Provider that calculates the number of due cards based on current filters
final dueCardsProvider = Provider<int>((ref) {
  final cardManagementState = ref.watch(cardManagementNotifierProvider);
  final exercisePrefs = ref.watch(exercisePreferencesNotifierProvider);
  final activeLanguage = ref.read(languageNotifierProvider).activeLanguage;

  return _calculateTotalDueCards(
    cardManagementState.allCards,
    exercisePrefs.preferences,
    activeLanguage,
  );
});

int _calculateTotalDueCards(
  List<CardModel> cards,
  ExercisePreferences exercisePreferences,
  String activeLanguage,
) {
  return cards.filterForPractice(exercisePreferences, activeLanguage).length;
}
