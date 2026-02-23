import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/supabase_auth_service.dart';
import '../../../shared/domain/base_provider.dart';
import '../../../shared/services/logger_service.dart';
import '../../../shared/services/sentry_service.dart';
import '../../../shared/utils/rate_limiter.dart';

/// Callback type for when auth state changes
typedef OnAuthStateChanged = Future<void> Function(bool isAuthenticated);

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  static final _jsonMessagePattern = RegExp(r'"message"\s*:\s*"([^"]+)"');

  User? _user;
  StreamSubscription<AuthState>? _authSubscription;
  late final _state = ProviderState(notifyListeners);

  /// Callback to initialize data providers after auth
  OnAuthStateChanged? onAuthStateChanged;

  AuthProvider() {
    // Listen to auth state changes
    _authSubscription = SupabaseAuthService.client.auth.onAuthStateChange
        .listen((data) async {
          final wasAuthenticated = _user != null;
          _user = data.session?.user;
          final isNowAuthenticated = _user != null;

          // Update Sentry user context
          if (isNowAuthenticated && _user != null) {
            SentryService.setUser(id: _user!.id, email: _user!.email);
          } else {
            SentryService.clearUser();
          }

          // Notify data providers when auth state changes
          if (wasAuthenticated != isNowAuthenticated &&
              onAuthStateChanged != null) {
            await onAuthStateChanged!(isNowAuthenticated);
          }

          notifyListeners();
        });

    // Initialize with current user
    _user = SupabaseAuthService.client.auth.currentUser;

    // Set initial Sentry user context if already authenticated
    if (_user != null) {
      SentryService.setUser(id: _user!.id, email: _user!.email);
    }
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;
  String? get userEmail => _user?.email;
  String? get userId => _user?.id;

  /// Sign up with email and password
  Future<bool> signUp({required String email, required String password}) async {
    _state.setLoading(true);
    _state.clearError();

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
        _state.setError('Please check your email to confirm your account.');
        return false;
      } else {
        LoggerService.warning('Signup returned no user for: $email');
        _state.setError('Sign up failed. Please try again.');
        return false;
      }
    } on AuthException catch (e) {
      LoggerService.error('Sign up AuthException', e);
      _state.setError(_parseAuthError(e));
      return false;
    } catch (e, stackTrace) {
      LoggerService.error('Sign up unexpected error: ${e.runtimeType}', e);
      LoggerService.debug('Stack trace: $stackTrace');
      _state.setError(_parseGenericError(e));
      return false;
    } finally {
      _state.setLoading(false);
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
    _state.setLoading(true);
    _state.clearError();

    try {
      final response = await SupabaseAuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        LoggerService.info('User signed in: ${response.user!.email}');
        _user = response.user;

        // Add breadcrumb for successful sign-in
        SentryService.addBreadcrumb(
          message: 'User signed in',
          category: 'auth',
          data: {'email': response.user!.email},
        );

        notifyListeners();
        return true;
      } else {
        _state.setError('Sign in failed');
        return false;
      }
    } on AuthException catch (e) {
      LoggerService.error('Sign in error', e);
      _state.setError(e.message);
      return false;
    } catch (e) {
      LoggerService.error('Sign in error', e);
      _state.setError('An unexpected error occurred');
      return false;
    } finally {
      _state.setLoading(false);
    }
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    _state.setLoading(true);
    _state.clearError();

    try {
      final success = await SupabaseAuthService.signInWithGoogle();
      if (success) {
        LoggerService.info('Google OAuth flow initiated');
        SentryService.addBreadcrumb(
          message: 'Google OAuth initiated',
          category: 'auth',
        );
      }
      return success;
    } catch (e) {
      LoggerService.error('Google sign in error', e);
      _state.setError('Google sign in failed');
      return false;
    } finally {
      _state.setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _state.setLoading(true);
    _state.clearError();

    try {
      final userId = _user?.id;
      await SupabaseAuthService.signOut();
      _user = null;

      // Clear rate limit data for this user
      if (userId != null) {
        RateLimiter().clearUser(userId);
      }

      // Add breadcrumb for sign-out
      SentryService.addBreadcrumb(message: 'User signed out', category: 'auth');

      LoggerService.info('User signed out');
      notifyListeners();
    } on AuthException catch (e) {
      LoggerService.error('Sign out error', e);
      _state.setError(e.message);
    } catch (e) {
      LoggerService.error('Sign out error', e);
      _state.setError('An unexpected error occurred');
    } finally {
      _state.setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    _state.setLoading(true);
    _state.clearError();

    try {
      await SupabaseAuthService.client.auth.resetPasswordForEmail(email);
      LoggerService.info('Password reset email sent to: $email');
      return true;
    } on AuthException catch (e) {
      LoggerService.error('Password reset error', e);
      _state.setError(e.message);
      return false;
    } catch (e) {
      LoggerService.error('Password reset error', e);
      _state.setError('An unexpected error occurred');
      return false;
    } finally {
      _state.setLoading(false);
    }
  }

  void clearError() => _state.clearError();

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
