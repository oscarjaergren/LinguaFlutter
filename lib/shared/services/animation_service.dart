import 'package:flutter/material.dart';

/// Abstract service for controlling mascot animations
/// Allows for different implementations in production vs test environments
abstract class AnimationService {
  /// Whether animations should be enabled
  bool get animationsEnabled;

  /// Start a repeating animation controller
  void startRepeating(AnimationController controller, {bool reverse = false});

  /// Schedule a delayed callback
  void scheduleDelayed(Duration delay, VoidCallback callback);

  /// Forward an animation controller
  TickerFuture forward(AnimationController controller);

  /// Reverse an animation controller
  TickerFuture reverse(AnimationController controller);

  /// Stop and reset an animation controller
  void stopAndReset(AnimationController controller);
}

/// Production implementation that enables all animations
class ProductionAnimationService implements AnimationService {
  const ProductionAnimationService();

  @override
  bool get animationsEnabled => true;

  @override
  void startRepeating(AnimationController controller, {bool reverse = false}) {
    controller.repeat(reverse: reverse);
  }

  @override
  void scheduleDelayed(Duration delay, VoidCallback callback) {
    Future.delayed(delay, callback);
  }

  @override
  TickerFuture forward(AnimationController controller) {
    return controller.forward();
  }

  @override
  TickerFuture reverse(AnimationController controller) {
    return controller.reverse();
  }

  @override
  void stopAndReset(AnimationController controller) {
    controller.stop();
    controller.reset();
  }
}

/// Test implementation that disables animations
class TestAnimationService implements AnimationService {
  const TestAnimationService();

  @override
  bool get animationsEnabled => false;

  @override
  void startRepeating(AnimationController controller, {bool reverse = false}) {
    // No-op in tests
  }

  @override
  void scheduleDelayed(Duration delay, VoidCallback callback) {
    // Execute immediately in tests
    callback();
  }

  @override
  TickerFuture forward(AnimationController controller) {
    // Return completed future without animating
    return TickerFuture.complete();
  }

  @override
  TickerFuture reverse(AnimationController controller) {
    // Return completed future without animating
    return TickerFuture.complete();
  }

  @override
  void stopAndReset(AnimationController controller) {
    controller.stop();
    controller.reset();
  }
}
