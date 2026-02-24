import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/mascot/domain/mascot_notifier.dart';
import 'package:lingua_flutter/features/mascot/domain/mascot_state.dart';
import 'package:lingua_flutter/features/mascot/presentation/widgets/mascot_widget.dart';

void main() {
  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        mascotNotifierProvider.overrideWith(() => _TestMascotNotifier()),
      ],
    );
  }

  group('MascotNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = makeContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.idle);
        expect(state.currentMessage, isNull);
        expect(state.isVisible, true);
      });
    });

    group('showMessage', () {
      test('should show message from welcome context', () {
        container.read(mascotNotifierProvider.notifier).showMessage('welcome');
        final state = container.read(mascotNotifierProvider);
        expect(state.currentMessage, isNotNull);
        expect(state.currentState, MascotState.idle);
      });

      test('should show message from encouragement context', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showMessage('encouragement');
        expect(
          container.read(mascotNotifierProvider).currentMessage,
          isNotNull,
        );
      });

      test('should show message from celebration context', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showMessage('celebration');
        expect(
          container.read(mascotNotifierProvider).currentMessage,
          isNotNull,
        );
      });

      test('should show message from motivation context', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showMessage('motivation');
        expect(
          container.read(mascotNotifierProvider).currentMessage,
          isNotNull,
        );
      });

      test('should show message from tips context', () {
        container.read(mascotNotifierProvider.notifier).showMessage('tips');
        expect(
          container.read(mascotNotifierProvider).currentMessage,
          isNotNull,
        );
      });

      test('should show message from idle context', () {
        container.read(mascotNotifierProvider.notifier).showMessage('idle');
        expect(
          container.read(mascotNotifierProvider).currentMessage,
          isNotNull,
        );
      });

      test('should allow custom state with message', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showMessage('welcome', mascotState: MascotState.excited);
        expect(
          container.read(mascotNotifierProvider).currentState,
          MascotState.excited,
        );
      });

      test('should not show message for invalid context', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showMessage('nonexistent_context');
        expect(container.read(mascotNotifierProvider).currentMessage, isNull);
      });
    });

    group('showCustomMessage', () {
      test('should show custom message', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showCustomMessage('Hello, test!');
        final state = container.read(mascotNotifierProvider);
        expect(state.currentMessage, 'Hello, test!');
        expect(state.currentState, MascotState.idle);
      });

      test('should allow custom state with custom message', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showCustomMessage(
              'Excited message!',
              mascotState: MascotState.excited,
            );
        final state = container.read(mascotNotifierProvider);
        expect(state.currentMessage, 'Excited message!');
        expect(state.currentState, MascotState.excited);
      });
    });

    group('hideMessage', () {
      test('should hide current message', () {
        final notifier = container.read(mascotNotifierProvider.notifier);
        notifier.showCustomMessage('Test message');
        expect(
          container.read(mascotNotifierProvider).currentMessage,
          isNotNull,
        );

        notifier.hideMessage();

        final state = container.read(mascotNotifierProvider);
        expect(state.currentMessage, isNull);
        expect(state.currentState, MascotState.idle);
      });
    });

    group('setState', () {
      test('should set mascot state', () {
        container
            .read(mascotNotifierProvider.notifier)
            .setState(MascotState.thinking);
        expect(
          container.read(mascotNotifierProvider).currentState,
          MascotState.thinking,
        );
      });

      test('should not affect current message', () {
        final notifier = container.read(mascotNotifierProvider.notifier);
        notifier.showCustomMessage('Test');
        notifier.setState(MascotState.celebrating);

        final state = container.read(mascotNotifierProvider);
        expect(state.currentMessage, 'Test');
        expect(state.currentState, MascotState.celebrating);
      });
    });

    group('setVisibility', () {
      test('should set visibility to false', () {
        container.read(mascotNotifierProvider.notifier).setVisibility(false);
        expect(container.read(mascotNotifierProvider).isVisible, false);
      });

      test('should set visibility to true', () {
        final notifier = container.read(mascotNotifierProvider.notifier);
        notifier.setVisibility(false);
        notifier.setVisibility(true);
        expect(container.read(mascotNotifierProvider).isVisible, true);
      });
    });

    group('celebrate', () {
      test('should set celebrating state', () {
        container.read(mascotNotifierProvider.notifier).celebrate();
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.celebrating);
        expect(state.currentMessage, isNotNull);
      });

      test('should show custom celebration message', () {
        container
            .read(mascotNotifierProvider.notifier)
            .celebrate('Custom celebration!');
        final state = container.read(mascotNotifierProvider);
        expect(state.currentMessage, 'Custom celebration!');
        expect(state.currentState, MascotState.celebrating);
      });
    });

    group('showExcitement', () {
      test('should set excited state', () {
        container.read(mascotNotifierProvider.notifier).showExcitement();
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.excited);
        expect(state.currentMessage, isNotNull);
      });

      test('should show custom excitement message', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showExcitement('So exciting!');
        final state = container.read(mascotNotifierProvider);
        expect(state.currentMessage, 'So exciting!');
        expect(state.currentState, MascotState.excited);
      });
    });

    group('reactToAction', () {
      test('should react to streakAchieved action', () {
        container
            .read(mascotNotifierProvider.notifier)
            .reactToAction(MascotAction.streakAchieved);
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.celebrating);
        expect(state.currentMessage, contains('streak'));
      });

      test('should react to sessionCompleted action', () {
        container
            .read(mascotNotifierProvider.notifier)
            .reactToAction(MascotAction.sessionCompleted);
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.celebrating);
        expect(state.currentMessage, contains('Session complete'));
      });

      test('should react to firstVisit action', () {
        container
            .read(mascotNotifierProvider.notifier)
            .reactToAction(MascotAction.firstVisit);
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.excited);
        expect(state.currentMessage, isNotNull);
      });

      test('should react to longAbsence action', () {
        container
            .read(mascotNotifierProvider.notifier)
            .reactToAction(MascotAction.longAbsence);
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.excited);
        expect(state.currentMessage, contains('Welcome back'));
      });

      test('should react to struggling action', () {
        container
            .read(mascotNotifierProvider.notifier)
            .reactToAction(MascotAction.struggling);
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.thinking);
        expect(state.currentMessage, isNotNull);
      });

      test('should react to tapped action', () {
        container
            .read(mascotNotifierProvider.notifier)
            .reactToAction(MascotAction.tapped);
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.excited);
        expect(state.currentMessage, isNotNull);
      });
    });

    group('showContextualMessage', () {
      test('should show motivation when not studied today with due cards', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showContextualMessage(
              totalCards: 10,
              dueCards: 5,
              currentStreak: 3,
              hasStudiedToday: false,
            );
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.thinking);
        expect(state.currentMessage, isNotNull);
      });

      test('should celebrate week streak milestone', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showContextualMessage(
              totalCards: 10,
              dueCards: 0,
              currentStreak: 7,
              hasStudiedToday: true,
            );
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.celebrating);
        expect(state.currentMessage, contains('7 day streak'));
      });

      test('should celebrate when all cards done', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showContextualMessage(
              totalCards: 10,
              dueCards: 0,
              currentStreak: 3,
              hasStudiedToday: true,
            );
        expect(
          container.read(mascotNotifierProvider).currentState,
          MascotState.celebrating,
        );
      });

      test('should prompt to create first card when no cards', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showContextualMessage(
              totalCards: 0,
              dueCards: 0,
              currentStreak: 0,
              hasStudiedToday: false,
            );
        final state = container.read(mascotNotifierProvider);
        expect(state.currentState, MascotState.excited);
        expect(state.currentMessage, contains('first card'));
      });

      test('should show welcome message by default', () {
        container
            .read(mascotNotifierProvider.notifier)
            .showContextualMessage(
              totalCards: 10,
              dueCards: 5,
              currentStreak: 3,
              hasStudiedToday: true,
            );
        expect(
          container.read(mascotNotifierProvider).currentMessage,
          isNotNull,
        );
      });

      test('should only show message once per session', () {
        final notifier = container.read(mascotNotifierProvider.notifier);
        notifier.showContextualMessage(
          totalCards: 10,
          dueCards: 5,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        final firstMessage = container
            .read(mascotNotifierProvider)
            .currentMessage;

        notifier.showContextualMessage(
          totalCards: 0,
          dueCards: 0,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        // Second call should not change the message
        expect(
          container.read(mascotNotifierProvider).currentMessage,
          firstMessage,
        );
      });
    });

    group('resetSession', () {
      test('should allow new contextual message after reset', () {
        final notifier = container.read(mascotNotifierProvider.notifier);
        notifier.showContextualMessage(
          totalCards: 10,
          dueCards: 5,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        final firstMessage = container
            .read(mascotNotifierProvider)
            .currentMessage;
        notifier.hideMessage();
        notifier.resetSession();

        notifier.showContextualMessage(
          totalCards: 0,
          dueCards: 0,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        // After reset, should show new message
        final state = container.read(mascotNotifierProvider);
        expect(state.currentMessage, isNotNull);
        expect(state.currentMessage, isNot(equals(firstMessage)));
      });
    });
  });

  group('MascotAction', () {
    test('should have all expected values', () {
      expect(MascotAction.values.length, 7);
      expect(MascotAction.values, contains(MascotAction.cardCompleted));
      expect(MascotAction.values, contains(MascotAction.streakAchieved));
      expect(MascotAction.values, contains(MascotAction.sessionCompleted));
      expect(MascotAction.values, contains(MascotAction.firstVisit));
      expect(MascotAction.values, contains(MascotAction.longAbsence));
      expect(MascotAction.values, contains(MascotAction.struggling));
      expect(MascotAction.values, contains(MascotAction.tapped));
    });
  });
}

// Use notifier with animations disabled for testing
class _TestMascotNotifier extends MascotNotifier {
  @override
  MascotStateData build() {
    return const MascotStateData(animationsEnabled: false);
  }
}
