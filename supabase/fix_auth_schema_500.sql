-- ==============================================================================
-- FIX SUPABASE AUTH 500: "Database error querying schema"
-- Project: https://dikaqxsubzaqshwirsdh.supabase.co
-- Run this script in: Supabase Dashboard → SQL Editor → New Query → Run
-- ==============================================================================

-- ─── STEP 0: EXTENSIONS & PERMISSIONS ─────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure supabase_auth_admin has all required privileges on the auth schema
GRANT USAGE ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA auth TO supabase_auth_admin;

-- ─── STEP 1: FIX NULL COLUMNS IN auth.users (CAUSES GoTrue 500 SCAN ERROR) ────
-- Supabase GoTrue (Auth engine) scans these columns into non-nullable Go strings.
-- When users are manually inserted with NULL values, GoTrue crashes with:
-- 500 "Database error querying schema"
UPDATE auth.users
SET 
  confirmation_token          = COALESCE(confirmation_token, ''),
  recovery_token              = COALESCE(recovery_token, ''),
  email_change_token_new      = COALESCE(email_change_token_new, ''),
  email_change                = COALESCE(email_change, ''),
  email_change_token_current  = COALESCE(email_change_token_current, ''),
  phone_change                = COALESCE(phone_change, ''),
  phone_change_token          = COALESCE(phone_change_token, ''),
  reauthentication_token      = COALESCE(reauthentication_token, ''),
  is_sso_user                 = COALESCE(is_sso_user, false)
WHERE confirmation_token IS NULL
   OR recovery_token IS NULL
   OR email_change_token_new IS NULL
   OR email_change IS NULL
   OR email_change_token_current IS NULL
   OR phone_change IS NULL
   OR phone_change_token IS NULL
   OR reauthentication_token IS NULL
   OR is_sso_user IS NULL;


-- ─── STEP 2: UPSERT ALL 4 DEMO ACCOUNTS INTO auth.users & auth.identities ─────
-- Password for all demo accounts: Demo12345!
DO $$
DECLARE
  v_pw_hash text := crypt('Demo12345!', gen_salt('bf'));
  v_user record;
  v_id_type text;
BEGIN
  -- Check the data type of auth.identities.id (uuid vs text)
  SELECT data_type INTO v_id_type 
  FROM information_schema.columns 
  WHERE table_schema = 'auth' AND table_name = 'identities' AND column_name = 'id';

  CREATE TEMP TABLE IF NOT EXISTS _demo_users_seed (
    id uuid PRIMARY KEY,
    email text NOT NULL,
    name text NOT NULL,
    role text NOT NULL,
    phone text NOT NULL
  ) ON COMMIT DROP;

  DELETE FROM _demo_users_seed;

  INSERT INTO _demo_users_seed (id, email, name, role, phone) VALUES
    ('11111111-1111-1111-1111-111111111111'::uuid, 'student.demo@leidenschaft.com',    'Max Mustermann',           'student',    '+20 100 123 4567'),
    ('22222222-2222-2222-2222-222222222222'::uuid, 'instructor.demo@leidenschaft.com', 'Herr Thomas Müller',       'instructor', '+20 101 234 5678'),
    ('33333333-3333-3333-3333-333333333333'::uuid, 'secretary.demo@leidenschaft.com',  'Frau Sarah Schmidt',       'secretary',  '+20 102 345 6789'),
    ('44444444-4444-4444-4444-444444444444'::uuid, 'admin.demo@leidenschaft.com',      'Dr. Klaus Weber (Admin)',  'admin',      '+20 15 15638830'),
    ('11111111-1111-1111-1111-111111111199'::uuid, 'student.demo@acadflow.com',        'Max Mustermann',           'student',    '+20 100 123 4567'),
    ('22222222-2222-2222-2222-222222222299'::uuid, 'instructor.demo@acadflow.com',     'Herr Thomas Müller',       'instructor', '+20 101 234 5678'),
    ('33333333-3333-3333-3333-333333333399'::uuid, 'secretary.demo@acadflow.com',      'Frau Sarah Schmidt',       'secretary',  '+20 102 345 6789'),
    ('44444444-4444-4444-4444-444444444499'::uuid, 'admin.demo@acadflow.com',          'Dr. Klaus Weber (Admin)',  'admin',      '+20 15 15638830');

  FOR v_user IN SELECT * FROM _demo_users_seed LOOP

    -- 2.1 Insert / Update auth.users with ALL required GoTrue fields populated
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      role,
      aud,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change,
      email_change_token_current,
      phone_change,
      phone_change_token,
      reauthentication_token,
      is_sso_user,
      created_at,
      updated_at
    ) VALUES (
      v_user.id,
      '00000000-0000-0000-0000-000000000000'::uuid,
      v_user.email,
      v_pw_hash,
      NOW(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      jsonb_build_object('name', v_user.name, 'role', v_user.role, 'phone', v_user.phone),
      'authenticated',
      'authenticated',
      '', '', '', '', '', '', '', '',
      false,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      encrypted_password          = v_pw_hash,
      email                       = v_user.email,
      email_confirmed_at          = COALESCE(auth.users.email_confirmed_at, NOW()),
      raw_app_meta_data           = jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      raw_user_meta_data          = jsonb_build_object('name', v_user.name, 'role', v_user.role, 'phone', v_user.phone),
      confirmation_token          = '',
      recovery_token              = '',
      email_change_token_new      = '',
      email_change                = '',
      email_change_token_current  = '',
      phone_change                = '',
      phone_change_token          = '',
      reauthentication_token      = '',
      is_sso_user                 = false,
      updated_at                  = NOW();

    -- 2.2 Re-insert auth.identities (GoTrue requires matching identity for password login)
    DELETE FROM auth.identities WHERE user_id = v_user.id;

    IF v_id_type = 'uuid' THEN
      INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
      ) VALUES (
        v_user.id,
        v_user.id,
        jsonb_build_object('sub', v_user.id::text, 'email', v_user.email),
        'email',
        v_user.id::text,
        NOW(),
        NOW(),
        NOW()
      );
    ELSE
      INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
      ) VALUES (
        v_user.id::text,
        v_user.id,
        jsonb_build_object('sub', v_user.id::text, 'email', v_user.email),
        'email',
        v_user.id::text,
        NOW(),
        NOW(),
        NOW()
      );
    END IF;

    -- 2.3 Ensure public.profiles exists and is in sync
    INSERT INTO public.profiles (
      id,
      name,
      email,
      phone,
      role,
      current_level,
      created_at
    ) VALUES (
      v_user.id,
      v_user.name,
      v_user.email,
      v_user.phone,
      v_user.role,
      'A1',
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      name          = EXCLUDED.name,
      email         = EXCLUDED.email,
      phone         = EXCLUDED.phone,
      role          = EXCLUDED.role,
      current_level = COALESCE(public.profiles.current_level, 'A1');

  END LOOP;
END $$;


-- ─── STEP 3: BACKFILL IDENTITIES FOR ANY OTHER USER IN auth.users ─────────────
-- Ensures no other account ever triggers the 500 error due to missing identity
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT 
  u.id::text,
  u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  u.id::text,
  NOW(),
  NOW(),
  NOW()
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM auth.identities i WHERE i.user_id = u.id
)
ON CONFLICT DO NOTHING;


-- ─── STEP 4: HARDEN public.handle_new_user TRIGGER ────────────────────────────
-- Ensure the sign-up trigger never throws uncaught exceptions that break Auth API
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    NULLIF(btrim(COALESCE(NEW.raw_user_meta_data->>'phone', '')), '')
  )
  ON CONFLICT (id) DO UPDATE SET
    name  = EXCLUDED.name,
    email = EXCLUDED.email,
    phone = COALESCE(EXCLUDED.phone, public.profiles.phone);
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ─── STEP 5: VERIFICATION QUERY ───────────────────────────────────────────────
-- Run this to verify the demo users are ready:
SELECT 
  u.id,
  u.email,
  u.encrypted_password IS NOT NULL AS has_password,
  u.email_confirmed_at IS NOT NULL AS email_confirmed,
  u.confirmation_token = '' AS token_fixed,
  i.provider,
  i.provider_id,
  p.role,
  p.name
FROM auth.users u
JOIN auth.identities i ON i.user_id = u.id
JOIN public.profiles p ON p.id = u.id
WHERE u.email LIKE '%@leidenschaft.com';
