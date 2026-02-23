import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:lingua_flutter/features/streak/domain/streak_provider.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_model.dart';
import 'package:lingua_flutter/features/streak/data/services/streak_service.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';

@GenerateMocks([StreakService])
import 'streak_provider_test.mocks.dart';

ProviderContainer makeContainer(MockStreakService mockService) =>
    ProviderContainer(
      overrides: [streakServiceProvider.overrideWithValue(mockService)],
    );

void main() {
  setUpAll(LoggerService.initialize);

  group('StreakProvider', () {
    late MockStreakService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockStreakService();
      container = makeContainer(mockService);

      // Default stubs
      when(
        mockService.loadStreak(),
      ).thenAnswer((_) async => StreakModel.initial());
      when(
        mockService.getDailyReviewData(days: anyNamed('days')),
      ).thenAnswer((_) async => <String, int>{});
      when(mockService.getStreakStats()).thenAnswer(
        (_) async => {
          'currentStreak': 0,
          'bestStreak': 0,
          'totalSessions': 0,
          'totalCards': 0,
        },
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial state', () {
      final s = container.read(streakNotifierProvider);
      expect(s.streak.currentStreak, equals(0));
      expect(s.streak.bestStreak, equals(0));
      expect(s.streak.totalCardsReviewed, equals(0));
      expect(s.streak.totalReviewSessions, equals(0));
      expect(s.streak.cardsReviewedToday, equals(0));
      expect(s.isLoading, isFalse);
      expect(s.errorMessage, isNull);
      expect(s.newMilestones, isEmpty);
    });

    test('should load streak data', () async {
      await container.read(streakNotifierProvider.notifier).loadStreak();

      verify(mockService.loadStreak()).called(1);
      expect(container.read(streakNotifierProvider).isLoading, isFalse);
      expect(container.read(streakNotifierProvider).errorMessage, isNull);
    });

    test('should update streak with review', () async {
      final updatedStreak = StreakModel(
        currentStreak: 1,
        totalCardsReviewed: 10,
        totalReviewSessions: 1,
        lastReviewDate: DateTime.now(),
      );
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => updatedStreak);

      await container
          .read(streakNotifierProvider.notifier)
          .updateStreakWithReview(cardsReviewed: 10);

      verify(
        mockService.updateStreakWithReview(cardsReviewed: 10, reviewDate: null),
      ).called(1);
      expect(
        container.read(streakNotifierProvider).streak.currentStreak,
        equals(1),
      );
      expect(
        container.read(streakNotifierProvider).streak.totalCardsReviewed,
        equals(10),
      );
    });

    test('should detect new milestones', () async {
      // Update streak to potentially reach milestones
      final updatedStreak = StreakModel(
        currentStreak: 1,
        totalCardsReviewed: 5,
        totalReviewSessions: 1,
        lastReviewDate: DateTime.now(),
      );
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => updatedStreak);

      await container
          .read(streakNotifierProvider.notifier)
          .updateStreakWithReview(cardsReviewed: 5);

      expect(
        container.read(streakNotifierProvider).newMilestones,
        isA<List<int>>(),
      );
    });

    test('should clear new milestones', () async {
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => StreakModel.initial());
      await container
          .read(streakNotifierProvider.notifier)
          .updateStreakWithReview(cardsReviewed: 5);

      container.read(streakNotifierProvider.notifier).clearNewMilestones();
      expect(container.read(streakNotifierProvider).newMilestones, isEmpty);
    });

    test('should reset streak', () async {
      // Setup: first update to have a streak
      final updatedStreak = StreakModel(
        currentStreak: 1,
        totalCardsReviewed: 10,
        totalReviewSessions: 1,
        lastReviewDate: DateTime.now(),
      );
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => updatedStreak);

      final notifier = container.read(streakNotifierProvider.notifier);
      await notifier.updateStreakWithReview(cardsReviewed: 10);
      expect(
        container.read(streakNotifierProvider).streak.currentStreak,
        equals(1),
      );

      // Reset
      final resetStreak = updatedStreak.resetStreak();
      when(mockService.resetStreak()).thenAnswer((_) async {});
      when(mockService.loadStreak()).thenAnswer((_) async => resetStreak);

      await notifier.resetStreak();

      verify(mockService.resetStreak()).called(1);
      expect(
        container.read(streakNotifierProvider).streak.currentStreak,
        equals(0),
      );
      expect(
        container.read(streakNotifierProvider).streak.totalCardsReviewed,
        equals(10),
      );
    });

    test('should clear streak data', () async {
      when(mockService.clearStreakData()).thenAnswer((_) async {});

      await container.read(streakNotifierProvider.notifier).clearStreakData();

      verify(mockService.clearStreakData()).called(1);
      expect(
        container.read(streakNotifierProvider).streak.currentStreak,
        equals(0),
      );
    });

    test('should provide motivational messages', () {
      expect(
        container
            .read(streakNotifierProvider.notifier)
            .getMotivationalMessage(),
        contains('Every journey begins'),
      );
    });

    test('should provide streak status colors', () {
      expect(
        container.read(streakNotifierProvider.notifier).getStreakStatusColor(),
        equals('grey'),
      );
    });

    test('should check new milestones correctly', () {
      expect(
        container.read(streakNotifierProvider.notifier).isNewMilestone(7),
        isFalse,
      );
    });

    test('concurrent updates forward all review counts to service', () async {
      final cardsByCall = <int>[];
      int totalCardsPassedToService = 0;

      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((invocation) async {
        final cards =
            invocation.namedArguments[const Symbol('cardsReviewed')] as int;
        cardsByCall.add(cards);
        totalCardsPassedToService += cards;
        return StreakModel(
          currentStreak: 1,
          totalCardsReviewed: totalCardsPassedToService,
          totalReviewSessions: cardsByCall.length,
          lastReviewDate: DateTime.now(),
        );
      });

      final notifier = container.read(streakNotifierProvider.notifier);
      final first = notifier.updateStreakWithReview(cardsReviewed: 2);
      final second = notifier.updateStreakWithReview(cardsReviewed: 3);
      final third = notifier.updateStreakWithReview(cardsReviewed: 4);
      await Future.wait([first, second, third]);

      expect(cardsByCall, equals([2, 3, 4]));
      expect(totalCardsPassedToService, 9);
      expect(container.read(streakNotifierProvider).errorMessage, isNull);
    });

    test('failed update does not block later concurrent updates', () async {
      int serviceCallCount = 0;

      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((invocation) async {
        serviceCallCount++;
        final cards =
            invocation.namedArguments[const Symbol('cardsReviewed')] as int;
        if (serviceCallCount == 1) {
          throw Exception('first failure');
        }
        return StreakModel(
          currentStreak: 1,
          totalCardsReviewed: cards,
          totalReviewSessions: 1,
          lastReviewDate: DateTime.now(),
        );
      });

      final notifier = container.read(streakNotifierProvider.notifier);
      final first = notifier.updateStreakWithReview(cardsReviewed: 5);
      final second = notifier.updateStreakWithReview(cardsReviewed: 3);
      await Future.wait([first, second]);

      expect(serviceCallCount, 2);
      expect(
        container.read(streakNotifierProvider).streak.totalCardsReviewed,
        3,
      );
      expect(container.read(streakNotifierProvider).isLoading, isFalse);
    });

    test('update during loadStreak still reaches service', () async {
      int updateCallCount = 0;

      when(mockService.loadStreak()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return StreakModel.initial();
      });
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((invocation) async {
        updateCallCount++;
        final cards =
            invocation.namedArguments[const Symbol('cardsReviewed')] as int;
        return StreakModel(
          currentStreak: 1,
          totalCardsReviewed: cards,
          totalReviewSessions: 1,
          lastReviewDate: DateTime.now(),
        );
      });

      final notifier = container.read(streakNotifierProvider.notifier);
      final load = notifier.loadStreak();
      final update = notifier.updateStreakWithReview(cardsReviewed: 7);
      await Future.wait([load, update]);

      expect(updateCallCount, 1);
      verify(
        mockService.updateStreakWithReview(cardsReviewed: 7, reviewDate: null),
      ).called(1);
    });

    test('should get daily review data', () async {
      final dailyData = await container
          .read(streakNotifierProvider.notifier)
          .getDailyReviewData(days: 7);

      verify(mockService.getDailyReviewData(days: 7)).called(1);
      expect(dailyData, isA<Map<String, int>>());
    });

    test('should get streak statistics', () async {
      final stats = await container
          .read(streakNotifierProvider.notifier)
          .getStreakStats();

      verify(mockService.getStreakStats()).called(1);
      expect(stats.containsKey('currentStreak'), isTrue);
    });

    test(
      'errorMessage is cleared and listeners notified before next operation begins',
      () async {
        // Arrange: put the provider into an error state
        when(
          mockService.updateStreakWithReview(
            cardsReviewed: anyNamed('cardsReviewed'),
            reviewDate: anyNamed('reviewDate'),
          ),
        ).thenAnswer((_) async => throw Exception('first failure'));

        final notifier = container.read(streakNotifierProvider.notifier);
        await notifier.updateStreakWithReview(cardsReviewed: 1);
        expect(container.read(streakNotifierProvider).errorMessage, isNotNull);

        // Now make the service succeed
        when(
          mockService.updateStreakWithReview(
            cardsReviewed: anyNamed('cardsReviewed'),
            reviewDate: anyNamed('reviewDate'),
          ),
        ).thenAnswer(
          (_) async => StreakModel(
            currentStreak: 1,
            totalCardsReviewed: 5,
            totalReviewSessions: 1,
            lastReviewDate: DateTime.now(),
          ),
        );

        String? errorAtFirstNotify;
        bool captured = false;
        container.listen(streakNotifierProvider, (_, next) {
          if (!captured) {
            captured = true;
            errorAtFirstNotify = next.errorMessage;
          }
        });

        await notifier.updateStreakWithReview(cardsReviewed: 5);

        expect(errorAtFirstNotify, isNull);
        expect(container.read(streakNotifierProvider).errorMessage, isNull);
      },
    );
  });

  group('StreakModel', () {
    test('should create initial streak model', () {
      final streak = StreakModel.initial();

      expect(streak.currentStreak, equals(0));
      expect(streak.bestStreak, equals(0));
      expect(streak.totalCardsReviewed, equals(0));
      expect(streak.totalReviewSessions, equals(0));
      expect(streak.cardsReviewedToday, equals(0));
    });

    test('should reset streak but keep stats', () {
      final streak = StreakModel(
        currentStreak: 1,
        totalCardsReviewed: 10,
        totalReviewSessions: 1,
        lastReviewDate: DateTime.now(),
      );

      final reset = streak.resetStreak();

      expect(reset.currentStreak, equals(0));
      expect(reset.totalCardsReviewed, equals(10)); // Stats preserved
      expect(reset.totalReviewSessions, equals(1)); // Stats preserved
    });

    test('should detect milestones correctly', () {
      final streak = StreakModel.initial();

      // 0 -> 0, no milestone
      expect(streak.getNewMilestones(0), isEmpty);
    });
  });
}
