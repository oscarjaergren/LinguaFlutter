import 'package:freezed_annotation/freezed_annotation.dart';
import '../presentation/widgets/mascot_widget.dart';

part 'mascot_state.freezed.dart';

@freezed
abstract class MascotStateData with _$MascotStateData {
  const factory MascotStateData({
    @Default(MascotState.idle) MascotState currentState,
    String? currentMessage,
    @Default(true) bool isVisible,
    @Default(false) bool hasInitializedForSession,
    @Default(true) bool animationsEnabled,
  }) = _MascotStateData;
}
