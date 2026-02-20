import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_score.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

void main() {
  group('ExerciseScore', () {
    group('Creation', () {
      test('should create initial score with zero values', () {
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);

        expect(score.type, ExerciseType.readingRecognition);
        expect(score.correctCount, 0);
        expect(score.incorrectCount, 0);
        expect(score.lastPracticed, isNull);
        expect(score.nextReview, isNull);
      });

      test('should create score with all fields', () {
        final now = DateTime.now();
        final nextReview = now.add(const Duration(days: 1));

        final score = ExerciseScore(
          type: ExerciseType.reverseTranslation,
          correctCount: 5,
          incorrectCount: 2,
          lastPracticed: now,
          nextReview: nextReview,
        );

        expect(score.type, ExerciseType.reverseTranslation);
        expect(score.correctCount, 5);
        expect(score.incorrectCount, 2);
        expect(score.lastPracticed, now);
        expect(score.nextReview, nextReview);
      });
    });

    group('totalAttempts', () {
      test('should return sum of correct and incorrect counts', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 7,
          incorrectCount: 3,
        );

        expect(score.totalAttempts, 10);
      });

      test('should return 0 for initial score', () {
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);

        expect(score.totalAttempts, 0);
      });
    });

    group('successRate', () {
      test('should return 0 when no attempts', () {
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);

        expect(score.successRate, 0.0);
      });

      test('should calculate correct percentage', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 7,
          incorrectCount: 3,
        );

        expect(score.successRate, 70.0);
      });

      test('should return 100 when all correct', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 10,
          incorrectCount: 0,
        );

        expect(score.successRate, 100.0);
      });

      test('should return 0 when all incorrect', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 0,
          incorrectCount: 10,
        );

        expect(score.successRate, 0.0);
      });
    });

    group('isDueForReview', () {
      test('should return true when nextReview is null', () {
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);

        expect(score.isDueForReview, true);
      });

      test('should return true when nextReview is in the past', () {
        final score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          nextReview: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(score.isDueForReview, true);
      });

      test('should return false when nextReview is in the future', () {
        final score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          nextReview: DateTime.now().add(const Duration(days: 1)),
        );

        expect(score.isDueForReview, false);
      });
    });

    group('masteryLevel', () {
      test('should return New when no attempts', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 0,
          incorrectCount: 0,
          currentChain: 0,
        );

        expect(score.masteryLevel, 'New');
      });

      test('should return Difficult when chain is 0 with attempts', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 2,
          incorrectCount: 8,
          currentChain: 0,
        );

        expect(score.masteryLevel, 'Difficult');
      });

      test('should return Learning when chain is 1-2', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 6,
          incorrectCount: 4,
          currentChain: 2,
        );

        expect(score.masteryLevel, 'Learning');
      });

      test('should return Good when chain is 3-4', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 8,
          incorrectCount: 2,
          currentChain: 3,
        );

        expect(score.masteryLevel, 'Good');
      });

      test('should return Mastered when chain is 5+', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 9,
          incorrectCount: 1,
          currentChain: 5,
        );

        expect(score.masteryLevel, 'Mastered');
      });
    });

    group('netScore', () {
      test('should return correct minus incorrect', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 10,
          incorrectCount: 3,
        );

        expect(score.netScore, 7);
      });

      test('should return negative when more incorrect', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 2,
          incorrectCount: 8,
        );

        expect(score.netScore, -6);
      });
    });

    group('recordCorrect', () {
      test('should increment correctCount', () {
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);
        final updated = score.recordCorrect();

        expect(updated.correctCount, 1);
        expect(updated.incorrectCount, 0);
      });

      test('should set lastPracticed to now', () {
        final before = DateTime.now();
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);
        final updated = score.recordCorrect();
        final after = DateTime.now();

        expect(updated.lastPracticed, isNotNull);
        expect(
          updated.lastPracticed!.isAfter(
            before.subtract(const Duration(seconds: 1)),
          ),
          true,
        );
        expect(
          updated.lastPracticed!.isBefore(
            after.add(const Duration(seconds: 1)),
          ),
          true,
        );
      });

      test('should set nextReview in the future', () {
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);
        final updated = score.recordCorrect();

        expect(updated.nextReview, isNotNull);
        expect(updated.nextReview!.isAfter(DateTime.now()), true);
      });

      test('should increase interval with more correct answers', () {
        var score = ExerciseScore.initial(ExerciseType.readingRecognition);

        final first = score.recordCorrect();
        final firstInterval = first.nextReview!.difference(DateTime.now());

        final second = first.recordCorrect();
        final secondInterval = second.nextReview!.difference(DateTime.now());

        expect(
          secondInterval.inDays,
          greaterThanOrEqualTo(firstInterval.inDays),
        );
      });
    });

    group('recordIncorrect', () {
      test('should increment incorrectCount', () {
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);
        final updated = score.recordIncorrect();

        expect(updated.correctCount, 0);
        expect(updated.incorrectCount, 1);
      });

      test('should set lastPracticed to now', () {
        final before = DateTime.now();
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);
        final updated = score.recordIncorrect();
        final after = DateTime.now();

        expect(updated.lastPracticed, isNotNull);
        expect(
          updated.lastPracticed!.isAfter(
            before.subtract(const Duration(seconds: 1)),
          ),
          true,
        );
        expect(
          updated.lastPracticed!.isBefore(
            after.add(const Duration(seconds: 1)),
          ),
          true,
        );
      });

      test('should set nextReview to tomorrow', () {
        final now = DateTime.now();
        final score = ExerciseScore.initial(ExerciseType.readingRecognition);
        final updated = score.recordIncorrect();

        expect(updated.nextReview, isNotNull);
        final hoursDifference = updated.nextReview!.difference(now).inHours;
        expect(hoursDifference, greaterThanOrEqualTo(23));
        expect(hoursDifference, lessThanOrEqualTo(25));
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 5,
          incorrectCount: 2,
        );

        final copied = original.copyWith(correctCount: 10, incorrectCount: 3);

        expect(copied.type, ExerciseType.readingRecognition);
        expect(copied.correctCount, 10);
        expect(copied.incorrectCount, 3);
      });

      test('should preserve values when not specified', () {
        final now = DateTime.now();
        final score = ExerciseScore(
          type: ExerciseType.reverseTranslation,
          correctCount: 5,
          incorrectCount: 2,
          lastPracticed: now,
        );

        final copied = score.copyWith(correctCount: 10);

        expect(copied.type, ExerciseType.reverseTranslation);
        expect(copied.correctCount, 10);
        expect(copied.incorrectCount, 2);
        expect(copied.lastPracticed, now);
      });
    });

    group('JSON serialization', () {
      test('should convert to JSON', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 5,
          incorrectCount: 2,
        );

        final json = score.toJson();

        expect(json['type'], isNotNull);
        expect(json['correctCount'], 5);
        expect(json['incorrectCount'], 2);
      });

      test('should create from JSON', () {
        final json = {
          'type': 'reading_recognition',
          'correctCount': 7,
          'incorrectCount': 3,
          'lastPracticed': null,
          'nextReview': null,
        };

        final score = ExerciseScore.fromJson(json);

        expect(score.type, ExerciseType.readingRecognition);
        expect(score.correctCount, 7);
        expect(score.incorrectCount, 3);
      });

      test('should round-trip through JSON', () {
        const original = ExerciseScore(
          type: ExerciseType.multipleChoiceText,
          correctCount: 10,
          incorrectCount: 5,
        );

        final json = original.toJson();
        final restored = ExerciseScore.fromJson(json);

        expect(restored.type, original.type);
        expect(restored.correctCount, original.correctCount);
        expect(restored.incorrectCount, original.incorrectCount);
      });
    });

    group('Equality', () {
      test('should be equal when same type', () {
        const score1 = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 5,
        );
        const score2 = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 10,
        );

        expect(score1, equals(score2));
      });

      test('should not be equal when different type', () {
        const score1 = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 5,
        );
        const score2 = ExerciseScore(
          type: ExerciseType.reverseTranslation,
          correctCount: 5,
        );

        expect(score1, isNot(equals(score2)));
      });

      test('should have same hashCode for same type', () {
        const score1 = ExerciseScore(type: ExerciseType.readingRecognition);
        const score2 = ExerciseScore(type: ExerciseType.readingRecognition);

        expect(score1.hashCode, equals(score2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string', () {
        const score = ExerciseScore(
          type: ExerciseType.readingRecognition,
          correctCount: 7,
          incorrectCount: 3,
        );

        final str = score.toString();

        expect(str, contains('Reading Recognition'));
        expect(str, contains('correct: 7'));
        expect(str, contains('incorrect: 3'));
        expect(str, contains('70.0%'));
      });
    });
  });
}
