import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:lingua_flutter/features/streak/domain/streak_provider.dart';
import 'package:lingua_flutter/features/streak/domain/models/streak_model.dart';
import 'package:lingua_flutter/features/streak/data/services/streak_service.dart';

@GenerateMocks([StreakService])
import 'streak_provider_test.mocks.dart';

void main() {
  group('StreakProvider', () {
    late StreakProvider streakProvider;
    late MockStreakService mockService;

    setUp(() {
      mockService = MockStreakService();
      streakProvider = StreakProvider(streakService: mockService);

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
      streakProvider.dispose();
    });

    test('should have initial state', () {
      expect(streakProvider.currentStreak, equals(0));
      expect(streakProvider.bestStreak, equals(0));
      expect(streakProvider.totalCardsReviewed, equals(0));
      expect(streakProvider.totalReviewSessions, equals(0));
      expect(streakProvider.cardsReviewedToday, equals(0));
      expect(streakProvider.isLoading, isFalse);
      expect(streakProvider.errorMessage, isNull);
      expect(streakProvider.newMilestones, isEmpty);
    });

    test('should load streak data', () async {
      await streakProvider.loadStreak();

      verify(mockService.loadStreak()).called(1);
      expect(streakProvider.isLoading, isFalse);
      expect(streakProvider.errorMessage, isNull);
    });

    test('should update streak with review', () async {
      final updatedStreak = StreakModel.initial().updateWithReview(
        cardsReviewed: 10,
      );
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => updatedStreak);

      await streakProvider.updateStreakWithReview(cardsReviewed: 10);

      verify(
        mockService.updateStreakWithReview(cardsReviewed: 10, reviewDate: null),
      ).called(1);
      expect(streakProvider.currentStreak, equals(1));
      expect(streakProvider.totalCardsReviewed, equals(10));
    });

    test('should detect new milestones', () async {
      // Update streak to potentially reach milestones
      final updatedStreak = StreakModel.initial().updateWithReview(
        cardsReviewed: 5,
      );
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => updatedStreak);

      await streakProvider.updateStreakWithReview(cardsReviewed: 5);

      expect(streakProvider.newMilestones, isA<List<int>>());
    });

    test('should clear new milestones', () async {
      await streakProvider.updateStreakWithReview(cardsReviewed: 5);

      streakProvider.clearNewMilestones();
      expect(streakProvider.newMilestones, isEmpty);
    });

    test('should reset streak', () async {
      // Setup: first update to have a streak
      final updatedStreak = StreakModel.initial().updateWithReview(
        cardsReviewed: 10,
      );
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => updatedStreak);

      await streakProvider.updateStreakWithReview(cardsReviewed: 10);
      expect(streakProvider.currentStreak, equals(1));

      // Reset
      final resetStreak = updatedStreak.resetStreak();
      when(mockService.resetStreak()).thenAnswer((_) async {});
      when(mockService.loadStreak()).thenAnswer((_) async => resetStreak);

      await streakProvider.resetStreak();

      verify(mockService.resetStreak()).called(1);
      expect(streakProvider.currentStreak, equals(0));
      expect(streakProvider.totalCardsReviewed, equals(10)); // Stats preserved
    });

    test('should clear streak data', () async {
      when(mockService.clearStreakData()).thenAnswer((_) async {});

      await streakProvider.clearStreakData();

      verify(mockService.clearStreakData()).called(1);
      expect(streakProvider.currentStreak, equals(0));
    });

    test('should provide motivational messages', () {
      expect(
        streakProvider.getMotivationalMessage(),
        contains('Start your learning streak'),
      );
    });

    test('should provide streak status colors', () {
      expect(streakProvider.getStreakStatusColor(), equals('grey'));
    });

    test('should check new milestones correctly', () {
      expect(streakProvider.isNewMilestone(7), isFalse);
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
        return StreakModel.initial().updateWithReview(
          cardsReviewed: totalCardsPassedToService,
        );
      });

      final first = streakProvider.updateStreakWithReview(cardsReviewed: 2);
      final second = streakProvider.updateStreakWithReview(cardsReviewed: 3);
      final third = streakProvider.updateStreakWithReview(cardsReviewed: 4);
      await Future.wait([first, second, third]);

      expect(cardsByCall, equals([2, 3, 4]));
      expect(totalCardsPassedToService, 9);
      expect(streakProvider.errorMessage, isNull);
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
        return StreakModel.initial().updateWithReview(cardsReviewed: cards);
      });

      final first = streakProvider.updateStreakWithReview(cardsReviewed: 5);
      final second = streakProvider.updateStreakWithReview(cardsReviewed: 3);
      await Future.wait([first, second]);

      expect(serviceCallCount, 2);
      expect(streakProvider.totalCardsReviewed, 3);
      expect(streakProvider.isLoading, isFalse);
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
        return StreakModel.initial().updateWithReview(cardsReviewed: cards);
      });

      final load = streakProvider.loadStreak();
      final update = streakProvider.updateStreakWithReview(cardsReviewed: 7);
      await Future.wait([load, update]);

      expect(updateCallCount, 1);
      verify(
        mockService.updateStreakWithReview(cardsReviewed: 7, reviewDate: null),
      ).called(1);
    });

    test('should get daily review data', () async {
      final dailyData = await streakProvider.getDailyReviewData(days: 7);

      verify(mockService.getDailyReviewData(days: 7)).called(1);
      expect(dailyData, isA<Map<String, int>>());
    });

    test('should get streak statistics', () async {
      final stats = await streakProvider.getStreakStats();

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

        await streakProvider.updateStreakWithReview(cardsReviewed: 1);
        expect(streakProvider.errorMessage, isNotNull);

        // Now make the service succeed
        when(
          mockService.updateStreakWithReview(
            cardsReviewed: anyNamed('cardsReviewed'),
            reviewDate: anyNamed('reviewDate'),
          ),
        ).thenAnswer(
          (_) async => StreakModel.initial().updateWithReview(cardsReviewed: 5),
        );

        // Capture the errorMessage value at the moment the first notification
        // fires after the new call starts (i.e. when _setLoading(true) is called,
        // which happens AFTER _clearError()).
        String? errorAtFirstNotify;
        bool captured = false;
        streakProvider.addListener(() {
          if (!captured) {
            captured = true;
            errorAtFirstNotify = streakProvider.errorMessage;
          }
        });

        await streakProvider.updateStreakWithReview(cardsReviewed: 5);

        // The very first notification must already see a null errorMessage,
        // meaning _clearError notified listeners before _setLoading(true).
        expect(errorAtFirstNotify, isNull);
        expect(streakProvider.errorMessage, isNull);
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

    test('should update with review', () {
      final streak = StreakModel.initial();
      final updated = streak.updateWithReview(cardsReviewed: 5);

      expect(updated.currentStreak, equals(1));
      expect(updated.totalCardsReviewed, equals(5));
      expect(updated.totalReviewSessions, equals(1));
    });

    test('should reset streak but keep stats', () {
      final streak = StreakModel.initial().updateWithReview(cardsReviewed: 10);

      expect(streak.currentStreak, equals(1));

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
