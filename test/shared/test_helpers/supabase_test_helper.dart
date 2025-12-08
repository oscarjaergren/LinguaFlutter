/// Helper utilities for Supabase integration tests
///
/// Provides setup/teardown and utilities for testing against
/// the local Docker-based Supabase stack.
///
/// Note: These tests require Docker and make real HTTP requests.
/// Run with: dart test (not flutter test) to avoid HTTP blocking.
library;

import 'dart:io';
import 'package:supabase/supabase.dart';
import 'test_config.dart';

/// Helper class for managing Supabase test environment
class SupabaseTestHelper {
  static bool _isInitialized = false;
  static SupabaseClient? _client;

  /// Get the Supabase client for tests
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'SupabaseTestHelper not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  /// Initialize Supabase for testing
  ///
  /// Call this in setUpAll() of your integration tests
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if Docker containers are running
    await _ensureContainersRunning();

    // Create Supabase client directly (no Flutter dependencies)
    _client = SupabaseClient(
      TestConfig.supabaseUrl,
      TestConfig.anonKey,
    );

    _isInitialized = true;
  }

  /// Sign in as the test user
  static Future<AuthResponse> signInTestUser() async {
    return await client.auth.signInWithPassword(
      email: TestConfig.testUserEmail,
      password: TestConfig.testUserPassword,
    );
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Clean up test data for a specific table
  ///
  /// Uses service role to bypass RLS
  static Future<void> cleanTable(String tableName) async {
    // Create admin client with service role
    final adminClient = SupabaseClient(
      TestConfig.supabaseUrl,
      TestConfig.serviceRoleKey,
    );

    try {
      await adminClient.from(tableName).delete().neq('id', '');
    } finally {
      adminClient.dispose();
    }
  }

  /// Clean up all test cards for the test user
  static Future<void> cleanTestUserCards() async {
    await client
        .from('cards')
        .delete()
        .eq('user_id', TestConfig.testUserId);
  }

  /// Clean up all test streaks for the test user
  static Future<void> cleanTestUserStreaks() async {
    await client
        .from('streaks')
        .delete()
        .eq('user_id', TestConfig.testUserId);
  }

  /// Reset the test environment
  ///
  /// Call this in tearDown() to clean up between tests
  static Future<void> reset() async {
    await cleanTestUserCards();
  }

  /// Dispose of Supabase resources
  ///
  /// Call this in tearDownAll()
  static Future<void> dispose() async {
    await signOut();
    _client = null;
    _isInitialized = false;
  }

  /// Check if Docker containers are running
  static Future<void> _ensureContainersRunning() async {
    try {
      final result = await Process.run(
        'docker',
        ['ps', '--filter', 'name=lingua_test', '--format', '{{.Names}}'],
      );

      final containers = (result.stdout as String).trim().split('\n');
      final requiredContainers = [
        'lingua_test_db',
        'lingua_test_auth',
        'lingua_test_rest',
      ];

      for (final container in requiredContainers) {
        if (!containers.contains(container)) {
          throw StateError(
            'Required container $container is not running.\n'
            'Start the test environment with:\n'
            '  docker-compose -f docker-compose.test.yml up -d',
          );
        }
      }
    } catch (e) {
      if (e is StateError) rethrow;
      throw StateError(
        'Could not check Docker containers. Is Docker running?\n'
        'Error: $e',
      );
    }
  }

  /// Wait for the database to be ready
  static Future<void> waitForDatabase({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      try {
        // Try a simple query
        await client.from('languages').select().limit(1);
        return; // Success
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    throw StateError('Database not ready after ${timeout.inSeconds} seconds');
  }
}
