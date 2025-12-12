/// Integration tests for Streak database operations
///
/// Tests database schema and CRUD operations directly via Supabase client.
/// No Flutter dependencies - uses pure supabase package.
///
/// Run with: dart test lib/features/streak/test/integration/ --tags integration
///
/// Ensure Docker is running:
///   docker-compose -f docker-compose.test.yml up -d
@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:lingua_flutter/shared/test_helpers/supabase_test_helper.dart';

void main() {
  setUpAll(() async {
    await SupabaseTestHelper.initialize();
    await SupabaseTestHelper.waitForDatabase();
    await SupabaseTestHelper.signInTestUser();
  });

  setUp(() async {
    // Clean up any existing streak data for test user
    await SupabaseTestHelper.cleanTestUserStreaks();
  });

  tearDownAll(() async {
    await SupabaseTestHelper.dispose();
  });

  group('Streak Database Integration Tests', () {
    test('should insert and select a streak', () async {
      final insertResponse = await SupabaseTestHelper.client
          .from('streaks')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'current_streak': 5,
            'best_streak': 10,
            'total_cards_reviewed': 100,
            'total_review_sessions': 20,
          })
          .select()
          .single();

      expect(insertResponse['current_streak'], equals(5));
      expect(insertResponse['best_streak'], equals(10));
      expect(insertResponse['total_cards_reviewed'], equals(100));
      expect(insertResponse['id'], isNotNull);
    });

    test('should update a streak', () async {
      // Insert
      await SupabaseTestHelper.client.from('streaks').insert({
        'user_id': SupabaseTestHelper.currentUserId,
        'current_streak': 1,
        'best_streak': 1,
      });

      // Update
      await SupabaseTestHelper.client
          .from('streaks')
          .update({
            'current_streak': 5,
            'best_streak': 5,
            'total_cards_reviewed': 50,
          })
          .eq('user_id', SupabaseTestHelper.currentUserId);

      // Verify
      final updated = await SupabaseTestHelper.client
          .from('streaks')
          .select()
          .eq('user_id', SupabaseTestHelper.currentUserId)
          .single();

      expect(updated['current_streak'], equals(5));
      expect(updated['best_streak'], equals(5));
      expect(updated['total_cards_reviewed'], equals(50));
    });

    test('should enforce unique user_id constraint', () async {
      // Insert first streak
      await SupabaseTestHelper.client.from('streaks').insert({
        'user_id': SupabaseTestHelper.currentUserId,
        'current_streak': 1,
      });

      // Try to insert duplicate - should use upsert with onConflict
      final upserted = await SupabaseTestHelper.client
          .from('streaks')
          .upsert(
            {
              'user_id': SupabaseTestHelper.currentUserId,
              'current_streak': 10,
              'best_streak': 10,
            },
            onConflict: 'user_id',
          )
          .select()
          .single();

      expect(upserted['current_streak'], equals(10));

      // Verify only one record exists
      final all = await SupabaseTestHelper.client
          .from('streaks')
          .select()
          .eq('user_id', SupabaseTestHelper.currentUserId);

      expect(all, hasLength(1));
    });

    test('should persist daily review counts as JSONB', () async {
      final dailyCounts = {
        '2024-01-01': 10,
        '2024-01-02': 15,
        '2024-01-03': 20,
      };

      final streak = await SupabaseTestHelper.client
          .from('streaks')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'current_streak': 3,
            'daily_review_counts': dailyCounts,
          })
          .select()
          .single();

      expect(streak['daily_review_counts']['2024-01-01'], equals(10));
      expect(streak['daily_review_counts']['2024-01-02'], equals(15));
      expect(streak['daily_review_counts']['2024-01-03'], equals(20));
    });

    test('should persist last review date', () async {
      final now = DateTime.now().toUtc();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final streak = await SupabaseTestHelper.client
          .from('streaks')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'current_streak': 1,
            'last_review_date': dateString,
          })
          .select()
          .single();

      expect(streak['last_review_date'], equals(dateString));
    });

    test('should auto-generate timestamps', () async {
      final streak = await SupabaseTestHelper.client
          .from('streaks')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'current_streak': 1,
          })
          .select()
          .single();

      expect(streak['created_at'], isNotNull);
      expect(streak['updated_at'], isNotNull);
    });

    test('should handle zero/default values correctly', () async {
      final streak = await SupabaseTestHelper.client
          .from('streaks')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
          })
          .select()
          .single();

      expect(streak['current_streak'], equals(0));
      expect(streak['best_streak'], equals(0));
      expect(streak['total_cards_reviewed'], equals(0));
      expect(streak['total_review_sessions'], equals(0));
    });
  });
}
