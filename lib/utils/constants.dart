/// Application constants and configuration values
class AppConstants {
  // API Configuration
  static const String iconifyBaseUrl = 'https://api.iconify.design';
  static const int defaultSearchLimit = 999;
  static const int searchDebounceMs = 300;
  
  // UI Configuration
  static const double iconGridItemSize = 48.0;
  static const double iconGridSpacing = 4.0;
  static const double iconGridPadding = 16.0;
  static const int minGridColumns = 3;
  static const int maxGridColumns = 12;
  static const double gridItemWidth = 60.0;
  
  // Error messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String generalErrorMessage = 'Something went wrong. Please try again.';
}

/// Theme-related constants
class ThemeConstants {
  static const double borderRadius = 12.0;
  static const double cardElevation = 1.0;
  static const double selectedCardElevation = 4.0;
  static const double iconBorderWidth = 2.0;
}
