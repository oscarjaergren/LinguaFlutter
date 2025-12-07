import '../../../../shared/services/animation_service.dart';

/// Service for mascot behavior and animation logic
class MascotService {
  final AnimationService _animationService;
  
  MascotService({AnimationService? animationService})
      : _animationService = animationService ?? const ProductionAnimationService();

  /// Get mascot reaction based on card review performance
  MascotReaction getMascotReaction({
    required double sessionAccuracy,
    required int cardsReviewed,
    required bool wasLastAnswerCorrect,
  }) {
    if (cardsReviewed == 0) {
      return MascotReaction.idle;
    }
    
    if (wasLastAnswerCorrect) {
      if (sessionAccuracy >= 0.9) {
        return MascotReaction.excellent;
      } else if (sessionAccuracy >= 0.7) {
        return MascotReaction.good;
      } else {
        return MascotReaction.encouraging;
      }
    } else {
      if (sessionAccuracy < 0.3) {
        return MascotReaction.concerned;
      } else {
        return MascotReaction.supportive;
      }
    }
  }

  /// Get mascot message based on performance
  String getMascotMessage(MascotReaction reaction) {
    return switch (reaction) {
      MascotReaction.idle => "Ready to learn? Let's go!",
      MascotReaction.excellent => "Amazing work! You're on fire! 🔥",
      MascotReaction.good => "Great job! Keep it up! 👍",
      MascotReaction.encouraging => "You're doing well! Stay focused! 💪",
      MascotReaction.supportive => "Don't worry, you've got this! 🌟",
      MascotReaction.concerned => "Take your time, we'll get through this together! 🤗",
      MascotReaction.celebrating => "Fantastic session! You're improving! 🎉",
    };
  }

  /// Get animation duration based on reaction type
  Duration getAnimationDuration(MascotReaction reaction) {
    if (!_animationService.animationsEnabled) {
      return Duration.zero;
    }
    
    return switch (reaction) {
      MascotReaction.idle => const Duration(seconds: 2),
      MascotReaction.excellent => const Duration(seconds: 3),
      MascotReaction.good => const Duration(seconds: 2),
      MascotReaction.encouraging => const Duration(milliseconds: 1500),
      MascotReaction.supportive => const Duration(seconds: 2),
      MascotReaction.concerned => const Duration(milliseconds: 1500),
      MascotReaction.celebrating => const Duration(seconds: 4),
    };
  }

  /// Determine if mascot should show celebration animation
  bool shouldCelebrate({
    required int sessionCardsReviewed,
    required double sessionAccuracy,
    required bool isSessionComplete,
  }) {
    if (!isSessionComplete) return false;
    
    return sessionCardsReviewed >= 5 && sessionAccuracy >= 0.8;
  }

  /// Get mascot encouragement frequency (how often to show encouraging messages)
  int getEncouragementFrequency(double currentAccuracy) {
    if (currentAccuracy >= 0.8) return 10; // Every 10 cards
    if (currentAccuracy >= 0.6) return 7;  // Every 7 cards
    if (currentAccuracy >= 0.4) return 5;  // Every 5 cards
    return 3; // Every 3 cards for struggling users
  }
}

/// Enum for different mascot reactions
enum MascotReaction {
  idle,
  excellent,
  good,
  encouraging,
  supportive,
  concerned,
  celebrating,
}
