/// Helper utilities for Supabase integration tests
///
/// Provides setup/teardown and utilities for testing against
/// the local Docker-based Supabase stack.
///
/// Note: These tests require Docker and make real HTTP requests.
/// Uses pure supabase package (not supabase_flutter) to avoid Flutter dependencies.
library;

import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:lingua_flutter/shared/test_helpers/test_config.dart';

/// Helper class for managing Supabase test environment
class SupabaseTestHelper {
  static bool _isInitialized = false;
  static SupabaseClient? _client;
  static String? _currentUserId;

  /// Get the Supabase client for tests
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError('SupabaseTestHelper not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Get the current authenticated user's ID
  static String get currentUserId {
    if (_currentUserId == null) {
      throw StateError('No user signed in. Call signInTestUser() first.');
    }
    return _currentUserId!;
  }

  /// Initialize Supabase for testing
  ///
  /// Call this in setUpAll() of your integration tests
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if Docker containers are running
    await _ensureContainersRunning();

    // Create pure Supabase client (no Flutter dependencies)
    _client = SupabaseClient(
      TestConfig.supabaseUrl,
      TestConfig.anonKey,
    );

    _isInitialized = true;
  }

  /// Sign in as the test user
  static Future<AuthResponse> signInTestUser() async {
    final response = await client.auth.signInWithPassword(
      email: TestConfig.testUserEmail,
      password: TestConfig.testUserPassword,
    );
    _currentUserId = response.user?.id;
    return response;
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

  /// Clean up all test cards for the current user
  static Future<void> cleanTestUserCards() async {
    if (_currentUserId == null) return;
    await client
        .from('cards')
        .delete()
        .eq('user_id', _currentUserId!);
  }

  /// Clean up all test streaks for the current user
  static Future<void> cleanTestUserStreaks() async {
    if (_currentUserId == null) return;
    await client
        .from('streaks')
        .delete()
        .eq('user_id', _currentUserId!);
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
    _client?.dispose();
    _client = null;
    _isInitialized = false;
  }

  /// Ensure Docker containers are running, start them if not
  static Future<void> _ensureContainersRunning() async {
    final requiredContainers = [
      'lingua_test_db',
      'lingua_test_auth',
      'lingua_test_rest',
    ];

    try {
      // Check if containers are already running
      final result = await Process.run(
        'docker',
        ['ps', '--filter', 'name=lingua_test', '--format', '{{.Names}}'],
      );

      final runningContainers = (result.stdout as String).trim().split('\n');
      final allRunning = requiredContainers.every(
        (c) => runningContainers.contains(c),
      );

      if (!allRunning) {
        // Start containers with docker-compose
        await _startContainers();
      } else {
        // Containers running, but ensure test user exists
        await _ensureTestUserExists();
      }
    } catch (e) {
      throw StateError(
        'Could not check/start Docker containers. Is Docker Desktop running?\n'
        'Error: $e',
      );
    }
  }

  /// Start Docker containers using docker-compose
  static Future<void> _startContainers() async {
    // Find project root by looking for docker-compose.test.yml
    final projectRoot = await _findProjectRoot();

    final result = await Process.run(
      'docker-compose',
      ['-f', 'docker-compose.test.yml', 'up', '-d'],
      workingDirectory: projectRoot,
    );

    if (result.exitCode != 0) {
      throw StateError(
        'Failed to start Docker containers:\n'
        '${result.stderr}',
      );
    }

    // Wait for containers to be healthy
    await _waitForContainersHealthy();

    // Create test user if it doesn't exist
    await _ensureTestUserExists();
  }

  /// Find project root directory
  static Future<String> _findProjectRoot() async {
    var dir = Directory.current;
    while (dir.path != dir.parent.path) {
      final dockerCompose = File('${dir.path}/docker-compose.test.yml');
      if (await dockerCompose.exists()) {
        return dir.path;
      }
      dir = dir.parent;
    }
    throw StateError('Could not find project root with docker-compose.test.yml');
  }

  /// Wait for containers to be healthy
  static Future<void> _waitForContainersHealthy() async {
    final stopwatch = Stopwatch()..start();
    const timeout = Duration(seconds: 60);

    while (stopwatch.elapsed < timeout) {
      try {
        final result = await Process.run(
          'docker',
          ['exec', 'lingua_test_db', 'pg_isready', '-U', 'postgres'],
        );
        if (result.exitCode == 0) {
          // Give other services a moment to start
          await Future.delayed(const Duration(seconds: 5));
          return;
        }
      } catch (_) {
        // Container not ready yet
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    throw StateError('Containers did not become healthy within ${timeout.inSeconds}s');
  }

  /// Ensure test user exists in GoTrue
  static Future<void> _ensureTestUserExists() async {
    // Use direct auth URL, bypassing Kong for reliability
    final stopwatch = Stopwatch()..start();
    const timeout = Duration(seconds: 30);

    while (stopwatch.elapsed < timeout) {
      try {
        // Use HTTP directly to GoTrue signup endpoint
        final httpClient = HttpClient();
        final request = await httpClient.postUrl(
          Uri.parse('${TestConfig.authUrl}/signup'),
        );
        request.headers.contentType = ContentType.json;
        request.write(
          '{"email":"${TestConfig.testUserEmail}","password":"${TestConfig.testUserPassword}"}',
        );

        final response = await request.close();
        final statusCode = response.statusCode;
        httpClient.close();

        // 200/201 = created, 400 with "already registered" = exists (both OK)
        if (statusCode == 200 || statusCode == 201 || statusCode == 400) {
          return; // Success or user already exists
        }

        await Future.delayed(const Duration(seconds: 2));
      } catch (_) {
        await Future.delayed(const Duration(seconds: 2));
      }
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
