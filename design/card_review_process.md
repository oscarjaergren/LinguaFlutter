# Design Document: Card Review Process

## 1. Goal

To transform the card review screen from a simple card-swiping interface into an immersive, book-like experience. The user should feel like they are flipping through pages of a study book rather than just interacting with digital cards.

## 2. Current State & Issues

The `card_review_screen.dart` file contains multiple `AnimationControllers` intended to create a page-turning effect, including animations for page flips, bookbinding, and shadows. However, the user has reported that the flipping mechanism is not working correctly. The complexity of the existing animations might be leading to conflicts or unexpected behavior, preventing a smooth user experience.

## 3. Proposed User Flow

1.  **Session Start**: The user initiates a review session. The cards are presented as a stack of pages in a book, with the top card visible.
2.  **Viewing a Card (Front)**: The user sees the front of the top card (e.g., a word in German). The UI should resemble an open page of a book.
3.  **Flipping the Page**: The user can **tap** the card. This action triggers a 3D page-turning animation, revealing the back of the card (the answer, e.g., the English translation).
4.  **Answering a Card**: After viewing the answer, the user **swipes** the card:
    *   **Swipe Right (Correct)**: The current page (card) gracefully slides or flips away to the right, revealing the next card in the stack. This action is accompanied by positive haptic and visual feedback (e.g., a green glow).
    *   **Swipe Left (Incorrect)**: The current page slides or flips away to the left, accompanied by negative feedback (e.g., a red glow).
5.  **Session End**: When all cards are reviewed, a summary or completion screen is displayed.

## 4. Animation and Visuals

-   __Page Flip Animation__: A `Transform` widget with a `rotateY` transformation should be used to create a realistic 3D page flip effect on tap. The animation should be controlled by an `AnimationController` and feel fluid.
-   __Book Structure__: The card stack should be visually represented as a book. This includes:
    -   A subtle book spine on the left.
    -   Visible edges of the underlying pages (next cards in the queue) to create a sense of depth.
-   __Shadows and Lighting__: Dynamic shadows should be cast by the turning page to enhance the 3D effect. The shadow should move and change intensity as the page flips.
-   __Swipe Feedback__: Swiping should provide immediate visual feedback. A colored overlay (green for correct, red for incorrect) should appear and intensify as the user drags their finger.
-   __Haptic Feedback__: Use `HapticFeedback` to provide tactile confirmation for key actions:
    -   `lightImpact` when tapping to flip a card.
    -   `mediumImpact` when a swipe action is successfully completed.

## 5. Interactions

-   **Tap**: Tapping anywhere on the current card flips it to show the answer.
-   **Pan/Swipe**: Dragging the card left or right and releasing it will register an answer (incorrect/correct).
-   **Keyboard Shortcuts** (for Desktop/Web):
    -   `Space` or `ArrowUp`/`ArrowDown`: Flip the card.
    -   `ArrowLeft`: Answer as incorrect.
    -   `ArrowRight`: Answer as correct.

## 6. State Management (`CardProvider`)

The `CardProvider` will continue to manage the review session's state. Its responsibilities include:

-   Managing the queue of cards for the current review session (`currentReviewSession`).
-   Tracking the `currentCard` and its flipped state (`showingBack`).
-   Processing user answers (`answerCard`) and updating card statistics.
-   Resetting the state for the next card in the queue.
