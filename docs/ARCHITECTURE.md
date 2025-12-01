# LinguaFlutter Architecture

> **Feature-Organized Clean Architecture with a Core Domain**

## What This Is (And Isn't)

This project uses **Feature-Organized Clean Architecture**, not Vertical Slice Architecture (VSA).

**The key difference:** In true VSA, each feature is completely independent with its own models. We have a **shared core domain** (`CardModel`) that the entire app is built around. This is intentional - cards ARE the core domain concept.

### Why Not True VSA?

- `CardModel` is the central entity - everything revolves around cards
- Duplicating card models per feature would add complexity with no benefit
- The app is small enough that feature independence isn't critical
- We prioritize clarity over architectural purity

---

## Project Structure

```
lib/
├── core/                          # Core domain & infrastructure
│   ├── domain/
│   │   └── models/                # Core domain entities
│   │       ├── card_model.dart    # THE central domain entity
│   │       ├── exercise_type.dart
│   │       └── icon_model.dart
│   ├── services/                  # Technical infrastructure
│   │   ├── card_storage_service.dart
│   │   ├── tts_service.dart
│   │   └── ...
│   ├── widgets/                   # Generic UI components
│   └── navigation/                # App routing
│
├── features/                      # Feature modules
│   ├── card_management/           # Card CRUD, filtering, search
│   ├── card_review/               # Review sessions, spaced repetition
│   ├── duplicate_detection/       # Duplicate card detection
│   ├── dashboard/                 # Stats and overview
│   ├── language/                  # Language selection
│   └── ...
│
└── main.dart                      # Composition root
```

> **Note:** Currently named `shared/` but conceptually this is `core/`.

---

## The Rules

### 1. Core domain models live in `core/`

`CardModel`, `ExerciseType`, `IconModel` - these are the foundational entities.

```dart
// core/domain/models/card_model.dart
class CardModel {
  // Business logic lives IN the model
  bool get isDue => nextReview == null || nextReview!.isBefore(DateTime.now());
  
  CardModel processAnswer(CardAnswer answer) {
    // Spaced repetition algorithm here
  }
}
```

### 2. Features CAN depend on `core/`

This is expected and fine:

```dart
// features/card_review/domain/providers/review_session_provider.dart
import '../../../../core/domain/models/card_model.dart'; // ✅ OK
```

### 3. Features should NOT depend on each other

This is where we need discipline:

```dart
// ❌ BAD: Feature importing another feature
import '../../../card_management/domain/providers/card_management_provider.dart';

// ✅ BETTER: Depend on core, receive data via injection
class ReviewSessionProvider {
  final List<CardModel> Function() getReviewCards;
  ReviewSessionProvider({required this.getReviewCards});
}
```

**Current state:** We have some feature-to-feature dependencies. This is a known trade-off for simplicity.

### 4. Feature-specific models stay in features

Models only used by one feature belong to that feature:

```dart
// features/duplicate_detection/domain/models/duplicate_match.dart
// ✅ Correctly placed - only duplicate_detection uses this
class DuplicateMatch {
  final CardModel card;
  final CardModel duplicate;
  final double similarity;
}
```

### 5. Infrastructure is shared by default

Storage, HTTP, logging, navigation - these are technical concerns in `core/services/`.

### 6. Coordination happens at the composition root

`main.dart` wires everything together:

```dart
// main.dart - the composition root
final cardManagement = CardManagementProvider(...);
final reviewSession = ReviewSessionProvider(
  cardManagement: cardManagement,  // Wired here, not imported in feature
);
```

---

## Feature Structure

Each feature follows this internal structure:

```
features/[feature_name]/
├── data/
│   ├── repositories/      # Data access implementations
│   └── services/          # Feature-specific services
├── domain/
│   ├── models/            # Feature-specific models (if any)
│   └── providers/         # State management (ChangeNotifiers)
├── presentation/
│   ├── screens/           # Full-page widgets
│   ├── widgets/           # Feature UI components
│   └── view_models/       # UI logic (MVVM)
├── test/                  # Feature tests
└── [feature_name].dart    # Barrel export
```

---

## Dependency Graph

```
                    ┌─────────────────────────────────────┐
                    │              core/                  │
                    │  - CardModel (central entity)       │
                    │  - CardStorageService               │
                    │  - Navigation, Widgets              │
                    └─────────────────────────────────────┘
                                    ▲
                                    │ (allowed)
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│card_management│         │  card_review  │         │   dashboard   │
└───────────────┘         └───────────────┘         └───────────────┘
        │                           │
        │     (currently exists,    │
        └─────── should minimize) ──┘
```

**Goal:** Features depend on `core/`, not on each other.

---

## When to Share vs. Duplicate

| Scenario | Action |
|----------|--------|
| Core domain entity (CardModel) | Share in `core/` |
| Technical infrastructure | Share in `core/services/` |
| Feature-specific model | Keep in feature |
| Similar-looking DTOs | Duplicate - they'll diverge |
| Business logic | Push into domain models |

### The Rule of Three

- 1 occurrence: Just write it
- 2 occurrences: Consider if they'll diverge
- 3+ occurrences with identical, stable logic: Extract to `core/`

---

## Anti-Patterns

### ❌ The "Utils" Junk Drawer

```dart
// ❌ Bad
lib/utils/
  ├── helpers.dart      # Vague
  └── common.dart       # Everything ends up here
```

### ❌ Premature Abstraction

```dart
// ❌ Bad: Created after seeing 2 similar classes
abstract class BaseProvider<T> { ... }
```

### ❌ Renaming for the Sake of It

```dart
// ❌ Bad: Caused 90 files to change
// Old: CardProvider
// New: CardManagementProvider
// Should have: Updated CardProvider in place
```

**Lesson learned:** When refactoring, prefer modifying existing classes over renaming. Renaming causes unnecessary churn.

---

## Lessons Learned

### What We Did Right

1. **Separated responsibilities** - CardManagementProvider (CRUD), ReviewSessionProvider (sessions), DuplicateDetectionProvider (detection)
2. **Feature-specific models** - DuplicateMatch stays in duplicate_detection
3. **Business logic in models** - CardModel.processAnswer(), CardModel.isDue

### What We Could Improve

1. **Reduce feature-to-feature imports** - card_review imports card_management
2. **Rename `shared/` to `core/`** - Better reflects its purpose
3. **Avoid unnecessary renames** - Modify in place when possible

### The 90-File Change

We renamed `CardProvider` → `CardManagementProvider`, causing ~90 files to change. 

**What we should have done:** Keep `CardProvider` as a facade, have it delegate to new providers internally. Changes would have been ~10 files.

**Lesson:** Backward compatibility matters. Facades are your friend.

---

## Summary

| Aspect | Our Approach |
|--------|--------------|
| Architecture | Feature-Organized Clean Architecture |
| Core Domain | Shared `CardModel` in `core/` |
| Features | Organized by capability, can depend on `core/` |
| Feature Independence | Partial - some cross-feature dependencies exist |
| Trade-off | Simplicity over purity |

This isn't textbook VSA, and that's OK. It's a pragmatic architecture that fits the app's needs.
