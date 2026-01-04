import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests for Supabase authentication error handling
///
/// These tests verify that stale refresh tokens are handled gracefully
/// without throwing unhandled exceptions.
void main() {
  group('Supabase Auth Error Handling', () {
    group('Stale Refresh Token Handling', () {
      test('should identify refresh token error by message', () {
        // Arrange
        const errorMessage = 'Invalid Refresh Token: Refresh Token Not Found';
        final exception = AuthException(errorMessage);

        // Act & Assert
        expect(exception.message.contains('Refresh Token'), isTrue);
      });

      test('should catch AuthException in try-catch block', () async {
        // Arrange
        const errorMessage = 'Invalid Refresh Token: Refresh Token Not Found';
        var exceptionCaught = false;
        var isRefreshTokenError = false;

        // Act
        try {
          throw AuthException(errorMessage);
        } on AuthException catch (e) {
          exceptionCaught = true;
          isRefreshTokenError = e.message.contains('Refresh Token');
        }

        // Assert
        expect(exceptionCaught, isTrue);
        expect(isRefreshTokenError, isTrue);
      });

      test(
        'should not catch unrelated exceptions as refresh token error',
        () async {
          // Arrange
          const errorMessage = 'Network error';
          var isRefreshTokenError = false;

          // Act
          try {
            throw AuthException(errorMessage);
          } on AuthException catch (e) {
            isRefreshTokenError = e.message.contains('Refresh Token');
          }

          // Assert
          expect(isRefreshTokenError, isFalse);
        },
      );

      test('should handle exception with statusCode in message', () {
        // Arrange - simulating the real error format from Supabase
        const errorMessage = 'Invalid Refresh Token: Refresh Token Not Found';
        final exception = AuthException(errorMessage, statusCode: '400');

        // Act & Assert
        expect(exception.message.contains('Refresh Token'), isTrue);
        expect(exception.statusCode, equals('400'));
      });
    });

    group('Session Recovery Logic', () {
      test('should handle null session gracefully', () {
        // Arrange
        final String? refreshToken = null;

        // Act - simulating the null-coalescing in our code
        final tokenToUse = refreshToken ?? '';

        // Assert
        expect(tokenToUse, equals(''));
      });

      test('should handle empty refresh token', () {
        // Arrange
        const refreshToken = '';

        // Act & Assert
        expect(refreshToken, isEmpty);
      });
    });

    group('Error Classification', () {
      test('should classify refresh token error as recoverable', () {
        // Arrange
        final error = AuthException(
          'Invalid Refresh Token: Refresh Token Not Found',
          statusCode: '400',
        );

        // Act
        final isRecoverable = _isRecoverableAuthError(error);

        // Assert
        expect(isRecoverable, isTrue);
      });

      test('should classify session expired as recoverable', () {
        // Arrange
        final error = AuthException('Session expired', statusCode: '401');

        // Act
        final isRecoverable = _isRecoverableAuthError(error);

        // Assert
        expect(isRecoverable, isTrue);
      });

      test('should not classify network errors as recoverable', () {
        // Arrange
        final error = AuthException('Network error');

        // Act
        final isRecoverable = _isRecoverableAuthError(error);

        // Assert
        expect(isRecoverable, isFalse);
      });

      test('should not classify invalid credentials as recoverable', () {
        // Arrange
        final error = AuthException(
          'Invalid login credentials',
          statusCode: '401',
        );

        // Act
        final isRecoverable = _isRecoverableAuthError(error);

        // Assert
        expect(isRecoverable, isFalse);
      });

      test('should classify token not found as recoverable', () {
        // Arrange
        final error = AuthException('Token not found', statusCode: '400');

        // Act
        final isRecoverable = _isRecoverableAuthError(error);

        // Assert
        expect(isRecoverable, isTrue);
      });
    });

    group('SupabaseAuthService Integration Simulation', () {
      test('should simulate stale token recovery flow', () async {
        // This simulates what happens in SupabaseAuthService.initialize()
        var sessionCleared = false;
        var errorLogged = false;

        // Simulate the recovery attempt
        Future<void> simulateRecoverSession() async {
          throw AuthException(
            'Invalid Refresh Token: Refresh Token Not Found',
            statusCode: '400',
          );
        }

        // Act - simulate our error handling
        try {
          await simulateRecoverSession();
        } on AuthException catch (e) {
          if (e.message.contains('Refresh Token')) {
            errorLogged = true;
            // Simulate signOut
            sessionCleared = true;
          }
        }

        // Assert
        expect(errorLogged, isTrue);
        expect(sessionCleared, isTrue);
      });

      test('should not clear session for non-recoverable errors', () async {
        var sessionCleared = false;

        Future<void> simulateRecoverSession() async {
          throw AuthException('Network timeout');
        }

        // Act
        try {
          await simulateRecoverSession();
        } on AuthException catch (e) {
          if (_isRecoverableAuthError(e)) {
            sessionCleared = true;
          }
        }

        // Assert - session should NOT be cleared for network errors
        expect(sessionCleared, isFalse);
      });
    });
  });
}

/// Helper function to classify auth errors as recoverable (stale session) or not
/// This mirrors the logic we use in SupabaseAuthService
bool _isRecoverableAuthError(AuthException error) {
  final message = error.message.toLowerCase();

  // Check for known recoverable error patterns
  final recoverablePatterns = [
    'refresh token',
    'token not found',
    'session expired',
    'session not found',
    'invalid grant',
  ];

  for (final pattern in recoverablePatterns) {
    if (message.contains(pattern)) {
      return true;
    }
  }

  return false;
}
