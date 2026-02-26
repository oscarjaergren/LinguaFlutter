import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_notifier.dart';
import 'package:lingua_flutter/features/card_management/domain/providers/card_management_state.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/exercise_preferences_state.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_notifier.dart';
import 'package:lingua_flutter/features/card_review/domain/providers/practice_session_state.dart';
import 'package:lingua_flutter/features/language/domain/language_notifier.dart';
import 'package:lingua_flutter/features/language/domain/language_state.dart';
import 'package:lingua_flutter/shared/domain/models/card_model.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

class _TestCardManagementNotifier extends CardManagementNotifier {
  _TestCardManagementNotifier(this.cards);

  final List<CardModel> cards;
  CardModel? lastUpdatedCard;

  @override
  CardManagementState build() => CardManagementState(allCards: cards);

  @override
  Future<void> updateCard(CardModel card) async {
    lastUpdatedCard = card;
    state = state.copyWith(
      allCards: [
        for (final existing in state.allCards)
          if (existing.id == card.id) card else existing,
      ],
    );
  }
}

class _TestExercisePreferencesNotifier extends ExercisePreferencesNotifier {
  _TestExercisePreferencesNotifier(this.initialPreferences);

  final ExercisePreferences initialPreferences;

  @override
  ExercisePreferencesState build() => ExercisePreferencesState(
    preferences: initialPreferences,
    isInitialized: true,
  );
}

class _TestLanguageNotifier extends LanguageNotifier {
  _TestLanguageNotifier(this.activeLanguageCode);

  final String activeLanguageCode;

  @override
  LanguageState build() => LanguageState(activeLanguage: activeLanguageCode);
}

void main() {
  group('PracticeSessionNotifier Lifecycle', () {
    late ProviderContainer container;
    late _TestCardManagementNotifier testCardManagement;
    late _TestExercisePreferencesNotifier testExercisePrefs;
    late _TestLanguageNotifier testLanguage;
    late List<CardModel> testCards;

    setUp(() {
      testCards = [
        CardModel.create(frontText: 'Hund', backText: 'dog', language: 'de'),
        CardModel.create(frontText: 'Katze', backText: 'cat', language: 'de'),
      ];

      testCardManagement = _TestCardManagementNotifier(testCards);
      testExercisePrefs = _TestExercisePreferencesNotifier(
        const ExercisePreferences(
          enabledTypes: {ExerciseType.reverseTranslation},
        ),
      );
      testLanguage = _TestLanguageNotifier('de');

      container = ProviderContainer(
        overrides: [
          cardManagementNotifierProvider.overrideWith(() => testCardManagement),
          exercisePreferencesNotifierProvider.overrideWith(
            () => testExercisePrefs,
          ),
          languageNotifierProvider.overrideWith(() => testLanguage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with empty default state', () {
      final state = container.read(practiceSessionNotifierProvider);

      expect(state, const PracticeSessionState());
      expect(state.isSessionActive, isFalse);
      expect(state.sessionQueue, isEmpty);
      expect(state.currentIndex, 0);
    });

    test('startSession initializes active session and start time', () {
      final notifier = container.read(practiceSessionNotifierProvider.notifier);

      notifier.startSession(cards: testCards);

      final state = container.read(practiceSessionNotifierProvider);
      expect(state.isSessionActive, isTrue);
      expect(state.sessionQueue, isNotEmpty);
      expect(state.currentIndex, 0);
      expect(state.sessionStartTime, isNotNull);
    });

    test('startSession remains inactive when no cards are due', () {
      final notifier = container.read(practiceSessionNotifierProvider.notifier);
      final notDueCards = [
        CardModel.create(
          frontText: 'Baum',
          backText: 'tree',
          language: 'de',
        ).copyWith(nextReview: DateTime.now().add(const Duration(days: 1))),
      ];

      notifier.startSession(cards: notDueCards);

      final state = container.read(practiceSessionNotifierProvider);
      expect(state.isSessionActive, isFalse);
      expect(state.sessionQueue, isEmpty);
    });

    test('endSession clears queue and resets index', () {
      final notifier = container.read(practiceSessionNotifierProvider.notifier);
      notifier.startSession(cards: testCards);

      notifier.endSession();

      final state = container.read(practiceSessionNotifierProvider);
      expect(state.isSessionActive, isFalse);
      expect(state.isSessionComplete, isFalse);
      expect(state.sessionQueue, isEmpty);
      expect(state.currentIndex, 0);
    });

    test(
      'confirmAnswerAndAdvance updates progress and completes session',
      () async {
        final notifier = container.read(
          practiceSessionNotifierProvider.notifier,
        );
        notifier.startSession(cards: testCards);

        notifier.confirmAnswerAndAdvance(markedCorrect: true);
        await Future<void>.delayed(Duration.zero);

        var state = container.read(practiceSessionNotifierProvider);
        expect(state.isSessionActive, isTrue);
        expect(state.correctCount, 1);
        expect(state.progress, 0.5);

        notifier.confirmAnswerAndAdvance(markedCorrect: false);
        await Future<void>.delayed(Duration.zero);

        state = container.read(practiceSessionNotifierProvider);
        expect(state.isSessionActive, isFalse);
        expect(state.isSessionComplete, isTrue);
        expect(state.correctCount, 1);
        expect(state.incorrectCount, 1);
        expect(state.progress, 1.0);
      },
    );

    test(
      'removeCardFromQueue ends session when current/only card is removed',
      () async {
        final notifier = container.read(
          practiceSessionNotifierProvider.notifier,
        );
        final singleCard = [testCards.first];
        notifier.startSession(cards: singleCard);

        await notifier.removeCardFromQueue(singleCard.first.id);

        final state = container.read(practiceSessionNotifierProvider);
        expect(state.sessionQueue, isEmpty);
        expect(state.isSessionActive, isFalse);
        expect(state.isSessionComplete, isTrue);
        expect(state.incorrectCount, 1);
      },
    );
  });
}
