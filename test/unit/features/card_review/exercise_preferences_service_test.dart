import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_flutter/features/card_review/data/services/exercise_preferences_service.dart';
import 'package:lingua_flutter/features/card_review/domain/models/exercise_preferences.dart';
import 'package:lingua_flutter/shared/domain/models/exercise_type.dart';

void main() {
  group('ExercisePreferencesService', () {
    late ExercisePreferencesService service;

    setUp(() {
      service = ExercisePreferencesService();
      SharedPreferences.setMockInitialValues({});
    });

    test('loadPreferences returns defaults when no data stored', () async {
      final prefs = await service.loadPreferences();
      
      final defaults = ExercisePreferences.defaults();
      expect(prefs.enabledTypes.length, defaults.enabledTypes.length);
      expect(prefs.prioritizeWeaknesses, defaults.prioritizeWeaknesses);
      expect(prefs.weaknessThreshold, defaults.weaknessThreshold);
    });

    test('savePreferences stores data correctly', () async {
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition, ExerciseType.writingTranslation},
        prioritizeWeaknesses: false,
        weaknessThreshold: 80.0,
      );
      
      await service.savePreferences(prefs);
      
      final loaded = await service.loadPreferences();
      expect(loaded.enabledTypes.length, 2);
      expect(loaded.isEnabled(ExerciseType.readingRecognition), true);
      expect(loaded.isEnabled(ExerciseType.writingTranslation), true);
      expect(loaded.prioritizeWeaknesses, false);
      expect(loaded.weaknessThreshold, 80.0);
    });

    test('loadPreferences handles corrupted data gracefully', () async {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('exercise_preferences', 'invalid json');
      
      final prefs = await service.loadPreferences();
      
      // Should return defaults on error
      final defaults = ExercisePreferences.defaults();
      expect(prefs.enabledTypes.length, defaults.enabledTypes.length);
    });

    test('resetToDefaults restores default preferences', () async {
      // Save custom preferences
      final custom = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition},
        prioritizeWeaknesses: false,
        weaknessThreshold: 50.0,
      );
      await service.savePreferences(custom);
      
      // Reset to defaults
      final defaults = await service.resetToDefaults();
      
      expect(defaults.enabledTypes.length, greaterThan(1));
      expect(defaults.prioritizeWeaknesses, true);
      expect(defaults.weaknessThreshold, 70.0);
      
      // Verify it was saved
      final loaded = await service.loadPreferences();
      expect(loaded.enabledTypes.length, defaults.enabledTypes.length);
    });

    test('clearPreferences removes stored data', () async {
      // Save preferences
      final prefs = ExercisePreferences(
        enabledTypes: {ExerciseType.readingRecognition},
      );
      await service.savePreferences(prefs);
      
      // Clear
      await service.clearPreferences();
      
      // Should return defaults after clear
      final loaded = await service.loadPreferences();
      final defaults = ExercisePreferences.defaults();
      expect(loaded.enabledTypes.length, defaults.enabledTypes.length);
    });

    test('multiple save/load cycles preserve data', () async {
      for (var i = 0; i < 3; i++) {
        final prefs = ExercisePreferences(
          enabledTypes: {ExerciseType.values[i]},
          weaknessThreshold: 60.0 + i * 10,
        );
        
        await service.savePreferences(prefs);
        final loaded = await service.loadPreferences();
        
        expect(loaded.enabledTypes.length, 1);
        expect(loaded.weaknessThreshold, 60.0 + i * 10);
      }
    });
  });
}
