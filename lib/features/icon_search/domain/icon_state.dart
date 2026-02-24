import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../shared/domain/models/icon_model.dart';

part 'icon_state.freezed.dart';

@freezed
abstract class IconState with _$IconState {
  const factory IconState({
    @Default([]) List<IconModel> searchResults,
    @Default(false) bool isLoading,
    @Default('') String searchQuery,
    String? errorMessage,
    IconModel? selectedIcon,
  }) = _IconState;
}
