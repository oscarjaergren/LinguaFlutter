import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/logger_service.dart';
import '../../../shared/domain/models/icon_model.dart';
import '../data/iconify_service.dart';
import 'icon_state.dart';

final iconNotifierProvider = NotifierProvider<IconNotifier, IconState>(() {
  return IconNotifier();
});

class IconNotifier extends Notifier<IconState> {
  late final IconifyService _iconifyService;

  /// Optional factory for testing; if null, creates a default IconifyService.
  static IconifyService Function()? serviceFactory;

  @override
  IconState build() {
    _iconifyService = serviceFactory != null
        ? serviceFactory!()
        : IconifyService();
    // In Riverpod, disposal of state can be handled via ref.onDispose
    ref.onDispose(() {
      _iconifyService.dispose();
    });
    return const IconState();
  }

  /// Search for icons based on query
  Future<void> searchIcons(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        searchResults: [],
        searchQuery: '',
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      searchQuery: query,
      errorMessage: null,
    );

    try {
      final results = await _iconifyService.searchIcons(query);
      state = state.copyWith(
        searchResults: results,
        errorMessage: null,
        isLoading: false,
      );
    } catch (e) {
      LoggerService.error('Icon search error', e);
      state = state.copyWith(
        errorMessage: 'Error searching icons: $e',
        searchResults: [],
        isLoading: false,
      );
    }
  }

  /// Select an icon for use in cards
  void selectIcon(IconModel icon) {
    state = state.copyWith(selectedIcon: icon);
  }

  /// Clear the selected icon
  void clearSelection() {
    state = state.copyWith(selectedIcon: null);
  }

  /// Clear search results and reset state
  void clearSearch() {
    state = state.copyWith(
      searchResults: [],
      searchQuery: '',
      errorMessage: null,
      isLoading: false,
    );
  }

  /// Get popular icon collections for initial display
  Future<void> loadPopularCollections() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Load some popular icons from common collections
      final popularSearches = ['home', 'user', 'heart', 'star', 'check'];
      final results = <IconModel>[];

      for (final search in popularSearches) {
        final icons = await _iconifyService.searchIcons(search, limit: 4);
        results.addAll(icons);
      }

      state = state.copyWith(
        searchResults: results,
        searchQuery: 'Popular Icons',
        errorMessage: null,
        isLoading: false,
      );
    } catch (e) {
      LoggerService.error('Popular icons error', e);
      state = state.copyWith(
        errorMessage: 'Error loading popular icons: $e',
        searchResults: [],
        isLoading: false,
      );
    }
  }
}
