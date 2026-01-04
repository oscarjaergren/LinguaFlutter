/// Integration tests for Card database operations
///
/// Tests database schema and CRUD operations directly via Supabase client.
/// No Flutter dependencies - uses pure supabase package.
///
/// Run with: dart test lib/features/card_management/test/integration/ --tags integration
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
    await SupabaseTestHelper.cleanTestUserCards();
  });

  tearDownAll(() async {
    await SupabaseTestHelper.dispose();
  });

  group('Card Database Integration Tests', () {
    test('should insert and select a card', () async {
      // Insert
      final insertResponse = await SupabaseTestHelper.client
          .from('cards')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'front_text': 'Hallo',
            'back_text': 'Hello',
            'language': 'de',
            'category': 'Greetings',
          })
          .select()
          .single();

      expect(insertResponse['front_text'], equals('Hallo'));
      expect(insertResponse['back_text'], equals('Hello'));
      expect(insertResponse['id'], isNotNull);

      // Select
      final selectResponse = await SupabaseTestHelper.client
          .from('cards')
          .select()
          .eq('user_id', SupabaseTestHelper.currentUserId);

      expect(selectResponse, hasLength(1));
      expect(selectResponse.first['front_text'], equals('Hallo'));
    });

    test('should update a card', () async {
      // Insert
      final card = await SupabaseTestHelper.client
          .from('cards')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'front_text': 'Original',
            'back_text': 'Original',
            'language': 'de',
          })
          .select()
          .single();

      // Update
      await SupabaseTestHelper.client
          .from('cards')
          .update({'front_text': 'Updated', 'back_text': 'Updated'})
          .eq('id', card['id']);

      // Verify
      final updated = await SupabaseTestHelper.client
          .from('cards')
          .select()
          .eq('id', card['id'])
          .single();

      expect(updated['front_text'], equals('Updated'));
      expect(updated['back_text'], equals('Updated'));
    });

    test('should delete a card', () async {
      // Insert
      final card = await SupabaseTestHelper.client
          .from('cards')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'front_text': 'ToDelete',
            'back_text': 'ToDelete',
            'language': 'de',
          })
          .select()
          .single();

      // Delete
      await SupabaseTestHelper.client
          .from('cards')
          .delete()
          .eq('id', card['id']);

      // Verify
      final remaining = await SupabaseTestHelper.client
          .from('cards')
          .select()
          .eq('user_id', SupabaseTestHelper.currentUserId);

      expect(remaining, isEmpty);
    });

    test('should filter cards by language', () async {
      // Insert German card
      await SupabaseTestHelper.client.from('cards').insert({
        'user_id': SupabaseTestHelper.currentUserId,
        'front_text': 'Hallo',
        'back_text': 'Hello',
        'language': 'de',
      });

      // Insert Spanish card
      await SupabaseTestHelper.client.from('cards').insert({
        'user_id': SupabaseTestHelper.currentUserId,
        'front_text': 'Hola',
        'back_text': 'Hello',
        'language': 'es',
      });

      // Query German only
      final germanCards = await SupabaseTestHelper.client
          .from('cards')
          .select()
          .eq('user_id', SupabaseTestHelper.currentUserId)
          .eq('language', 'de');

      expect(germanCards, hasLength(1));
      expect(germanCards.first['front_text'], equals('Hallo'));

      // Query all
      final allCards = await SupabaseTestHelper.client
          .from('cards')
          .select()
          .eq('user_id', SupabaseTestHelper.currentUserId);

      expect(allCards, hasLength(2));
    });

    test('should persist review statistics', () async {
      // Insert with review stats
      final card = await SupabaseTestHelper.client
          .from('cards')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'front_text': 'Test',
            'back_text': 'Test',
            'language': 'de',
            'review_count': 10,
            'correct_count': 8,
          })
          .select()
          .single();

      expect(card['review_count'], equals(10));
      expect(card['correct_count'], equals(8));
    });

    test('should persist boolean flags', () async {
      final card = await SupabaseTestHelper.client
          .from('cards')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'front_text': 'Flagged',
            'back_text': 'Flagged',
            'language': 'de',
            'is_favorite': true,
            'is_archived': true,
          })
          .select()
          .single();

      expect(card['is_favorite'], isTrue);
      expect(card['is_archived'], isTrue);
    });

    test('should persist arrays (tags, examples)', () async {
      final card = await SupabaseTestHelper.client
          .from('cards')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'front_text': 'Tagged',
            'back_text': 'Tagged',
            'language': 'de',
            'tags': ['important', 'review'],
            'examples': ['Example 1', 'Example 2'],
          })
          .select()
          .single();

      expect(card['tags'], containsAll(['important', 'review']));
      expect(card['examples'], containsAll(['Example 1', 'Example 2']));
    });

    test('should persist notes', () async {
      final card = await SupabaseTestHelper.client
          .from('cards')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'front_text': 'WithNotes',
            'back_text': 'WithNotes',
            'language': 'de',
            'notes': 'This is a helpful note.',
          })
          .select()
          .single();

      expect(card['notes'], equals('This is a helpful note.'));
    });

    test('should auto-generate timestamps', () async {
      final card = await SupabaseTestHelper.client
          .from('cards')
          .insert({
            'user_id': SupabaseTestHelper.currentUserId,
            'front_text': 'Timestamps',
            'back_text': 'Timestamps',
            'language': 'de',
          })
          .select()
          .single();

      expect(card['created_at'], isNotNull);
      expect(card['updated_at'], isNotNull);
    });
  });
}
