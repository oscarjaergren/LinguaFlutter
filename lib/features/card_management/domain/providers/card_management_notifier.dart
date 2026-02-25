import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/card_model.dart';
import '../../data/repositories/card_management_repository.dart';
import '../../../../shared/utils/rate_limiter.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../auth/data/services/supabase_auth_service.dart';
import '../../../language/language.dart';
import 'card_management_state.dart';

final cardManagementRepositoryProvider = Provider<CardManagementRepository>((
  ref,
) {
  return SupabaseCardManagementRepository();
});

final cardManagementNotifierProvider =
    NotifierProvider<CardManagementNotifier, CardManagementState>(
      () => CardManagementNotifier(),
    );

class CardManagementNotifier extends Notifier<CardManagementState> {
  late CardManagementRepository _repository;
  final RateLimiter _rateLimiter = RateLimiter();

  @override
  CardManagementState build() {
    _repository = ref.watch(cardManagementRepositoryProvider);

    // Watch language changes to re-filter
    ref.watch(languageNotifierProvider);

    // Initial state
    return const CardManagementState();
  }

  String? _getUserId() {
    try {
      return SupabaseAuthService.currentUserId;
    } catch (_) {
      return null;
    }
  }

  String _getActiveLanguage() {
    return ref.read(languageNotifierProvider).activeLanguage;
  }

  // ============================================================
  // Card CRUD Operations
  // ============================================================

  Future<void> initialize() async {
    await loadCards();
  }

  Future<void> loadCards() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cards = await _repository.getAllCards();
      state = state.copyWith(allCards: cards);
      _applyFilters();
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load cards', e, stackTrace);
      state = state.copyWith(errorMessage: 'Failed to load cards: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveCard(CardModel card) async {
    try {
      final sanitizedCard = _sanitizeCard(card);
      _validateCard(sanitizedCard);

      await _repository.saveCard(sanitizedCard);
      await loadCards();
    } catch (e, stackTrace) {
      LoggerService.error('Failed to save card', e, stackTrace);
      state = state.copyWith(errorMessage: 'Failed to save card: $e');
      rethrow;
    }
  }

  Future<void> addCard(CardModel card) async {
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

  Future<void> addMultipleCards(List<CardModel> cards) async {
    try {
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
      state = state.copyWith(errorMessage: 'Failed to add cards: $e');
      rethrow;
    }
  }

  Future<void> updateCard(CardModel card) async {
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

  Future<void> deleteCard(String cardId) async {
    try {
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

      // Optimistic delete from local state
      final updatedAllCards = state.allCards
          .where((c) => c.id != cardId)
          .toList();
      state = state.copyWith(allCards: updatedAllCards);
      _applyFilters();

      await _repository.deleteCard(cardId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete card: $e');
      rethrow;
    }
  }

  Future<void> toggleArchive(String cardId) async {
    try {
      final card = state.allCards.firstWhere((c) => c.id == cardId);
      final updatedCard = card.copyWith(isArchived: !card.isArchived);
      await updateCard(updatedCard);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to toggle archive: $e');
    }
  }

  Future<void> toggleFavorite(String cardId) async {
    try {
      final card = state.allCards.firstWhere((c) => c.id == cardId);
      final updatedCard = card.copyWith(isFavorite: !card.isFavorite);
      await updateCard(updatedCard);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to toggle favorite: $e');
    }
  }

  Future<void> clearAllCards() async {
    try {
      await _repository.clearAllCards();
      await loadCards();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to clear cards: $e');
    }
  }

  // ============================================================
  // Search and Filter Operations
  // ============================================================

  void searchCards(String query) {
    state = state.copyWith(searchQuery: query.trim());
    _applyFilters();
  }

  void filterByTags(List<String> tags) {
    state = state.copyWith(selectedTags: tags);
    _applyFilters();
  }

  void toggleTag(String tag) {
    final currentTags = List<String>.from(state.selectedTags);
    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      currentTags.add(tag);
    }
    state = state.copyWith(selectedTags: currentTags);
    _applyFilters();
  }

  void toggleShowOnlyDue() {
    state = state.copyWith(showOnlyDue: !state.showOnlyDue);
    _applyFilters();
  }

  void toggleShowOnlyFavorites() {
    state = state.copyWith(showOnlyFavorites: !state.showOnlyFavorites);
    _applyFilters();
  }

  void toggleShowOnlyDuplicates() {
    state = state.copyWith(showOnlyDuplicates: !state.showOnlyDuplicates);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedTags: [],
      showOnlyDue: false,
      showOnlyFavorites: false,
      showOnlyDuplicates: false,
    );
    _applyFilters();
  }

  void clearAllFilters() => clearFilters();

  // ============================================================
  // Duplicate Detection Integration
  // ============================================================

  void updateDuplicateCardIds(Set<String> duplicateIds) {
    state = state.copyWith(duplicateCardIds: duplicateIds);
    if (state.showOnlyDuplicates) {
      _applyFilters();
    }
  }

  // ============================================================
  // Private Methods
  // ============================================================

  void _applyFilters() {
    final activeLanguage = _getActiveLanguage();

    final filtered = state.allCards.where((card) {
      // Language filter
      if (activeLanguage.isNotEmpty && card.language != activeLanguage) {
        return false;
      }

      // Search filter
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        if (!card.frontText.toLowerCase().contains(query) &&
            !card.backText.toLowerCase().contains(query) &&
            !card.tags.any((tag) => tag.toLowerCase().contains(query))) {
          return false;
        }
      }

      // Tags filter
      if (state.selectedTags.isNotEmpty &&
          !state.selectedTags.every((tag) => card.tags.contains(tag))) {
        return false;
      }

      // Due filter
      if (state.showOnlyDue && !card.isDueForReview) {
        return false;
      }

      // Favorites filter
      if (state.showOnlyFavorites && !card.isFavorite) {
        return false;
      }

      // Duplicates filter
      if (state.showOnlyDuplicates &&
          !state.duplicateCardIds.contains(card.id)) {
        return false;
      }

      // Archived filter (exclude archived by default)
      if (card.isArchived) {
        return false;
      }

      return true;
    }).toList();

    state = state.copyWith(filteredCards: filtered);
  }

  // ============================================================
  // Sanitization & Validation (Private Business Logic)
  // ============================================================

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

  void _validateCard(CardModel card) {
    if (card.frontText.trim().isEmpty) {
      throw Exception('Front text is required');
    }
    if (card.backText.trim().isEmpty) {
      throw Exception('Back text is required');
    }
    if (!_isValidLanguageCode(card.language)) {
      throw Exception('Invalid language code: ${card.language}');
    }
  }

  static const int _maxTextLength = 500;
  static const int _maxNotesLength = 2000;
  static const int _maxExampleLength = 300;
  static const int _maxTagLength = 50;

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

  String _sanitizeCardText(String? input) {
    if (input == null || input.isEmpty) return '';
    return _applySanitizationPipeline(
      input,
      maxLength: _maxTextLength,
      preserveNewlines: false,
    );
  }

  String _sanitizeNotes(String? input) {
    if (input == null || input.isEmpty) return '';
    return _applySanitizationPipeline(
      input,
      maxLength: _maxNotesLength,
      preserveNewlines: true,
    );
  }

  String _sanitizeExample(String? input) {
    if (input == null || input.isEmpty) return '';
    return _applySanitizationPipeline(
      input,
      maxLength: _maxExampleLength,
      preserveNewlines: false,
    );
  }

  List<String> _sanitizeExamples(List<String>? examples) =>
      examples?.map(_sanitizeExample).where((e) => e.isNotEmpty).toList() ?? [];

  List<String> _sanitizeTags(List<String>? tags) =>
      tags
          ?.map((tag) => tag.trim().toLowerCase())
          .where((tag) => tag.isNotEmpty && tag.length <= _maxTagLength)
          .map((tag) => tag.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), ''))
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList() ??
      [];

  String _applySanitizationPipeline(
    String input, {
    required int maxLength,
    required bool preserveNewlines,
  }) {
    var s = input.trim();
    s = s
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?</script>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '');

    if (preserveNewlines) {
      s = s
          .split('\n')
          .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
          .join('\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    } else {
      s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return s.length > maxLength ? s.substring(0, maxLength) : s;
  }

  String? _sanitizeLanguageCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final sanitized = code.trim().toLowerCase();
    return _isValidLanguageCode(sanitized) ? sanitized : null;
  }

  bool _isValidLanguageCode(String? code) {
    if (code == null || code.isEmpty) return false;
    return _supportedLanguages.contains(code.toLowerCase());
  }
}
