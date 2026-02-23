import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lingua_flutter/features/streak/domain/streak_notifier.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_model.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_state.dart';
import 'package:lingua_flutter/shared/services/logger_service.dart';
import 'streak_provider_test.mocks.dart';

ProviderContainer makeContainer(MockStreakService mockService) {
  return ProviderContainer(
    overrides: [streakServiceProvider.overrideWithValue(mockService)],
  );
}

void main() {
  setUpAll(LoggerService.initialize);

  group('StreakNotifier', () {
    late MockStreakService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockStreakService();
      container = makeContainer(mockService);

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

    StreakNotifier notifier() =>
        container.read(streakNotifierProvider.notifier);
    StreakState state() => container.read(streakNotifierProvider);

    test('should have initial state', () {
      expect(state().streak.currentStreak, equals(0));
      expect(state().streak.bestStreak, equals(0));
      expect(state().streak.totalCardsReviewed, equals(0));
      expect(state().isLoading, isFalse);
      expect(state().errorMessage, isNull);
      expect(state().newMilestones, isEmpty);
    });

    test('should load streak data', () async {
      await notifier().loadStreak();

      verify(mockService.loadStreak()).called(1);
      expect(state().isLoading, isFalse);
      expect(state().errorMessage, isNull);
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

      await notifier().updateStreakWithReview(cardsReviewed: 10);

      verify(
        mockService.updateStreakWithReview(cardsReviewed: 10, reviewDate: null),
      ).called(1);
      expect(state().streak.currentStreak, equals(1));
      expect(state().streak.totalCardsReviewed, equals(10));
    });

    test('should detect new milestones', () async {
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

      await notifier().updateStreakWithReview(cardsReviewed: 5);

      expect(state().newMilestones, isA<List<int>>());
    });

    test('should clear new milestones', () async {
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => StreakModel.initial());

      await notifier().updateStreakWithReview(cardsReviewed: 5);
      notifier().clearNewMilestones();

      expect(state().newMilestones, isEmpty);
    });

    test('should reset streak', () async {
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

      await notifier().updateStreakWithReview(cardsReviewed: 10);
      expect(state().streak.currentStreak, equals(1));

      final resetStreak = updatedStreak.resetStreak();
      when(mockService.resetStreak()).thenAnswer((_) async {});
      when(mockService.loadStreak()).thenAnswer((_) async => resetStreak);

      await notifier().resetStreak();

      verify(mockService.resetStreak()).called(1);
      expect(state().streak.currentStreak, equals(0));
      expect(state().streak.totalCardsReviewed, equals(10));
    });

    test('should clear streak data', () async {
      when(mockService.clearStreakData()).thenAnswer((_) async {});

      await notifier().clearStreakData();

      verify(mockService.clearStreakData()).called(1);
      expect(state().streak.currentStreak, equals(0));
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

      final first = notifier().updateStreakWithReview(cardsReviewed: 2);
      final second = notifier().updateStreakWithReview(cardsReviewed: 3);
      final third = notifier().updateStreakWithReview(cardsReviewed: 4);
      await Future.wait([first, second, third]);

      expect(cardsByCall, equals([2, 3, 4]));
      expect(totalCardsPassedToService, 9);
      expect(state().errorMessage, isNull);
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
        if (serviceCallCount == 1) throw Exception('first failure');
        return StreakModel(
          currentStreak: 1,
          totalCardsReviewed: cards,
          totalReviewSessions: 1,
          lastReviewDate: DateTime.now(),
        );
      });

      final first = notifier().updateStreakWithReview(cardsReviewed: 5);
      final second = notifier().updateStreakWithReview(cardsReviewed: 3);
      await Future.wait([first, second]);

      expect(serviceCallCount, 2);
      expect(state().streak.totalCardsReviewed, 3);
      expect(state().isLoading, isFalse);
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

      final load = notifier().loadStreak();
      final update = notifier().updateStreakWithReview(cardsReviewed: 7);
      await Future.wait([load, update]);

      expect(updateCallCount, 1);
      verify(
        mockService.updateStreakWithReview(cardsReviewed: 7, reviewDate: null),
      ).called(1);
    });

    test('should get daily review data', () async {
      final dailyData = await notifier().getDailyReviewData(days: 7);

      verify(mockService.getDailyReviewData(days: 7)).called(1);
      expect(dailyData, isA<Map<String, int>>());
    });

    test('should get streak statistics', () async {
      final stats = await notifier().getStreakStats();

      verify(mockService.getStreakStats()).called(1);
      expect(stats.containsKey('currentStreak'), isTrue);
    });

    test('errorMessage is cleared before next operation begins', () async {
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => throw Exception('first failure'));

      await notifier().updateStreakWithReview(cardsReviewed: 1);
      expect(state().errorMessage, isNotNull);

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

      await notifier().updateStreakWithReview(cardsReviewed: 5);

      expect(errorAtFirstNotify, isNull);
      expect(state().errorMessage, isNull);
    });
  });
}
