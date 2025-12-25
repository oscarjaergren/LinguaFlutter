-- Add exercise_scores column to cards table
-- This stores per-exercise mastery tracking for each card

ALTER TABLE cards 
ADD COLUMN IF NOT EXISTS exercise_scores JSONB DEFAULT '{}'::jsonb;

-- Add index for querying exercise scores
CREATE INDEX IF NOT EXISTS idx_cards_exercise_scores ON cards USING GIN (exercise_scores);

-- Add comment explaining the column
COMMENT ON COLUMN cards.exercise_scores IS 'Per-exercise type mastery tracking. Maps ExerciseType enum values to ExerciseScore objects containing correctCount, incorrectCount, lastPracticed, nextReview, etc.';
