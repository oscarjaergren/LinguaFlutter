import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/domain/models/icon_model.dart';
import '../../../../shared/domain/models/word_data.dart';

part 'card_creation_state.freezed.dart';

@freezed
sealed class CardCreationState with _$CardCreationState {
  const factory CardCreationState({
    @Default('') String frontText,
    @Default('') String backText,
    @Default([]) List<String> tags,
    IconModel? selectedIcon,
    String? notes,
    @Default([]) List<String> examples,
    @Default(WordType.other) WordType wordType,

    // Verb-specific state
    @Default(true) bool isRegularVerb,
    @Default(false) bool isSeparableVerb,
    @Default('haben') String auxiliaryVerb,
    String? separablePrefix,
    String? presentSecondPerson,
    String? presentThirdPerson,
    String? pastSimple,
    String? pastParticiple,

    // Noun-specific state
    String? nounGender,
    String? plural,
    String? genitive,

    // Adjective-specific state
    String? comparative,
    String? superlative,

    // Adverb-specific state
    String? usageNote,

    // UI state
    @Default(false) bool isLoading,
    @Default(false) bool isEditing,
    String? errorMessage,
  }) = _CardCreationState;
}
