import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/supabase_auth_service.dart';
import '../../../shared/services/logger_service.dart';

/// Callback type for when auth state changes
typedef OnAuthStateChanged = Future<void> Function(bool isAuthenticated);

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  static final _jsonMessagePattern = RegExp(r'"message"\s*:\s*"([^"]+)"');

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  /// Callback to initialize data providers after auth
  OnAuthStateChanged? onAuthStateChanged;

  AuthProvider() {
    // Listen to auth state changes
    SupabaseAuthService.client.auth.onAuthStateChange.listen((data) async {
      final wasAuthenticated = _user != null;
      _user = data.session?.user;
      final isNowAuthenticated = _user != null;

      // Notify data providers when auth state changes
      if (wasAuthenticated != isNowAuthenticated &&
          onAuthStateChanged != null) {
        await onAuthStateChanged!(isNowAuthenticated);
      }

      notifyListeners();
    });

    // Initialize with current user
    _user = SupabaseAuthService.client.auth.currentUser;
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _user?.email;
  String? get userId => _user?.id;

  /// Sign up with email and password
  Future<bool> signUp({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      LoggerService.debug('Attempting signup for: $email');

      final response = await SupabaseAuthService.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        LoggerService.info(
          'User signed up successfully: ${response.user!.email}',
        );
        _user = response.user;
        notifyListeners();
        return true;
      } else if (response.session == null) {
        // Email confirmation required
        LoggerService.info(
          'Signup successful, email confirmation required for: $email',
        );
        _setError('Please check your email to confirm your account.');
        return false;
      } else {
        LoggerService.warning('Signup returned no user for: $email');
        _setError('Sign up failed. Please try again.');
        return false;
      }
    } on AuthException catch (e) {
      LoggerService.error('Sign up AuthException', e);
      _setError(_parseAuthError(e));
      return false;
    } catch (e, stackTrace) {
      LoggerService.error('Sign up unexpected error: ${e.runtimeType}', e);
      LoggerService.debug('Stack trace: $stackTrace');
      _setError(_parseGenericError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Parse auth exception into user-friendly message
  String _parseAuthError(AuthException e) {
    final message = e.message.toLowerCase();

    // Parse JSON error if present
    if (e.message.contains('"code"')) {
      try {
        final match = _jsonMessagePattern.firstMatch(e.message);
        if (match != null) {
          final errorMsg = match.group(1)!;
          if (errorMsg.contains('Database error')) {
            return 'Server configuration error. Please try again later or contact support.';
          }
          return errorMsg;
        }
      } catch (_) {}
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

  /// Parse generic error into user-friendly message
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

  /// Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await SupabaseAuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        LoggerService.info('User signed in: ${response.user!.email}');
        _user = response.user;
        notifyListeners();
        return true;
      } else {
        _setError('Sign in failed');
        return false;
      }
    } on AuthException catch (e) {
      LoggerService.error('Sign in error', e);
      _setError(e.message);
      return false;
    } catch (e) {
      LoggerService.error('Sign in error', e);
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await SupabaseAuthService.signOut();
      _user = null;
      LoggerService.info('User signed out');
      notifyListeners();
    } on AuthException catch (e) {
      LoggerService.error('Sign out error', e);
      _setError(e.message);
    } catch (e) {
      LoggerService.error('Sign out error', e);
      _setError('An unexpected error occurred');
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await SupabaseAuthService.client.auth.resetPasswordForEmail(email);
      LoggerService.info('Password reset email sent to: $email');
      return true;
    } on AuthException catch (e) {
      LoggerService.error('Password reset error', e);
      _setError(e.message);
      return false;
    } catch (e) {
      LoggerService.error('Password reset error', e);
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message (for UI)
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
