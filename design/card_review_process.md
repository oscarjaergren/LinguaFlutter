# Design Document: Card Review Process

## 1. Goal

To create a modern, efficient card review screen that combines the best practices from industry-leading spaced repetition apps (Anki, DuoCards) with an immersive book-like experience. The interface should prioritize learning effectiveness while maintaining visual appeal.

## 2. Current State & Issues

The previous `card_review_screen.dart` implementation had complex animation conflicts and non-functional flipping mechanisms. Based on user feedback, we're starting fresh with a proven approach.

## 3. Industry Standards Analysis

### Anki Patterns:
- **Answer Buttons**: 2-4 difficulty buttons (Again, Hard, Good, Easy) with time intervals
- **Gesture Support**: Configurable swipe gestures for quick answering
- **Show Answer**: Separate step to reveal answer before grading
- **Progress Indicators**: Clear count of new/learning/review cards

### DuoCards Patterns:
- **Binary Classification**: Simple "Know/Don't Know" swipe system
- **Visual Feedback**: Immediate color-coded feedback (green/red)
- **Smooth Animations**: Clean card transitions without complex 3D effects
- **Touch-First Design**: Optimized for mobile interaction

## 4. Proposed User Flow

1.  **Session Start**: Display card count and progress. Show first card's question side.
2.  **Question Phase**: User reads the question/prompt on the card front.
3.  **Reveal Answer**: Tap anywhere on card OR tap "Show Answer" button to reveal the back.
4.  **Answer Phase**: User evaluates their knowledge using one of these methods:
    *   **Swipe Right**: "I knew this" (Easy/Good) - green feedback
    *   **Swipe Left**: "I didn't know this" (Again/Hard) - red feedback  
    *   **Button Tap**: More granular difficulty selection (Again, Hard, Good, Easy)
5.  **Transition**: Card animates away, next card appears with smooth transition.
6.  **Session End**: Show completion summary with statistics.

## 5. Animation and Visual Design

### Core Principles:
- **Performance First**: Smooth 60fps animations using efficient transforms
- **Subtle Book Aesthetic**: Book-like elements without overwhelming complexity
- **Immediate Feedback**: Clear visual responses to user actions

### Visual Elements:
-   **Card Flip Animation**: Simple `AnimatedSwitcher` or `Transform` with `rotateY` for question/answer reveal
-   **Book-like Styling**: 
    -   Subtle paper texture background
    -   Soft drop shadows to simulate page depth
    -   Rounded corners mimicking book pages
    -   Optional book spine visual on the left edge
-   **Swipe Feedback**: 
    -   Real-time color overlay (green/red) during drag gesture
    -   Opacity increases with drag distance
    -   Smooth card translation following finger movement
-   **Transition Animations**:
    -   Cards slide out in swipe direction
    -   Next card scales up from behind with slight delay
    -   Fade transitions for answer reveal
-   **Haptic Feedback**: 
    -   `HapticFeedback.lightImpact()` on card tap
    -   `HapticFeedback.mediumImpact()` on successful swipe completion

## 6. Interactions

-   **Tap**: Tapping anywhere on the current card reveals the answer
-   **Swipe Left**: Mark as "Don't Know" - card moves left with red feedback
-   **Swipe Right**: Mark as "Know" - card moves right with green feedback
-   **Button Interface**: Optional difficulty buttons (Again, Hard, Good, Easy) for precise grading
-   **Keyboard Shortcuts** (Desktop/Web):
    -   `Space`: Reveal answer or advance to next card
    -   `1-4`: Select difficulty (Again, Hard, Good, Easy)
    -   `ArrowLeft`: Don't Know
    -   `ArrowRight`: Know

## 7. State Management

### CardProvider Responsibilities:
-   **Session Management**: Handle review queue and current card state
-   **Answer Processing**: Update card statistics based on user responses
-   **Progress Tracking**: Monitor cards remaining, session completion
-   **State Transitions**: Manage question/answer flip state

### Card States:
-   `showingQuestion`: Initial state showing card front
-   `showingAnswer`: After tap, showing card back
-   `answering`: During swipe gesture with visual feedback
-   `transitioning`: Card leaving, next card appearing

## 8. Technical Implementation

### Key Components:
1. **CardReviewScreen**: Main screen widget with gesture handling
2. **ReviewCard**: Individual card widget with flip animation
3. **SwipeDetector**: Custom gesture recognizer for swipe actions
4. **ProgressIndicator**: Shows session progress and card counts
5. **AnswerButtons**: Optional precise difficulty selection

### Performance Considerations:
-   Use `RepaintBoundary` for card widgets to optimize repaints
-   Implement card preloading for smooth transitions
-   Dispose animation controllers properly to prevent memory leaks
-   Use `const` constructors where possible
