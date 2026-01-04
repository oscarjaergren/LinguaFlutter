/// Configuration for integration tests with local Supabase
///
/// This file contains constants and helpers for connecting to
/// the local Docker-based Supabase stack for integration testing.
library;

/// Test environment configuration
class TestConfig {
  TestConfig._();

  /// Local Supabase URL (Kong gateway)
  static const String supabaseUrl = 'http://localhost:8000';

  /// Direct REST API URL (bypasses Kong)
  static const String restUrl = 'http://localhost:3000';

  /// Direct Auth URL (bypasses Kong)
  static const String authUrl = 'http://localhost:9999';

  /// Database connection string
  static const String databaseUrl =
      'postgres://postgres:postgres@localhost:54322/postgres';

  /// Anon key for public access (matches JWT secret in docker-compose)
  /// This is a test-only key, not for production
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.'
      'CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  /// Service role key for admin access (matches JWT secret in docker-compose)
  /// This is a test-only key, not for production
  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.'
      'EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

  /// Test user credentials
  static const String testUserEmail = 'test@linguaflutter.dev';
  static const String testUserPassword = 'testpass123';
  static const String testUserId = '00000000-0000-0000-0000-000000000001';
}
