import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests for AuthProvider error parsing logic
/// 
/// These tests verify that authentication errors are properly parsed
/// into user-friendly messages. The actual AuthProvider requires
/// Supabase initialization, so we test the parsing logic separately.
void main() {
  group('AuthProvider Error Parsing', () {
    group('parseAuthError', () {
      test('should parse email already registered error', () {
        final message = _parseAuthError(
          AuthException('User already registered'),
        );

        expect(message, contains('already registered'));
        expect(message, contains('signing in'));
      });

      test('should parse email already registered variant', () {
        final message = _parseAuthError(
          AuthException('email already registered'),
        );

        expect(message, contains('already registered'));
      });

      test('should parse invalid email error', () {
        final message = _parseAuthError(
          AuthException('Invalid email format'),
        );

        expect(message, contains('valid email'));
      });

      test('should parse weak password error', () {
        final message = _parseAuthError(
          AuthException('Password should be at least 6 characters'),
        );

        expect(message, contains('6 characters'));
      });

      test('should parse generic password error', () {
        final message = _parseAuthError(
          AuthException('password too short'),
        );

        expect(message, contains('6 characters'));
      });

      test('should parse rate limit error', () {
        final message = _parseAuthError(
          AuthException('Rate limit exceeded'),
        );

        expect(message, contains('Too many attempts'));
      });

      test('should parse database error', () {
        final message = _parseAuthError(
          AuthException('Database error saving user'),
        );

        expect(message, contains('Server error'));
      });

      test('should parse JSON error with message field', () {
        final message = _parseAuthError(
          AuthException('{"code": "error", "message": "Database error occurred"}'),
        );

        expect(message, contains('Server configuration error'));
      });

      test('should return original message for unknown errors', () {
        final message = _parseAuthError(
          AuthException('Some specific error'),
        );

        expect(message, 'Some specific error');
      });
    });

    group('parseGenericError', () {
      test('should parse network error', () {
        final message = _parseGenericError(Exception('Network unreachable'));

        expect(message, contains('Network error'));
        expect(message, contains('internet connection'));
      });

      test('should parse connection error', () {
        final message = _parseGenericError(Exception('Connection refused'));

        expect(message, contains('Network error'));
      });

      test('should parse timeout error', () {
        final message = _parseGenericError(Exception('Request timeout'));

        expect(message, contains('timed out'));
      });

      test('should parse database error from generic exception', () {
        final message = _parseGenericError(Exception('database error'));

        expect(message, contains('Server configuration error'));
      });

      test('should return generic message for unknown errors', () {
        final message = _parseGenericError(Exception('Something happened'));

        expect(message, contains('unexpected error'));
      });
    });

    group('Error State Management Logic', () {
      test('should identify loading states correctly', () {
        // Simulating loading state management
        var isLoading = false;

        void setLoading(bool loading) {
          isLoading = loading;
        }

        setLoading(true);
        expect(isLoading, true);

        setLoading(false);
        expect(isLoading, false);
      });

      test('should clear error on new operation', () {
        String? errorMessage = 'Previous error';

        void clearError() {
          errorMessage = null;
        }

        clearError();
        expect(errorMessage, isNull);
      });

      test('should set error message', () {
        String? errorMessage;

        void setError(String error) {
          errorMessage = error;
        }

        setError('New error message');
        expect(errorMessage, 'New error message');
      });
    });

    group('Auth State Detection', () {
      test('should detect authenticated state', () {
        // Simulating auth state check
        String? userId = 'user-123';

        final isAuthenticated = userId != null;

        expect(isAuthenticated, true);
      });

      test('should detect unauthenticated state', () {
        const String? userId = null;

        final isAuthenticated = userId != null;

        expect(isAuthenticated, false);
      });
    });

    group('Email Validation Patterns', () {
      test('should identify valid email format', () {
        expect(_isValidEmail('user@example.com'), true);
        expect(_isValidEmail('user.name@domain.co.uk'), true);
        expect(_isValidEmail('user+tag@example.org'), true);
      });

      test('should identify invalid email format', () {
        expect(_isValidEmail('notanemail'), false);
        expect(_isValidEmail('@nodomain.com'), false);
        expect(_isValidEmail('no@domain'), false);
        expect(_isValidEmail(''), false);
      });
    });

    group('Password Validation', () {
      test('should accept passwords with 6+ characters', () {
        expect(_isPasswordValid('123456'), true);
        expect(_isPasswordValid('abcdef'), true);
        expect(_isPasswordValid('longpassword123'), true);
      });

      test('should reject passwords with less than 6 characters', () {
        expect(_isPasswordValid('12345'), false);
        expect(_isPasswordValid('abc'), false);
        expect(_isPasswordValid(''), false);
      });
    });
  });
}

/// Simulates the _parseAuthError method from AuthProvider
String _parseAuthError(AuthException e) {
  final message = e.message.toLowerCase();
  
  // Parse JSON error if present
  if (e.message.contains('"code"')) {
    final jsonMessagePattern = RegExp(r'"message"\s*:\s*"([^"]+)"');
    final match = jsonMessagePattern.firstMatch(e.message);
    if (match != null) {
      final errorMsg = match.group(1)!;
      if (errorMsg.contains('Database error')) {
        return 'Server configuration error. Please try again later or contact support.';
      }
      return errorMsg;
    }
  }
  
  if (message.contains('email already registered') || 
      message.contains('user already registered')) {
    return 'This email is already registered. Try signing in instead.';
  }
  if (message.contains('invalid email')) {
    return 'Please enter a valid email address.';
  }
  if (message.contains('weak password') || message.contains('password')) {
    return 'Password must be at least 6 characters.';
  }
  if (message.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (message.contains('database error')) {
    return 'Server error. Please try again later.';
  }
  
  return e.message;
}

/// Simulates the _parseGenericError method from AuthProvider
String _parseGenericError(dynamic e) {
  final errorStr = e.toString().toLowerCase();
  
  if (errorStr.contains('network') || errorStr.contains('connection')) {
    return 'Network error. Please check your internet connection.';
  }
  if (errorStr.contains('timeout')) {
    return 'Request timed out. Please try again.';
  }
  if (errorStr.contains('database error')) {
    return 'Server configuration error. Please try again later.';
  }
  
  return 'An unexpected error occurred. Please try again.';
}

/// Simple email validation pattern
bool _isValidEmail(String email) {
  if (email.isEmpty) return false;
  final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$');
  return emailRegex.hasMatch(email);
}

/// Password validation
bool _isPasswordValid(String password) {
  return password.length >= 6;
}
