import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

void main() {
  group('ExercisePreferences', () {
    test('defaults() creates preferences with all implemented types enabled', () {
      final prefs = ExercisePreferences.defaults();
      
      final implementedTypes = ExerciseType.values.where((t) => t.isImplemented).toList();
      
      expect(prefs.enabledTypes.length, implementedTypes.length);
      for (final type in implementedTypes) {
        expect(prefs.isEnabled(type), true);
      }
      expect(prefs.prioritizeWeaknesses, true);
      expect(prefs.weaknessThreshold, 70.0);
    });

    test('isEnabled returns correct status', () {
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition, ExerciseType.writingTranslation},
      );
      
      expect(prefs.isEnabled(ExerciseType.readingRecognition), true);
      expect(prefs.isEnabled(ExerciseType.writingTranslation), true);
      expect(prefs.isEnabled(ExerciseType.multipleChoiceText), false);
    });

    test('toggleType adds and removes types correctly', () {
      var prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition},
      );
      
      // Add a type
      prefs = prefs.toggleType(ExerciseType.writingTranslation);
      expect(prefs.isEnabled(ExerciseType.writingTranslation), true);
      expect(prefs.enabledTypes.length, 2);
      
      // Remove a type
      prefs = prefs.toggleType(ExerciseType.readingRecognition);
      expect(prefs.isEnabled(ExerciseType.readingRecognition), false);
      expect(prefs.enabledTypes.length, 1);
    });

    test('toggleCategory enables/disables all types in category', () {
      var prefs = ExercisePreferences.defaults();
      
      // Disable recognition category
      prefs = prefs.toggleCategory(ExerciseCategory.recognition, enabled: false);
      
      for (final type in ExerciseCategory.recognition.exerciseTypes) {
        expect(prefs.isEnabled(type), false);
      }
      
      // Production types should still be enabled
      for (final type in ExerciseCategory.production.exerciseTypes) {
        expect(prefs.isEnabled(type), true);
      }
      
      // Re-enable recognition category
      prefs = prefs.toggleCategory(ExerciseCategory.recognition, enabled: true);
      
      for (final type in ExerciseCategory.recognition.exerciseTypes) {
        expect(prefs.isEnabled(type), true);
      }
    });

    test('isCategoryFullyEnabled returns correct status', () {
      final prefs = ExercisePreferences(
        enabledTypes: ExerciseCategory.recognition.exerciseTypes.toSet(),
      );
      
      expect(prefs.isCategoryFullyEnabled(ExerciseCategory.recognition), true);
      expect(prefs.isCategoryFullyEnabled(ExerciseCategory.production), false);
    });

    test('isCategoryPartiallyEnabled returns correct status', () {
      final recognitionTypes = ExerciseCategory.recognition.exerciseTypes;
      final prefs = ExercisePreferences(
        enabledTypes: {recognitionTypes.first},
      );
      
      expect(prefs.isCategoryPartiallyEnabled(ExerciseCategory.recognition), true);
      expect(prefs.isCategoryPartiallyEnabled(ExerciseCategory.production), false);
    });

    test('enableAll enables all implemented types', () {
      var prefs = ExercisePreferences(enabledTypes: {});
      
      prefs = prefs.enableAll();
      
      final implementedTypes = ExerciseType.values.where((t) => t.isImplemented);
      expect(prefs.enabledTypes.length, implementedTypes.length);
      for (final type in implementedTypes) {
        expect(prefs.isEnabled(type), true);
      }
    });

    test('disableAll removes all types', () {
      var prefs = ExercisePreferences.defaults();
      
      prefs = prefs.disableAll();
      
      expect(prefs.enabledTypes.isEmpty, true);
      expect(prefs.hasAnyEnabled, false);
    });

    test('toJson and fromJson preserve data', () {
      final original = ExercisePreferences(
        enabledTypes: {
          ExerciseType.readingRecognition,
          ExerciseType.writingTranslation,
          ExerciseType.sentenceBuilding,
        },
        prioritizeWeaknesses: false,
        weaknessThreshold: 80.0,
      );
      
      final json = original.toJson();
      final restored = ExercisePreferences.fromJson(json);
      
      expect(restored.enabledTypes.length, original.enabledTypes.length);
      expect(restored.isEnabled(ExerciseType.readingRecognition), true);
      expect(restored.isEnabled(ExerciseType.writingTranslation), true);
      expect(restored.isEnabled(ExerciseType.sentenceBuilding), true);
      expect(restored.prioritizeWeaknesses, false);
      expect(restored.weaknessThreshold, 80.0);
    });

    test('fromJson handles unknown exercise types gracefully', () {
      final json = {
        'enabledTypes': ['readingRecognition', 'unknownType', 'writingTranslation'],
        'prioritizeWeaknesses': true,
        'weaknessThreshold': 70.0,
      };
      
      final prefs = ExercisePreferences.fromJson(json);
      
      expect(prefs.enabledTypes.length, 2); // Only known types
      expect(prefs.isEnabled(ExerciseType.readingRecognition), true);
      expect(prefs.isEnabled(ExerciseType.writingTranslation), true);
    });

    test('equality works correctly', () {
      final prefs1 = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition, ExerciseType.writingTranslation},
        prioritizeWeaknesses: true,
        weaknessThreshold: 70.0,
      );
      
      final prefs2 = ExercisePreferences(
        enabledTypes: {ExerciseType.writingTranslation, ExerciseType.readingRecognition},
        prioritizeWeaknesses: true,
        weaknessThreshold: 70.0,
      );
      
      final prefs3 = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition},
        prioritizeWeaknesses: true,
        weaknessThreshold: 70.0,
      );
      
      expect(prefs1, equals(prefs2)); // Order doesn't matter
      expect(prefs1, isNot(equals(prefs3))); // Different types
    });
  });

  group('ExerciseCategory', () {
    test('exerciseTypes returns correct types for recognition', () {
      final types = ExerciseCategory.recognition.exerciseTypes;
      
      expect(types.contains(ExerciseType.readingRecognition), true);
      expect(types.contains(ExerciseType.multipleChoiceText), true);
      expect(types.contains(ExerciseType.multipleChoiceIcon), true);
      expect(types.contains(ExerciseType.articleSelection), true);
      expect(types.contains(ExerciseType.writingTranslation), false);
    });

    test('exerciseTypes returns correct types for production', () {
      final types = ExerciseCategory.production.exerciseTypes;
      
      expect(types.contains(ExerciseType.writingTranslation), true);
      expect(types.contains(ExerciseType.reverseTranslation), true);
      expect(types.contains(ExerciseType.sentenceBuilding), true);
      expect(types.contains(ExerciseType.conjugationPractice), true);
      expect(types.contains(ExerciseType.readingRecognition), false);
    });

    test('displayName returns correct names', () {
      expect(ExerciseCategory.recognition.displayName, 'Recognition');
      expect(ExerciseCategory.production.displayName, 'Production');
    });
  });

  group('ExerciseTypeGrouping', () {
    test('category returns correct category for each type', () {
      expect(ExerciseType.readingRecognition.category, ExerciseCategory.recognition);
      expect(ExerciseType.multipleChoiceText.category, ExerciseCategory.recognition);
      expect(ExerciseType.articleSelection.category, ExerciseCategory.recognition);
      
      expect(ExerciseType.writingTranslation.category, ExerciseCategory.production);
      expect(ExerciseType.sentenceBuilding.category, ExerciseCategory.production);
      expect(ExerciseType.conjugationPractice.category, ExerciseCategory.production);
    });

    test('isRecognition returns correct value', () {
      expect(ExerciseType.readingRecognition.isRecognition, true);
      expect(ExerciseType.multipleChoiceText.isRecognition, true);
      expect(ExerciseType.writingTranslation.isRecognition, false);
      expect(ExerciseType.sentenceBuilding.isRecognition, false);
    });

    test('isProduction returns correct value', () {
      expect(ExerciseType.writingTranslation.isProduction, true);
      expect(ExerciseType.sentenceBuilding.isProduction, true);
      expect(ExerciseType.readingRecognition.isProduction, false);
      expect(ExerciseType.multipleChoiceText.isProduction, false);
    });
  });
}
