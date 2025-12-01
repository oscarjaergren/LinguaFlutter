# Vertical Slice Architecture (VSA) Guidelines

> **Project-specific guidelines for implementing Vertical Slice Architecture in LinguaFlutter**

## Overview

Vertical Slice Architecture organizes code by **feature** rather than **technical layer**. Each feature contains everything it needs: UI, business logic, data access, and models.

This document provides practical guidelines for when and how to share code between slices while maintaining the independence that makes VSA worthwhile.

---

## Project Structure

```
lib/
├── features/                    # Feature slices (VSA)
│   ├── card_management/
│   │   ├── data/
│   │   │   ├── repositories/    # Data access implementations
│   │   │   └── services/        # Feature-specific services
│   │   ├── domain/
│   │   │   ├── models/          # Feature-specific models (if any)
│   │   │   └── providers/       # State management (ChangeNotifiers)
│   │   ├── presentation/
│   │   │   ├── screens/         # Full-page widgets
│   │   │   ├── widgets/         # Reusable UI components
│   │   │   └── view_models/     # UI logic (MVVM)
│   │   ├── test/                # Feature-specific tests
│   │   └── card_management.dart # Barrel export
│   │
│   ├── card_review/
│   ├── duplicate_detection/
│   ├── dashboard/
│   └── ...
│
├── shared/                      # Cross-cutting concerns ONLY
│   ├── domain/
│   │   └── models/              # Shared domain models (CardModel, etc.)
│   ├── services/                # Technical infrastructure
│   ├── widgets/                 # Truly generic UI components
│   └── navigation/              # App-wide routing
│
└── main.dart                    # App entry point & provider registration
```

---

## The Three Tiers of Sharing

### Tier 1: Technical Infrastructure (Share Freely)

Pure plumbing that affects all features equally. Place in `shared/`.

**Examples:**
- Database/storage services (`CardStorageService`)
- Logging and analytics
- HTTP clients
- Authentication middleware
- Navigation/routing (`AppRouter`)
- Generic UI widgets (`IconifyIcon`, `SpeakerButton`)
- Result patterns and error handling

```dart
// shared/services/card_storage_service.dart
// ✅ Good: Technical infrastructure shared by all features
class CardStorageService {
  Future<List<CardModel>> loadCards();
  Future<void> saveCards(List<CardModel> cards);
}
```

### Tier 2: Domain Models (Share with Business Logic)

Shared domain models should contain their own business logic. Push rules INTO the model.

**Examples:**
- `CardModel` with spaced repetition logic
- `ExerciseType` with validation rules
- Value objects with invariants

```dart
// shared/domain/models/card_model.dart
// ✅ Good: Business logic lives IN the model
class CardModel {
  final String id;
  final DateTime? nextReview;
  final int reviewCount;
  
  // Business logic belongs here, not scattered across features
  bool get isDue => nextReview == null || nextReview!.isBefore(DateTime.now());
  
  CardModel processAnswer(CardAnswer answer) {
    // Spaced repetition algorithm lives here
    return copyWith(
      reviewCount: reviewCount + 1,
      nextReview: _calculateNextReview(answer),
    );
  }
}
```

### Tier 3: Feature-Specific Logic (Keep Local)

Logic shared between related slices within the same feature stays LOCAL to that feature.

```
features/
└── card_management/
    ├── domain/
    │   └── providers/
    │       └── card_management_provider.dart  # Shared within feature
    ├── presentation/
    │   ├── screens/
    │   │   ├── card_list_screen.dart
    │   │   └── card_creation_screen.dart
    │   └── view_models/
    │       ├── card_list_view_model.dart      # Uses shared provider
    │       └── card_creation_view_model.dart  # Uses shared provider
```

**Benefit:** If you delete the feature, all related code goes with it. No zombie code.

---

## Decision Framework

When you encounter potential code sharing, ask these questions:

### 1. Is this infrastructural or domain?

| Type | Action |
|------|--------|
| **Infrastructure** (storage, HTTP, logging) | Share in `shared/services/` |
| **Domain** (business rules, calculations) | Push into domain models or keep local |

### 2. How stable is this concept?

| Stability | Action |
|-----------|--------|
| Changes rarely (once a year) | Safe to share |
| Changes with feature requests | Keep local to the feature |

### 3. Rule of Three

| Occurrences | Action |
|-------------|--------|
| 1 duplicate | Fine, leave it |
| 2 duplicates | Consider if they'll diverge |
| 3+ duplicates | Time to extract (if logic is identical AND stable) |

---

## Cross-Feature Communication

### ❌ DON'T: Create shared services between unrelated features

```dart
// ❌ Bad: Coupling unrelated features
class SharedOrderCustomerService {
  // Methods used by both Orders and Customers features
  // Creates tight coupling
}
```

### ✅ DO: Query data directly or use domain models

```dart
// ✅ Good: Each feature queries what it needs
// card_review uses CardManagementProvider to get cards
class ReviewSessionProvider {
  final CardManagementProvider _cardManagement;
  
  void startSession() {
    final cards = _cardManagement.reviewCards; // Direct access
    // ...
  }
}
```

### ✅ DO: Use explicit dependencies

```dart
// ✅ Good: Explicit dependency injection
class ExerciseSessionProvider {
  final CardManagementProvider cardManagement;
  
  ExerciseSessionProvider({required this.cardManagement});
}
```

### ✅ DO: Push shared logic into domain models

```dart
// ✅ Good: Both features use the same model method
// card_review and card_management both call:
final updatedCard = card.processAnswer(CardAnswer.correct);
```

---

## When Duplication Is Correct

### Response/Request Models

```dart
// features/card_management/presentation/screens/card_list_screen.dart
class CardListState {
  final List<CardModel> cards;
  final bool isLoading;
}

// features/card_review/presentation/screens/card_review_screen.dart
class CardReviewState {
  final List<CardModel> cards;
  final bool isLoading;
}
```

These look identical but will diverge:
- `CardListState` might add `selectedCards`, `sortOrder`
- `CardReviewState` might add `currentIndex`, `sessionProgress`

**Duplication is cheaper than the wrong abstraction.**

### Feature-Specific Validation

```dart
// ✅ Good: Each feature validates what IT needs
// card_creation validates: frontText, backText required
// card_import validates: CSV format, batch limits
```

---

## Anti-Patterns to Avoid

### ❌ The "Common" Junk Drawer

```dart
// ❌ Bad: Dumping ground for unrelated code
lib/common/
  ├── utils.dart           # What even is this?
  ├── helpers.dart         # Vague and coupled
  └── shared_services.dart # Everything depends on this
```

### ❌ Premature Abstraction

```dart
// ❌ Bad: Abstracting before you understand the variations
abstract class BaseCardProvider {
  // Created after seeing 2 similar providers
  // Now constrains both in ways neither needs
}
```

### ❌ Feature Calling Feature Directly

```dart
// ❌ Bad: Tight coupling between features
class CardReviewScreen {
  void onComplete() {
    // Directly calling into another feature
    context.read<DashboardProvider>().refreshStats();
  }
}
```

### ✅ Better: Let the data layer handle it

```dart
// ✅ Good: Dashboard listens to CardManagementProvider
class DashboardScreen {
  // Consumer<CardManagementProvider> rebuilds when cards change
}
```

---

## LinguaFlutter Specific Guidelines

### Provider Registration (main.dart)

```dart
// Core providers first
ChangeNotifierProvider.value(value: languageProvider),

// Feature providers (VSA)
ChangeNotifierProvider.value(value: cardManagementProvider),
ChangeNotifierProvider.value(value: duplicateDetectionProvider),

// Session providers (depend on feature providers)
ChangeNotifierProxyProvider<CardManagementProvider, ReviewSessionProvider>(...),
```

### Feature Barrel Exports

Each feature should have a barrel file exporting its public API:

```dart
// features/card_management/card_management.dart
export 'domain/providers/card_management_provider.dart';
export 'presentation/screens/card_list_screen.dart';
export 'presentation/screens/card_creation_screen.dart';
// Don't export internal implementation details
```

### Shared Domain Models

Models in `shared/domain/models/` are shared because:
1. Multiple features need the same data structure
2. Business logic is encapsulated IN the model
3. They represent core domain concepts (Card, Language, etc.)

---

## Summary: The Rules

1. **Features own their request/response models.** No exceptions.

2. **Push business logic into domain models.** Entities and value objects are the best place to share business rules.

3. **Keep feature-family sharing local.** If only card_management slices need it, keep it in `features/card_management/`.

4. **Infrastructure is shared by default.** Storage, HTTP, logging are technical concerns.

5. **Apply the Rule of Three.** Don't extract until you have three real usages with identical, stable logic.

6. **Explicit dependencies over implicit coupling.** Use constructor injection, not service locators or event buses.

7. **When in doubt, duplicate.** Duplication is cheaper than the wrong abstraction.
