# Exercise System Implementation

## Overview

The Exercise System provides multiple interactive ways to practice flashcards, each testing different language learning skills. Each exercise type maintains independent scoring with +1 for correct answers and +1 for incorrect answers (tracked separately).

## Architecture

### Core Components

#### 1. **ExerciseType** (`shared/domain/models/exercise_type.dart`)
Enum defining all available exercise types:
- ✅ `readingRecognition` - View word and recall meaning
- ✅ `writingTranslation` - Type the translation
- ✅ `multipleChoiceText` - Select correct translation from text options
- ✅ `multipleChoiceIcon` - Select correct icon
- ✅ `reverseTranslation` - Translate from native to target language
- ⏳ `listeningRecognition` - Audio-based (future)
- ⏳ `speakingPronunciation` - Speech recognition (future)
- ⏳ `sentenceFill` - Context-based (future)

#### 2. **ExerciseScore** (`shared/domain/models/exercise_score.dart`)
Tracks performance per exercise type:
```dart
final exerciseScore = card.getExerciseScore(ExerciseType.writingTranslation);
print('Success rate: ${exerciseScore?.successRate}%');
print('Net score: ${exerciseScore?.netScore}'); // correct - incorrect
```

#### 3. **CardModel** (`shared/domain/models/card_model.dart`)
Enhanced with exercise tracking:
```dart
// Update card after exercise
final updatedCard = card.copyWithExerciseResult(
  exerciseType: ExerciseType.multipleChoiceText,
  wasCorrect: true, // +1 to correctCount
);

// Check what exercises are due
final dueExercises = card.dueExerciseTypes;

// Get overall mastery across all exercises
final mastery = card.overallMasteryLevel; // 'New', 'Learning', 'Good', 'Mastered'
```

#### 4. **ExerciseSessionProvider** (`domain/providers/exercise_session_provider.dart`)
Manages exercise practice sessions:
```dart
final provider = context.read<ExerciseSessionProvider>();

// Start session (automatically builds exercise queue)
provider.startSession();

// Current exercise info
final currentCard = provider.currentCard;
final exerciseType = provider.currentExerciseType;
final progress = provider.progress;

// Submit answer
await provider.submitAnswer(isCorrect: true);

// Session stats
print('Accuracy: ${provider.sessionAccuracy}');
print('Correct: ${provider.correctCount}');
print('Incorrect: ${provider.incorrectCount}');
```

### Exercise Widgets

Each exercise type has a dedicated widget in `presentation/widgets/exercises/`:

1. **ReadingRecognitionWidget** - Shows word/icon, user recalls meaning, then self-reports accuracy
2. **WritingTranslationWidget** - Shows word, user types translation, automatic validation
3. **MultipleChoiceTextWidget** - Shows word, user selects from 4 text options
4. **MultipleChoiceIconWidget** - Shows word/translation, user selects correct icon from 4 options
5. **ReverseTranslationWidget** - Shows native language, user types target language word

## Usage

### Starting an Exercise Session

#### From Dashboard/Home Screen:
```dart
ElevatedButton(
  onPressed: () => context.pushExerciseSession(),
  child: const Text('Start Practice'),
)
```

#### With Specific Cards:
```dart
final provider = context.read<ExerciseSessionProvider>();
provider.startSession(cards: specificCards);
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ExerciseSessionScreen()),
);
```

### Navigation

The exercise session screen is automatically routed:
- Path: `/exercise-session`
- Helper: `context.goToExerciseSession()` or `context.pushExerciseSession()`

### Automatic Exercise Selection

The `ExerciseSessionProvider` automatically:
1. Filters cards that are due for review
2. Determines which exercise types are due for each card
3. Builds a mixed queue of exercises
4. Shuffles for variety
5. Skips exercises that can't be performed (e.g., icon exercise without icon)

### Session Flow

1. **Start** → `ExerciseSessionScreen` displayed
2. **Practice** → User completes each exercise
3. **Progress** → Linear progress indicator shows completion
4. **Complete** → `ExerciseCompletionScreen` shows stats
5. **Options** → Restart or return home

## Scoring System

### Individual Exercise Scoring
Each exercise type independently tracks:
- **correctCount**: +1 for each successful answer
- **incorrectCount**: +1 for each failed answer
- **netScore**: `correctCount - incorrectCount`
- **successRate**: `(correctCount / totalAttempts) * 100`
- **masteryLevel**: Based on success rate and attempts

### Overall Card Mastery
The card's `overallMasteryLevel` aggregates performance across all exercise types:
- **New**: < 5 total attempts across all exercises
- **Difficult**: < 50% overall accuracy
- **Learning**: 50-69% accuracy
- **Good**: 70-89% accuracy
- **Mastered**: ≥ 90% accuracy

### Spaced Repetition
Each exercise type has independent review scheduling:
- **Correct answer**: Interval increases based on success rate
- **Incorrect answer**: Review again tomorrow
- Formula: `intervalDays = baseDays * (1 + successMultiplier * 2)`

## Adding New Exercise Types

1. **Add enum value** in `ExerciseType`:
```dart
enum ExerciseType {
  // ...
  @JsonValue('my_new_exercise')
  myNewExercise,
}
```

2. **Update extension methods**:
```dart
bool get isImplemented {
  case ExerciseType.myNewExercise:
    return true; // or false if not ready
}
```

3. **Create widget** in `presentation/widgets/exercises/my_new_exercise_widget.dart`

4. **Add to session screen** in `_getExerciseWidgetForType()`:
```dart
case ExerciseType.myNewExercise:
  return const MyNewExerciseWidget(key: ValueKey('my_new'));
```

5. **Export in barrel file** `card_review.dart`

## Testing

### Unit Testing Exercise Logic
```dart
test('ExerciseScore records correct answer', () {
  final score = ExerciseScore.initial(ExerciseType.writingTranslation);
  final updated = score.recordCorrect();
  
  expect(updated.correctCount, 1);
  expect(updated.incorrectCount, 0);
  expect(updated.netScore, 1);
});
```

### Widget Testing
```dart
testWidgets('WritingTranslationWidget validates input', (tester) async {
  await tester.pumpWidget(/* setup */);
  
  await tester.enterText(find.byType(TextField), 'correct answer');
  await tester.tap(find.text('Check Answer'));
  
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
});
```

## Performance Considerations

- **Exercise Queue**: Built once at session start, not recalculated per exercise
- **Multiple Choice Options**: Generated on-demand, cached until answer submitted
- **Icon Loading**: Uses `IconifyIcon` widget with network caching
- **State Management**: Minimal rebuilds using `Consumer` targeting specific providers

## Future Enhancements

### Phase 2: Audio Integration
- Add audio files/TTS to `CardModel`
- Implement `ListeningRecognitionWidget`
- Implement `SpeakingPronunciationWidget` with speech recognition

### Phase 3: Advanced Exercises
- Add example sentences to `CardModel`
- Implement `SentenceFillWidget`
- Add conjugation exercises for verbs
- Add plural/gender exercises for nouns

### Phase 4: Adaptive Learning
- Adjust exercise difficulty based on performance
- Prioritize weaker exercise types
- Implement SRS algorithms per exercise type
- Add personalized practice recommendations

## Migration Notes

### Existing Cards
- Legacy `reviewCount` and `correctCount` fields remain for backward compatibility
- New exercises automatically initialize with empty `exerciseScores` map
- Old review data doesn't transfer to new exercise system

### Updating Old Code
```dart
// Old approach
card.copyWithReview(wasCorrect: true);

// New approach (preferred)
card.copyWithExerciseResult(
  exerciseType: ExerciseType.readingRecognition,
  wasCorrect: true,
);
```

## Troubleshooting

### Exercise not appearing
- Check `exerciseType.isImplemented` returns `true`
- Verify card meets requirements (e.g., has icon for icon-based exercises)
- Confirm exercise is due: `card.isExerciseDue(type)`

### Session starts but no exercises shown
- Ensure `CardProvider` has cards loaded
- Check that cards are marked as due
- Verify `ExerciseSessionProvider` is registered in `main.dart`

### Scores not saving
- Confirm `CardProvider.updateCard()` is called after `copyWithExerciseResult()`
- Check `CardStorageService` is properly initialized
- Verify JSON serialization includes `exerciseScores` field

## Files Created

### Models
- `lib/shared/domain/models/exercise_type.dart` (8 types, extensions)
- `lib/shared/domain/models/exercise_score.dart` (scoring model + JSON)

### Providers
- `lib/features/card_review/domain/providers/exercise_session_provider.dart`

### Screens
- `lib/features/card_review/presentation/screens/exercise_session_screen.dart`
- `lib/features/card_review/presentation/widgets/exercise_completion_screen.dart`

### Exercise Widgets
- `lib/features/card_review/presentation/widgets/exercises/reading_recognition_widget.dart`
- `lib/features/card_review/presentation/widgets/exercises/writing_translation_widget.dart`
- `lib/features/card_review/presentation/widgets/exercises/multiple_choice_text_widget.dart`
- `lib/features/card_review/presentation/widgets/exercises/multiple_choice_icon_widget.dart`
- `lib/features/card_review/presentation/widgets/exercises/reverse_translation_widget.dart`

### Configuration
- Updated `lib/shared/shared.dart` (exports)
- Updated `lib/features/card_review/card_review.dart` (barrel exports)
- Updated `lib/main.dart` (provider registration)
- Updated `lib/shared/navigation/app_router.dart` (routing)
- Updated `lib/shared/domain/models/card_model.dart` (exercise support)
- Updated `.gitignore` (*.g.dart files)

## Summary

The Exercise System provides a flexible, extensible framework for varied language practice. With 5 implemented exercise types and independent scoring, users can practice different skills and track mastery across multiple dimensions. The architecture supports easy addition of new exercise types and integrates seamlessly with the existing spaced repetition system.
