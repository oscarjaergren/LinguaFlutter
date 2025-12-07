import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

/// Service for managing Supabase authentication
/// 
/// Handles initialization, sign in, sign up, sign out, and session management.
class SupabaseAuthService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  /// Initialize Supabase - call this once at app startup
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || anonKey == null) {
        throw Exception('Missing Supabase configuration in .env file');
      }

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: FlutterAuthClientOptions(
          // Use implicit flow for web (handles URL fragments with tokens)
          authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
          // Don't auto-refresh on init - we'll handle it manually to avoid exceptions
          autoRefreshToken: false,
        ),
        debug: kDebugMode,
      );

      _client = Supabase.instance.client;
      _initialized = true;
      
      // Try to recover session manually - this way we catch the exception
      try {
        await _client!.auth.recoverSession(_client!.auth.currentSession?.refreshToken ?? '');
      } on AuthException catch (e) {
        if (e.message.contains('Refresh Token')) {
          LoggerService.debug('Stale session cleared on startup');
          await _client!.auth.signOut();
        }
      } catch (_) {
        // No session to recover, that's fine
      }
      
      // Log current auth state
      final user = _client!.auth.currentUser;
      if (user != null) {
        LoggerService.info('✅ Supabase initialized - User logged in: ${user.email}');
      } else {
        LoggerService.info('✅ Supabase initialized - No user session');
      }
    } catch (e) {
      LoggerService.error('Failed to initialize Supabase', e);
      rethrow;
    }
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw Exception('Supabase not initialized. Call SupabaseAuthService.initialize() first.');
    }
    return _client!;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user ID
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      LoggerService.info('User signed up: ${response.user?.email}');
      return response;
    } catch (e) {
      LoggerService.error('Sign up failed', e);
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      LoggerService.info('User signed in: ${response.user?.email}');
      return response;
    } catch (e) {
      LoggerService.error('Sign in failed', e);
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
      LoggerService.info('User signed out');
    } catch (e) {
      LoggerService.error('Sign out failed', e);
      rethrow;
    }
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
