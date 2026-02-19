import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/icon_model.dart';
import '../../../../shared/domain/models/word_data.dart';
import '../../../language/domain/language_provider.dart';
import '../../../icon_search/domain/icon_provider.dart';
import '../../domain/providers/card_management_provider.dart';

/// ViewModel for card creation and editing with full model support
class CardCreationViewModel extends ChangeNotifier {
  final CardManagementProvider _cardManagement;
  final LanguageProvider _languageProvider;
  final IconProvider _iconProvider;
  final CardModel? _cardToEdit;

  // Basic form state
  String _frontText = '';
  String _backText = '';
  List<String> _tags = [];
  IconModel? _selectedIcon;
  String? _notes;
  List<String> _examples = [];

  // Word type state
  WordType _wordType = WordType.other;

  // Verb-specific state
  bool _isRegularVerb = true;
  bool _isSeparableVerb = false;
  String _auxiliaryVerb = 'haben';
  String? _separablePrefix;
  String? _presentDu;
  String? _presentEr;
  String? _pastSimple;
  String? _pastParticiple;

  // Noun-specific state
  String? _nounGender;
  String? _plural;
  String? _genitive;

  // Adjective-specific state
  String? _comparative;
  String? _superlative;

  // Adverb-specific state
  String? _usageNote;

  // UI state
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;

  CardCreationViewModel({
    required CardManagementProvider cardManagement,
    required LanguageProvider languageProvider,
    required IconProvider iconProvider,
    CardModel? cardToEdit,
  }) : _cardManagement = cardManagement,
       _languageProvider = languageProvider,
       _iconProvider = iconProvider,
       _cardToEdit = cardToEdit {
    _isEditing = cardToEdit != null;
    if (_isEditing) {
      _initializeFromCard(cardToEdit!);
    }
    _cardManagement.addListener(_onProviderChanged);
    _languageProvider.addListener(_onProviderChanged);
    _iconProvider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _cardManagement.removeListener(_onProviderChanged);
    _languageProvider.removeListener(_onProviderChanged);
    _iconProvider.removeListener(_onProviderChanged);
    super.dispose();
  }

  // UI state getters
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;

  // Basic form getters
  String get frontText => _frontText;
  String get backText => _backText;
  List<String> get tags => List.unmodifiable(_tags);
  String get tagsAsString => _tags.join(', ');
  IconModel? get selectedIcon => _selectedIcon;
  String? get notes => _notes;
  List<String> get examples => List.unmodifiable(_examples);

  // Word type getters
  WordType get wordType => _wordType;

  // Verb getters
  bool get isRegularVerb => _isRegularVerb;
  bool get isSeparableVerb => _isSeparableVerb;
  String get auxiliaryVerb => _auxiliaryVerb;
  String? get separablePrefix => _separablePrefix;
  String? get presentDu => _presentDu;
  String? get presentEr => _presentEr;
  String? get pastSimple => _pastSimple;
  String? get pastParticiple => _pastParticiple;

  // Noun getters
  String? get nounGender => _nounGender;
  String? get plural => _plural;
  String? get genitive => _genitive;

  // Adjective getters
  String? get comparative => _comparative;
  String? get superlative => _superlative;

  // Adverb getters
  String? get usageNote => _usageNote;

  // Validation
  bool get isFormValid => _frontText.isNotEmpty && _backText.isNotEmpty;

  // Language getters
  String get activeLanguage => _languageProvider.activeLanguage;
  bool get isGermanLanguage => activeLanguage == 'de';
  List<String> get availableTags => _cardManagement.availableTags;

  // Basic field updates
  void updateFrontText(String value) {
    _frontText = value.trim();
    _clearError();
    notifyListeners();
  }

  void updateBackText(String value) {
    _backText = value.trim();
    _clearError();
    notifyListeners();
  }

  void updateTags(String value) {
    _tags = value
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    _clearError();
    notifyListeners();
  }

  void updateNotes(String? value) {
    _notes = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  void selectIcon(IconModel? icon) {
    _selectedIcon = icon;
    notifyListeners();
  }

  void clearIcon() {
    _selectedIcon = null;
    notifyListeners();
  }

  // Word type update
  void updateWordType(WordType type) {
    _wordType = type;
    notifyListeners();
  }

  // Verb updates
  void updateIsRegularVerb(bool value) {
    _isRegularVerb = value;
    notifyListeners();
  }

  void updateIsSeparableVerb(bool value) {
    _isSeparableVerb = value;
    notifyListeners();
  }

  void updateAuxiliaryVerb(String value) {
    _auxiliaryVerb = value;
    notifyListeners();
  }

  void updateSeparablePrefix(String? value) {
    _separablePrefix = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  void updatePresentDu(String? value) {
    _presentDu = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  void updatePresentEr(String? value) {
    _presentEr = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  void updatePastSimple(String? value) {
    _pastSimple = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  void updatePastParticiple(String? value) {
    _pastParticiple = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  // Noun updates
  void updateNounGender(String? value) {
    _nounGender = value;
    notifyListeners();
  }

  void updatePlural(String? value) {
    _plural = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  void updateGenitive(String? value) {
    _genitive = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  // Adjective updates
  void updateComparative(String? value) {
    _comparative = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  void updateSuperlative(String? value) {
    _superlative = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  // Adverb updates
  void updateUsageNote(String? value) {
    _usageNote = value?.trim().isNotEmpty == true ? value!.trim() : null;
    notifyListeners();
  }

  // Examples management
  void addExample(String example) {
    if (example.trim().isNotEmpty) {
      _examples.add(example.trim());
      notifyListeners();
    }
  }

  void removeExample(int index) {
    if (index >= 0 && index < _examples.length) {
      _examples.removeAt(index);
      notifyListeners();
    }
  }

  // Build WordData from current state
  WordData? _buildWordData() {
    switch (_wordType) {
      case WordType.verb:
        return WordData.verb(
          isRegular: _isRegularVerb,
          isSeparable: _isSeparableVerb,
          separablePrefix: _separablePrefix,
          auxiliary: _auxiliaryVerb,
          presentDu: _presentDu,
          presentEr: _presentEr,
          pastSimple: _pastSimple,
          pastParticiple: _pastParticiple,
        );
      case WordType.noun:
        if (_nounGender == null) return null;
        return WordData.noun(
          gender: _nounGender!,
          plural: _plural,
          genitive: _genitive,
        );
      case WordType.adjective:
        return WordData.adjective(
          comparative: _comparative,
          superlative: _superlative,
        );
      case WordType.adverb:
        return WordData.adverb(usageNote: _usageNote);
      case WordType.phrase:
      case WordType.other:
        return null;
    }
  }

  // Actions
  Future<bool> saveCard() async {
    if (!isFormValid) {
      _setError('Please fill in all required fields');
      return false;
    }

    _setLoading(true);

    try {
      final wordData = _buildWordData();

      final CardModel card;
      if (_isEditing) {
        card = _cardToEdit!.copyWith(
          frontText: _frontText,
          backText: _backText,
          icon: _selectedIcon,
          language: activeLanguage,
          tags: _tags,
          wordData: wordData,
          examples: _examples,
          notes: _notes,
          updatedAt: DateTime.now(),
        );
      } else {
        card = CardModel.create(
          frontText: _frontText,
          backText: _backText,
          icon: _selectedIcon,
          language: activeLanguage,
          tags: _tags,
        ).copyWith(wordData: wordData, examples: _examples, notes: _notes);
      }

      await _cardManagement.saveCard(card);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to save card: $e');
      return false;
    }
  }

  Future<void> deleteCard() async {
    if (!_isEditing || _cardToEdit == null) return;
    _setLoading(true);
    try {
      await _cardManagement.deleteCard(_cardToEdit.id);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete card: $e');
    }
  }

  void resetForm() {
    _frontText = '';
    _backText = '';
    _tags = [];
    _selectedIcon = null;
    _notes = null;
    _examples = [];
    _wordType = WordType.other;
    _isRegularVerb = true;
    _isSeparableVerb = false;
    _auxiliaryVerb = 'haben';
    _separablePrefix = null;
    _presentDu = null;
    _presentEr = null;
    _pastSimple = null;
    _pastParticiple = null;
    _nounGender = null;
    _plural = null;
    _genitive = null;
    _comparative = null;
    _superlative = null;
    _usageNote = null;
    _clearError();
    notifyListeners();
  }

  void _initializeFromCard(CardModel card) {
    _frontText = card.frontText;
    _backText = card.backText;
    _tags = List.from(card.tags);
    _selectedIcon = card.icon;
    _notes = card.notes;
    _examples = List.from(card.examples);

    // Initialize word data
    if (card.wordData != null) {
      _initializeWordData(card.wordData!);
    }
  }

  void _initializeWordData(WordData wordData) {
    switch (wordData) {
      case VerbData():
        _wordType = WordType.verb;
        _isRegularVerb = wordData.isRegular;
        _isSeparableVerb = wordData.isSeparable;
        _separablePrefix = wordData.separablePrefix;
        _auxiliaryVerb = wordData.auxiliary;
        _presentDu = wordData.presentDu;
        _presentEr = wordData.presentEr;
        _pastSimple = wordData.pastSimple;
        _pastParticiple = wordData.pastParticiple;
      case NounData():
        _wordType = WordType.noun;
        _nounGender = wordData.gender;
        _plural = wordData.plural;
        _genitive = wordData.genitive;
      case AdjectiveData():
        _wordType = WordType.adjective;
        _comparative = wordData.comparative;
        _superlative = wordData.superlative;
      case AdverbData():
        _wordType = WordType.adverb;
        _usageNote = wordData.usageNote;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _onProviderChanged() => notifyListeners();
}
