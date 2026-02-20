/// Integration tests for SupabaseStreakService.
///
/// Verifies service-level behavior against local Supabase, including the
/// atomic streak RPC flow.
@Tags(['integration'])
library;

import 'package:lingua_flutter/features/streak/data/services/supabase_streak_service.dart';
import 'package:lingua_flutter/shared/test_helpers/supabase_test_helper.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';
import 'package:test/test.dart';

void main() {
  late SupabaseStreakService streakService;
  var helperInitialized = false;

  setUpAll(() async {
    LoggerService.initialize();
    await SupabaseTestHelper.initialize();
    await SupabaseTestHelper.waitForDatabase();
    await SupabaseTestHelper.signInTestUser();
    helperInitialized = true;
  });

  setUp(() async {
    await SupabaseTestHelper.cleanTestUserStreaks();
    streakService = SupabaseStreakService(
      clientProvider: () => SupabaseTestHelper.client,
      isAuthenticatedProvider: () => true,
      userIdProvider: () => SupabaseTestHelper.currentUserId,
    );
  });

  tearDownAll(() async {
    if (!helperInitialized) return;
    await SupabaseTestHelper.dispose();
  });

  group('SupabaseStreakService integration', () {
    test(
      'updateStreakWithReview applies cards atomically and returns model',
      () async {
        final updated = await streakService.updateStreakWithReview(
          cardsReviewed: 5,
        );

        expect(updated.currentStreak, equals(1));
        expect(updated.bestStreak, equals(1));
        expect(updated.totalCardsReviewed, equals(5));
        expect(updated.totalReviewSessions, equals(1));
        expect(updated.dailyReviewCounts, isNotEmpty);
      },
    );

    test(
      'concurrent review updates preserve total cards and sessions',
      () async {
        final first = streakService.updateStreakWithReview(cardsReviewed: 5);
        final second = streakService.updateStreakWithReview(cardsReviewed: 3);
        final results = await Future.wait([first, second]);

        expect(results, hasLength(2));

        final loaded = await streakService.loadStreak();
        expect(loaded.totalCardsReviewed, equals(8));
        expect(loaded.totalReviewSessions, equals(2));
        expect(loaded.currentStreak, equals(1));
      },
    );

    test('returns initial model when not authenticated', () async {
      final unauthenticatedService = SupabaseStreakService(
        clientProvider: () => SupabaseTestHelper.client,
        isAuthenticatedProvider: () => false,
        userIdProvider: () => null,
      );

      final updated = await unauthenticatedService.updateStreakWithReview(
        cardsReviewed: 5,
      );

      expect(updated.currentStreak, equals(0));
      expect(updated.totalCardsReviewed, equals(0));
      expect(updated.totalReviewSessions, equals(0));
    });
  });
}
