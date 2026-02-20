/// In-memory rate limiter for UX feedback only.
///
/// This is NOT a security control — limits reset on every app restart and
/// can be bypassed trivially. Actual enforcement must happen server-side
/// (e.g. Supabase RLS or a server-side rate limiter).
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  final Map<String, List<DateTime>> _actionTimestamps = {};

  /// Rate limit configurations
  static const Map<String, RateLimitConfig> _configs = {
    'card_creation': RateLimitConfig(maxActions: 50, windowMinutes: 60),
    'card_bulk_create': RateLimitConfig(maxActions: 100, windowMinutes: 60),
    'card_update': RateLimitConfig(maxActions: 100, windowMinutes: 60),
    'card_delete': RateLimitConfig(maxActions: 50, windowMinutes: 60),
  };

  /// Check if action is allowed for user
  bool isAllowed({required String userId, required String action}) {
    final config = _configs[action];
    if (config == null) return true; // No limit configured

    final key = '$userId:$action';
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

    // Get or create timestamp list
    _actionTimestamps[key] ??= [];
    final timestamps = _actionTimestamps[key]!;

    // Remove old timestamps outside the window
    timestamps.removeWhere((timestamp) => timestamp.isBefore(windowStart));

    // Check if limit exceeded
    if (timestamps.length >= config.maxActions) {
      return false;
    }

    // Record this action
    timestamps.add(now);
    return true;
  }

  /// Get remaining actions for user
  int getRemainingActions({required String userId, required String action}) {
    final config = _configs[action];
    if (config == null) return -1; // No limit

    final key = '$userId:$action';
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

    final timestamps = _actionTimestamps[key] ?? [];
    final recentActions = timestamps
        .where((t) => t.isAfter(windowStart))
        .length;

    return (config.maxActions - recentActions).clamp(0, config.maxActions);
  }

  /// Get time until next action is allowed
  Duration? getTimeUntilNextAction({
    required String userId,
    required String action,
  }) {
    final config = _configs[action];
    if (config == null) return null;

    final key = '$userId:$action';
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: config.windowMinutes));

    final timestamps = _actionTimestamps[key] ?? [];
    final recentTimestamps = timestamps
        .where((t) => t.isAfter(windowStart))
        .toList();

    if (recentTimestamps.length < config.maxActions) {
      return Duration.zero; // Action allowed now
    }

    // Find oldest timestamp in window
    recentTimestamps.sort();
    final oldestInWindow = recentTimestamps.first;
    final whenOldestExpires = oldestInWindow.add(
      Duration(minutes: config.windowMinutes),
    );

    return whenOldestExpires.difference(now);
  }

  /// Clear rate limit data for user (e.g., on logout)
  void clearUser(String userId) {
    _actionTimestamps.removeWhere((key, _) => key.startsWith('$userId:'));
  }

  /// Clear all rate limit data
  void clearAll() {
    _actionTimestamps.clear();
  }

  /// Get human-readable error message
  String getErrorMessage({required String userId, required String action}) {
    final config = _configs[action];
    if (config == null) return 'Rate limit exceeded';

    final timeUntil = getTimeUntilNextAction(userId: userId, action: action);

    if (timeUntil != null && timeUntil > Duration.zero) {
      final minutes = timeUntil.inMinutes;
      final seconds = timeUntil.inSeconds % 60;

      if (minutes > 0) {
        return 'Rate limit exceeded. Try again in $minutes minute${minutes != 1 ? 's' : ''}.';
      } else {
        return 'Rate limit exceeded. Try again in $seconds second${seconds != 1 ? 's' : ''}.';
      }
    }

    return 'Rate limit exceeded. Maximum ${config.maxActions} actions per ${config.windowMinutes} minutes.';
  }
}

/// Configuration for rate limiting
class RateLimitConfig {
  final int maxActions;
  final int windowMinutes;

  const RateLimitConfig({
    required this.maxActions,
    required this.windowMinutes,
  });
}

/// Exception thrown when rate limit is exceeded
class RateLimitException implements Exception {
  final String message;
  final Duration? retryAfter;

  const RateLimitException(this.message, {this.retryAfter});

  @override
  String toString() => message;
}
