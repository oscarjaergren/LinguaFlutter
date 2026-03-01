# LinguaFlutter - Design Document

## Table of Contents
1. [Project Overview](#project-overview)
2. [Vertical Slice Architecture](#vertical-slice-architecture)
3. [Feature-Based Organization](#feature-based-organization)
4. [Architectural Principles](#architectural-principles)
5. [Current Features](#current-features)
6. [Shared Services](#shared-services)
7. [Development Guidelines](#development-guidelines)
8. [Testing Strategy](#testing-strategy)
9. [Performance Considerations](#performance-considerations)
10. [Exercise System](#exercise-system)

## Project Overview

LinguaFlutter is a modern Flutter-based language learning application focused on spaced repetition card review. The app emphasizes clean architecture, maintainable code, and excellent user experience through book-like interactions and smooth animations.

### Core Goals
- **Learning Effectiveness**: Implement proven spaced repetition algorithms
- **User Experience**: Create immersive, book-like card review experience
- **Code Quality**: Maintain clean, testable, and scalable architecture
- **Performance**: Ensure smooth 60fps animations and responsive UI

## Vertical Slice Architecture

### What is Vertical Slice Architecture?

Vertical Slice Architecture organizes code by **features** rather than technical layers. Each feature contains all the code needed to implement a complete user scenario, from UI to data persistence.

### Benefits in LinguaFlutter

1. **Feature Isolation**: Each feature is self-contained and can be developed independently
2. **Reduced Coupling**: Features communicate through well-defined interfaces
3. **Team Scalability**: Different developers can work on different features without conflicts
4. **Easier Testing**: Each slice can be tested in isolation
5. **Faster Development**: Changes are localized to specific features

### Implementation Strategy

```
lib/
├── features/           # Vertical slices - each feature is complete
│   ├── card_management/
│   ├── card_review/
│   ├── streak/
│   └── mascot/
├── shared/            # Horizontal concerns shared across features
│   ├── domain/
│   ├── services/
│   └── widgets/
└── main.dart
```

## Feature-Based Organization

### Feature Structure

Each feature follows a consistent internal structure:

```
features/[feature_name]/
├── domain/           # Business logic, providers, models
│   ├── providers/
│   └── models/
├── data/            # Data access, repositories, services
│   ├── repositories/
│   └── services/
├── presentation/    # UI components, screens, widgets
│   ├── screens/
│   └── widgets/
├── design/         # Feature-specific design documents
└── test/          # Co-located tests
```

### Feature Communication

Features communicate through:
- **Shared Services**: Common functionality in `lib/shared/services/`
- **Provider Dependencies**: Injected through constructor parameters
- **Event System**: For loose coupling between features
- **Navigation**: Centralized routing configuration

## Architectural Principles

### 1. Dependency Injection
- Use constructor injection for testability
- Avoid service locators and global state
- Example: `AnimationService` injection in `MascotWidget`

### 2. Single Responsibility
- Each class has one reason to change
- Features handle one specific user capability
- Services handle one specific technical concern

### 3. Interface Segregation
- Abstract classes define contracts
- Multiple small interfaces over large ones
- Example: `AnimationService` with production/test implementations

### 4. Separation of Concerns
- **Domain**: Business rules and logic
- **Data**: External data access and persistence
- **Presentation**: UI and user interaction

### 5. Testability First
- All dependencies are injectable
- Business logic is separated from UI
- Test doubles can replace any dependency

## Current Features

### Core Features

#### 1. Card Management (`lib/features/card_management/`)
- **Purpose**: Create, edit, and organize flashcards
- **Key Components**: 
  - `SimpleCardCreationScreen`
  - `CardProvider` (manages card CRUD operations)
- **Dependencies**: `CardStorageService`, `IconifyService`

#### 2. Card Review (`lib/features/card_review/`)
- **Purpose**: Continuous spaced repetition practice (no explicit sessions)
- **Key Components**:
  - `PracticeScreen` with swipe-based interactions
  - Exercise widgets (multiple choice, reading, listening, etc.)
- **Dependencies**: `CardProvider`, `StreakProvider`

#### 3. Streak Management (`lib/features/streak/`)
- **Purpose**: Track learning consistency and motivation
- **Key Components**:
  - `StreakProvider` (manages daily streaks)
  - Streak calculation and persistence
- **Dependencies**: `PreferencesService`

#### 4. Mascot System (`lib/features/mascot/`)
- **Purpose**: Animated mascot for user engagement
- **Key Components**:
  - `MascotWidget` with proper animation service injection
  - `MascotProvider` (manages mascot state)
- **Dependencies**: `AnimationService`

### Supporting Features

#### 5. Debug Tools (`lib/features/debug/`)
- **Purpose**: Development and testing utilities
- **Key Components**: `DebugMenuScreen`
- **Dependencies**: Various providers for testing

#### 6. Icon Search (`lib/features/icon_search/`)
- **Purpose**: Icon selection for cards
- **Key Components**: `IconGridItem`, search functionality
- **Dependencies**: `IconifyService`

#### 7. Theme Management (`lib/features/theme/`)
- **Purpose**: App theming and visual customization
- **Key Components**: `ThemeProvider`
- **Dependencies**: `PreferencesService`

#### 8. Language Support (`lib/features/language/`)
- **Purpose**: Internationalization and localization
- **Key Components**: `LanguageProvider`
- **Dependencies**: `PreferencesService`

## Shared Services

### Service Layer (`lib/shared/services/`)

#### 1. AnimationService
```dart
abstract class AnimationService {
  bool get shouldAnimate;
}

class ProductionAnimationService implements AnimationService {
  bool get shouldAnimate => true;
}

class TestAnimationService implements AnimationService {
  bool get shouldAnimate => false;
}
```

#### 2. CardStorageService
- Handles card persistence
- Provides CRUD operations for cards
- Manages data consistency

#### 3. PreferencesService
- User settings and preferences
- App configuration persistence
- Cross-feature settings access

#### 4. IconifyService
- Icon search and retrieval
- External icon API integration
- Caching and performance optimization

### Domain Layer (`lib/shared/domain/`)

#### CardProvider
- Central card management
- Business logic for card operations
- State management for UI components

## Development Guidelines

### Adding New Features

1. **Create Feature Directory Structure**
   ```bash
   mkdir -p lib/features/new_feature/{domain,data,presentation}/{providers,services,screens,widgets}
   ```

2. **Define Feature Interface**
   - Create abstract classes for external dependencies
   - Define data models and business entities
   - Establish provider contracts

3. **Implement Vertical Slice**
   - Build complete user scenario from UI to data
   - Minimize dependencies on other features
   - Use shared services for common functionality

4. **Add Tests**
   - Co-locate tests with feature code
   - Test business logic independently of UI
   - Use dependency injection for test doubles

5. **Update Barrel Files**
   - Export public APIs through feature barrel files
   - Update shared barrel file if adding shared services

### Code Quality Standards

#### File Organization
- Use descriptive file names
- Group related functionality
- Maintain consistent naming conventions

#### Import Management
- Use barrel files for clean imports
- Avoid circular dependencies
- Import only what you need

#### State Management
- Use Provider pattern consistently
- Minimize widget rebuilds
- Separate business logic from UI state

### Performance Guidelines

#### Animation Performance
- Use `RepaintBoundary` for complex widgets
- Implement proper animation disposal
- Prefer `Transform` over layout changes
- Target 60fps for all animations

#### Memory Management
- Dispose controllers and streams
- Use `const` constructors where possible
- Implement proper lifecycle management

## Testing Strategy

### Unit Testing
- Test business logic in isolation
- Mock external dependencies
- Focus on edge cases and error handling

### Widget Testing
- Test UI components independently
- Use `TestAnimationService` for consistent test behavior
- Verify user interactions and state changes

### Integration Testing
- Test feature workflows end-to-end
- Verify feature integration points
- Test with realistic data scenarios

### Test Organization
```
lib/features/card_management/
├── test/
│   ├── domain/
│   │   └── providers/
│   ├── data/
│   │   └── services/
│   └── presentation/
│       ├── screens/
│       └── widgets/
```

## Performance Considerations

### Animation Performance
- Use hardware acceleration where possible
- Implement animation preloading for smooth transitions
- Optimize complex visual effects
- Monitor frame rates during development

### Memory Optimization
- Implement proper widget disposal
- Use object pooling for frequently created objects
- Monitor memory usage during card review sessions
- Optimize image and asset loading

### Startup Performance
- Lazy load non-critical features
- Optimize initial route loading
- Minimize synchronous operations on startup

### Data Performance
- Implement efficient card querying
- Use pagination for large card sets
- Cache frequently accessed data
- Optimize database queries

## Exercise System

### Overview

The exercise system allows cards to be practiced in multiple ways, each testing different language skills. Each exercise type maintains independent scoring to track mastery across different practice modes.

### Exercise Types

#### Implemented Exercises

1. **Reading Recognition** (`ExerciseType.readingRecognition`)
   - View the word and recall its meaning
   - Tests: Recognition, visual memory
   - Benefits from having an icon
   - Icon: `mdi:book-open-page-variant`

2. **Writing Translation** (`ExerciseType.writingTranslation`)
   - Type the correct translation of the word
   - Tests: Spelling, active recall, writing skills
   - Icon: `mdi:pencil`

3. **Multiple Choice (Text)** (`ExerciseType.multipleChoiceText`)
   - Select the correct translation from text options
   - Tests: Recognition, comprehension
   - Icon: `mdi:format-list-checks`

4. **Multiple Choice (Icon)** (`ExerciseType.multipleChoiceIcon`)
   - Select the correct icon that represents the word
   - Tests: Visual association, meaning comprehension
   - Requires the card to have an icon
   - Icon: `mdi:image-multiple`

5. **Reverse Translation** (`ExerciseType.reverseTranslation`)
   - Translate from native language to target language
   - Tests: Active production, harder recall
   - Icon: `mdi:swap-horizontal`

#### Future Exercise Types

1. **Listening Recognition** (`ExerciseType.listeningRecognition`)
   - Listen to audio and identify the correct word
   - Tests: Listening comprehension, pronunciation recognition
   - Requires audio integration
   - Icon: `mdi:ear-hearing`

2. **Speaking Pronunciation** (`ExerciseType.speakingPronunciation`)
   - Speak the word and receive pronunciation feedback
   - Tests: Speaking skills, pronunciation accuracy
   - Requires speech recognition
   - Icon: `mdi:microphone`

3. **Sentence Fill** (`ExerciseType.sentenceFill`)
   - Fill in the blank in a sentence with the correct word
   - Tests: Context usage, grammar
   - Requires sentence examples
   - Icon: `mdi:text-box`

### Exercise Scoring

#### ExerciseScore Model

Each `ExerciseScore` tracks:
- **correctCount**: Number of successful attempts (+1 per success)
- **incorrectCount**: Number of failed attempts (+1 per failure)
- **lastPracticed**: Timestamp of last practice
- **nextReview**: Scheduled review date (spaced repetition)
- **successRate**: Percentage of correct answers
- **masteryLevel**: 'New', 'Learning', 'Good', 'Mastered', or 'Difficult'
- **netScore**: `correctCount - incorrectCount`

#### Spaced Repetition

Each exercise type uses independent spaced repetition:
- **Correct answer**: Review interval increases based on success rate
- **Incorrect answer**: Review again tomorrow
- Formula: `intervalDays = baseDays * (1 + multiplier * 2)`

#### CardModel Integration

The `CardModel` now includes:
```dart
final Map<ExerciseType, ExerciseScore> exerciseScores;
```

New methods:
- `getExerciseScore(ExerciseType)`: Get score for specific exercise
- `overallMasteryLevel`: Aggregate mastery across all exercises
- `isExerciseDue(ExerciseType)`: Check if exercise needs review
- `dueExerciseTypes`: List of exercises due for review
- `copyWithExerciseResult()`: Update card with exercise result

### Exercise Selection Strategy

When starting a practice session:
1. Filter cards by due date
2. For each card, get `dueExerciseTypes`
3. Select exercise types that:
   - Are implemented
   - Are due for review
   - Have requirements met (e.g., icon for icon-based exercises)
4. Prioritize exercises with lower mastery levels

### Usage Example

```dart
// Recording an exercise result
final card = CardModel.create(...);
final updatedCard = card.copyWithExerciseResult(
  exerciseType: ExerciseType.writingTranslation,
  wasCorrect: true,
);

// Checking due exercises
final dueExercises = card.dueExerciseTypes;
if (card.isExerciseDue(ExerciseType.readingRecognition)) {
  // Practice this exercise
}

// Getting specific exercise performance
final score = card.getExerciseScore(ExerciseType.multipleChoiceText);
print('Success rate: ${score?.successRate}%');
```

### Implementation Roadmap

#### Phase 1: Core Exercises (Current)
- ✅ Reading Recognition
- ✅ Writing Translation
- ✅ Multiple Choice (Text)
- ✅ Multiple Choice (Icon)
- ✅ Reverse Translation

#### Phase 2: Audio Integration
- ⏳ Listening Recognition (requires audio files/TTS)
- ⏳ Speaking Pronunciation (requires speech recognition)

#### Phase 3: Advanced Exercises
- ⏳ Sentence Fill (requires example sentences)

## Future Considerations

### Scalability
- Plan for additional learning modes
- Consider multi-language support expansion
- Prepare for cloud synchronization
- Design for offline-first functionality

### Maintainability
- Continue refining feature boundaries
- Improve automated testing coverage
- Enhance development tooling
- Document architectural decisions

### User Experience Enhancements
- **Dashboard Statistics Integration**: Add comprehensive practice stats to the main dashboard
  - Daily/weekly/monthly progress tracking
  - Streak information and achievements
  - Cards learned vs practiced metrics
  - Progress charts and learning trends
  - Performance analytics by exercise type

---

*This document should be updated as the architecture evolves and new patterns emerge.*
