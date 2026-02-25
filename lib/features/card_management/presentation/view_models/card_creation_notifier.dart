import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/icon_model.dart';
import '../../../../shared/domain/models/word_data.dart';
import '../../../language/language.dart';
import '../../domain/providers/card_management_notifier.dart';
import 'card_creation_state.dart';

final cardCreationNotifierProvider =
    NotifierProvider.autoDispose<CardCreationNotifier, CardCreationState>(
      () => CardCreationNotifier(),
    );

class CardCreationNotifier extends Notifier<CardCreationState> {
  CardModel? _editingCard;

  @override
  CardCreationState build() {
    return const CardCreationState();
  }

  void loadCard(CardModel card) {
    _editingCard = card;
    state = _stateFromCard(card);
  }

  CardCreationState _stateFromCard(CardModel card) {
    CardCreationState newState = CardCreationState(
      frontText: card.frontText,
      backText: card.backText,
      tags: card.tags,
      selectedIcon: card.icon,
      notes: card.notes,
      examples: card.examples,
      isEditing: true,
    );

    final wordData = card.wordData;
    if (wordData != null) {
      switch (wordData) {
        case VerbData():
          newState = newState.copyWith(
            wordType: WordType.verb,
            isRegularVerb: wordData.isRegular,
            isSeparableVerb: wordData.isSeparable,
            separablePrefix: wordData.separablePrefix,
            auxiliaryVerb: wordData.auxiliary,
            presentSecondPerson: wordData.presentSecondPerson,
            presentThirdPerson: wordData.presentThirdPerson,
            pastSimple: wordData.pastSimple,
            pastParticiple: wordData.pastParticiple,
          );
        case NounData():
          newState = newState.copyWith(
            wordType: WordType.noun,
            nounGender: wordData.gender,
            plural: wordData.plural,
            genitive: wordData.genitive,
          );
        case AdjectiveData():
          newState = newState.copyWith(
            wordType: WordType.adjective,
            comparative: wordData.comparative,
            superlative: wordData.superlative,
          );
        case AdverbData():
          newState = newState.copyWith(
            wordType: WordType.adverb,
            usageNote: wordData.usageNote,
          );
      }
    }
    return newState;
  }

  // Field updates
  void updateFrontText(String value) =>
      state = state.copyWith(frontText: value.trim(), errorMessage: null);
  void updateBackText(String value) =>
      state = state.copyWith(backText: value.trim(), errorMessage: null);

  void updateTags(String value) {
    final tags = value
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    state = state.copyWith(tags: tags, errorMessage: null);
  }

  void updateNotes(String? value) => state = state.copyWith(
    notes: value?.trim().isNotEmpty == true ? value!.trim() : null,
  );

  void selectIcon(IconModel? icon) =>
      state = state.copyWith(selectedIcon: icon);
  void clearIcon() => state = state.copyWith(selectedIcon: null);

  void updateWordType(WordType type) => state = state.copyWith(wordType: type);

  // Verb updates
  void updateIsRegularVerb(bool value) =>
      state = state.copyWith(isRegularVerb: value);
  void updateIsSeparableVerb(bool value) =>
      state = state.copyWith(isSeparableVerb: value);
  void updateAuxiliaryVerb(String value) =>
      state = state.copyWith(auxiliaryVerb: value);
  void updateSeparablePrefix(String? value) =>
      state = state.copyWith(separablePrefix: value?.trim());
  void updatePresentSecondPerson(String? value) =>
      state = state.copyWith(presentSecondPerson: value?.trim());
  void updatePresentThirdPerson(String? value) =>
      state = state.copyWith(presentThirdPerson: value?.trim());
  void updatePastSimple(String? value) =>
      state = state.copyWith(pastSimple: value?.trim());
  void updatePastParticiple(String? value) =>
      state = state.copyWith(pastParticiple: value?.trim());

  // Noun updates
  void updateNounGender(String? value) =>
      state = state.copyWith(nounGender: value);
  void updatePlural(String? value) =>
      state = state.copyWith(plural: value?.trim());
  void updateGenitive(String? value) =>
      state = state.copyWith(genitive: value?.trim());

  // Adjective updates
  void updateComparative(String? value) =>
      state = state.copyWith(comparative: value?.trim());
  void updateSuperlative(String? value) =>
      state = state.copyWith(superlative: value?.trim());

  // Adverb updates
  void updateUsageNote(String? value) =>
      state = state.copyWith(usageNote: value?.trim());

  // Examples
  void addExample(String example) {
    if (example.trim().isNotEmpty) {
      state = state.copyWith(examples: [...state.examples, example.trim()]);
    }
  }

  void removeExample(int index) {
    if (index >= 0 && index < state.examples.length) {
      final updated = List<String>.from(state.examples)..removeAt(index);
      state = state.copyWith(examples: updated);
    }
  }

  WordData? _buildWordData() {
    return switch (state.wordType) {
      WordType.verb => WordData.verb(
        isRegular: state.isRegularVerb,
        isSeparable: state.isSeparableVerb,
        separablePrefix: state.separablePrefix,
        auxiliary: state.auxiliaryVerb,
        presentSecondPerson: state.presentSecondPerson,
        presentThirdPerson: state.presentThirdPerson,
        pastSimple: state.pastSimple,
        pastParticiple: state.pastParticiple,
      ),
      WordType.noun =>
        state.nounGender == null
            ? null
            : WordData.noun(
                gender: state.nounGender!,
                plural: state.plural,
                genitive: state.genitive,
              ),
      WordType.adjective => WordData.adjective(
        comparative: state.comparative,
        superlative: state.superlative,
      ),
      WordType.adverb => WordData.adverb(usageNote: state.usageNote),
      WordType.phrase || WordType.other => null,
    };
  }

  Future<bool> saveCard() async {
    if (!_validateRequiredFields()) {
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final wordData = _buildWordData();
      final activeLanguage = ref.read(languageNotifierProvider).activeLanguage;

      final CardModel card;
      if (state.isEditing) {
        card = _editingCard!.copyWith(
          frontText: state.frontText,
          backText: state.backText,
          icon: state.selectedIcon,
          language: activeLanguage,
          tags: state.tags,
          wordData: wordData,
          examples: state.examples,
          notes: state.notes,
          updatedAt: DateTime.now(),
        );
      } else {
        card =
            CardModel.create(
              frontText: state.frontText,
              backText: state.backText,
              icon: state.selectedIcon,
              language: activeLanguage,
              tags: state.tags,
            ).copyWith(
              wordData: wordData,
              examples: state.examples,
              notes: state.notes,
            );
      }

      await ref.read(cardManagementNotifierProvider.notifier).saveCard(card);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save card: $e',
      );
      return false;
    }
  }

  Future<bool> deleteCard() async {
    if (!state.isEditing) return false;
    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(cardManagementNotifierProvider.notifier)
          .deleteCard(_editingCard!.id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete card: $e',
      );
      return false;
    }
  }

  void resetForm() {
    _editingCard = null;
    state = const CardCreationState();
  }

  /// Validates required fields based on word type
  bool _validateRequiredFields() {
    if (state.frontText.isEmpty || state.backText.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please fill in all required fields',
      );
      return false;
    }

    switch (state.wordType) {
      case WordType.noun:
        if (state.nounGender == null || state.nounGender!.isEmpty) {
          state = state.copyWith(errorMessage: 'Noun gender is required');
          return false;
        }
      case WordType.verb:
      case WordType.adjective:
      case WordType.adverb:
      case WordType.phrase:
      case WordType.other:
        break;
    }

    return true;
  }
}
