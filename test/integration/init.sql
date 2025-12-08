-- Test Database Initialization Script
-- Creates minimal schema for integration testing
-- Note: auth schema is managed by GoTrue service

-- Create roles for Supabase compatibility
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    CREATE ROLE supabase_auth_admin NOLOGIN;
  END IF;
END
$$;

-- Create auth schema (GoTrue will populate it)
CREATE SCHEMA IF NOT EXISTS auth;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;

-- ============================================
-- LANGUAGES TABLE (reference data)
-- ============================================
CREATE TABLE IF NOT EXISTS languages (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  native_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed language data
INSERT INTO languages (code, name, native_name) VALUES
  ('de', 'German', 'Deutsch'),
  ('es', 'Spanish', 'Español'),
  ('fr', 'French', 'Français')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- CARDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,  -- No FK constraint for testing (auth.users created by GoTrue)
  front_text TEXT NOT NULL,
  back_text TEXT NOT NULL,
  language TEXT NOT NULL REFERENCES languages(code),
  category TEXT,
  tags TEXT[] DEFAULT '{}',
  examples TEXT[] DEFAULT '{}',
  notes TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  review_count INTEGER DEFAULT 0,
  correct_count INTEGER DEFAULT 0,
  last_reviewed TIMESTAMPTZ,
  next_review TIMESTAMPTZ,
  ease_factor REAL DEFAULT 2.5,
  interval_days INTEGER DEFAULT 0,
  exercise_scores JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STREAKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,  -- No FK constraint for testing (auth.users created by GoTrue)
  current_streak INTEGER DEFAULT 0,
  best_streak INTEGER DEFAULT 0,
  last_review_date DATE,
  total_cards_reviewed INTEGER DEFAULT 0,
  total_review_sessions INTEGER DEFAULT 0,
  daily_review_counts JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Grant permissions on tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Enable RLS (but allow all for testing)
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;

-- Permissive policies for testing
CREATE POLICY "Allow all for cards" ON cards FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for streaks" ON streaks FOR ALL USING (true) WITH CHECK (true);
