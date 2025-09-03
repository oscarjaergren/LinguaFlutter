import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing search history and user preferences
class PreferencesService {
  static const String _searchHistoryKey = 'search_history';
  static const String _selectedIconKey = 'selected_icon';
  static const int _maxHistoryItems = 10;

  /// Save a search term to history
  static Future<void> saveSearchTerm(String term) async {
    if (term.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    
    // Remove if already exists to avoid duplicates
    history.remove(term);
    
    // Add to beginning of list
    history.insert(0, term);
    
    // Limit to max items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    await prefs.setStringList(_searchHistoryKey, history);
  }

  /// Get search history
  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  /// Clear search history
  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  /// Save the last selected icon ID
  static Future<void> saveSelectedIcon(String iconId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedIconKey, iconId);
  }

  /// Get the last selected icon ID
  static Future<String?> getSelectedIcon() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedIconKey);
  }

  /// Clear the selected icon
  static Future<void> clearSelectedIcon() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedIconKey);
  }
}
