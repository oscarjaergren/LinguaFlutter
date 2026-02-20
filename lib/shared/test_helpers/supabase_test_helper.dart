/// Helper utilities for Supabase integration tests
///
/// Provides setup/teardown and utilities for testing against
/// the local Docker-based Supabase stack.
///
/// Note: These tests require Docker and make real HTTP requests.
/// Uses pure supabase package (not supabase_flutter) to avoid Flutter dependencies.
library;

import 'dart:io';
import 'dart:convert';
import 'package:supabase/supabase.dart';
import 'package:lingua_flutter/shared/test_helpers/test_config.dart';

/// Helper class for managing Supabase test environment
class SupabaseTestHelper {
  static const String _defaultSupabaseUrl = 'http://127.0.0.1:54321';
  static const String _defaultAuthUrl = 'http://127.0.0.1:54321/auth/v1';

  static bool _isInitialized = false;
  static SupabaseClient? _client;
  static String? _currentUserId;
  static String _resolvedSupabaseUrl = _defaultSupabaseUrl;
  static String _resolvedAuthUrl = _defaultAuthUrl;
  static String _resolvedAnonKey = TestConfig.anonKey;
  static String _resolvedServiceRoleKey = TestConfig.serviceRoleKey;

  /// Get the Supabase client for tests
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'SupabaseTestHelper not initialized. Call initialize() first.',
      );
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
    _client = SupabaseClient(_resolvedSupabaseUrl, _resolvedAnonKey);

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
    _currentUserId = null;
  }

  /// Clean up test data for a specific table
  ///
  /// Uses service role to bypass RLS
  static Future<void> cleanTable(String tableName) async {
    // Create admin client with service role
    final adminClient = SupabaseClient(
      _resolvedSupabaseUrl,
      _resolvedServiceRoleKey,
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
    await client.from('cards').delete().eq('user_id', _currentUserId!);
  }

  /// Clean up all test streaks for the current user
  static Future<void> cleanTestUserStreaks() async {
    if (_currentUserId == null) return;

    final adminClient = SupabaseClient(
      _resolvedSupabaseUrl,
      _resolvedServiceRoleKey,
    );

    try {
      await adminClient.from('streaks').delete().eq('user_id', _currentUserId!);
    } finally {
      adminClient.dispose();
    }
  }

  /// Reset the test environment
  ///
  /// Call this in tearDown() to clean up between tests
  static Future<void> reset() async {
    await cleanTestUserCards();
    await cleanTestUserStreaks();
  }

  /// Dispose of Supabase resources
  ///
  /// Call this in tearDownAll()
  static Future<void> dispose() async {
    if (_client != null) {
      await signOut();
    }
    _client?.dispose();
    _client = null;
    _isInitialized = false;
    _currentUserId = null;
    _resolvedSupabaseUrl = _defaultSupabaseUrl;
    _resolvedAuthUrl = _defaultAuthUrl;
    _resolvedAnonKey = TestConfig.anonKey;
    _resolvedServiceRoleKey = TestConfig.serviceRoleKey;
  }

  /// Ensure local Supabase services are running.
  static Future<void> _ensureContainersRunning() async {
    final projectRoot = await _findProjectRoot();

    // Fast path: if this repo's Supabase project is reachable, use it directly.
    if (await _resolveEndpointsIfReachable(projectRoot: projectRoot)) {
      await _ensureTestUserExists();
      return;
    }

    try {
      await _startContainers(projectRoot: projectRoot);
    } catch (e) {
      throw StateError(
        'Could not start local Supabase services. Is Docker Desktop running?\n'
        'Error: $e',
      );
    }

    final resolved = await _resolveEndpointsIfReachable(
      projectRoot: projectRoot,
    );
    if (!resolved) {
      throw StateError(
        'Started Supabase CLI, but could not resolve this project\'s API URL and keys. '
        'Run `supabase status -o env` in $projectRoot to inspect local status.',
      );
    }

    await _ensureTestUserExists();
  }

  /// Start local Supabase services using Supabase CLI.
  static Future<void> _startContainers({required String projectRoot}) async {
    final supabaseConfigPath = File('$projectRoot/supabase/config.toml');

    if (!await supabaseConfigPath.exists()) {
      throw StateError('Could not find supabase/config.toml in project root.');
    }

    final result = await _startSupabaseCliWithRecovery(
      projectRoot: projectRoot,
    );

    if (result.exitCode != 0) {
      throw StateError(
        'Failed to start local Supabase services:\n'
        '${result.stderr}',
      );
    }

    await _waitForContainersHealthy(projectRoot: projectRoot);
  }

  /// Find project root directory
  static Future<String> _findProjectRoot() async {
    var dir = Directory.current;
    while (dir.path != dir.parent.path) {
      final supabaseConfig = File('${dir.path}/supabase/config.toml');
      if (await supabaseConfig.exists()) {
        return dir.path;
      }
      dir = dir.parent;
    }
    throw StateError('Could not find project root for integration tests');
  }

  static Future<bool> _resolveEndpointsIfReachable({
    required String projectRoot,
  }) async {
    final status = await _resolveSupabaseCliStatus(projectRoot: projectRoot);
    if (status == null) {
      return false;
    }

    final authUrl = '${status.supabaseUrl}/auth/v1';
    final reachable = await _isHealthEndpointReachable('$authUrl/health');
    if (!reachable) {
      return false;
    }

    _resolvedSupabaseUrl = status.supabaseUrl;
    _resolvedAuthUrl = authUrl;
    _resolvedAnonKey = status.anonKey;
    _resolvedServiceRoleKey = status.serviceRoleKey;
    return true;
  }

  static Future<({String supabaseUrl, String anonKey, String serviceRoleKey})?>
  _resolveSupabaseCliStatus({required String projectRoot}) async {
    try {
      final result = await Process.run('supabase', [
        'status',
        '-o',
        'env',
      ], workingDirectory: projectRoot);

      if (result.exitCode != 0) {
        return null;
      }

      final output = '${result.stdout}\n${result.stderr}';
      final apiUrl = _readEnvLine(output, ['API_URL', 'SUPABASE_URL']);
      final anonKey = _readEnvLine(output, ['ANON_KEY', 'SUPABASE_ANON_KEY']);
      final serviceRoleKey = _readEnvLine(output, [
        'SERVICE_ROLE_KEY',
        'SUPABASE_SERVICE_ROLE_KEY',
      ]);
      if (apiUrl == null || anonKey == null || serviceRoleKey == null) {
        return null;
      }

      return (
        supabaseUrl: apiUrl,
        anonKey: anonKey,
        serviceRoleKey: serviceRoleKey,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _readEnvLine(String output, List<String> keys) {
    for (final rawLine in output.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      for (final key in keys) {
        final prefix = '$key=';
        if (line.startsWith(prefix)) {
          final value = line.substring(prefix.length).trim();
          return value.replaceAll('"', '');
        }
      }
    }
    return null;
  }

  static Future<bool> _isHealthEndpointReachable(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      client.close();
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<ProcessResult> _startSupabaseCliWithRecovery({
    required String projectRoot,
  }) async {
    var result = await Process.run('supabase', [
      'start',
    ], workingDirectory: projectRoot);

    if (result.exitCode == 0) {
      return result;
    }

    final stderrText = (result.stderr ?? '').toString().toLowerCase();
    final shouldRecover =
        stderrText.contains('network') ||
        stderrText.contains('not found') ||
        stderrText.contains('failed to start docker container');

    if (!shouldRecover) {
      return result;
    }

    await Process.run('supabase', [
      'stop',
      '--no-backup',
    ], workingDirectory: projectRoot);

    result = await Process.run('supabase', [
      'start',
    ], workingDirectory: projectRoot);

    return result;
  }

  /// Wait for containers to be healthy
  static Future<void> _waitForContainersHealthy({
    required String projectRoot,
  }) async {
    final stopwatch = Stopwatch()..start();
    const timeout = Duration(seconds: 90);

    while (stopwatch.elapsed < timeout) {
      if (await _resolveEndpointsIfReachable(projectRoot: projectRoot)) {
        await Future.delayed(const Duration(seconds: 2));
        return;
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    throw StateError(
      'Containers did not become healthy within ${timeout.inSeconds}s',
    );
  }

  /// Ensure test user exists in GoTrue
  static Future<void> _ensureTestUserExists() async {
    // Use direct auth URL, bypassing Kong for reliability
    final stopwatch = Stopwatch()..start();
    const timeout = Duration(seconds: 30);
    int? lastStatusCode;
    String? lastResponseBody;
    Object? lastError;

    while (stopwatch.elapsed < timeout) {
      try {
        // Use HTTP directly to GoTrue signup endpoint
        final httpClient = HttpClient();
        final request = await httpClient.postUrl(
          Uri.parse('$_resolvedAuthUrl/signup'),
        );
        request.headers.contentType = ContentType.json;
        request.headers.set('apikey', _resolvedAnonKey);
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $_resolvedAnonKey',
        );
        request.write(
          '{"email":"${TestConfig.testUserEmail}","password":"${TestConfig.testUserPassword}"}',
        );

        final response = await request.close();
        final statusCode = response.statusCode;
        final body = await response.transform(utf8.decoder).join();
        lastStatusCode = statusCode;
        lastResponseBody = body;
        httpClient.close();

        final lowerBody = body.toLowerCase();
        final alreadyExists =
            lowerBody.contains('already registered') ||
            lowerBody.contains('already exists') ||
            lowerBody.contains('exists');

        // Created or already-existing user are both valid outcomes.
        if (statusCode == 200 ||
            statusCode == 201 ||
            statusCode == 400 ||
            statusCode == 409 ||
            statusCode == 422 ||
            alreadyExists) {
          return; // Success or user already exists
        }

        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        lastError = e;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw StateError(
      'Could not ensure test user exists within ${timeout.inSeconds}s '
      'at $_resolvedAuthUrl/signup. '
      'Last status: ${lastStatusCode ?? 'none'}, '
      'last response: ${lastResponseBody ?? 'none'}, '
      'last error: ${lastError ?? 'none'}',
    );
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
