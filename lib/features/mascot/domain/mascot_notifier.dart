import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/widgets/mascot_widget.dart';
import 'mascot_state.dart';



// Pre-define MascotAction here instead since it's used directly in the old provider
enum MascotAction {
  cardCompleted,
  streakAchieved,
  sessionCompleted,
  firstVisit,
  longAbsence,
  struggling,
  tapped,
}

final mascotNotifierProvider = NotifierProvider<MascotNotifier, MascotStateData>(() {
  return MascotNotifier();
});

class MascotNotifier extends Notifier<MascotStateData> {
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

  @override
  MascotStateData build() {
    return const MascotStateData();
  }
  
  void setAnimationsEnabled(bool enabled) {
    state = state.copyWith(animationsEnabled: enabled);
  }

  /// Show a message from a specific context
  void showMessage(String context, {MascotState? mascotState}) {
    final messages = _contextMessages[context];
    if (messages != null && messages.isNotEmpty) {
      final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
      state = state.copyWith(
        currentMessage: messages[randomIndex],
        currentState: mascotState ?? MascotState.idle,
      );

      // Auto-hide message after 4 seconds
      if (state.animationsEnabled) {
        Future.delayed(const Duration(seconds: 4), () {
          hideMessage();
        });
      }
    }
  }

  /// Show a custom message
  void showCustomMessage(String message, {MascotState? mascotState}) {
    state = state.copyWith(
      currentMessage: message,
      currentState: mascotState ?? MascotState.idle,
    );

    // Auto-hide message after 4 seconds
    if (state.animationsEnabled) {
      Future.delayed(const Duration(seconds: 4), () {
        hideMessage();
      });
    }
  }

  /// Hide the current message
  void hideMessage() {
    state = state.copyWith(
      currentMessage: null,
      currentState: MascotState.idle,
    );
  }

  /// Set mascot state without message
  void setState(MascotState mascotState) {
    state = state.copyWith(currentState: mascotState);
  }

  /// Show/hide mascot
  void setVisibility(bool visible) {
    state = state.copyWith(isVisible: visible);
  }

  /// Celebrate achievement
  void celebrate([String? customMessage]) {
    state = state.copyWith(
      currentState: MascotState.celebrating,
      currentMessage: customMessage ?? _getRandomMessage('celebration')
    );

    if (state.animationsEnabled) {
      // Return to idle after celebration
      Future.delayed(const Duration(seconds: 3), () {
        state = state.copyWith(currentState: MascotState.idle);
      });

      // Hide message after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        hideMessage();
      });
    }
  }

  /// Show excitement
  void showExcitement([String? customMessage]) {
    state = state.copyWith(
      currentState: MascotState.excited,
      currentMessage: customMessage ?? _getRandomMessage('encouragement')
    );

    if (state.animationsEnabled) {
      // Return to idle after excitement
      Future.delayed(const Duration(seconds: 2), () {
        state = state.copyWith(currentState: MascotState.idle);
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
        if (DateTime.now().millisecond % 3 == 0) {
          // Random chance
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
        showMessage('welcome', mascotState: MascotState.excited);
        break;
      case MascotAction.longAbsence:
        showCustomMessage('Welcome back! I missed you!', mascotState: MascotState.excited);
        break;
      case MascotAction.struggling:
        showMessage('motivation', mascotState: MascotState.thinking);
        break;
      case MascotAction.tapped:
        final messages = [
          ..._contextMessages['tips']!,
          ..._contextMessages['encouragement']!,
          ..._contextMessages['motivation']!,
        ];
        final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
        showCustomMessage(messages[randomIndex], mascotState: MascotState.excited);
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
    if (state.hasInitializedForSession) return;

    state = state.copyWith(hasInitializedForSession: true);

    if (!hasStudiedToday && dueCards > 0) {
      showMessage('motivation', mascotState: MascotState.thinking);
    } else if (currentStreak > 0 && currentStreak % 7 == 0) {
      celebrate('$currentStreak day streak! You\'re amazing! 🔥');
    } else if (dueCards == 0 && totalCards > 0) {
      showMessage('celebration', mascotState: MascotState.celebrating);
    } else if (totalCards == 0) {
      showCustomMessage('Let\'s create your first card!', mascotState: MascotState.excited);
    } else {
      // Show welcome message
      showMessage('welcome');
    }
  }

  /// Reset session state (call when screen is reopened)
  void resetSession() {
    state = state.copyWith(hasInitializedForSession: false);
  }
}
