import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_list_state.freezed.dart';

@freezed
sealed class CardListState with _$CardListState {
  const factory CardListState({@Default(false) bool isSearching}) =
      _CardListState;
}
