import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/domain/models/card_model.dart';

part 'card_management_state.freezed.dart';

@freezed
sealed class CardManagementState with _$CardManagementState {
  const factory CardManagementState({
    @Default([]) List<CardModel> allCards,
    @Default([]) List<CardModel> filteredCards,
    @Default('') String searchQuery,
    @Default([]) List<String> selectedTags,
    @Default(false) bool showOnlyDue,
    @Default(false) bool showOnlyFavorites,
    @Default(false) bool showOnlyDuplicates,
    @Default({}) Set<String> duplicateCardIds,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _CardManagementState;
}

extension CardManagementStateExtension on CardManagementState {
  int get dueCount => filteredCards.where((card) => card.isDueForReview).length;
}
