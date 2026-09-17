-- ==============================================================================
-- LEIDENSCHAFT KLUB / ACADFLOW LMS — DEMO DATA RESET (FIXED FOR GOTRUE AUTH)
-- Project: https://dikaqxsubzaqshwirsdh.supabase.co
-- Run this in: Supabase Dashboard → SQL Editor
-- Password for ALL demo accounts: Demo12345!
-- ==============================================================================

create extension if not exists pgcrypto;

-- ─── 0. CLEANUP (idempotent, safe order) ────────────────────────────────────────
-- 1. Remove all child records referencing demo accounts or demo entities
delete from public.notifications
where user_id::text like '11111111-%'
   or user_id::text like '22222222-%'
   or user_id::text like '33333333-%'
   or user_id::text like '44444444-%'
   or created_by::text like '11111111-%'
   or created_by::text like '22222222-%'
   or created_by::text like '33333333-%'
   or created_by::text like '44444444-%'
   or id::text like '60606060-%';

delete from public.website_event_bookings
where user_id::text like '11111111-%'
   or id::text like '50505050-%';

delete from public.website_events        where id::text like '40404040-%';
delete from public.website_spaces        where id::text like '30303030-%';

delete from public.results
where student_id::text like '11111111-%'
   or exam_id::text like '10101010-%';

delete from public.exam_answers
where student_id::text like '11111111-%'
   or exam_id::text like '10101010-%';

delete from public.questions             where id::text like '20202020-%';
delete from public.group_exams           where exam_id::text like '10101010-%';
delete from public.exams                 where id::text like '10101010-%';

delete from public.submissions
where id::text like 'ffffffff-%'
   or student_id::text like '11111111-%';

delete from public.group_assignments     where assignment_id::text like 'eeeeeeee-%';

delete from public.assignments
where id::text like 'eeeeeeee-%'
   or created_by::text like '22222222-%'
   or created_by::text like '44444444-%'
   or instructor_id::text like '22222222-%';

delete from public.student_materials
where id::text like 'dddddddd-%'
   or student_id::text like '11111111-%'
   or assigned_by::text like '22222222-%'
   or assigned_by::text like '33333333-%';

delete from public.materials             where id::text like 'cccccccc-%';
delete from public.attendance            where student_id::text like '11111111-%';
delete from public.level_sessions        where level_id::text like 'bbbbbbbb-%';
delete from public.level_settings        where level_id::text like 'bbbbbbbb-%';
delete from public.level_students        where student_id::text like '11111111-%';
delete from public.instructor_groups     where instructor_id::text like '22222222-%';

-- Levels: remove sub-levels first, then base levels
delete from public.levels where id::text like 'bbbbbbbb-%' and parent_level_id is not null;
delete from public.levels where id::text like 'bbbbbbbb-%';

-- Profiles
delete from public.profiles
where id::text like '11111111-%'
   or id::text like '22222222-%'
   or id::text like '33333333-%'
   or id::text like '44444444-%';

-- Groups
delete from public.groups where id::text like 'aaaaaaaa-%';

-- Auth Identities (delete for demo users)
delete from auth.identities
where user_id::text like '11111111-%'
   or user_id::text like '22222222-%'
   or user_id::text like '33333333-%'
   or user_id::text like '44444444-%'
   or identity_data->>'email' ilike '%@leidenschaft.com'
   or identity_data->>'email' ilike '%@acadflow-demo.com';

-- Auth Users (delete by ID and by Email)
delete from auth.users
where id::text like '11111111-%'
   or id::text like '22222222-%'
   or id::text like '33333333-%'
   or id::text like '44444444-%'
   or email ilike '%@leidenschaft.com'
   or email ilike '%@acadflow-demo.com';


-- ─── 1. FIX auth.users NULL COLUMNS (prevents GoTrue 500) ──────────────────────
update auth.users
set
  confirmation_token         = coalesce(confirmation_token, ''),
  recovery_token             = coalesce(recovery_token, ''),
  email_change_token_new     = coalesce(email_change_token_new, ''),
  email_change               = coalesce(email_change, ''),
  email_change_token_current = coalesce(email_change_token_current, ''),
  phone_change               = coalesce(phone_change, ''),
  phone_change_token         = coalesce(phone_change_token, ''),
  reauthentication_token     = coalesce(reauthentication_token, ''),
  is_sso_user                = coalesce(is_sso_user, false)
where confirmation_token is null
   or recovery_token is null
   or email_change_token_new is null
   or email_change is null
   or email_change_token_current is null
   or phone_change is null
   or phone_change_token is null
   or reauthentication_token is null
   or is_sso_user is null;


-- ─── 2. AUTH USERS + IDENTITIES ───────────────────────────────────────────────
do $$
declare
  -- bcrypt hash with standard 10 rounds for 'Demo12345!'
  pw_hash text := crypt('Demo12345!', gen_salt('bf', 10));
  v_id_type text;
begin
  -- Detect auth.identities.id data type (uuid vs text)
  select data_type into v_id_type
  from information_schema.columns
  where table_schema = 'auth' and table_name = 'identities' and column_name = 'id';

  ------------------------------------------------------------------
  -- 2.1 STAFF
  ------------------------------------------------------------------
  -- Admin
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values (
    '44444444-4444-4444-4444-444444444444', '00000000-0000-0000-0000-000000000000',
    'admin.demo@leidenschaft.com', pw_hash,
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Dr. Klaus Weber (Admin)","role":"admin","phone":"+20 15 15638830","locale":"de"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '', false, false, now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  -- Secretary 1 (German)
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values (
    '33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000',
    'secretary.demo@leidenschaft.com', pw_hash,
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Frau Sarah Schmidt","role":"secretary","phone":"+20 102 345 6789","locale":"de"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '', false, false, now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  -- Secretary 2 (Arabic)
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values (
    '33333333-3333-3333-3333-333333333334', '00000000-0000-0000-0000-000000000000',
    'secretary.ar@leidenschaft.com', pw_hash,
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"أ. منى عبد الرحمن","role":"secretary","phone":"+20 102 999 8877","locale":"ar"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '', false, false, now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  ------------------------------------------------------------------
  -- 2.2 INSTRUCTORS
  ------------------------------------------------------------------
  -- Instructor 1: German
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values (
    '22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000',
    'instructor.demo@leidenschaft.com', pw_hash,
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Herr Thomas Müller","role":"instructor","phone":"+20 101 234 5678","locale":"de","specialty":"German General & Business"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '', false, false, now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  -- Instructor 2: English
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values (
    '22222222-2222-2222-2222-222222222223', '00000000-0000-0000-0000-000000000000',
    'instructor.emily@leidenschaft.com', pw_hash,
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Ms. Emily Carter","role":"instructor","phone":"+20 101 555 0011","locale":"en","specialty":"English IELTS & Academic"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '', false, false, now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  -- Instructor 3: Arabic
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values (
    '22222222-2222-2222-2222-222222222224', '00000000-0000-0000-0000-000000000000',
    'instructor.ahmed@leidenschaft.com', pw_hash,
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"د. أحمد الشافعي","role":"instructor","phone":"+20 101 777 8899","locale":"ar","specialty":"Arabic for Non-Natives"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '', false, false, now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  -- Instructor 4: French & Spanish
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values (
    '22222222-2222-2222-2222-222222222225', '00000000-0000-0000-0000-000000000000',
    'instructor.claire@leidenschaft.com', pw_hash,
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Mme Claire Dubois","role":"instructor","phone":"+20 101 222 3344","locale":"fr","specialty":"French & Spanish"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '', false, false, now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  -- Instructor 5: Medical German
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values (
    '22222222-2222-2222-2222-222222222226', '00000000-0000-0000-0000-000000000000',
    'instructor.med@leidenschaft.com', pw_hash,
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Dr. Youssef Kamal","role":"instructor","phone":"+20 101 888 7766","locale":"de","specialty":"German Medical"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '', false, false, now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  ------------------------------------------------------------------
  -- 2.3 STUDENTS
  ------------------------------------------------------------------
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, confirmed_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token,
    reauthentication_token, is_sso_user, is_super_admin, created_at, updated_at
  ) values
    -- S1: Primary demo student
    ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000000',
     'student.demo@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Max Mustermann (محمود)","role":"student","phone":"+20 100 123 4567","locale":"ar","goal":"Work in Germany","nationality":"Egyptian"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S2: Anna
    ('11111111-1111-1111-1111-111111111112','00000000-0000-0000-0000-000000000000',
     'anna.student@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Anna Becker","role":"student","phone":"+20 103 456 7890","locale":"de","goal":"University admission","nationality":"German-Egyptian"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S3: Lukas
    ('11111111-1111-1111-1111-111111111113','00000000-0000-0000-0000-000000000000',
     'lukas.student@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Lukas Fischer (ليث)","role":"student","phone":"+20 104 567 8901","locale":"ar","goal":"Medical residency","nationality":"Syrian"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S4: Sara
    ('11111111-1111-1111-1111-111111111114','00000000-0000-0000-0000-000000000000',
     'sara.sudan@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"سارة عثمان","role":"student","phone":"+20 105 111 2233","locale":"ar","goal":"Business export","nationality":"Sudanese"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S5: Khaled
    ('11111111-1111-1111-1111-111111111115','00000000-0000-0000-0000-000000000000',
     'khaled.yemen@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"خالد الحمادي","role":"student","phone":"+20 106 444 5566","locale":"ar","goal":"Pharmacy certification","nationality":"Yemeni"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S6: Merve
    ('11111111-1111-1111-1111-111111111116','00000000-0000-0000-0000-000000000000',
     'merve.turkey@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Merve Yılmaz","role":"student","phone":"+20 107 777 8899","locale":"tr","goal":"IELTS 7.5","nationality":"Turkish"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S7: Omar
    ('11111111-1111-1111-1111-111111111117','00000000-0000-0000-0000-000000000000',
     'omar.libya@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Omar Al-Mansouri","role":"student","phone":"+20 108 222 3344","locale":"en","goal":"School English","nationality":"Libyan","age":14}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S8: Rania
    ('11111111-1111-1111-1111-111111111118','00000000-0000-0000-0000-000000000000',
     'rania.pal@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"رانيا خليل","role":"student","phone":"+20 109 555 6677","locale":"ar","goal":"Journalism in Paris","nationality":"Palestinian"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S9: Zaid
    ('11111111-1111-1111-1111-111111111119','00000000-0000-0000-0000-000000000000',
     'zaid.jordan@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Zaid Al-Khatib","role":"student","phone":"+20 110 666 7788","locale":"ar","goal":"Travel & Tourism","nationality":"Jordanian"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S10: Layla
    ('11111111-1111-1111-1111-111111111120','00000000-0000-0000-0000-000000000000',
     'layla.lebanon@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"ليلى حداد","role":"student","phone":"+20 111 333 4455","locale":"ar","goal":"Freelance design","nationality":"Lebanese"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S11: Olena
    ('11111111-1111-1111-1111-111111111121','00000000-0000-0000-0000-000000000000',
     'olena.ukraine@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Olena Kovalenko","role":"student","phone":"+20 112 999 0011","locale":"uk","goal":"Integration in Germany","nationality":"Ukrainian"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S12: Dmitri
    ('11111111-1111-1111-1111-111111111122','00000000-0000-0000-0000-000000000000',
     'dmitri.russia@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Dmitri Sokolov","role":"student","phone":"+20 113 222 4433","locale":"ru","goal":"Import/Export","nationality":"Russian"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S13: Mona
    ('11111111-1111-1111-1111-111111111123','00000000-0000-0000-0000-000000000000',
     'mona.mother@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"منى سيد","role":"student","phone":"+20 114 555 6677","locale":"ar","goal":"Support children''s English","nationality":"Egyptian"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S14: Ali
    ('11111111-1111-1111-1111-111111111124','00000000-0000-0000-0000-000000000000',
     'ali.iraq@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"د. علي الجبوري","role":"student","phone":"+20 115 777 8899","locale":"ar","goal":"Medical residency","nationality":"Iraqi"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now()),

    -- S15: Carlos
    ('11111111-1111-1111-1111-111111111125','00000000-0000-0000-0000-000000000000',
     'carlos.spain@leidenschaft.com', pw_hash, now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"name":"Carlos Ramírez","role":"student","phone":"+20 116 333 2244","locale":"es","goal":"Living in Cairo — Arabic","nationality":"Spanish"}'::jsonb,
     'authenticated','authenticated','','','','','','','','', false, false, now(), now())
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email = excluded.email,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmed_at = excluded.confirmed_at,
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data,
    is_sso_user = false,
    updated_at = now();

  ------------------------------------------------------------------
  -- 2.4 IDENTITIES (FIXED: provider_id = u.id::text)
  ------------------------------------------------------------------
  -- Note: GoTrue requires provider_id to be user ID string for email provider!
  if v_id_type = 'uuid' then
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    )
    select
      u.id,
      u.id,
      jsonb_build_object('sub', u.id::text, 'email', lower(u.email)),
      'email',
      u.id::text, -- << CRITICAL FIX: must be user ID, not email
      now(), now(), now()
    from auth.users u
    where u.id::text like '11111111-%'
       or u.id::text like '22222222-%'
       or u.id::text like '33333333-%'
       or u.id::text like '44444444-%'
    on conflict (provider, provider_id) do update set
      identity_data = excluded.identity_data,
      updated_at = now();
  else
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    )
    select
      u.id::text,
      u.id,
      jsonb_build_object('sub', u.id::text, 'email', lower(u.email)),
      'email',
      u.id::text, -- << CRITICAL FIX: must be user ID, not email
      now(), now(), now()
    from auth.users u
    where u.id::text like '11111111-%'
       or u.id::text like '22222222-%'
       or u.id::text like '33333333-%'
       or u.id::text like '44444444-%'
    on conflict (provider, provider_id) do update set
      identity_data = excluded.identity_data,
      updated_at = now();
  end if;

end $$;


-- ─── 3. GROUPS (12 groups across languages) ───────────────────────────────────
insert into public.groups (id, name, level, description, created_at) values
  ('aaaaaaaa-0001-0000-0000-000000000001', 'DE-A1.1 Abendgruppe',    'A1.1', 'German A1.1 — Evening course (Mon & Wed)',          now() - interval '30 days'),
  ('aaaaaaaa-0001-0000-0000-000000000002', 'DE-A2 Business',         'A2',   'German A2 — Business & workplace communication',    now() - interval '25 days'),
  ('aaaaaaaa-0001-0000-0000-000000000003', 'DE-B1 Conversation',     'B1',   'German B1 — Conversation & fluency',                now() - interval '20 days'),
  ('aaaaaaaa-0001-0000-0000-000000000004', 'DE-B2 Medical',          'B2',   'German B2 — Medical professionals',                 now() - interval '18 days'),
  ('aaaaaaaa-0002-0000-0000-000000000001', 'EN-A1 Kids',             'A1',   'English A1 — Kids (ages 10-14)',                    now() - interval '22 days'),
  ('aaaaaaaa-0002-0000-0000-000000000002', 'EN-A2 General',          'A2',   'English A2 — General English',                      now() - interval '22 days'),
  ('aaaaaaaa-0002-0000-0000-000000000003', 'EN-B1 IELTS Prep',       'B1',   'English B1 — IELTS preparation',                    now() - interval '20 days'),
  ('aaaaaaaa-0002-0000-0000-000000000004', 'EN-B2 Business',         'B2',   'English B2 — Business English',                     now() - interval '15 days'),
  ('aaaaaaaa-0003-0000-0000-000000000001', 'AR-A1 Non-Native',       'A1',   'Arabic A1 — For non-native speakers',               now() - interval '28 days'),
  ('aaaaaaaa-0003-0000-0000-000000000002', 'AR-A2 Conversation',     'A2',   'Arabic A2 — Egyptian dialect conversation',         now() - interval '24 days'),
  ('aaaaaaaa-0004-0000-0000-000000000001', 'FR-A1 Beginner',         'A1',   'French A1 — Beginner',                              now() - interval '26 days'),
  ('aaaaaaaa-0005-0000-0000-000000000001', 'ES-A1 Travel',           'A1',   'Spanish A1 — Travel & tourism',                     now() - interval '26 days')
on conflict (id) do update set
  name = excluded.name, level = excluded.level, description = excluded.description;


-- ─── 4. PROFILES ───────────────────────────────────────────────────────────────
insert into public.profiles (id, name, email, phone, role, current_level, group_id, created_at) values
  ('44444444-4444-4444-4444-444444444444','Dr. Klaus Weber (Admin)',  'admin.demo@leidenschaft.com',       '+20 15 15638830','admin',      'B2',   null,                                   now() - interval '60 days'),
  ('33333333-3333-3333-3333-333333333333','Frau Sarah Schmidt',       'secretary.demo@leidenschaft.com',   '+20 102 345 6789','secretary', 'B1',   null,                                   now() - interval '50 days'),
  ('33333333-3333-3333-3333-333333333334','أ. منى عبد الرحمن',       'secretary.ar@leidenschaft.com',     '+20 102 999 8877','secretary', 'B2',   null,                                   now() - interval '48 days'),
  ('22222222-2222-2222-2222-222222222222','Herr Thomas Müller',       'instructor.demo@leidenschaft.com',  '+20 101 234 5678','instructor','B2',   'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '45 days'),
  ('22222222-2222-2222-2222-222222222223','Ms. Emily Carter',         'instructor.emily@leidenschaft.com', '+20 101 555 0011','instructor','C1',   'aaaaaaaa-0002-0000-0000-000000000003', now() - interval '44 days'),
  ('22222222-2222-2222-2222-222222222224','د. أحمد الشافعي',         'instructor.ahmed@leidenschaft.com', '+20 101 777 8899','instructor','C1',   'aaaaaaaa-0003-0000-0000-000000000001', now() - interval '43 days'),
  ('22222222-2222-2222-2222-222222222225','Mme Claire Dubois',        'instructor.claire@leidenschaft.com','+20 101 222 3344','instructor','C1',   'aaaaaaaa-0004-0000-0000-000000000001', now() - interval '42 days'),
  ('22222222-2222-2222-2222-222222222226','Dr. Youssef Kamal',        'instructor.med@leidenschaft.com',   '+20 101 888 7766','instructor','C1',   'aaaaaaaa-0001-0000-0000-000000000004', now() - interval '41 days'),
  ('11111111-1111-1111-1111-111111111111','Max Mustermann (محمود)',   'student.demo@leidenschaft.com',     '+20 100 123 4567','student',   'A1.1', 'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '30 days'),
  ('11111111-1111-1111-1111-111111111112','Anna Becker',              'anna.student@leidenschaft.com',     '+20 103 456 7890','student',   'A1.1', 'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '28 days'),
  ('11111111-1111-1111-1111-111111111113','Lukas Fischer (ليث)',      'lukas.student@leidenschaft.com',    '+20 104 567 8901','student',   'A1.1', 'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '28 days'),
  ('11111111-1111-1111-1111-111111111114','سارة عثمان',               'sara.sudan@leidenschaft.com',       '+20 105 111 2233','student',   'A2',   'aaaaaaaa-0001-0000-0000-000000000002', now() - interval '25 days'),
  ('11111111-1111-1111-1111-111111111115','خالد الحمادي',             'khaled.yemen@leidenschaft.com',     '+20 106 444 5566','student',   'A2',   'aaaaaaaa-0001-0000-0000-000000000002', now() - interval '24 days'),
  ('11111111-1111-1111-1111-111111111116','Merve Yılmaz',             'merve.turkey@leidenschaft.com',     '+20 107 777 8899','student',   'B1',   'aaaaaaaa-0002-0000-0000-000000000003', now() - interval '22 days'),
  ('11111111-1111-1111-1111-111111111117','Omar Al-Mansouri',         'omar.libya@leidenschaft.com',       '+20 108 222 3344','student',   'A1',   'aaaaaaaa-0002-0000-0000-000000000001', now() - interval '21 days'),
  ('11111111-1111-1111-1111-111111111118','رانيا خليل',               'rania.pal@leidenschaft.com',        '+20 109 555 6677','student',   'A1',   'aaaaaaaa-0004-0000-0000-000000000001', now() - interval '20 days'),
  ('11111111-1111-1111-1111-111111111119','Zaid Al-Khatib',           'zaid.jordan@leidenschaft.com',      '+20 110 666 7788','student',   'A1',   'aaaaaaaa-0005-0000-0000-000000000001', now() - interval '20 days'),
  ('11111111-1111-1111-1111-111111111120','ليلى حداد',                'layla.lebanon@leidenschaft.com',    '+20 111 333 4455','student',   'B2',   'aaaaaaaa-0002-0000-0000-000000000004', now() - interval '18 days'),
  ('11111111-1111-1111-1111-111111111121','Olena Kovalenko',          'olena.ukraine@leidenschaft.com',    '+20 112 999 0011','student',   'A2',   'aaaaaaaa-0001-0000-0000-000000000002', now() - interval '17 days'),
  ('11111111-1111-1111-1111-111111111122','Dmitri Sokolov',           'dmitri.russia@leidenschaft.com',    '+20 113 222 4433','student',   'A2',   'aaaaaaaa-0001-0000-0000-000000000002', now() - interval '16 days'),
  ('11111111-1111-1111-1111-111111111123','منى سيد',                  'mona.mother@leidenschaft.com',      '+20 114 555 6677','student',   'A1',   'aaaaaaaa-0002-0000-0000-000000000001', now() - interval '15 days'),
  ('11111111-1111-1111-1111-111111111124','د. علي الجبوري',           'ali.iraq@leidenschaft.com',         '+20 115 777 8899','student',   'B2',   'aaaaaaaa-0001-0000-0000-000000000004', now() - interval '14 days'),
  ('11111111-1111-1111-1111-111111111125','Carlos Ramírez',           'carlos.spain@leidenschaft.com',     '+20 116 333 2244','student',   'A1',   'aaaaaaaa-0003-0000-0000-000000000001', now() - interval '12 days')
on conflict (id) do update set
  name = excluded.name, role = excluded.role,
  current_level = excluded.current_level,
  group_id = excluded.group_id, phone = excluded.phone;


-- ─── 5. LEVELS (base + sub-levels) ─────────────────────────────────────────────
delete from public.levels
where name in ('A1','A2','B1','B2')
  and parent_level_id is null
  and not exists (
    select 1 from public.levels child where child.parent_level_id = public.levels.id
  );

insert into public.levels (id, name, description, created_at) values
  ('bbbbbbbb-0001-0000-0000-000000000001','A1','Absolute Beginner — basic expressions',            now() - interval '60 days'),
  ('bbbbbbbb-0002-0000-0000-000000000001','A2','Elementary — everyday situations',                now() - interval '60 days'),
  ('bbbbbbbb-0003-0000-0000-000000000001','B1','Intermediate — familiar topics & travel',         now() - interval '60 days'),
  ('bbbbbbbb-0004-0000-0000-000000000001','B2','Upper-Intermediate — complex texts & fluency',    now() - interval '60 days')
on conflict (id) do update set
  name = excluded.name, description = excluded.description;

-- Sub-levels linked to instructors & groups
insert into public.levels (id, name, description, parent_level_id, instructor_id, group_id, created_at) values
  ('bbbbbbbb-0001-0000-0000-000000000002','A1.1','Introduction: alphabet, numbers & greetings',
   'bbbbbbbb-0001-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','aaaaaaaa-0001-0000-0000-000000000001', now() - interval '30 days'),
  ('bbbbbbbb-0001-0000-0000-000000000003','A1.2','Daily life, shopping & housing',
   'bbbbbbbb-0001-0000-0000-000000000001','22222222-2222-2222-2222-222222222222', null, now() - interval '30 days'),
  ('bbbbbbbb-0002-0000-0000-000000000002','A2.1','Travel, free time & appointments',
   'bbbbbbbb-0002-0000-0000-000000000001','22222222-2222-2222-2222-222222222222', null, now() - interval '28 days'),
  ('bbbbbbbb-0002-0000-0000-000000000003','A2.2','Business & professional life',
   'bbbbbbbb-0002-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','aaaaaaaa-0001-0000-0000-000000000002', now() - interval '25 days'),
  ('bbbbbbbb-0003-0000-0000-000000000002','B1.1','Conversation & fluency',
   'bbbbbbbb-0003-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','aaaaaaaa-0001-0000-0000-000000000003', now() - interval '22 days'),
  ('bbbbbbbb-0004-0000-0000-000000000002','B2.1','Medical German',
   'bbbbbbbb-0004-0000-0000-000000000001','22222222-2222-2222-2222-222222222226','aaaaaaaa-0001-0000-0000-000000000004', now() - interval '18 days'),
  ('bbbbbbbb-0001-0000-0000-000000000010','EN-A1','English A1 — Kids',
   null,'22222222-2222-2222-2222-222222222223','aaaaaaaa-0002-0000-0000-000000000001', now() - interval '22 days'),
  ('bbbbbbbb-0002-0000-0000-000000000010','EN-A2','English A2 — General',
   null,'22222222-2222-2222-2222-222222222223','aaaaaaaa-0002-0000-0000-000000000002', now() - interval '22 days'),
  ('bbbbbbbb-0003-0000-0000-000000000010','EN-B1','English B1 — IELTS Prep',
   null,'22222222-2222-2222-2222-222222222223','aaaaaaaa-0002-0000-0000-000000000003', now() - interval '20 days'),
  ('bbbbbbbb-0004-0000-0000-000000000010','EN-B2','English B2 — Business',
   null,'22222222-2222-2222-2222-222222222223','aaaaaaaa-0002-0000-0000-000000000004', now() - interval '15 days'),
  ('bbbbbbbb-0001-0000-0000-000000000020','AR-A1','Arabic A1 — Non-Native',
   null,'22222222-2222-2222-2222-222222222224','aaaaaaaa-0003-0000-0000-000000000001', now() - interval '28 days'),
  ('bbbbbbbb-0002-0000-0000-000000000020','AR-A2','Arabic A2 — Egyptian Dialect',
   null,'22222222-2222-2222-2222-222222222224','aaaaaaaa-0003-0000-0000-000000000002', now() - interval '24 days'),
  ('bbbbbbbb-0001-0000-0000-000000000030','FR-A1','French A1 — Beginner',
   null,'22222222-2222-2222-2222-222222222225','aaaaaaaa-0004-0000-0000-000000000001', now() - interval '26 days'),
  ('bbbbbbbb-0001-0000-0000-000000000040','ES-A1','Spanish A1 — Travel',
   null,'22222222-2222-2222-2222-222222222225','aaaaaaaa-0005-0000-0000-000000000001', now() - interval '26 days')
on conflict (id) do update set
  parent_level_id = excluded.parent_level_id,
  instructor_id = excluded.instructor_id,
  group_id = excluded.group_id,
  description = excluded.description;


-- ─── 6. INSTRUCTOR_GROUPS ──────────────────────────────────────────────────────
insert into public.instructor_groups (instructor_id, group_id, assigned_at) values
  ('22222222-2222-2222-2222-222222222222','aaaaaaaa-0001-0000-0000-000000000001', now() - interval '30 days'),
  ('22222222-2222-2222-2222-222222222222','aaaaaaaa-0001-0000-0000-000000000002', now() - interval '25 days'),
  ('22222222-2222-2222-2222-222222222222','aaaaaaaa-0001-0000-0000-000000000003', now() - interval '22 days'),
  ('22222222-2222-2222-2222-222222222226','aaaaaaaa-0001-0000-0000-000000000004', now() - interval '18 days'),
  ('22222222-2222-2222-2222-222222222223','aaaaaaaa-0002-0000-0000-000000000001', now() - interval '22 days'),
  ('22222222-2222-2222-2222-222222222223','aaaaaaaa-0002-0000-0000-000000000002', now() - interval '22 days'),
  ('22222222-2222-2222-2222-222222222223','aaaaaaaa-0002-0000-0000-000000000003', now() - interval '20 days'),
  ('22222222-2222-2222-2222-222222222223','aaaaaaaa-0002-0000-0000-000000000004', now() - interval '15 days'),
  ('22222222-2222-2222-2222-222222222224','aaaaaaaa-0003-0000-0000-000000000001', now() - interval '28 days'),
  ('22222222-2222-2222-2222-222222222224','aaaaaaaa-0003-0000-0000-000000000002', now() - interval '24 days'),
  ('22222222-2222-2222-2222-222222222225','aaaaaaaa-0004-0000-0000-000000000001', now() - interval '26 days'),
  ('22222222-2222-2222-2222-222222222225','aaaaaaaa-0005-0000-0000-000000000001', now() - interval '26 days')
on conflict (instructor_id, group_id) do nothing;


-- ─── 7. LEVEL_STUDENTS ─────────────────────────────────────────────────────────
insert into public.level_students (student_id, level_id, instructor_id, assigned_at) values
  ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0001-0000-0000-000000000002','22222222-2222-2222-2222-222222222222', now() - interval '30 days'),
  ('11111111-1111-1111-1111-111111111112','bbbbbbbb-0001-0000-0000-000000000002','22222222-2222-2222-2222-222222222222', now() - interval '28 days'),
  ('11111111-1111-1111-1111-111111111113','bbbbbbbb-0001-0000-0000-000000000002','22222222-2222-2222-2222-222222222222', now() - interval '28 days'),
  ('11111111-1111-1111-1111-111111111114','bbbbbbbb-0002-0000-0000-000000000003','22222222-2222-2222-2222-222222222222', now() - interval '25 days'),
  ('11111111-1111-1111-1111-111111111115','bbbbbbbb-0002-0000-0000-000000000003','22222222-2222-2222-2222-222222222222', now() - interval '24 days'),
  ('11111111-1111-1111-1111-111111111116','bbbbbbbb-0003-0000-0000-000000000010','22222222-2222-2222-2222-222222222223', now() - interval '22 days'),
  ('11111111-1111-1111-1111-111111111117','bbbbbbbb-0001-0000-0000-000000000010','22222222-2222-2222-2222-222222222223', now() - interval '21 days'),
  ('11111111-1111-1111-1111-111111111118','bbbbbbbb-0001-0000-0000-000000000030','22222222-2222-2222-2222-222222222225', now() - interval '20 days'),
  ('11111111-1111-1111-1111-111111111119','bbbbbbbb-0001-0000-0000-000000000040','22222222-2222-2222-2222-222222222225', now() - interval '20 days'),
  ('11111111-1111-1111-1111-111111111120','bbbbbbbb-0004-0000-0000-000000000010','22222222-2222-2222-2222-222222222223', now() - interval '18 days'),
  ('11111111-1111-1111-1111-111111111121','bbbbbbbb-0002-0000-0000-000000000003','22222222-2222-2222-2222-222222222222', now() - interval '17 days'),
  ('11111111-1111-1111-1111-111111111122','bbbbbbbb-0002-0000-0000-000000000003','22222222-2222-2222-2222-222222222222', now() - interval '16 days'),
  ('11111111-1111-1111-1111-111111111123','bbbbbbbb-0001-0000-0000-000000000010','22222222-2222-2222-2222-222222222223', now() - interval '15 days'),
  ('11111111-1111-1111-1111-111111111124','bbbbbbbb-0004-0000-0000-000000000002','22222222-2222-2222-2222-222222222226', now() - interval '14 days'),
  ('11111111-1111-1111-1111-111111111125','bbbbbbbb-0001-0000-0000-000000000020','22222222-2222-2222-2222-222222222224', now() - interval '12 days')
on conflict (student_id) do update set
  level_id = excluded.level_id, instructor_id = excluded.instructor_id;


-- ─── 8. LEVEL_SETTINGS + LEVEL_SESSIONS ────────────────────────────────────────
insert into public.level_settings (level_id, total_sessions, max_absences) values
  ('bbbbbbbb-0001-0000-0000-000000000002', 8, 2),
  ('bbbbbbbb-0002-0000-0000-000000000003', 10, 3),
  ('bbbbbbbb-0003-0000-0000-000000000010', 12, 3)
on conflict (level_id) do nothing;

insert into public.level_sessions (level_id, session_number, session_date) values
  ('bbbbbbbb-0001-0000-0000-000000000002', 1, current_date - 24),
  ('bbbbbbbb-0001-0000-0000-000000000002', 2, current_date - 21),
  ('bbbbbbbb-0001-0000-0000-000000000002', 3, current_date - 17),
  ('bbbbbbbb-0001-0000-0000-000000000002', 4, current_date - 14),
  ('bbbbbbbb-0001-0000-0000-000000000002', 5, current_date - 10),
  ('bbbbbbbb-0001-0000-0000-000000000002', 6, current_date - 7),
  ('bbbbbbbb-0001-0000-0000-000000000002', 7, current_date - 3),
  ('bbbbbbbb-0001-0000-0000-000000000002', 8, current_date + 4)
on conflict (level_id, session_number) do update set session_date = excluded.session_date;


-- ─── 9. ATTENDANCE ─────────────────────────────────────────────────────────────
insert into public.attendance (student_id, level_id, session_number, status, session_date) values
  ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0001-0000-0000-000000000002',1,'present', current_date - 24),
  ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0001-0000-0000-000000000002',2,'present', current_date - 21),
  ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0001-0000-0000-000000000002',3,'present', current_date - 17),
  ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0001-0000-0000-000000000002',4,'absent',  current_date - 14),
  ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0001-0000-0000-000000000002',5,'present', current_date - 10),
  ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0001-0000-0000-000000000002',6,'present', current_date - 7),
  ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0001-0000-0000-000000000002',7,'present', current_date - 3),
  ('11111111-1111-1111-1111-111111111112','bbbbbbbb-0001-0000-0000-000000000002',1,'present', current_date - 24),
  ('11111111-1111-1111-1111-111111111112','bbbbbbbb-0001-0000-0000-000000000002',2,'present', current_date - 21),
  ('11111111-1111-1111-1111-111111111113','bbbbbbbb-0001-0000-0000-000000000002',1,'present', current_date - 24),
  ('11111111-1111-1111-1111-111111111113','bbbbbbbb-0001-0000-0000-000000000002',2,'absent',  current_date - 21)
on conflict (student_id, level_id, session_number) do update set status = excluded.status;


-- ─── 10. MATERIALS + STUDENT_MATERIALS ─────────────────────────────────────────
insert into public.materials (id, title, description, file_url, level_id, created_at) values
  ('cccccccc-0001-0000-0000-000000000001','DE A1.1 Kursbuch Lektion 1-3',      'Grundwortschatz & Phonetik','materials/de_a1_1_kursbuch.pdf','bbbbbbbb-0001-0000-0000-000000000002', now() - interval '25 days'),
  ('cccccccc-0001-0000-0000-000000000002','DE A1.1 Audio: Begrüßung im Café',  'Hörübung Lektion 1',        'materials/de_a1_1_audio.mp3',   'bbbbbbbb-0001-0000-0000-000000000002', now() - interval '22 days'),
  ('cccccccc-0001-0000-0000-000000000003','DE A1.1 Grammatik: Artikel',        'Bestimmte & Unbestimmte',   'materials/de_a1_1_artikel.pdf', 'bbbbbbbb-0001-0000-0000-000000000002', now() - interval '18 days'),
  ('cccccccc-0001-0000-0000-000000000004','EN IELTS Reading Strategies',       'Academic reading skills',   'materials/en_ielts_reading.pdf','bbbbbbbb-0003-0000-0000-000000000010', now() - interval '15 days'),
  ('cccccccc-0001-0000-0000-000000000005','EN IELTS Writing Task 2 Templates','Essay structures for band 7+','materials/en_ielts_writing.pdf','bbbbbbbb-0003-0000-0000-000000000010', now() - interval '14 days'),
  ('cccccccc-0001-0000-0000-000000000006','AR A1 الحروف والتحيات',           'Arabic alphabet & greetings','materials/ar_a1_alphabet.pdf',  'bbbbbbbb-0001-0000-0000-000000000020', now() - interval '20 days'),
  ('cccccccc-0001-0000-0000-000000000007','AR A2 العامية المصرية',           'Egyptian dialect basics',   'materials/ar_a2_dialect.pdf',   'bbbbbbbb-0002-0000-0000-000000000020', now() - interval '18 days'),
  ('cccccccc-0001-0000-0000-000000000008','FR A1 Les Bases',                   'French basics for beginners','materials/fr_a1_basics.pdf',    'bbbbbbbb-0001-0000-0000-000000000030', now() - interval '22 days'),
  ('cccccccc-0001-0000-0000-000000000009','ES A1 Español para Viajar',         'Spanish for travelers',     'materials/es_a1_travel.pdf',    'bbbbbbbb-0001-0000-0000-000000000040', now() - interval '20 days'),
  ('cccccccc-0001-0000-0000-000000000010','DE B2 Medizinische Fachbegriffe',   'Medical terminology for B2', 'materials/de_b2_medical.pdf',  'bbbbbbbb-0004-0000-0000-000000000002', now() - interval '10 days')
on conflict (id) do update set title = excluded.title;

insert into public.student_materials (student_id, material_id, assigned_by, status, visible, notes, assigned_at) values
  ('11111111-1111-1111-1111-111111111111','cccccccc-0001-0000-0000-000000000001','33333333-3333-3333-3333-333333333333','assigned', true,'Main textbook for the module', now() - interval '25 days'),
  ('11111111-1111-1111-1111-111111111111','cccccccc-0001-0000-0000-000000000002','22222222-2222-2222-2222-222222222222','assigned', true,'Listen before session 4',      now() - interval '20 days'),
  ('11111111-1111-1111-1111-111111111111','cccccccc-0001-0000-0000-000000000003','22222222-2222-2222-2222-222222222222','assigned', true,'Important grammar reference',  now() - interval '18 days'),
  ('11111111-1111-1111-1111-111111111116','cccccccc-0001-0000-0000-000000000004','22222222-2222-2222-2222-222222222223','assigned', true,'IELTS reading practice',       now() - interval '15 days'),
  ('11111111-1111-1111-1111-111111111116','cccccccc-0001-0000-0000-000000000005','22222222-2222-2222-2222-222222222223','assigned', true,'Writing templates',            now() - interval '14 days'),
  ('11111111-1111-1111-1111-111111111125','cccccccc-0001-0000-0000-000000000006','22222222-2222-2222-2222-222222222224','assigned', true,'Arabic alphabet',              now() - interval '20 days'),
  ('11111111-1111-1111-1111-111111111114','cccccccc-0001-0000-0000-000000000007','22222222-2222-2222-2222-222222222224','assigned', true,'Egyptian dialect basics',      now() - interval '18 days'),
  ('11111111-1111-1111-1111-111111111118','cccccccc-0001-0000-0000-000000000008','22222222-2222-2222-2222-222222222225','assigned', true,'French basics',                now() - interval '22 days'),
  ('11111111-1111-1111-1111-111111111119','cccccccc-0001-0000-0000-000000000009','22222222-2222-2222-2222-222222222225','assigned', true,'Spanish for travel',           now() - interval '20 days'),
  ('11111111-1111-1111-1111-111111111124','cccccccc-0001-0000-0000-000000000010','22222222-2222-2222-2222-222222222226','assigned', true,'Medical terminology',          now() - interval '10 days')
on conflict (student_id, material_id) do update set status = excluded.status;


-- ─── 11. ASSIGNMENTS + GROUP_ASSIGNMENTS ───────────────────────────────────────
insert into public.assignments (id, title, description, level_id, deadline, audio_url, created_by, instructor_id, created_at) values
  ('eeeeeeee-0001-0000-0000-000000000001','Schreibaufgabe: Stellen Sie sich vor!',
   'Schreiben Sie einen kurzen Text über sich selbst (Name, Herkunft, Wohnort, Hobbys). Mindestens 6 Sätze.',
   'bbbbbbbb-0001-0000-0000-000000000002', now() - interval '12 days', null,
   '22222222-2222-2222-2222-222222222222','22222222-2222-2222-2222-222222222222', now() - interval '20 days'),
  ('eeeeeeee-0001-0000-0000-000000000002','IELTS Writing Task 2 Practice',
   'Write a 250-word essay on: "Some people believe technology has made our lives too complex." Discuss both views.',
   'bbbbbbbb-0003-0000-0000-000000000010', now() + interval '5 days', null,
   '22222222-2222-2222-2222-222222222223','22222222-2222-2222-2222-222222222223', now() - interval '7 days'),
  ('eeeeeeee-0001-0000-0000-000000000003','واجب العربية: تعريف بنفسك',
   'اكتب فقرة قصيرة عن نفسك: الاسم، الجنسية، العمل، وأهدافك في تعلم العربية.',
   'bbbbbbbb-0001-0000-0000-000000000020', now() + interval '6 days', null,
   '22222222-2222-2222-2222-222222222224','22222222-2222-2222-2222-222222222224', now() - interval '5 days'),
  ('eeeeeeee-0001-0000-0000-000000000004','Devoir de Français: Ma Famille',
   'Écrivez un paragraphe de 80 mots sur votre famille.',
   'bbbbbbbb-0001-0000-0000-000000000030', now() + interval '9 days', null,
   '22222222-2222-2222-2222-222222222225','22222222-2222-2222-2222-222222222225', now() - interval '3 days'),
  ('eeeeeeee-0001-0000-0000-000000000005','Tarea de Español: Mi Rutina Diaria',
   'Escribe una tarea de 100 palabras sobre tu rutina diaria.',
   'bbbbbbbb-0001-0000-0000-000000000040', now() + interval '8 days', null,
   '22222222-2222-2222-2222-222222222225','22222222-2222-2222-2222-222222222225', now() - interval '2 days')
on conflict (id) do update set title = excluded.title;

insert into public.group_assignments (group_id, assignment_id, assigned_at) values
  ('aaaaaaaa-0001-0000-0000-000000000001','eeeeeeee-0001-0000-0000-000000000001', now() - interval '20 days'),
  ('aaaaaaaa-0002-0000-0000-000000000003','eeeeeeee-0001-0000-0000-000000000002', now() - interval '7 days'),
  ('aaaaaaaa-0003-0000-0000-000000000001','eeeeeeee-0001-0000-0000-000000000003', now() - interval '5 days'),
  ('aaaaaaaa-0004-0000-0000-000000000001','eeeeeeee-0001-0000-0000-000000000004', now() - interval '3 days'),
  ('aaaaaaaa-0005-0000-0000-000000000001','eeeeeeee-0001-0000-0000-000000000005', now() - interval '2 days')
on conflict (group_id, assignment_id) do nothing;


-- ─── 12. SUBMISSIONS ───────────────────────────────────────────────────────────
insert into public.submissions (
  id, assignment_id, student_id, answer, audio_answer_url,
  grade, status, feedback, submitted_at
) values
  ('ffffffff-0001-0000-0000-000000000001',
   'eeeeeeee-0001-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111',
   'Guten Tag! Mein Name ist Max Mustermann. Ich komme aus Alexandria und wohne in Sidi Gaber. Ich bin Softwareentwickler von Beruf.',
   null,
   95.00,
   'graded',
   'Sehr gut geschrieben, Max! Der Satzbau ist fehlerfrei.',
   now() - interval '14 days'),

  ('ffffffff-0001-0000-0000-000000000002',
   'eeeeeeee-0001-0000-0000-000000000002',
   '11111111-1111-1111-1111-111111111116',
   'Technology has indeed simplified many aspects of our lives, but it has also introduced new complexities...',
   null,
   null,
   'submitted',
   null,
   now() - interval '1 day'),

  ('ffffffff-0001-0000-0000-000000000003',
   'eeeeeeee-0001-0000-0000-000000000003',
   '11111111-1111-1111-1111-111111111125',
   'اسمي كارلوس، أنا من إسبانيا وأعيش في القاهرة.',
   'submissions/11111111-1111-1111-1111-111111111125/arabic_intro.webm',
   null,
   'submitted',
   null,
   now() - interval '1 day')
on conflict (assignment_id, student_id) do update set
  status = excluded.status,
  answer = excluded.answer;


-- ─── 13. EXAMS + GROUP_EXAMS ───────────────────────────────────────────────────
insert into public.exams (id, title, level_id, duration, created_by, instructor_id, created_at) values
  ('10101010-0001-0000-0000-000000000001','DE A1.1 Zwischentest',         'bbbbbbbb-0001-0000-0000-000000000002', 45,'22222222-2222-2222-2222-222222222222','22222222-2222-2222-2222-222222222222', now() - interval '15 days'),
  ('10101010-0001-0000-0000-000000000002','EN IELTS Mock Test',           'bbbbbbbb-0003-0000-0000-000000000010', 90,'22222222-2222-2222-2222-222222222223','22222222-2222-2222-2222-222222222223', now() - interval '10 days'),
  ('10101010-0001-0000-0000-000000000003','AR A1 اختبار الحروف',         'bbbbbbbb-0001-0000-0000-000000000020', 30,'22222222-2222-2222-2222-222222222224','22222222-2222-2222-2222-222222222224', now() - interval '8 days')
on conflict (id) do update set title = excluded.title;

insert into public.group_exams (group_id, exam_id, assigned_at) values
  ('aaaaaaaa-0001-0000-0000-000000000001','10101010-0001-0000-0000-000000000001', now() - interval '15 days'),
  ('aaaaaaaa-0002-0000-0000-000000000003','10101010-0001-0000-0000-000000000002', now() - interval '10 days'),
  ('aaaaaaaa-0003-0000-0000-000000000001','10101010-0001-0000-0000-000000000003', now() - interval '8 days')
on conflict (group_id, exam_id) do nothing;


-- ─── 14. QUESTIONS ─────────────────────────────────────────────────────────────
insert into public.questions (id, exam_id, question_text, type, options, correct_answer, correct_answer_json, audio_url, content, extra_data, order_index) values
  ('20202020-0001-0000-0000-000000000001','10101010-0001-0000-0000-000000000001',
   'Wie heißt die Hauptstadt von Deutschland?','mcq',
   '["Berlin", "München", "Frankfurt", "Hamburg"]'::jsonb,'Berlin','"Berlin"'::jsonb,null,null,null,1),
  ('20202020-0001-0000-0000-000000000002','10101010-0001-0000-0000-000000000001',
   'Er _____ jeden Morgen um 7:00 Uhr auf.','grammar',
   '["steht", "stehe", "stehen", "stehst"]'::jsonb,'steht','"steht"'::jsonb,null,null,null,2),
  ('20202020-0001-0000-0000-000000000003','10101010-0001-0000-0000-000000000001',
   'Freies Schreiben: Mein Wochenende in Alexandria','writing',
   null,'',null,null,
   'Schreiben Sie 5 bis 7 Sätze: Was machen Sie gerne am Wochenende?',null,3),
  ('20202020-0001-0000-0000-000000000004','10101010-0001-0000-0000-000000000002',
   'Choose the correct word: "The government has decided to ___ the new policy."','mcq',
   '["implement", "imply", "implant", "import"]'::jsonb,'implement','"implement"'::jsonb,null,null,null,1),
  ('20202020-0001-0000-0000-000000000005','10101010-0001-0000-0000-000000000002',
   'IELTS Writing Task 2: Discuss both views and give your opinion.','writing',
   null,'',null,null,
   'Some people believe technology has made our lives too complex. To what extent do you agree?',null,2),
  ('20202020-0001-0000-0000-000000000006','10101010-0001-0000-0000-000000000003',
   'ما هو الحرف الأول في كلمة "كتاب"؟','mcq',
   '["ك", "ت", "ا", "ب"]'::jsonb,'ك','"ك"'::jsonb,null,null,null,1),
  ('20202020-0001-0000-0000-000000000007','10101010-0001-0000-0000-000000000003',
   'اكتب فقرة قصيرة تعرّف فيها بنفسك.','writing',
   null,'',null,null,'اكتب 5 جمل على الأقل عن نفسك.',null,2)
on conflict (id) do update set question_text = excluded.question_text;


-- ─── 15. EXAM_ANSWERS + RESULTS ────────────────────────────────────────────────
insert into public.exam_answers (student_id, exam_id, question_id, answer, is_correct, score, admin_grade, answer_status) values
  ('11111111-1111-1111-1111-111111111111','10101010-0001-0000-0000-000000000001','20202020-0001-0000-0000-000000000001',
   '"Berlin"'::jsonb, true, 100.0, 100.0, 'auto_graded'),
  ('11111111-1111-1111-1111-111111111111','10101010-0001-0000-0000-000000000001','20202020-0001-0000-0000-000000000002',
   '"steht"'::jsonb, true, 100.0, 100.0, 'auto_graded'),
  ('11111111-1111-1111-1111-111111111111','10101010-0001-0000-0000-000000000001','20202020-0001-0000-0000-000000000003',
   '"Am Wochenende gehe ich gerne mit Freunden am Meer spazieren."'::jsonb,
   null, null, null, 'pending'),
  ('11111111-1111-1111-1111-111111111116','10101010-0001-0000-0000-000000000002','20202020-0001-0000-0000-000000000004',
   '"implement"'::jsonb, true, 100.0, 100.0, 'auto_graded'),
  ('11111111-1111-1111-1111-111111111125','10101010-0001-0000-0000-000000000003','20202020-0001-0000-0000-000000000006',
   '"ك"'::jsonb, true, 100.0, 100.0, 'auto_graded')
on conflict (student_id, exam_id, question_id) do update set is_correct = excluded.is_correct;

insert into public.results (student_id, exam_id, score, passed, review_status, taken_at) values
  ('11111111-1111-1111-1111-111111111111','10101010-0001-0000-0000-000000000001', 95.00, true,  'pending_review', now() - interval '15 days'),
  ('11111111-1111-1111-1111-111111111116','10101010-0001-0000-0000-000000000002', 88.00, true,  'completed',      now() - interval '10 days'),
  ('11111111-1111-1111-1111-111111111125','10101010-0001-0000-0000-000000000003', 92.00, true,  'completed',      now() - interval '8 days')
on conflict (student_id, exam_id) do update set score = excluded.score, passed = excluded.passed;


-- ─── 16. WEBSITE SPACES + EVENTS + BOOKINGS ────────────────────────────────────
insert into public.website_spaces (id, title, description, category, image_path, order_index) values
  ('30303030-0001-0000-0000-000000000001','Vienna Language Lounge',    'Cozy study area with German literature and coffee',      'Lounge',      'public-assets/spaces/vienna_lounge.jpg', 1),
  ('30303030-0001-0000-0000-000000000002','Berlin Collaboration Lab',  'Fully equipped media room with smart boards',            'Studio',      'public-assets/spaces/berlin_lab.jpg',    2),
  ('30303030-0001-0000-0000-000000000003','Cairo Arabic Corner',       'Arabic learning space with calligraphy and culture',     'Cultural',    'public-assets/spaces/cairo_arabic.jpg',  3),
  ('30303030-0001-0000-0000-000000000004','Paris Reading Nook',        'French literature and quiet reading area',               'Quiet Zone',  'public-assets/spaces/paris_nook.jpg',    4)
on conflict (id) do update set title = excluded.title;

insert into public.website_events (id, title, description, starts_at, ends_at, location, type, image_path, capacity, price, is_active) values
  ('40404040-0001-0000-0000-000000000001','Kaffee & Konversation (German)',
   'Open conversation circle for all levels (A1-C1).',
   now() + interval '5 days' + interval '18 hours',
   now() + interval '5 days' + interval '21 hours',
   'Leidenschaft Klub — Portsaid St 261, Cleopatra','Cultural & Speaking',
   'public-assets/events/kaffee_stammtisch.jpg',30,'Free for enrolled students', true),
  ('40404040-0001-0000-0000-000000000002','English Debate Night',
   'Practice English through structured debates on current topics.',
   now() + interval '10 days' + interval '19 hours',
   now() + interval '10 days' + interval '22 hours',
   'Berlin Collaboration Lab','Debate & Speaking',
   'public-assets/events/english_debate.jpg',25,'Free', true),
  ('40404040-0001-0000-0000-000000000003','أمسية عربية: الشعر والثقافة',
   'أمسية ثقافية للتعرف على الشعر العربي والحوار بالعربية.',
   now() + interval '14 days' + interval '19 hours',
   now() + interval '14 days' + interval '22 hours',
   'Cairo Arabic Corner','Cultural & Poetry',
   'public-assets/events/arabic_poetry.jpg',40,'Free', true)
on conflict (id) do update set title = excluded.title;

insert into public.website_event_bookings (id, event_id, user_id, name, email, seats, created_at) values
  ('50505050-0001-0000-0000-000000000001','40404040-0001-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','Max Mustermann','student.demo@leidenschaft.com',1, now() - interval '2 days'),
  ('50505050-0001-0000-0000-000000000002','40404040-0001-0000-0000-000000000002','11111111-1111-1111-1111-111111111116','Merve Yılmaz',  'merve.turkey@leidenschaft.com', 1, now() - interval '1 day'),
  ('50505050-0001-0000-0000-000000000003','40404040-0001-0000-0000-000000000003','11111111-1111-1111-1111-111111111125','Carlos Ramírez','carlos.spain@leidenschaft.com',2, now() - interval '1 day')
on conflict (id) do nothing;


-- ─── 17. NOTIFICATIONS ─────────────────────────────────────────────────────────
insert into public.notifications (id, user_id, type, title, message, is_read, priority, target_level, is_active, created_by, created_at) values
  ('60606060-0001-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','announcement',
   'Willkommen bei Leidenschaft Klub!','Ihr A1.1-Kurs hat begonnen. Prüfen Sie Ihren Lehrplan.',
   true,'high','all',true,'44444444-4444-4444-4444-444444444444', now() - interval '25 days'),
  ('60606060-0001-0000-0000-000000000002','11111111-1111-1111-1111-111111111111','material',
   'Neues Material verfügbar','Das Audio-Material "Begrüßung im Café" wurde freigeschaltet.',
   true,'medium','A1.1',true,'22222222-2222-2222-2222-222222222222', now() - interval '20 days'),
  ('60606060-0001-0000-0000-000000000003','11111111-1111-1111-1111-111111111116','assignment',
   'IELTS Writing Task Due','Your IELTS Writing Task 2 is due in 5 days.',
   false,'high','all',true,'22222222-2222-2222-2222-222222222223', now() - interval '1 day'),
  ('60606060-0001-0000-0000-000000000004','11111111-1111-1111-1111-111111111125','announcement',
   'أهلاً بك في نادي شغف','بدأ كورس اللغة العربية A1. تحقق من موادك.',
   false,'high','all',true,'22222222-2222-2222-2222-222222222224', now() - interval '12 days'),
  ('60606060-0001-0000-0000-000000000005','11111111-1111-1111-1111-111111111118','announcement',
   'Bienvenue au Club Leidenschaft','Votre cours de français A1 a commencé.',
   false,'medium','all',true,'22222222-2222-2222-2222-222222222225', now() - interval '20 days'),
  ('60606060-0001-0000-0000-000000000006','11111111-1111-1111-1111-111111111119','announcement',
   '¡Bienvenido al Club Leidenschaft!','Tu curso de español A1 ha comenzado.',
   false,'medium','all',true,'22222222-2222-2222-2222-222222222225', now() - interval '20 days'),
  ('60606060-0001-0000-0000-000000000007','22222222-2222-2222-2222-222222222222','submission',
   'Neue Einreichung zur Korrektur','Max Mustermann hat eine Aufgabe eingereicht.',
   false,'high','all',true,'11111111-1111-1111-1111-111111111111', now() - interval '1 day'),
  ('60606060-0001-0000-0000-000000000008','33333333-3333-3333-3333-333333333333','event',
   'Neue Veranstaltungsbuchung','Eine neue Anmeldung für "Kaffee & Konversation" ist eingegangen.',
   false,'medium','all',true,'44444444-4444-4444-4444-444444444444', now() - interval '1 day')
on conflict (id) do nothing;


-- ─── 18. VERIFY ────────────────────────────────────────────────────────────────
select 'auth.users'       as tbl, count(*) from auth.users where id::text like '11111111-%' or id::text like '22222222-%' or id::text like '33333333-%' or id::text like '44444444-%'
union all select 'auth.identities', count(*) from auth.identities where user_id::text like '11111111-%' or user_id::text like '22222222-%' or user_id::text like '33333333-%' or user_id::text like '44444444-%'
union all select 'profiles',        count(*) from public.profiles
union all select 'groups',          count(*) from public.groups
union all select 'levels',          count(*) from public.levels
union all select 'level_students',  count(*) from public.level_students
union all select 'materials',       count(*) from public.materials
union all select 'assignments',     count(*) from public.assignments
union all select 'submissions',     count(*) from public.submissions
union all select 'exams',           count(*) from public.exams
union all select 'questions',       count(*) from public.questions
union all select 'exam_answers',    count(*) from public.exam_answers
union all select 'results',         count(*) from public.results
union all select 'attendance',      count(*) from public.attendance
union all select 'notifications',   count(*) from public.notifications
union all select 'website_events',  count(*) from public.website_events;
