import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

void main() {
  group('ExerciseType', () {
    test('should have all expected values', () {
      expect(ExerciseType.values.length, 8);
      expect(ExerciseType.values, contains(ExerciseType.readingRecognition));
      expect(ExerciseType.values, contains(ExerciseType.writingTranslation));
      expect(ExerciseType.values, contains(ExerciseType.multipleChoiceText));
      expect(ExerciseType.values, contains(ExerciseType.multipleChoiceIcon));
      expect(ExerciseType.values, contains(ExerciseType.reverseTranslation));
      expect(ExerciseType.values, contains(ExerciseType.listeningRecognition));
      expect(ExerciseType.values, contains(ExerciseType.speakingPronunciation));
      expect(ExerciseType.values, contains(ExerciseType.sentenceFill));
    });
  });

  group('ExerciseTypeExtension', () {
    group('displayName', () {
      test('should return correct display names', () {
        expect(ExerciseType.readingRecognition.displayName, 'Reading Recognition');
        expect(ExerciseType.writingTranslation.displayName, 'Writing Translation');
        expect(ExerciseType.multipleChoiceText.displayName, 'Multiple Choice (Text)');
        expect(ExerciseType.multipleChoiceIcon.displayName, 'Multiple Choice (Icon)');
        expect(ExerciseType.reverseTranslation.displayName, 'Reverse Translation');
        expect(ExerciseType.listeningRecognition.displayName, 'Listening Recognition');
        expect(ExerciseType.speakingPronunciation.displayName, 'Speaking Pronunciation');
        expect(ExerciseType.sentenceFill.displayName, 'Sentence Fill');
      });

      test('should return non-empty display names for all types', () {
        for (final type in ExerciseType.values) {
          expect(type.displayName, isNotEmpty);
        }
      });
    });

    group('description', () {
      test('should return correct descriptions', () {
        expect(
          ExerciseType.readingRecognition.description,
          'See the word and recall its meaning',
        );
        expect(
          ExerciseType.writingTranslation.description,
          'Type the correct translation',
        );
        expect(
          ExerciseType.multipleChoiceText.description,
          'Choose the correct meaning from options',
        );
        expect(
          ExerciseType.multipleChoiceIcon.description,
          'Choose the matching icon',
        );
        expect(
          ExerciseType.reverseTranslation.description,
          'Translate from your native language',
        );
      });

      test('should return non-empty descriptions for all types', () {
        for (final type in ExerciseType.values) {
          expect(type.description, isNotEmpty);
        }
      });
    });

    group('isImplemented', () {
      test('should return true for implemented types', () {
        expect(ExerciseType.readingRecognition.isImplemented, true);
        expect(ExerciseType.writingTranslation.isImplemented, true);
        expect(ExerciseType.multipleChoiceText.isImplemented, true);
        expect(ExerciseType.multipleChoiceIcon.isImplemented, true);
        expect(ExerciseType.reverseTranslation.isImplemented, true);
      });

      test('should return false for unimplemented types', () {
        expect(ExerciseType.listeningRecognition.isImplemented, false);
        expect(ExerciseType.speakingPronunciation.isImplemented, false);
        expect(ExerciseType.sentenceFill.isImplemented, false);
      });

      test('should have exactly 5 implemented types', () {
        final implementedCount = ExerciseType.values.where((t) => t.isImplemented).length;
        expect(implementedCount, 5);
      });
    });

    group('requiresIcon', () {
      test('should return true only for multipleChoiceIcon', () {
        expect(ExerciseType.multipleChoiceIcon.requiresIcon, true);

        for (final type in ExerciseType.values) {
          if (type != ExerciseType.multipleChoiceIcon) {
            expect(type.requiresIcon, false, reason: '${type.name} should not require icon');
          }
        }
      });
    });

    group('benefitsFromIcon', () {
      test('should return true only for readingRecognition', () {
        expect(ExerciseType.readingRecognition.benefitsFromIcon, true);

        for (final type in ExerciseType.values) {
          if (type != ExerciseType.readingRecognition) {
            expect(type.benefitsFromIcon, false, reason: '${type.name} should not benefit from icon');
          }
        }
      });
    });

    group('iconName', () {
      test('should return valid iconify icon names', () {
        expect(ExerciseType.readingRecognition.iconName, 'mdi:book-open-page-variant');
        expect(ExerciseType.writingTranslation.iconName, 'mdi:pencil');
        expect(ExerciseType.multipleChoiceText.iconName, 'mdi:format-list-checks');
        expect(ExerciseType.multipleChoiceIcon.iconName, 'mdi:image-multiple');
        expect(ExerciseType.reverseTranslation.iconName, 'mdi:swap-horizontal');
        expect(ExerciseType.listeningRecognition.iconName, 'mdi:ear-hearing');
        expect(ExerciseType.speakingPronunciation.iconName, 'mdi:microphone');
        expect(ExerciseType.sentenceFill.iconName, 'mdi:text-box');
      });

      test('should return non-empty icon names for all types', () {
        for (final type in ExerciseType.values) {
          expect(type.iconName, isNotEmpty);
          expect(type.iconName, startsWith('mdi:'));
        }
      });
    });

    group('icon', () {
      test('should return valid IconData for all types', () {
        expect(ExerciseType.readingRecognition.icon, Icons.menu_book);
        expect(ExerciseType.writingTranslation.icon, Icons.edit);
        expect(ExerciseType.multipleChoiceText.icon, Icons.checklist);
        expect(ExerciseType.multipleChoiceIcon.icon, Icons.image);
        expect(ExerciseType.reverseTranslation.icon, Icons.swap_horiz);
        expect(ExerciseType.listeningRecognition.icon, Icons.hearing);
        expect(ExerciseType.speakingPronunciation.icon, Icons.mic);
        expect(ExerciseType.sentenceFill.icon, Icons.short_text);
      });

      test('should return IconData for all types', () {
        for (final type in ExerciseType.values) {
          expect(type.icon, isA<IconData>());
        }
      });
    });
  });
}
