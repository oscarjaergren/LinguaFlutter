import 'package:flutter/foundation.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../../language/domain/language_provider.dart';
import '../../data/repositories/card_management_repository.dart';
import '../../../../shared/utils/rate_limiter.dart';
import '../../../auth/data/services/supabase_auth_service.dart';

/// Function type for resolving the current user ID.
typedef UserIdResolver = String? Function();

/// Provider for managing card data, filtering, and CRUD operations.
///
/// This is the primary provider for card management within the card_management feature.
/// Assumes user is authenticated - callers must ensure this.
class CardManagementProvider extends ChangeNotifier {
  final LanguageProvider _languageProvider;
  final CardManagementRepository _repository;
  final RateLimiter _rateLimiter = RateLimiter();
  final UserIdResolver _getUserId;

  // Core card data
  List<CardModel> _allCards = [];
  List<CardModel> _filteredCards = [];

  // Filter and search state
  String _searchQuery = '';
  List<String> _selectedTags = [];
  bool _showOnlyDue = false;
  bool _showOnlyFavorites = false;
  bool _showOnlyDuplicates = false;
  Set<String> _duplicateCardIds = {};

  // UI state
  bool _isLoading = false;
  String? _errorMessage;

  /// Create a CardManagementProvider with optional repository injection for testing.
  ///
  /// By default uses [SupabaseCardManagementRepository]. Pass a mock implementation
  /// for unit testing. Pass [getUserId] to override the user ID resolver (for tests).
  CardManagementProvider({
    required LanguageProvider languageProvider,
    CardManagementRepository? repository,
    UserIdResolver? getUserId,
  }) : _languageProvider = languageProvider,
       _repository = repository ?? SupabaseCardManagementRepository(),
       _getUserId =
           getUserId ??
           (() {
             try {
               return SupabaseAuthService.currentUserId;
             } catch (_) {
               return null;
             }
           }) {
    _languageProvider.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  // ============================================================
  // Getters
  // ============================================================

  /// All cards in storage (unfiltered)
  List<CardModel> get allCards => List.unmodifiable(_allCards);

  /// Cards after applying current filters
  List<CardModel> get filteredCards => List.unmodifiable(_filteredCards);

  /// Cards that are due for review (filtered by active language)
  List<CardModel> get reviewCards => _allCards
      .where(
        (card) =>
            card.isDue &&
            !card.isArchived &&
            (_languageProvider.activeLanguage.isEmpty ||
                card.language == _languageProvider.activeLanguage),
      )
      .toList();

  // Filter state getters
  String get searchQuery => _searchQuery;
  List<String> get selectedTags => List.unmodifiable(_selectedTags);
  bool get showOnlyDue => _showOnlyDue;
  bool get showOnlyFavorites => _showOnlyFavorites;
  bool get showOnlyDuplicates => _showOnlyDuplicates;

  // UI state getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed properties
  List<String> get availableTags =>
      _allCards.expand((card) => card.tags).toSet().toList()..sort();

  /// Statistics for the current language filter
  Map<String, dynamic> get stats {
    final languageFilteredCards = _allCards.where((card) {
      return _languageProvider.activeLanguage.isEmpty ||
          card.language == _languageProvider.activeLanguage;
    }).toList();

    return {
      'totalCards': languageFilteredCards.length,
      'dueCards': reviewCards.length,
      'favoriteCards': languageFilteredCards.where((c) => c.isFavorite).length,
      'archivedCards': languageFilteredCards.where((c) => c.isArchived).length,
      'duplicateCards': languageFilteredCards
          .where((c) => _duplicateCardIds.contains(c.id))
          .length,
    };
  }

  // ============================================================
  // Card CRUD Operations
  // ============================================================

  /// Initialize the provider by loading cards
  Future<void> initialize() async {
    await loadCards();
  }

  /// Load all cards from storage
  Future<void> loadCards() async {
    _setLoading(true);
    try {
      _allCards = await _repository.getAllCards();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError('Failed to load cards: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save a card (create or update)
  Future<void> saveCard(CardModel card) async {
    try {
      // Sanitize and validate card data
      final sanitizedCard = _sanitizeCard(card);
      _validateCard(sanitizedCard);

      await _repository.saveCard(sanitizedCard);
      await loadCards();
    } catch (e) {
      _setError('Failed to save card: $e');
      rethrow;
    }
  }

  /// Add a new card
  Future<void> addCard(CardModel card) async {
    // Check rate limit (skipped when no userId — repository enforces auth)
    final userId = _getUserId();
    if (userId != null) {
      if (!_rateLimiter.isAllowed(userId: userId, action: 'card_creation')) {
        final errorMsg = _rateLimiter.getErrorMessage(
          userId: userId,
          action: 'card_creation',
        );
        throw RateLimitException(errorMsg);
      }
    }

    await saveCard(card);
  }

  /// Add multiple cards in batch
  Future<void> addMultipleCards(List<CardModel> cards) async {
    try {
      // Check rate limit for bulk operations (skipped when no userId)
      final userId = _getUserId();
      if (userId != null) {
        if (!_rateLimiter.isAllowed(
          userId: userId,
          action: 'card_bulk_create',
        )) {
          final errorMsg = _rateLimiter.getErrorMessage(
            userId: userId,
            action: 'card_bulk_create',
          );
          throw RateLimitException(errorMsg);
        }
      }

      for (final card in cards) {
        final sanitizedCard = _sanitizeCard(card);
        _validateCard(sanitizedCard);
        await _repository.saveCard(sanitizedCard);
      }
      await loadCards();
    } catch (e) {
      _setError('Failed to add cards: $e');
      rethrow;
    }
  }

  /// Update an existing card
  Future<void> updateCard(CardModel card) async {
    // Check rate limit (skipped when no userId — repository enforces auth)
    final userId = _getUserId();
    if (userId != null) {
      if (!_rateLimiter.isAllowed(userId: userId, action: 'card_update')) {
        final errorMsg = _rateLimiter.getErrorMessage(
          userId: userId,
          action: 'card_update',
        );
        throw RateLimitException(errorMsg);
      }
    }

    await saveCard(card);
  }

  /// Delete a card by ID
  Future<void> deleteCard(String cardId) async {
    try {
      // Check rate limit (skipped when no userId — repository enforces auth)
      final userId = _getUserId();
      if (userId != null) {
        if (!_rateLimiter.isAllowed(userId: userId, action: 'card_delete')) {
          final errorMsg = _rateLimiter.getErrorMessage(
            userId: userId,
            action: 'card_delete',
          );
          throw RateLimitException(errorMsg);
        }
      }

      // Remove from local state immediately for responsive UI
      _allCards.removeWhere((c) => c.id == cardId);
      _applyFilters();
      notifyListeners();

      // Then delete from backend
      await _repository.deleteCard(cardId);
    } catch (e) {
      _setError('Failed to delete card: $e');
      rethrow;
    }
  }

  /// Toggle archive status for a card
  Future<void> toggleArchive(String cardId) async {
    try {
      final card = _allCards.firstWhere((c) => c.id == cardId);
      final updatedCard = card.copyWith(isArchived: !card.isArchived);
      await updateCard(updatedCard);
    } catch (e) {
      _setError('Failed to toggle archive: $e');
    }
  }

  /// Toggle favorite status for a card
  Future<void> toggleFavorite(String cardId) async {
    try {
      final card = _allCards.firstWhere((c) => c.id == cardId);
      final updatedCard = card.copyWith(isFavorite: !card.isFavorite);
      await updateCard(updatedCard);
    } catch (e) {
      _setError('Failed to toggle favorite: $e');
    }
  }

  /// Clear all cards from storage
  Future<void> clearAllCards() async {
    try {
      await _repository.clearAllCards();
      await loadCards();
    } catch (e) {
      _setError('Failed to clear cards: $e');
    }
  }

  // ============================================================
  // Search and Filter Operations
  // ============================================================

  /// Search cards by query
  void searchCards(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  /// Filter by tags
  void filterByTags(List<String> tags) {
    _selectedTags = tags;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle show only due cards filter
  void toggleShowOnlyDue() {
    _showOnlyDue = !_showOnlyDue;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle show only favorites filter
  void toggleShowOnlyFavorites() {
    _showOnlyFavorites = !_showOnlyFavorites;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle show only duplicates filter
  void toggleShowOnlyDuplicates() {
    _showOnlyDuplicates = !_showOnlyDuplicates;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all active filters
  void clearFilters() {
    _searchQuery = '';
    _selectedTags = [];
    _showOnlyDue = false;
    _showOnlyFavorites = false;
    _showOnlyDuplicates = false;
    _applyFilters();
    notifyListeners();
  }

  // ============================================================
  // Duplicate Detection Integration
  // ============================================================

  /// Update the set of card IDs that have duplicates.
  /// Called by DuplicateDetectionProvider when analysis completes.
  void updateDuplicateCardIds(Set<String> duplicateIds) {
    _duplicateCardIds = duplicateIds;
    if (_showOnlyDuplicates) {
      _applyFilters();
    }
    notifyListeners();
  }

  /// Check if a card has duplicates
  bool cardHasDuplicates(String cardId) => _duplicateCardIds.contains(cardId);

  /// Count of cards with duplicates
  int get duplicateCount => _duplicateCardIds.length;

  // ============================================================
  // Private Methods
  // ============================================================

  void _applyFilters() {
    _filteredCards = _allCards.where((card) {
      // Language filter
      if (_languageProvider.activeLanguage.isNotEmpty &&
          card.language != _languageProvider.activeLanguage) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!card.frontText.toLowerCase().contains(query) &&
            !card.backText.toLowerCase().contains(query) &&
            !card.tags.any((tag) => tag.toLowerCase().contains(query))) {
          return false;
        }
      }

      // Tags filter
      if (_selectedTags.isNotEmpty &&
          !_selectedTags.every((tag) => card.tags.contains(tag))) {
        return false;
      }

      // Due filter
      if (_showOnlyDue && !card.isDue) {
        return false;
      }

      // Favorites filter
      if (_showOnlyFavorites && !card.isFavorite) {
        return false;
      }

      // Duplicates filter
      if (_showOnlyDuplicates && !_duplicateCardIds.contains(card.id)) {
        return false;
      }

      // Archived filter (exclude archived by default)
      if (card.isArchived) {
        return false;
      }

      return true;
    }).toList();
  }

  void _onLanguageChanged() {
    _applyFilters();
    notifyListeners();
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
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // Sanitization & Validation (Private Business Logic)
  // ============================================================

  /// Sanitize card data before saving
  CardModel _sanitizeCard(CardModel card) {
    return card.copyWith(
      frontText: _sanitizeCardText(card.frontText),
      backText: _sanitizeCardText(card.backText),
      notes: card.notes != null ? _sanitizeNotes(card.notes) : null,
      examples: _sanitizeExamples(card.examples),
      tags: _sanitizeTags(card.tags),
      language: _sanitizeLanguageCode(card.language) ?? 'de',
    );
  }

  /// Validate card data
  void _validateCard(CardModel card) {
    if (!_isValidCardText(card.frontText)) {
      throw Exception('Front text is required');
    }
    if (!_isValidCardText(card.backText)) {
      throw Exception('Back text is required');
    }
    if (!_isValidLanguageCode(card.language)) {
      throw Exception('Invalid language code: ${card.language}');
    }
  }

  // Sanitization constants
  static const int _maxTextLength = 500;
  static const int _maxNotesLength = 2000;
  static const int _maxExampleLength = 300;
  static const int _maxTagLength = 50;

  // Validation constants
  static const List<String> _supportedLanguages = [
    'de',
    'es',
    'fr',
    'it',
    'pt',
    'nl',
    'sv',
    'ja',
    'zh',
    'ko',
  ];

  /// Sanitize card text (functional pipeline)
  String _sanitizeCardText(String? input) {
    if (input == null || input.isEmpty) return '';
    return _applySanitizationPipeline(
      input,
      maxLength: _maxTextLength,
      preserveNewlines: false,
    );
  }

  /// Sanitize notes (allows more length, preserves newlines)
  String _sanitizeNotes(String? input) {
    if (input == null || input.isEmpty) return '';
    return _applySanitizationPipeline(
      input,
      maxLength: _maxNotesLength,
      preserveNewlines: true,
    );
  }

  /// Sanitize example sentence
  String _sanitizeExample(String? input) {
    if (input == null || input.isEmpty) return '';
    return _applySanitizationPipeline(
      input,
      maxLength: _maxExampleLength,
      preserveNewlines: false,
    );
  }

  /// Sanitize list of examples
  List<String> _sanitizeExamples(List<String>? examples) =>
      examples?.map(_sanitizeExample).where((e) => e.isNotEmpty).toList() ?? [];

  /// Sanitize list of tags (LINQ-style functional)
  List<String> _sanitizeTags(List<String>? tags) =>
      tags
          ?.map((tag) => tag.trim().toLowerCase())
          .where((tag) => tag.isNotEmpty && tag.length <= _maxTagLength)
          .map(_removeSpecialCharacters)
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList() ??
      [];

  /// Apply sanitization pipeline in functional style
  String _applySanitizationPipeline(
    String input, {
    required int maxLength,
    required bool preserveNewlines,
  }) {
    return input
        .trim()
        .let(_removeScriptContent)
        .let(_removeHtmlTags)
        .let(
          (s) => preserveNewlines
              ? _normalizeWhitespacePreserveNewlines(s)
              : _normalizeWhitespace(s),
        )
        .let((s) => s.length > maxLength ? s.substring(0, maxLength) : s);
  }

  /// Remove HTML tags
  String _removeHtmlTags(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>'), '');

  /// Remove script-like content
  String _removeScriptContent(String input) {
    return input
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?</script>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
  }

  /// Normalize whitespace (collapse multiple spaces)
  String _normalizeWhitespace(String input) =>
      input.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Normalize whitespace but preserve newlines
  String _normalizeWhitespacePreserveNewlines(String input) {
    return input
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Remove special characters (for tags)
  String _removeSpecialCharacters(String input) =>
      input.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '');

  /// Sanitize and validate language code
  String? _sanitizeLanguageCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final sanitized = code.trim().toLowerCase();
    return _isValidLanguageCode(sanitized) ? sanitized : null;
  }

  /// Validate language code
  bool _isValidLanguageCode(String? code) {
    if (code == null || code.isEmpty) return false;
    return _supportedLanguages.contains(code.toLowerCase());
  }

  /// Validate card text is not empty
  bool _isValidCardText(String? text) {
    if (text == null) return false;
    return text.trim().isNotEmpty;
  }
}

/// Extension to enable LINQ-like .let() method for functional pipelines
extension _FunctionalStringExtension on String {
  String let(String Function(String) transform) => transform(this);
}
