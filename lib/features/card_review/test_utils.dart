import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_state.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/features/language/domain/language_notifier.dart';
import 'package:lingua_flutter/features/language/domain/language_state.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_score.dart';

/// Test utilities for card review feature tests
class TestCardManagementNotifier extends CardManagementNotifier {
  TestCardManagementNotifier(this.cards);

  final List<CardModel> cards;

  @override
  CardManagementState build() =>
      CardManagementState(allCards: cards, filteredCards: cards);
}

class TestExercisePreferencesNotifier extends ExercisePreferencesNotifier {
  @override
  ExercisePreferencesState build() => ExercisePreferencesState(
    preferences: ExercisePreferences.defaults(),
    isInitialized: true,
  );
}

class TestPracticeSessionNotifier extends PracticeSessionNotifier {
  TestPracticeSessionNotifier({
    int runCorrectCount = 0,
    int runIncorrectCount = 0,
  }) : _runCorrectCount = runCorrectCount,
       _runIncorrectCount = runIncorrectCount;

  final int _runCorrectCount;
  final int _runIncorrectCount;

  @override
  PracticeSessionState build() => PracticeSessionState(
    runCorrectCount: _runCorrectCount,
    runIncorrectCount: _runIncorrectCount,
    sessionStartTime: null,
  );
}

class TestLanguageNotifier extends LanguageNotifier {
  TestLanguageNotifier(this.activeLanguageCode);

  final String activeLanguageCode;

  @override
  LanguageState build() => LanguageState(activeLanguage: activeLanguageCode);
}

/// Creates a ProviderContainer with common test overrides
ProviderContainer createTestContainer({
  List<CardModel>? cards,
  String? activeLanguage,
  int correctCount = 0,
  int incorrectCount = 0,
}) {
  return ProviderContainer(
    overrides: [
      cardManagementNotifierProvider.overrideWith(
        () => TestCardManagementNotifier(cards ?? []),
      ),
      exercisePreferencesNotifierProvider.overrideWith(
        () => TestExercisePreferencesNotifier(),
      ),
      practiceSessionNotifierProvider.overrideWith(
        () => TestPracticeSessionNotifier(
          runCorrectCount: correctCount,
          runIncorrectCount: incorrectCount,
        ),
      ),
      languageNotifierProvider.overrideWith(
        () => TestLanguageNotifier(activeLanguage ?? ''),
      ),
    ],
  );
}

/// Creates test cards with different due states
List<CardModel> createTestCards({
  int count = 2,
  String language = 'de',
  bool makeDue = true,
  DateTime? baseTime,
}) {
  final cards = <CardModel>[];
  final now = baseTime ?? DateTime.now();

  for (int i = 0; i < count; i++) {
    final card = CardModel.create(
      frontText: 'Card ${i + 1}',
      backText: 'Translation ${i + 1}',
      language: language,
    );

    // Make cards actually due by setting exercise scores with past due dates
    if (makeDue) {
      final cardWithScores = card.copyWith(
        exerciseScores: {
          ExerciseType.readingRecognition: ExerciseScore(
            type: ExerciseType.readingRecognition,
            correctCount: 0,
            incorrectCount: 0,
            lastPracticed: now.subtract(const Duration(days: 1)),
            nextReview: now.subtract(const Duration(hours: 1)), // Past due
          ),
        },
      );
      cards.add(cardWithScores);
    } else {
      cards.add(card);
    }
  }

  return cards;
}
