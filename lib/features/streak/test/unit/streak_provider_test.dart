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

    test('concurrent update is queued and not silently dropped', () async {
      int serviceCallCount = 0;
      int totalCardsPassedToService = 0;

      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((invocation) async {
        serviceCallCount++;
        final cards =
            invocation.namedArguments[const Symbol('cardsReviewed')] as int;
        totalCardsPassedToService += cards;
        return StreakModel.initial().updateWithReview(
          cardsReviewed: totalCardsPassedToService,
        );
      });

      // Fire two updates concurrently — the second should be queued
      final first = streakProvider.updateStreakWithReview(cardsReviewed: 5);
      final second = streakProvider.updateStreakWithReview(cardsReviewed: 3);
      await Future.wait([first, second]);

      // Both updates must have been applied (not dropped)
      expect(serviceCallCount, 2);
      expect(totalCardsPassedToService, 8);
    });

    test('pending update accumulates multiple concurrent calls', () async {
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
        return StreakModel.initial().updateWithReview(cardsReviewed: cards);
      });

      // Fire three updates concurrently — only 2 service calls expected:
      // the first immediate one, then one flush call with the accumulated total.
      final first = streakProvider.updateStreakWithReview(cardsReviewed: 2);
      final second = streakProvider.updateStreakWithReview(cardsReviewed: 3);
      final third = streakProvider.updateStreakWithReview(cardsReviewed: 4);
      await Future.wait([first, second, third]);

      // First call runs immediately; second and third are queued together
      // and flushed as a single call with 3+4=7.
      expect(serviceCallCount, 2);
    });

    test('pending flush is skipped when primary call fails', () async {
      int serviceCallCount = 0;

      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async {
        serviceCallCount++;
        throw Exception('service unavailable');
      });

      // Fire two concurrent updates — first fails, second should be queued
      // but NOT flushed (because primary failed).
      final first = streakProvider.updateStreakWithReview(cardsReviewed: 5);
      final second = streakProvider.updateStreakWithReview(cardsReviewed: 3);
      await Future.wait([first, second]);

      // Service called only once (the primary); flush suppressed on error.
      expect(serviceCallCount, 1);
      // Error message from the primary call is preserved.
      expect(streakProvider.errorMessage, isNotNull);
      expect(streakProvider.errorMessage, contains('Failed to update streak'));
    });

    test('error message is preserved when pending flush is suppressed', () async {
      when(
        mockService.updateStreakWithReview(
          cardsReviewed: anyNamed('cardsReviewed'),
          reviewDate: anyNamed('reviewDate'),
        ),
      ).thenAnswer((_) async => throw Exception('network error'));

      final first = streakProvider.updateStreakWithReview(cardsReviewed: 5);
      final second = streakProvider.updateStreakWithReview(cardsReviewed: 3);
      await Future.wait([first, second]);

      // The original error message must not be overwritten by a second failure.
      expect(streakProvider.errorMessage, isNotNull);
      expect(streakProvider.isLoading, isFalse);
    });

    test(
      'pending data is retained after failure so a retry can apply it',
      () async {
        int serviceCallCount = 0;

        when(
          mockService.updateStreakWithReview(
            cardsReviewed: anyNamed('cardsReviewed'),
            reviewDate: anyNamed('reviewDate'),
          ),
        ).thenAnswer((_) async {
          serviceCallCount++;
          throw Exception('service unavailable');
        });

        // First call fails; second is queued as pending.
        final first = streakProvider.updateStreakWithReview(cardsReviewed: 5);
        final second = streakProvider.updateStreakWithReview(cardsReviewed: 3);
        await Future.wait([first, second]);

        expect(serviceCallCount, 1);
        expect(streakProvider.errorMessage, isNotNull);

        // Now the service recovers — a retry should apply the pending 3 cards.
        when(
          mockService.updateStreakWithReview(
            cardsReviewed: anyNamed('cardsReviewed'),
            reviewDate: anyNamed('reviewDate'),
          ),
        ).thenAnswer((invocation) async {
          serviceCallCount++;
          final cards =
              invocation.namedArguments[const Symbol('cardsReviewed')] as int;
          return StreakModel.initial().updateWithReview(cardsReviewed: cards);
        });

        await streakProvider.retryPendingUpdate();

        // The pending 3-card update must have been sent to the service.
        expect(serviceCallCount, 2);
        expect(streakProvider.errorMessage, isNull);
      },
    );

    test(
      'earliest reviewDate wins when multiple pending calls carry explicit dates',
      () async {
        final earlier = DateTime(2026, 1, 1);
        final later = DateTime(2026, 3, 1);

        DateTime? capturedDate;

        when(
          mockService.updateStreakWithReview(
            cardsReviewed: anyNamed('cardsReviewed'),
            reviewDate: anyNamed('reviewDate'),
          ),
        ).thenAnswer((invocation) async {
          capturedDate =
              invocation.namedArguments[const Symbol('reviewDate')]
                  as DateTime?;
          final cards =
              invocation.namedArguments[const Symbol('cardsReviewed')] as int;
          return StreakModel.initial().updateWithReview(cardsReviewed: cards);
        });

        // Primary call fires immediately; second and third are queued.
        // Second carries the later date, third carries the earlier date.
        // The flush should use the earlier date.
        final first = streakProvider.updateStreakWithReview(
          cardsReviewed: 1,
          reviewDate: later,
        );
        final second = streakProvider.updateStreakWithReview(
          cardsReviewed: 2,
          reviewDate: later,
        );
        final third = streakProvider.updateStreakWithReview(
          cardsReviewed: 3,
          reviewDate: earlier,
        );
        await Future.wait([first, second, third]);

        // The flush call (second service invocation) must use the earliest date.
        expect(capturedDate, equals(earlier));
      },
    );

    test('pending flush runs when primary call succeeds', () async {
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
        return StreakModel.initial().updateWithReview(cardsReviewed: cards);
      });

      final first = streakProvider.updateStreakWithReview(cardsReviewed: 5);
      final second = streakProvider.updateStreakWithReview(cardsReviewed: 3);
      await Future.wait([first, second]);

      // Both calls should have been made (primary + flush).
      expect(serviceCallCount, 2);
      expect(streakProvider.errorMessage, isNull);
    });

    test(
      'update queued during loadStreak is flushed after load completes',
      () async {
        int updateCallCount = 0;

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

        // Start loadStreak (sets _isLoading = true) and concurrently fire an
        // updateStreakWithReview — the update should be queued and flushed once
        // loadStreak finishes, not silently dropped.
        final load = streakProvider.loadStreak();
        final update = streakProvider.updateStreakWithReview(cardsReviewed: 7);
        await Future.wait([load, update]);

        // The update must have been sent to the service.
        expect(updateCallCount, 1);
        expect(streakProvider.totalCardsReviewed, 7);
      },
    );

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
      'a review queued while loadStreak is in progress is applied after retryPendingUpdate when the flush fails',
      () async {
        when(
          mockService.loadStreak(),
        ).thenAnswer((_) async => StreakModel.initial());
        when(
          mockService.updateStreakWithReview(
            cardsReviewed: anyNamed('cardsReviewed'),
            reviewDate: anyNamed('reviewDate'),
          ),
        ).thenAnswer((_) async => throw Exception('service unavailable'));

        final load = streakProvider.loadStreak();
        final update = streakProvider.updateStreakWithReview(cardsReviewed: 7);
        await Future.wait([load, update]);

        expect(streakProvider.errorMessage, isNotNull);

        when(
          mockService.updateStreakWithReview(
            cardsReviewed: anyNamed('cardsReviewed'),
            reviewDate: anyNamed('reviewDate'),
          ),
        ).thenAnswer((invocation) async {
          final cards =
              invocation.namedArguments[const Symbol('cardsReviewed')] as int;
          return StreakModel.initial().updateWithReview(cardsReviewed: cards);
        });

        await streakProvider.retryPendingUpdate();

        expect(streakProvider.errorMessage, isNull);
        expect(streakProvider.totalCardsReviewed, 7);
      },
    );

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

    group('pending data is not double-counted when loadStreak flush fails', () {
      test(
        'retryPendingUpdate after a failed loadStreak flush sends exactly the queued count',
        () async {
          int updateCallCount = 0;
          int? lastCardsArg;

          when(
            mockService.updateStreakWithReview(
              cardsReviewed: anyNamed('cardsReviewed'),
              reviewDate: anyNamed('reviewDate'),
            ),
          ).thenAnswer((_) async => throw Exception('service unavailable'));

          final load = streakProvider.loadStreak();
          final update = streakProvider.updateStreakWithReview(
            cardsReviewed: 7,
          );
          await Future.wait([load, update]);

          expect(streakProvider.errorMessage, isNotNull);

          when(
            mockService.updateStreakWithReview(
              cardsReviewed: anyNamed('cardsReviewed'),
              reviewDate: anyNamed('reviewDate'),
            ),
          ).thenAnswer((invocation) async {
            updateCallCount++;
            lastCardsArg =
                invocation.namedArguments[const Symbol('cardsReviewed')] as int;
            return StreakModel.initial().updateWithReview(
              cardsReviewed: lastCardsArg!,
            );
          });

          await streakProvider.retryPendingUpdate();

          expect(updateCallCount, 1);
          expect(lastCardsArg, equals(7));
        },
      );
    });

    group(
      'flush restore does not double-count when a new call arrives during the failed flush',
      () {
        test(
          'pending count is not doubled when a concurrent call queues during a failed flush',
          () async {
            int serviceCallCount = 0;
            int? lastCardsArg;

            when(
              mockService.updateStreakWithReview(
                cardsReviewed: anyNamed('cardsReviewed'),
                reviewDate: anyNamed('reviewDate'),
              ),
            ).thenAnswer((invocation) async {
              serviceCallCount++;
              final cards =
                  invocation.namedArguments[const Symbol('cardsReviewed')]
                      as int;
              if (serviceCallCount == 1) {
                // Primary call succeeds
                return StreakModel.initial().updateWithReview(
                  cardsReviewed: cards,
                );
              }
              // Flush call fails
              throw Exception('flush failed');
            });

            // Primary (5) fires immediately; secondary (3) is queued as pending.
            final first = streakProvider.updateStreakWithReview(
              cardsReviewed: 5,
            );
            final second = streakProvider.updateStreakWithReview(
              cardsReviewed: 3,
            );
            await Future.wait([first, second]);

            // Flush failed — pending should be exactly 3, not 6.
            expect(streakProvider.errorMessage, isNotNull);

            when(
              mockService.updateStreakWithReview(
                cardsReviewed: anyNamed('cardsReviewed'),
                reviewDate: anyNamed('reviewDate'),
              ),
            ).thenAnswer((invocation) async {
              serviceCallCount++;
              lastCardsArg =
                  invocation.namedArguments[const Symbol('cardsReviewed')]
                      as int;
              return StreakModel.initial().updateWithReview(
                cardsReviewed: lastCardsArg!,
              );
            });

            await streakProvider.retryPendingUpdate();

            expect(
              lastCardsArg,
              equals(3),
              reason: 'pending must be exactly 3, not 6 (double-count bug)',
            );
            expect(streakProvider.errorMessage, isNull);
          },
        );
      },
    );

    group(
      'pending data is retained for retry when updateStreakWithReview flush fails',
      () {
        test(
          'retryPendingUpdate after a failed flush applies the pending cards',
          () async {
            int serviceCallCount = 0;
            int? lastCardsArg;

            when(
              mockService.updateStreakWithReview(
                cardsReviewed: anyNamed('cardsReviewed'),
                reviewDate: anyNamed('reviewDate'),
              ),
            ).thenAnswer((invocation) async {
              serviceCallCount++;
              final cards =
                  invocation.namedArguments[const Symbol('cardsReviewed')]
                      as int;
              if (serviceCallCount == 1) {
                return StreakModel.initial().updateWithReview(
                  cardsReviewed: cards,
                );
              }
              throw Exception('flush failed');
            });

            final first = streakProvider.updateStreakWithReview(
              cardsReviewed: 5,
            );
            final second = streakProvider.updateStreakWithReview(
              cardsReviewed: 3,
            );
            await Future.wait([first, second]);

            expect(streakProvider.errorMessage, isNotNull);

            when(
              mockService.updateStreakWithReview(
                cardsReviewed: anyNamed('cardsReviewed'),
                reviewDate: anyNamed('reviewDate'),
              ),
            ).thenAnswer((invocation) async {
              serviceCallCount++;
              lastCardsArg =
                  invocation.namedArguments[const Symbol('cardsReviewed')]
                      as int;
              return StreakModel.initial().updateWithReview(
                cardsReviewed: lastCardsArg!,
              );
            });

            await streakProvider.retryPendingUpdate();

            expect(
              lastCardsArg,
              equals(3),
              reason:
                  'pending 3 cards must be sent on retry, not silently lost',
            );
            expect(streakProvider.errorMessage, isNull);
          },
        );
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
