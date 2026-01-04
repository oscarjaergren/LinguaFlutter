import 'package:flutter/foundation.dart';
import '../../../shared/services/logger_service.dart';
import 'package:lingua_flutter/shared/domain/models/icon_model.dart';
import '../data/iconify_service.dart';

/// Provider for managing icon search state and selected icons
class IconProvider extends ChangeNotifier {
  final IconifyService _iconifyService;

  /// Create an IconProvider with optional service injection for testing.
  IconProvider({IconifyService? iconifyService})
    : _iconifyService = iconifyService ?? IconifyService();

  // Search state
  List<IconModel> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;

  // Selected icon state
  IconModel? _selectedIcon;

  // Getters
  List<IconModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  IconModel? get selectedIcon => _selectedIcon;

  /// Search for icons based on query
  Future<void> searchIcons(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _searchQuery = query;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _iconifyService.searchIcons(query);
      _searchResults = results;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error searching icons: $e';
      _searchResults = [];
      LoggerService.error('Icon search error', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select an icon for use in cards
  void selectIcon(IconModel icon) {
    _selectedIcon = icon;
    notifyListeners();
  }

  /// Clear the selected icon
  void clearSelection() {
    _selectedIcon = null;
    notifyListeners();
  }

  /// Clear search results and reset state
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Get popular icon collections for initial display
  Future<void> loadPopularCollections() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load some popular icons from common collections
      final popularSearches = ['home', 'user', 'heart', 'star', 'check'];
      final results = <IconModel>[];

      for (final search in popularSearches) {
        final icons = await _iconifyService.searchIcons(search, limit: 4);
        results.addAll(icons);
      }

      _searchResults = results;
      _searchQuery = 'Popular Icons';
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error loading popular icons: $e';
      _searchResults = [];
      LoggerService.error('Popular icons error', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _iconifyService.dispose();
    super.dispose();
  }
}
