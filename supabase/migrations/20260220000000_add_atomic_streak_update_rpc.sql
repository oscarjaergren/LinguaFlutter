-- Atomic streak update RPC to avoid client-side read-modify-write races

CREATE OR REPLACE FUNCTION public.update_streak_with_review_atomic(
  p_cards_reviewed INTEGER,
  p_review_date DATE DEFAULT NULL
)
RETURNS public.streaks
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_review_date DATE := COALESCE(p_review_date, CURRENT_DATE);
  v_date_key TEXT := to_char(v_review_date, 'YYYY-MM-DD');

  v_current public.streaks%ROWTYPE;
  v_updated public.streaks%ROWTYPE;

  v_days_diff INTEGER;
  v_new_current_streak INTEGER;
  v_new_best_streak INTEGER;

  v_daily_review_counts JSONB;
  v_existing_cards_for_day INTEGER;

  v_milestones INTEGER[] := ARRAY[3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365];
  v_new_milestones INTEGER[];
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  IF p_cards_reviewed <= 0 THEN
    RAISE EXCEPTION 'cards_reviewed must be greater than 0';
  END IF;

  INSERT INTO public.streaks (user_id)
  VALUES (v_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT *
  INTO v_current
  FROM public.streaks
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_current.last_review_date IS NULL THEN
    v_new_current_streak := 1;
  ELSE
    v_days_diff := v_review_date - v_current.last_review_date;

    IF v_days_diff = 0 THEN
      v_new_current_streak := v_current.current_streak;
    ELSIF v_days_diff = 1 THEN
      v_new_current_streak := v_current.current_streak + 1;
    ELSE
      v_new_current_streak := 1;
    END IF;
  END IF;

  v_new_best_streak := GREATEST(v_current.best_streak, v_new_current_streak);

  v_daily_review_counts := COALESCE(v_current.daily_review_counts, '{}'::jsonb);
  v_existing_cards_for_day := COALESCE((v_daily_review_counts ->> v_date_key)::INTEGER, 0);
  v_daily_review_counts := jsonb_set(
    v_daily_review_counts,
    ARRAY[v_date_key],
    to_jsonb(v_existing_cards_for_day + p_cards_reviewed),
    TRUE
  );

  SELECT COALESCE(array_agg(m), '{}'::INTEGER[])
  INTO v_new_milestones
  FROM unnest(v_milestones) AS m
  WHERE m <= v_new_current_streak
    AND m > v_current.current_streak
    AND NOT (m = ANY(COALESCE(v_current.achieved_milestones, '{}'::INTEGER[])));

  UPDATE public.streaks
  SET
    current_streak = v_new_current_streak,
    best_streak = v_new_best_streak,
    total_cards_reviewed = COALESCE(v_current.total_cards_reviewed, 0) + p_cards_reviewed,
    total_review_sessions = COALESCE(v_current.total_review_sessions, 0) + 1,
    last_review_date = v_review_date,
    daily_review_counts = v_daily_review_counts,
    achieved_milestones =
      COALESCE(v_current.achieved_milestones, '{}'::INTEGER[]) || v_new_milestones
  WHERE user_id = v_user_id
  RETURNING * INTO v_updated;

  RETURN v_updated;
END;
$$;
