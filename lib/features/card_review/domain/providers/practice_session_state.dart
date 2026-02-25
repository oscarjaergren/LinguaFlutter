import 'package:freezed_annotation/freezed_annotation.dart';
import 'practice_session_types.dart';

part 'practice_session_state.freezed.dart';

@freezed
sealed class PracticeSessionState with _$PracticeSessionState {
  const factory PracticeSessionState({
    @Default([]) List<PracticeItem> sessionQueue,
    @Default(0) int currentIndex,
    @Default(false) bool isSessionActive,
    @Default(false) bool isSessionComplete,
    DateTime? sessionStartTime,
    @Default(0) int correctCount,
    @Default(0) int incorrectCount,
    @Default(AnswerState.pending) AnswerState answerState,
    bool? currentAnswerCorrect,
    List<String>? multipleChoiceOptions,
    String? userInput,
    @Default(0.0) double progress,
  }) = _PracticeSessionState;
}
