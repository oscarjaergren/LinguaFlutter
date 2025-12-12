import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/mascot/domain/mascot_provider.dart';
import 'package:lingua_flutter/features/mascot/presentation/widgets/mascot_widget.dart';

void main() {
  group('MascotProvider', () {
    late MascotProvider provider;

    setUp(() {
      // Disable animations to avoid async delays in tests
      provider = MascotProvider(animationsEnabled: false);
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(provider.currentState, MascotState.idle);
        expect(provider.currentMessage, isNull);
        expect(provider.isVisible, true);
      });

      test('should have animations enabled by default', () {
        final defaultProvider = MascotProvider();
        expect(defaultProvider.animationsEnabled, true);
      });
    });

    group('showMessage', () {
      test('should show message from welcome context', () {
        provider.showMessage('welcome');

        expect(provider.currentMessage, isNotNull);
        expect(provider.currentState, MascotState.idle);
      });

      test('should show message from encouragement context', () {
        provider.showMessage('encouragement');

        expect(provider.currentMessage, isNotNull);
      });

      test('should show message from celebration context', () {
        provider.showMessage('celebration');

        expect(provider.currentMessage, isNotNull);
      });

      test('should show message from motivation context', () {
        provider.showMessage('motivation');

        expect(provider.currentMessage, isNotNull);
      });

      test('should show message from tips context', () {
        provider.showMessage('tips');

        expect(provider.currentMessage, isNotNull);
      });

      test('should show message from idle context', () {
        provider.showMessage('idle');

        expect(provider.currentMessage, isNotNull);
      });

      test('should allow custom state with message', () {
        provider.showMessage('welcome', state: MascotState.excited);

        expect(provider.currentState, MascotState.excited);
      });

      test('should not show message for invalid context', () {
        provider.showMessage('nonexistent_context');

        expect(provider.currentMessage, isNull);
      });
    });

    group('showCustomMessage', () {
      test('should show custom message', () {
        provider.showCustomMessage('Hello, test!');

        expect(provider.currentMessage, 'Hello, test!');
        expect(provider.currentState, MascotState.idle);
      });

      test('should allow custom state with custom message', () {
        provider.showCustomMessage('Excited message!', state: MascotState.excited);

        expect(provider.currentMessage, 'Excited message!');
        expect(provider.currentState, MascotState.excited);
      });
    });

    group('hideMessage', () {
      test('should hide current message', () {
        provider.showCustomMessage('Test message');
        expect(provider.currentMessage, isNotNull);

        provider.hideMessage();

        expect(provider.currentMessage, isNull);
        expect(provider.currentState, MascotState.idle);
      });
    });

    group('setState', () {
      test('should set mascot state', () {
        provider.setState(MascotState.thinking);

        expect(provider.currentState, MascotState.thinking);
      });

      test('should not affect current message', () {
        provider.showCustomMessage('Test');
        provider.setState(MascotState.celebrating);

        expect(provider.currentMessage, 'Test');
        expect(provider.currentState, MascotState.celebrating);
      });
    });

    group('setVisibility', () {
      test('should set visibility to false', () {
        provider.setVisibility(false);

        expect(provider.isVisible, false);
      });

      test('should set visibility to true', () {
        provider.setVisibility(false);
        provider.setVisibility(true);

        expect(provider.isVisible, true);
      });
    });

    group('celebrate', () {
      test('should set celebrating state', () {
        provider.celebrate();

        expect(provider.currentState, MascotState.celebrating);
        expect(provider.currentMessage, isNotNull);
      });

      test('should show custom celebration message', () {
        provider.celebrate('Custom celebration!');

        expect(provider.currentMessage, 'Custom celebration!');
        expect(provider.currentState, MascotState.celebrating);
      });
    });

    group('showExcitement', () {
      test('should set excited state', () {
        provider.showExcitement();

        expect(provider.currentState, MascotState.excited);
        expect(provider.currentMessage, isNotNull);
      });

      test('should show custom excitement message', () {
        provider.showExcitement('So exciting!');

        expect(provider.currentMessage, 'So exciting!');
        expect(provider.currentState, MascotState.excited);
      });
    });

    group('reactToAction', () {
      test('should react to streakAchieved action', () {
        provider.reactToAction(MascotAction.streakAchieved);

        expect(provider.currentState, MascotState.celebrating);
        expect(provider.currentMessage, contains('streak'));
      });

      test('should react to sessionCompleted action', () {
        provider.reactToAction(MascotAction.sessionCompleted);

        expect(provider.currentState, MascotState.celebrating);
        expect(provider.currentMessage, contains('Session complete'));
      });

      test('should react to firstVisit action', () {
        provider.reactToAction(MascotAction.firstVisit);

        expect(provider.currentState, MascotState.excited);
        expect(provider.currentMessage, isNotNull);
      });

      test('should react to longAbsence action', () {
        provider.reactToAction(MascotAction.longAbsence);

        expect(provider.currentState, MascotState.excited);
        expect(provider.currentMessage, contains('Welcome back'));
      });

      test('should react to struggling action', () {
        provider.reactToAction(MascotAction.struggling);

        expect(provider.currentState, MascotState.thinking);
        expect(provider.currentMessage, isNotNull);
      });

      test('should react to tapped action', () {
        provider.reactToAction(MascotAction.tapped);

        expect(provider.currentState, MascotState.excited);
        expect(provider.currentMessage, isNotNull);
      });
    });

    group('showContextualMessage', () {
      test('should show motivation when not studied today with due cards', () {
        provider.showContextualMessage(
          totalCards: 10,
          dueCards: 5,
          currentStreak: 3,
          hasStudiedToday: false,
        );

        expect(provider.currentState, MascotState.thinking);
        expect(provider.currentMessage, isNotNull);
      });

      test('should celebrate week streak milestone', () {
        provider.showContextualMessage(
          totalCards: 10,
          dueCards: 0,
          currentStreak: 7,
          hasStudiedToday: true,
        );

        expect(provider.currentState, MascotState.celebrating);
        expect(provider.currentMessage, contains('7 day streak'));
      });

      test('should celebrate when all cards done', () {
        provider.showContextualMessage(
          totalCards: 10,
          dueCards: 0,
          currentStreak: 3,
          hasStudiedToday: true,
        );

        expect(provider.currentState, MascotState.celebrating);
      });

      test('should prompt to create first card when no cards', () {
        provider.showContextualMessage(
          totalCards: 0,
          dueCards: 0,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        expect(provider.currentState, MascotState.excited);
        expect(provider.currentMessage, contains('first card'));
      });

      test('should show welcome message by default', () {
        provider.showContextualMessage(
          totalCards: 10,
          dueCards: 5,
          currentStreak: 3,
          hasStudiedToday: true,
        );

        expect(provider.currentMessage, isNotNull);
      });

      test('should only show message once per session', () {
        provider.showContextualMessage(
          totalCards: 10,
          dueCards: 5,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        final firstMessage = provider.currentMessage;

        provider.showContextualMessage(
          totalCards: 0,
          dueCards: 0,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        // Second call should not change the message
        expect(provider.currentMessage, firstMessage);
      });
    });

    group('resetSession', () {
      test('should allow new contextual message after reset', () {
        provider.showContextualMessage(
          totalCards: 10,
          dueCards: 5,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        final firstMessage = provider.currentMessage;
        provider.hideMessage();
        provider.resetSession();

        provider.showContextualMessage(
          totalCards: 0,
          dueCards: 0,
          currentStreak: 0,
          hasStudiedToday: false,
        );

        // After reset, should show new message
        expect(provider.currentMessage, isNotNull);
        expect(provider.currentMessage, isNot(equals(firstMessage)));
      });
    });

    group('ChangeNotifier', () {
      test('should notify listeners on showMessage', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.showMessage('welcome');

        expect(notified, true);
      });

      test('should notify listeners on showCustomMessage', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.showCustomMessage('Test');

        expect(notified, true);
      });

      test('should notify listeners on hideMessage', () {
        provider.showCustomMessage('Test');
        
        var notified = false;
        provider.addListener(() => notified = true);

        provider.hideMessage();

        expect(notified, true);
      });

      test('should notify listeners on setState', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setState(MascotState.thinking);

        expect(notified, true);
      });

      test('should notify listeners on setVisibility', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setVisibility(false);

        expect(notified, true);
      });

      test('should notify listeners on celebrate', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.celebrate();

        expect(notified, true);
      });

      test('should notify listeners on showExcitement', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.showExcitement();

        expect(notified, true);
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
