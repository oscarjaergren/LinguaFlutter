-- Seed data for testing
-- This file is loaded automatically when supabase starts with seed.enabled = true

-- Insert test user for integration tests
-- This user is used by SupabaseTestHelper in tests
INSERT INTO auth.users (id, email, email_confirmed_at, created_at, updated_at, phone, phone_confirmed_at, last_sign_in_at, user_metadata, is_super_admin)
VALUES ('00000000-0000-0000-0000-000000000001', 'test@linguaflutter.dev', NOW(), NOW(), NOW(), NULL, NULL, NULL, '{}', false)
ON CONFLICT (id) DO NOTHING;

-- Insert corresponding identity record for the test user
INSERT INTO auth.identities (id, user_id, identity_data, provider, created_at, updated_at, last_sign_in_at)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000001', '{"email": "test@linguaflutter.dev", "email_verified": true}', 'email', NOW(), NOW(), NOW())
ON CONFLICT (user_id) DO NOTHING;

-- Insert test profile record
INSERT INTO public.profiles (id, email, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000001', 'test@linguaflutter.dev', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;
