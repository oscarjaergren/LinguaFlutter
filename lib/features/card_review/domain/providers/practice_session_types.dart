import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/exercise_type.dart';

/// Represents a single practice item: a card + exercise type combination
class PracticeItem {
  final CardModel card;
  final ExerciseType exerciseType;

  const PracticeItem({required this.card, required this.exerciseType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeItem &&
          runtimeType == other.runtimeType &&
          card.id == other.card.id &&
          exerciseType == other.exerciseType;

  @override
  int get hashCode => card.id.hashCode ^ exerciseType.hashCode;
}

/// State of the current exercise answer
enum AnswerState {
  /// User hasn't answered yet
  pending,

  /// User has submitted an answer, waiting for confirmation swipe
  answered,
}
