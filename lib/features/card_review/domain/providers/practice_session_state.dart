import 'package:freezed_annotation/freezed_annotation.dart';
import 'practice_session_types.dart';

part 'practice_session_state.freezed.dart';

@freezed
sealed class PracticeSessionState with _$PracticeSessionState {
  const factory PracticeSessionState({
    /// The current practice item being shown (card + exercise type).
    PracticeItem? currentItem,

    /// State of the current exercise answer (pending/answered).
    @Default(AnswerState.pending) AnswerState answerState,

    /// Whether the most recently checked answer was correct.
    bool? currentAnswerCorrect,

    /// Multiple choice options for the current exercise, if applicable.
    List<String>? multipleChoiceOptions,

    /// Free-form user input for text-based exercises.
    String? userInput,

    /// Simple counters for this continuous run (not persisted as a session).
    @Default(0) int runCorrectCount,
    @Default(0) int runIncorrectCount,

    /// Indicates that there are currently no due items to practice.
    @Default(false) bool noDueItems,

    /// When the current practice session started (for duration tracking).
    DateTime? sessionStartTime,
  }) = _PracticeSessionState;
}
