import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../data/services/supabase_auth_service.dart';
import '../../../shared/services/sentry_service.dart';
import '../../../shared/utils/rate_limiter.dart';
import 'auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

class AuthNotifier extends Notifier<AuthState> {
  static final _jsonMessagePattern = RegExp(r'"message"\s*:\s*"([^"]+)"');

  @override
  AuthState build() {
    // Listen to auth state changes
    final subscription = SupabaseAuthService.client.auth.onAuthStateChange
        .listen((data) async {
          final user = data.session?.user;
          state = state.copyWith(user: user);

          // Update Sentry user context
          if (user != null) {
            SentryService.setUser(id: user.id, email: user.email);
          } else {
            SentryService.clearUser();
          }
        });

    ref.onDispose(() => subscription.cancel());

    // Initialize with current user
    final currentUser = SupabaseAuthService.client.auth.currentUser;
    if (currentUser != null) {
      SentryService.setUser(id: currentUser.id, email: currentUser.email);
    }

    return AuthState(user: currentUser);
  }

  // === Auth Methods ===

  Future<bool> signUp({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await SupabaseAuthService.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(user: response.user);
        return true;
      } else if (response.session == null) {
        state = state.copyWith(
          errorMessage: 'Please check your email to confirm your account.',
        );
        return false;
      } else {
        state = state.copyWith(
          errorMessage: 'Sign up failed. Please try again.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: _parseAuthError(e));
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'An unexpected error occurred');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await SupabaseAuthService.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(user: response.user);
        return true;
      } else {
        state = state.copyWith(errorMessage: 'Sign in failed');
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      return await SupabaseAuthService.signInWithGoogle();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Google sign in failed');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await SupabaseAuthService.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: _parseAuthError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Failed to send password reset email',
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = state.userId;
      await SupabaseAuthService.signOut();
      if (userId != null) {
        RateLimiter().clearUser(userId);
      }
      state = state.copyWith(user: null, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Sign out failed');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  String _parseAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (e.message.contains('"code"')) {
      try {
        final match = _jsonMessagePattern.firstMatch(e.message);
        if (match != null) return match.group(1)!;
      } catch (_) {}
    }
    if (message.contains('email already registered')) {
      return 'This email is already registered.';
    }
    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    return e.message;
  }
}
