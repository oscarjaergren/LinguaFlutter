# Integration Tests

This directory contains shared test helpers for integration tests that run against a real PostgreSQL database using Docker.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose available

## Setup

1. **Start the test containers:**

   ```bash
   docker-compose -f docker-compose.test.yml up -d
   ```

2. **Wait for containers to be healthy** (usually 10-30 seconds):

   ```bash
   docker-compose -f docker-compose.test.yml ps
   ```

   All services should show as "healthy" or "running".

3. **Run integration tests:**

   ```bash
   flutter test lib/ --tags integration
   ```

4. **Stop containers when done:**

   ```bash
   docker-compose -f docker-compose.test.yml down -v
   ```

   The `-v` flag removes volumes to ensure a clean state for next run.

## Test Environment

The Docker Compose setup provides:

| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 54322 | Database with Supabase schema |
| GoTrue | 9999 | Authentication service |
| PostgREST | 3000 | REST API |
| Kong | 8000 | API Gateway (main entry point) |

## Test User

A test user is automatically created by the migration:

- **Email:** `test@linguaflutter.dev`
- **Password:** `testpass123`
- **User ID:** `00000000-0000-0000-0000-000000000001`

## Writing Integration Tests

```dart
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/test/test_helpers/supabase_test_helper.dart';

void main() {
  setUpAll(() async {
    await SupabaseTestHelper.initialize();
    await SupabaseTestHelper.waitForDatabase();
    await SupabaseTestHelper.signInTestUser();
  });

  tearDownAll(() async {
    await SupabaseTestHelper.dispose();
  });

  test('my integration test', () async {
    // Your test code here
  });
}
```
