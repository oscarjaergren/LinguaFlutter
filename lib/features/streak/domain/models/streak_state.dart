import 'streak_model.dart';

const _unset = Object();

/// Immutable state for [StreakNotifier].
class StreakState {
  const StreakState({
    required this.streak,
    required this.newMilestones,
    required this.isLoading,
    this.errorMessage,
  });

  factory StreakState.initial() => StreakState(
    streak: StreakModel.initial(),
    newMilestones: const [],
    isLoading: false,
  );

  final StreakModel streak;
  final List<int> newMilestones;
  final bool isLoading;
  final String? errorMessage;

  /// Pass [errorMessage] to set it, omit it to keep the current value,
  /// or pass `null` explicitly to clear it.
  StreakState copyWith({
    StreakModel? streak,
    List<int>? newMilestones,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) => StreakState(
    streak: streak ?? this.streak,
    newMilestones: newMilestones ?? this.newMilestones,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
  );
}
