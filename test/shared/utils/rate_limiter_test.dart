import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter();
      rateLimiter.clearAll();
    });

    tearDown(() {
      rateLimiter.clearAll();
    });

    group('isAllowed', () {
      test('allows actions within limit', () {
        const userId = 'user123';
        const action = 'card_creation';

        for (int i = 0; i < 50; i++) {
          expect(
            rateLimiter.isAllowed(userId: userId, action: action),
            true,
            reason: 'Action $i should be allowed',
          );
        }
      });

      test('blocks actions exceeding limit', () {
        const userId = 'user123';
        const action = 'card_creation';

        // Use up the limit (50 actions)
        for (int i = 0; i < 50; i++) {
          rateLimiter.isAllowed(userId: userId, action: action);
        }

        // Next action should be blocked
        expect(
          rateLimiter.isAllowed(userId: userId, action: action),
          false,
        );
      });

      test('allows actions for different users independently', () {
        const action = 'card_creation';

        // User 1 uses up their limit
        for (int i = 0; i < 50; i++) {
          rateLimiter.isAllowed(userId: 'user1', action: action);
        }

        // User 2 should still be allowed
        expect(
          rateLimiter.isAllowed(userId: 'user2', action: action),
          true,
        );
      });

      test('allows actions for different action types independently', () {
        const userId = 'user123';

        // Use up card_creation limit
        for (int i = 0; i < 50; i++) {
          rateLimiter.isAllowed(userId: userId, action: 'card_creation');
        }

        // card_update should still be allowed
        expect(
          rateLimiter.isAllowed(userId: userId, action: 'card_update'),
          true,
        );
      });

      test('allows unconfigured actions', () {
        const userId = 'user123';
        const action = 'unconfigured_action';

        expect(
          rateLimiter.isAllowed(userId: userId, action: action),
          true,
        );
      });
    });

    group('getRemainingActions', () {
      test('returns correct remaining count', () {
        const userId = 'user123';
        const action = 'card_creation';

        expect(
          rateLimiter.getRemainingActions(userId: userId, action: action),
          50,
        );

        // Use 10 actions
        for (int i = 0; i < 10; i++) {
          rateLimiter.isAllowed(userId: userId, action: action);
        }

        expect(
          rateLimiter.getRemainingActions(userId: userId, action: action),
          40,
        );
      });

      test('returns 0 when limit exceeded', () {
        const userId = 'user123';
        const action = 'card_creation';

        // Use up the limit
        for (int i = 0; i < 50; i++) {
          rateLimiter.isAllowed(userId: userId, action: action);
        }

        expect(
          rateLimiter.getRemainingActions(userId: userId, action: action),
          0,
        );
      });

      test('returns -1 for unconfigured actions', () {
        const userId = 'user123';
        const action = 'unconfigured_action';

        expect(
          rateLimiter.getRemainingActions(userId: userId, action: action),
          -1,
        );
      });
    });

    group('getTimeUntilNextAction', () {
      test('returns zero duration when actions are allowed', () {
        const userId = 'user123';
        const action = 'card_creation';

        final timeUntil = rateLimiter.getTimeUntilNextAction(
          userId: userId,
          action: action,
        );

        expect(timeUntil, Duration.zero);
      });

      test('returns positive duration when limit exceeded', () {
        const userId = 'user123';
        const action = 'card_creation';

        // Use up the limit
        for (int i = 0; i < 50; i++) {
          rateLimiter.isAllowed(userId: userId, action: action);
        }

        final timeUntil = rateLimiter.getTimeUntilNextAction(
          userId: userId,
          action: action,
        );

        expect(timeUntil, isNotNull);
        expect(timeUntil!.inSeconds, greaterThan(0));
      });

      test('returns null for unconfigured actions', () {
        const userId = 'user123';
        const action = 'unconfigured_action';

        final timeUntil = rateLimiter.getTimeUntilNextAction(
          userId: userId,
          action: action,
        );

        expect(timeUntil, null);
      });
    });

    group('getErrorMessage', () {
      test('returns generic message for unconfigured actions', () {
        const userId = 'user123';
        const action = 'unconfigured_action';

        final message = rateLimiter.getErrorMessage(
          userId: userId,
          action: action,
        );

        expect(message, 'Rate limit exceeded');
      });

      test('returns message with time when limit exceeded', () {
        const userId = 'user123';
        const action = 'card_creation';

        // Use up the limit
        for (int i = 0; i < 50; i++) {
          rateLimiter.isAllowed(userId: userId, action: action);
        }

        final message = rateLimiter.getErrorMessage(
          userId: userId,
          action: action,
        );

        expect(message.contains('Try again in'), true);
      });

      test('uses correct plural/singular for minutes', () {
        const userId = 'user123';
        const action = 'card_creation';

        // Use up the limit
        for (int i = 0; i < 50; i++) {
          rateLimiter.isAllowed(userId: userId, action: action);
        }

        final message = rateLimiter.getErrorMessage(
          userId: userId,
          action: action,
        );

        // Should contain "minute" or "minutes"
        expect(
          message.contains('minute') || message.contains('second'),
          true,
        );
      });
    });

    group('clearUser', () {
      test('clears rate limit data for specific user', () {
        const userId = 'user123';
        const action = 'card_creation';

        // Use some actions
        for (int i = 0; i < 10; i++) {
          rateLimiter.isAllowed(userId: userId, action: action);
        }

        expect(
          rateLimiter.getRemainingActions(userId: userId, action: action),
          40,
        );

        // Clear user data
        rateLimiter.clearUser(userId);

        // Should be reset
        expect(
          rateLimiter.getRemainingActions(userId: userId, action: action),
          50,
        );
      });

      test('does not affect other users', () {
        const action = 'card_creation';

        // User 1 uses some actions
        for (int i = 0; i < 10; i++) {
          rateLimiter.isAllowed(userId: 'user1', action: action);
        }

        // User 2 uses some actions
        for (int i = 0; i < 20; i++) {
          rateLimiter.isAllowed(userId: 'user2', action: action);
        }

        // Clear user 1
        rateLimiter.clearUser('user1');

        // User 1 should be reset
        expect(
          rateLimiter.getRemainingActions(userId: 'user1', action: action),
          50,
        );

        // User 2 should be unchanged
        expect(
          rateLimiter.getRemainingActions(userId: 'user2', action: action),
          30,
        );
      });
    });

    group('clearAll', () {
      test('clears all rate limit data', () {
        const action = 'card_creation';

        // Multiple users use actions
        for (int i = 0; i < 10; i++) {
          rateLimiter.isAllowed(userId: 'user1', action: action);
          rateLimiter.isAllowed(userId: 'user2', action: action);
        }

        // Clear all
        rateLimiter.clearAll();

        // All users should be reset
        expect(
          rateLimiter.getRemainingActions(userId: 'user1', action: action),
          50,
        );
        expect(
          rateLimiter.getRemainingActions(userId: 'user2', action: action),
          50,
        );
      });
    });

    group('RateLimitException', () {
      test('can be created with message', () {
        const exception = RateLimitException('Test message');
        expect(exception.message, 'Test message');
        expect(exception.retryAfter, null);
      });

      test('can be created with retry duration', () {
        final duration = Duration(minutes: 5);
        final exception = RateLimitException(
          'Test message',
          retryAfter: duration,
        );
        expect(exception.message, 'Test message');
        expect(exception.retryAfter, duration);
      });

      test('toString returns message', () {
        const exception = RateLimitException('Test message');
        expect(exception.toString(), 'Test message');
      });
    });

    group('rate limit configurations', () {
      test('card_creation has correct limits', () {
        const userId = 'user123';
        const action = 'card_creation';

        // Should allow 50 actions
        for (int i = 0; i < 50; i++) {
          expect(rateLimiter.isAllowed(userId: userId, action: action), true);
        }

        // 51st should be blocked
        expect(rateLimiter.isAllowed(userId: userId, action: action), false);
      });

      test('card_bulk_create has correct limits', () {
        const userId = 'user123';
        const action = 'card_bulk_create';

        // Should allow 100 actions
        for (int i = 0; i < 100; i++) {
          expect(rateLimiter.isAllowed(userId: userId, action: action), true);
        }

        // 101st should be blocked
        expect(rateLimiter.isAllowed(userId: userId, action: action), false);
      });

      test('card_update has correct limits', () {
        const userId = 'user123';
        const action = 'card_update';

        // Should allow 100 actions
        for (int i = 0; i < 100; i++) {
          expect(rateLimiter.isAllowed(userId: userId, action: action), true);
        }

        // 101st should be blocked
        expect(rateLimiter.isAllowed(userId: userId, action: action), false);
      });

      test('card_delete has correct limits', () {
        const userId = 'user123';
        const action = 'card_delete';

        // Should allow 50 actions
        for (int i = 0; i < 50; i++) {
          expect(rateLimiter.isAllowed(userId: userId, action: action), true);
        }

        // 51st should be blocked
        expect(rateLimiter.isAllowed(userId: userId, action: action), false);
      });
    });
  });
}
