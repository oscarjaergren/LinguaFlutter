import 'package:flutter/foundation.dart';
import '../presentation/widgets/mascot_widget.dart';

/// Provider for managing mascot state and interactions
class MascotProvider extends ChangeNotifier {
  MascotState _currentState = MascotState.idle;
  String? _currentMessage;
  bool _isVisible = true;
  bool _hasInitializedForSession = false;
  bool animationsEnabled;

  MascotProvider({this.animationsEnabled = true});

  // Getters
  MascotState get currentState => _currentState;
  String? get currentMessage => _currentMessage;
  bool get isVisible => _isVisible;

  // Predefined messages for different contexts
  static const Map<String, List<String>> _contextMessages = {
    'welcome': [
      'Welcome back! Ready to learn?',
      'Let\'s make today count!',
      'Time to expand your vocabulary!',
      'Ready for some language practice?',
    ],
    'encouragement': [
      'You\'re doing great!',
      'Keep up the excellent work!',
      'Learning is a journey, not a race!',
      'Every card brings you closer to fluency!',
    ],
    'celebration': [
      'Fantastic! You\'re on fire! 🔥',
      'Amazing progress today!',
      'You\'re becoming a language master!',
      'Incredible streak! Keep it going!',
    ],
    'motivation': [
      'Don\'t give up! You\'ve got this!',
      'Practice makes perfect!',
      'Small steps lead to big achievements!',
      'Consistency is key to success!',
    ],
    'tips': [
      'Try reviewing cards daily for best results!',
      'Focus on your difficult cards first!',
      'Use the favorites feature for important words!',
      'Regular practice beats cramming every time!',
    ],
    'idle': [
      'Tap me for a tip!',
      'Ready when you are!',
      'Let\'s learn something new!',
      'Your language journey awaits!',
    ],
  };

  /// Show a message from a specific context
  void showMessage(String context, {MascotState? state}) {
    final messages = _contextMessages[context];
    if (messages != null && messages.isNotEmpty) {
      final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
      _currentMessage = messages[randomIndex];
      _currentState = state ?? MascotState.idle;
      notifyListeners();
      
      // Auto-hide message after 4 seconds
      if (animationsEnabled) {
        Future.delayed(const Duration(seconds: 4), () {
          hideMessage();
        });
      }
    }
  }

  /// Show a custom message
  void showCustomMessage(String message, {MascotState? state}) {
    _currentMessage = message;
    _currentState = state ?? MascotState.idle;
    notifyListeners();
    
    // Auto-hide message after 4 seconds
    if (animationsEnabled) {
      Future.delayed(const Duration(seconds: 4), () {
        hideMessage();
      });
    }
  }

  /// Hide the current message
  void hideMessage() {
    _currentMessage = null;
    _currentState = MascotState.idle;
    notifyListeners();
  }

  /// Set mascot state without message
  void setState(MascotState state) {
    _currentState = state;
    notifyListeners();
  }

  /// Show/hide mascot
  void setVisibility(bool visible) {
    _isVisible = visible;
    notifyListeners();
  }

  /// Celebrate achievement
  void celebrate([String? customMessage]) {
    _currentState = MascotState.celebrating;
    _currentMessage = customMessage ?? _getRandomMessage('celebration');
    notifyListeners();
    
    if (animationsEnabled) {
      // Return to idle after celebration
      Future.delayed(const Duration(seconds: 3), () {
        _currentState = MascotState.idle;
        notifyListeners();
      });
      
      // Hide message after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        hideMessage();
      });
    }
  }

  /// Show excitement
  void showExcitement([String? customMessage]) {
    _currentState = MascotState.excited;
    _currentMessage = customMessage ?? _getRandomMessage('encouragement');
    notifyListeners();
    
    if (animationsEnabled) {
      // Return to idle after excitement
      Future.delayed(const Duration(seconds: 2), () {
        _currentState = MascotState.idle;
        notifyListeners();
      });
      
      // Hide message after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        hideMessage();
      });
    }
  }

  /// React to user actions
  void reactToAction(MascotAction action) {
    switch (action) {
      case MascotAction.cardCompleted:
        if (DateTime.now().millisecond % 3 == 0) { // Random chance
          showExcitement();
        }
        break;
      case MascotAction.streakAchieved:
        celebrate('Amazing streak! You\'re unstoppable! 🎉');
        break;
      case MascotAction.sessionCompleted:
        celebrate('Session complete! Great job! 🌟');
        break;
      case MascotAction.firstVisit:
        showMessage('welcome', state: MascotState.excited);
        break;
      case MascotAction.longAbsence:
        showCustomMessage('Welcome back! I missed you!', state: MascotState.excited);
        break;
      case MascotAction.struggling:
        showMessage('motivation', state: MascotState.thinking);
        break;
      case MascotAction.tapped:
        final messages = [
          ..._contextMessages['tips']!,
          ..._contextMessages['encouragement']!,
          ..._contextMessages['motivation']!,
        ];
        final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
        showCustomMessage(messages[randomIndex], state: MascotState.excited);
        break;
    }
  }

  String _getRandomMessage(String context) {
    final messages = _contextMessages[context];
    if (messages == null || messages.isEmpty) return '';
    
    final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
    return messages[randomIndex];
  }

  /// Get contextual message based on app state (only once per session)
  void showContextualMessage({
    required int totalCards,
    required int dueCards,
    required int currentStreak,
    required bool hasStudiedToday,
  }) {
    // Only show new message if we haven't initialized for this session
    if (_hasInitializedForSession) return;
    
    _hasInitializedForSession = true;
    
    if (!hasStudiedToday && dueCards > 0) {
      showMessage('motivation', state: MascotState.thinking);
    } else if (currentStreak > 0 && currentStreak % 7 == 0) {
      celebrate('${currentStreak} day streak! You\'re amazing! 🔥');
    } else if (dueCards == 0 && totalCards > 0) {
      showMessage('celebration', state: MascotState.celebrating);
    } else if (totalCards == 0) {
      showCustomMessage('Let\'s create your first card!', state: MascotState.excited);
    } else {
      // Show welcome message
      showMessage('welcome');
    }
  }
  
  /// Reset session state (call when screen is reopened)
  void resetSession() {
    _hasInitializedForSession = false;
  }
}

/// Enum for different mascot actions/triggers
enum MascotAction {
  cardCompleted,
  streakAchieved,
  sessionCompleted,
  firstVisit,
  longAbsence,
  struggling,
  tapped,
}
