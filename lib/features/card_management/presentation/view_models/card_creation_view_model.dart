import 'package:flutter/foundation.dart';
import '../../../../shared/domain/card_provider.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../../shared/domain/models/icon_model.dart';
import '../../../language/domain/language_provider.dart';
import '../../../icon_search/domain/icon_provider.dart';

/// ViewModel for card creation and editing, handling form state and validation
class CardCreationViewModel extends ChangeNotifier {
  final CardProvider _cardProvider;
  final LanguageProvider _languageProvider;
  final IconProvider _iconProvider;

  // Form state
  String _frontText = '';
  String _backText = '';
  String _category = '';
  List<String> _tags = [];
  IconModel? _selectedIcon;
  String? _germanArticle;
  int _difficulty = 1;
  
  // UI state
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  CardModel? _cardToEdit;

  // Validation state
  bool _frontTextValid = false;
  bool _backTextValid = false;
  bool _categoryValid = false;

  CardCreationViewModel({
    required CardProvider cardProvider,
    required LanguageProvider languageProvider,
    required IconProvider iconProvider,
    CardModel? cardToEdit,
  })  : _cardProvider = cardProvider,
        _languageProvider = languageProvider,
        _iconProvider = iconProvider,
        _cardToEdit = cardToEdit {
    
    _isEditing = cardToEdit != null;
    if (_isEditing) {
      _initializeFromCard(cardToEdit!);
    }
    
    // Listen to provider changes
    _cardProvider.addListener(_onCardProviderChanged);
    _languageProvider.addListener(_onLanguageProviderChanged);
    _iconProvider.addListener(_onIconProviderChanged);
  }

  @override
  void dispose() {
    _cardProvider.removeListener(_onCardProviderChanged);
    _languageProvider.removeListener(_onLanguageProviderChanged);
    _iconProvider.removeListener(_onIconProviderChanged);
    super.dispose();
  }

  // Getters for UI state
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;
  
  // Form field getters
  String get frontText => _frontText;
  String get backText => _backText;
  String get category => _category;
  List<String> get tags => List.unmodifiable(_tags);
  String get tagsAsString => _tags.join(', ');
  IconModel? get selectedIcon => _selectedIcon;
  String? get germanArticle => _germanArticle;
  int get difficulty => _difficulty;

  // Validation getters
  bool get frontTextValid => _frontTextValid;
  bool get backTextValid => _backTextValid;
  bool get categoryValid => _categoryValid;
  bool get isFormValid => _frontTextValid && _backTextValid && _categoryValid;

  // Language-related getters
  String get activeLanguage => _languageProvider.activeLanguage;
  Map<String, String> get languageDetails {
    final details = _languageProvider.getLanguageDetails(activeLanguage);
    return details != null ? Map<String, String>.from(details) : {};
  }
  bool get isGermanLanguage => activeLanguage == 'de';

  // Available options
  List<String> get availableCategories => _cardProvider.categories;
  List<String> get availableTags => _cardProvider.availableTags;
  List<String> get germanArticles => ['der', 'die', 'das'];

  // Form field updates
  void updateFrontText(String value) {
    _frontText = value.trim();
    _frontTextValid = _frontText.isNotEmpty;
    _clearError();
    notifyListeners();
  }

  void updateBackText(String value) {
    _backText = value.trim();
    _backTextValid = _backText.isNotEmpty;
    _clearError();
    notifyListeners();
  }

  void updateCategory(String value) {
    _category = value.trim();
    _categoryValid = _category.isNotEmpty;
    _clearError();
    notifyListeners();
  }

  void updateTags(String value) {
    _tags = value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    _clearError();
    notifyListeners();
  }

  void updateGermanArticle(String? article) {
    _germanArticle = article;
    _clearError();
    notifyListeners();
  }

  void updateDifficulty(int difficulty) {
    _difficulty = difficulty.clamp(1, 5);
    _clearError();
    notifyListeners();
  }

  void selectIcon(IconModel? icon) {
    _selectedIcon = icon;
    _clearError();
    notifyListeners();
  }

  void clearSelectedIcon() {
    _selectedIcon = null;
    notifyListeners();
  }

  // Form validation
  String? validateFrontText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Front text is required';
    }
    return null;
  }

  String? validateBackText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Back text is required';
    }
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category is required';
    }
    return null;
  }

  // Actions
  Future<bool> saveCard() async {
    if (!isFormValid) {
      _setError('Please fill in all required fields');
      return false;
    }

    _setLoading(true);
    
    try {
      final card = _buildCardModel();
      
      if (_isEditing) {
        await _cardProvider.updateCard(card);
      } else {
        await _cardProvider.saveCard(card);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to save card: ${e.toString()}');
      return false;
    }
  }

  Future<void> deleteCard() async {
    if (!_isEditing || _cardToEdit == null) return;

    _setLoading(true);
    
    try {
      await _cardProvider.deleteCard(_cardToEdit!.id);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete card: ${e.toString()}');
    }
  }

  void resetForm() {
    _frontText = '';
    _backText = '';
    _category = '';
    _tags = [];
    _selectedIcon = null;
    _germanArticle = null;
    _difficulty = 1;
    _frontTextValid = false;
    _backTextValid = false;
    _categoryValid = false;
    _clearError();
    notifyListeners();
  }

  // Helper methods
  CardModel _buildCardModel() {
    return CardModel(
      id: _isEditing ? _cardToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      frontText: _frontText,
      backText: _backText,
      icon: _selectedIcon,
      language: activeLanguage,
      category: _category,
      tags: _tags,
      difficulty: _difficulty,
      germanArticle: _germanArticle,
      createdAt: _isEditing ? _cardToEdit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      lastReviewed: _isEditing ? _cardToEdit!.lastReviewed : null,
      nextReview: _isEditing ? _cardToEdit!.nextReview : DateTime.now(),
      reviewCount: _isEditing ? _cardToEdit!.reviewCount : 0,
      correctCount: _isEditing ? _cardToEdit!.correctCount : 0,
      isFavorite: _isEditing ? _cardToEdit!.isFavorite : false,
    );
  }

  void _initializeFromCard(CardModel card) {
    _frontText = card.frontText;
    _backText = card.backText;
    _category = card.category;
    _tags = List.from(card.tags);
    _selectedIcon = card.icon;
    _germanArticle = card.germanArticle;
    _difficulty = card.difficulty;
    
    // Update validation state
    _frontTextValid = _frontText.isNotEmpty;
    _backTextValid = _backText.isNotEmpty;
    _categoryValid = _category.isNotEmpty;
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

  void _onCardProviderChanged() {
    // Handle any card provider changes if needed
    notifyListeners();
  }

  void _onLanguageProviderChanged() {
    // Handle language changes
    notifyListeners();
  }

  void _onIconProviderChanged() {
    // Handle icon provider changes if needed
    notifyListeners();
  }
}
