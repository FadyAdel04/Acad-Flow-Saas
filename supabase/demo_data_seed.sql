-- ==============================================================================
-- LEIDENSCHAFT KLUB LMS — COMPREHENSIVE REALISTIC DEMO DATASET
-- Project: https://dikaqxsubzaqshwirsdh.supabase.co
-- Run this in: Supabase Dashboard → SQL Editor
--
-- DEDICATED DEMO ACCOUNTS (Password for all: Demo12345!):
-- 1. Student Demo:    student.demo@leidenschaft.com
-- 2. Instructor Demo: instructor.demo@leidenschaft.com
-- 3. Secretary Demo:  secretary.demo@leidenschaft.com
-- 4. Admin Demo:      admin.demo@leidenschaft.com
-- ==============================================================================

create extension if not exists pgcrypto;

-- ─── 1. AUTH USERS (Allows real logins for all 4 roles) ────────────────────────
-- Password hash for 'Demo12345!' using blowfish crypt
do $$
declare
  pw_hash text := crypt('Demo12345!', gen_salt('bf'));
begin
  -- 1.1 Student Demo
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, phone_change, phone_change_token, reauthentication_token,
    is_sso_user, created_at, updated_at
  ) values (
    '11111111-1111-1111-1111-111111111111'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'student.demo@leidenschaft.com',
    pw_hash,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Max Mustermann","role":"student","phone":"+20 100 123 4567"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '',
    false, now(), now()
  ) on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    email_change_token_current = '',
    phone_change = '',
    phone_change_token = '',
    reauthentication_token = '',
    is_sso_user = false;

  -- 1.2 Instructor Demo
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, phone_change, phone_change_token, reauthentication_token,
    is_sso_user, created_at, updated_at
  ) values (
    '22222222-2222-2222-2222-222222222222'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'instructor.demo@leidenschaft.com',
    pw_hash,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Herr Thomas Müller","role":"instructor","phone":"+20 101 234 5678"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '',
    false, now(), now()
  ) on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    email_change_token_current = '',
    phone_change = '',
    phone_change_token = '',
    reauthentication_token = '',
    is_sso_user = false;

  -- 1.3 Secretary Demo
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, phone_change, phone_change_token, reauthentication_token,
    is_sso_user, created_at, updated_at
  ) values (
    '33333333-3333-3333-3333-333333333333'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'secretary.demo@leidenschaft.com',
    pw_hash,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Frau Sarah Schmidt","role":"secretary","phone":"+20 102 345 6789"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '',
    false, now(), now()
  ) on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    email_change_token_current = '',
    phone_change = '',
    phone_change_token = '',
    reauthentication_token = '',
    is_sso_user = false;

  -- 1.4 Admin Demo
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, role, aud,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, phone_change, phone_change_token, reauthentication_token,
    is_sso_user, created_at, updated_at
  ) values (
    '44444444-4444-4444-4444-444444444444'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'admin.demo@leidenschaft.com',
    pw_hash,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Dr. Klaus Weber (Admin)","role":"admin","phone":"+20 15 15638830"}'::jsonb,
    'authenticated', 'authenticated',
    '', '', '', '', '', '', '', '',
    false, now(), now()
  ) on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    email_change_token_current = '',
    phone_change = '',
    phone_change_token = '',
    reauthentication_token = '',
    is_sso_user = false;

  -- Ensure identities exist for GoTrue email logins
  delete from auth.identities where user_id in (
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid
  );

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  ) values
    ('11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'::uuid, '{"sub":"11111111-1111-1111-1111-111111111111","email":"student.demo@leidenschaft.com"}'::jsonb, 'email', '11111111-1111-1111-1111-111111111111', now(), now(), now()),
    ('22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222'::uuid, '{"sub":"22222222-2222-2222-2222-222222222222","email":"instructor.demo@leidenschaft.com"}'::jsonb, 'email', '22222222-2222-2222-2222-222222222222', now(), now(), now()),
    ('33333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333'::uuid, '{"sub":"33333333-3333-3333-3333-333333333333","email":"secretary.demo@leidenschaft.com"}'::jsonb, 'email', '33333333-3333-3333-3333-333333333333', now(), now(), now()),
    ('44444444-4444-4444-4444-444444444444', '44444444-4444-4444-4444-444444444444'::uuid, '{"sub":"44444444-4444-4444-4444-444444444444","email":"admin.demo@leidenschaft.com"}'::jsonb, 'email', '44444444-4444-4444-4444-444444444444', now(), now(), now())
  on conflict do nothing;
end $$;

-- ─── 2. GROUPS ─────────────────────────────────────────────────────────────────
insert into public.groups (id, name, level, description, created_at) values
  ('aaaaaaaa-0001-0000-0000-000000000001', 'A1.1 Abendgruppe (Mo & Mi)', 'A1.1', 'Standard Abendkurs für Deutsch-Anfänger (18:00 - 20:30)', now() - interval '30 days'),
  ('aaaaaaaa-0001-0000-0000-000000000002', 'A2.2 Intensivkurs (Di & Do)', 'A2.2', 'Zweimonatiger Intensivkurs für das A2-Zertifikat', now() - interval '25 days'),
  ('aaaaaaaa-0001-0000-0000-000000000003', 'B1 Konversationsklub',       'B1',   'Freies Sprechen, Diskussionen und Wortschatzerweiterung', now() - interval '20 days')
on conflict (id) do update set
  name = excluded.name,
  level = excluded.level,
  description = excluded.description;

-- ─── 3. PROFILES ───────────────────────────────────────────────────────────────
insert into public.profiles (id, name, email, phone, role, current_level, group_id, created_at) values
  ('44444444-4444-4444-4444-444444444444', 'Dr. Klaus Weber (Admin)',   'admin.demo@leidenschaft.com',      '+20 15 15638830', 'admin',      'B2',   null,                                   now() - interval '60 days'),
  ('33333333-3333-3333-3333-333333333333', 'Frau Sarah Schmidt',        'secretary.demo@leidenschaft.com',  '+20 102 345 6789', 'secretary',  'B1',   null,                                   now() - interval '50 days'),
  ('22222222-2222-2222-2222-222222222222', 'Herr Thomas Müller',        'instructor.demo@leidenschaft.com', '+20 101 234 5678', 'instructor', 'B2',   'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '45 days'),
  ('11111111-1111-1111-1111-111111111111', 'Max Mustermann',            'student.demo@leidenschaft.com',    '+20 100 123 4567', 'student',    'A1.1', 'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '30 days'),
  ('11111111-1111-1111-1111-111111111112', 'Anna Becker',               'anna.student@leidenschaft.com',    '+20 103 456 7890', 'student',    'A1.1', 'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '28 days'),
  ('11111111-1111-1111-1111-111111111113', 'Lukas Fischer',             'lukas.student@leidenschaft.com',   '+20 104 567 8901', 'student',    'A1.1', 'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '28 days')
on conflict (id) do update set
  name = excluded.name,
  role = excluded.role,
  current_level = excluded.current_level,
  group_id = excluded.group_id,
  phone = excluded.phone;

-- ─── 4. LEVELS & SUB-LEVELS ────────────────────────────────────────────────────
-- Base Levels
insert into public.levels (id, name, description, created_at) values
  ('bbbbbbbb-0001-0000-0000-000000000001', 'A1', 'Absolute Anfänger — Grundlegende Ausdrücke & Vorstellungen', now() - interval '60 days'),
  ('bbbbbbbb-0002-0000-0000-000000000001', 'A2', 'Grundlegende Kenntnisse — Alltägliche Situationen & Familie', now() - interval '60 days'),
  ('bbbbbbbb-0003-0000-0000-000000000001', 'B1', 'Fortgeschrittene Sprachverwendung — Beruf, Reisen & Freizeit', now() - interval '60 days'),
  ('bbbbbbbb-0004-0000-0000-000000000001', 'B2', 'Selbstständige Sprachverwendung — Komplexe Fachthemen & Diskussionen', now() - interval '60 days')
on conflict (name) do update set description = excluded.description;

-- Sub-Levels linked to Parent Levels and Instructor/Group
insert into public.levels (id, name, description, parent_level_id, instructor_id, group_id, created_at) values
  ('bbbbbbbb-0001-0000-0000-000000000002', 'A1.1', 'Einführung in das Deutsche: Alphabet, Zahlen & Begrüßung',
   'bbbbbbbb-0001-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '30 days'),
  ('bbbbbbbb-0001-0000-0000-000000000003', 'A1.2', 'Alltag, Einkaufen, Wohnen & Uhrzeiten',
   'bbbbbbbb-0001-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', null, now() - interval '30 days'),
  ('bbbbbbbb-0002-0000-0000-000000000002', 'A2.1', 'Reisen, Freizeitgestaltung und Termine vereinbaren',
   'bbbbbbbb-0002-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', null, now() - interval '30 days'),
  ('bbbbbbbb-0002-0000-0000-000000000003', 'A2.2', 'Berufsalltag, Gesundheit & Lebensläufe',
   'bbbbbbbb-0002-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0001-0000-0000-000000000002', now() - interval '30 days')
on conflict (name) do update set
  parent_level_id = excluded.parent_level_id,
  instructor_id = excluded.instructor_id,
  group_id = excluded.group_id;

-- ─── 5. INSTRUCTOR_GROUPS & LEVEL_STUDENTS ─────────────────────────────────────
insert into public.instructor_groups (instructor_id, group_id, assigned_at) values
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0001-0000-0000-000000000001', now() - interval '30 days'),
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0001-0000-0000-000000000002', now() - interval '25 days')
on conflict (instructor_id, group_id) do nothing;

-- Active Level Enrollments
insert into public.level_students (student_id, level_id, instructor_id, assigned_at) values
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0001-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', now() - interval '30 days'),
  ('11111111-1111-1111-1111-111111111112', 'bbbbbbbb-0001-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', now() - interval '28 days'),
  ('11111111-1111-1111-1111-111111111113', 'bbbbbbbb-0001-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', now() - interval '28 days')
on conflict (student_id) do update set
  level_id = excluded.level_id,
  instructor_id = excluded.instructor_id;

-- ─── 6. SESSIONS, SETTINGS & ATTENDANCE ────────────────────────────────────────
insert into public.level_settings (level_id, total_sessions, max_absences) values
  ('bbbbbbbb-0001-0000-0000-000000000002', 8, 2)
on conflict (level_id) do nothing;

-- 8 Schedule Sessions for A1.1
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

-- Attendance History for Student Demo (7 present, 1 absent -> 87.5% attendance)
insert into public.attendance (student_id, level_id, session_number, status, session_date) values
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0001-0000-0000-000000000002', 1, 'present', current_date - 24),
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0001-0000-0000-000000000002', 2, 'present', current_date - 21),
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0001-0000-0000-000000000002', 3, 'present', current_date - 17),
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0001-0000-0000-000000000002', 4, 'absent',  current_date - 14),
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0001-0000-0000-000000000002', 5, 'present', current_date - 10),
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0001-0000-0000-000000000002', 6, 'present', current_date - 7),
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0001-0000-0000-000000000002', 7, 'present', current_date - 3)
on conflict (student_id, level_id, session_number) do update set status = excluded.status;

-- Classmate attendance
insert into public.attendance (student_id, level_id, session_number, status, session_date) values
  ('11111111-1111-1111-1111-111111111112', 'bbbbbbbb-0001-0000-0000-000000000002', 1, 'present', current_date - 24),
  ('11111111-1111-1111-1111-111111111112', 'bbbbbbbb-0001-0000-0000-000000000002', 2, 'present', current_date - 21),
  ('11111111-1111-1111-1111-111111111112', 'bbbbbbbb-0001-0000-0000-000000000002', 3, 'present', current_date - 17),
  ('11111111-1111-1111-1111-111111111113', 'bbbbbbbb-0001-0000-0000-000000000002', 1, 'present', current_date - 24),
  ('11111111-1111-1111-1111-111111111113', 'bbbbbbbb-0001-0000-0000-000000000002', 2, 'absent',  current_date - 21)
on conflict do nothing;

-- ─── 7. MATERIALS & STUDENT MATERIALS ──────────────────────────────────────────
insert into public.materials (id, title, description, file_url, level_id, created_at) values
  ('cccccccc-0001-0000-0000-000000000001', 'A1.1 Kursbuch Lektion 1-3 (PDF)', 'Grundwortschatz, Begrüßungen & deutsche Phonetik', 'materials/a1_1_kursbuch_lektion_1_3.pdf', 'bbbbbbbb-0001-0000-0000-000000000002', now() - interval '25 days'),
  ('cccccccc-0001-0000-0000-000000000002', 'Audio-Übung: Begrüßung im Café', 'Hörübung für Lektion 1 zur Verbesserung der Aussprache', 'materials/audio_dialog_lektion1.mp3', 'bbbbbbbb-0001-0000-0000-000000000002', now() - interval '22 days'),
  ('cccccccc-0001-0000-0000-000000000003', 'Grammatiktabelle: Bestimmte & Unbestimmte Artikel', 'Übersichtstabelle der Artikel im Nominativ und Akkusativ', 'materials/grammatik_artikel_tabelle.pdf', 'bbbbbbbb-0001-0000-0000-000000000002', now() - interval '18 days'),
  ('cccccccc-0001-0000-0000-000000000004', 'Vokabelliste: Familie & Berufe (Revision)', 'Wiederholungsmaterial für den Übergang zu A1.2', 'materials/wortschatz_familie_berufe.pdf', 'bbbbbbbb-0001-0000-0000-000000000001', now() - interval '10 days')
on conflict (id) do update set title = excluded.title;

-- Material assignments (Active + Revision status)
insert into public.student_materials (id, student_id, material_id, assigned_by, status, visible, notes, assigned_at) values
  ('dddddddd-0001-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'cccccccc-0001-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 'assigned', true, 'Hauptlehrwerk für das laufende Modul', now() - interval '25 days'),
  ('dddddddd-0001-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'cccccccc-0001-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'assigned', true, 'Bitte vor Sitzung 4 anhören', now() - interval '20 days'),
  ('dddddddd-0001-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'cccccccc-0001-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'assigned', true, 'Wichtige Grammatikreferenz', now() - interval '18 days'),
  ('dddddddd-0001-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'cccccccc-0001-0000-0000-000000000004', '33333333-3333-3333-3333-333333333333', 'revision', true, 'Wiederholungsmaterial aus Einführungstagen', now() - interval '10 days')
on conflict (student_id, material_id) do update set status = excluded.status;

-- ─── 8. ASSIGNMENTS, SUBMISSIONS & GRADING ─────────────────────────────────────
insert into public.assignments (id, title, description, level_id, deadline, audio_url, created_by, instructor_id, created_at) values
  ('eeeeeeee-0001-0000-0000-000000000001',
   'Schreibaufgabe: Stellen Sie sich vor!',
   'Schreiben Sie einen kurzen Text über sich selbst (Name, Herkunft, Wohnort, Hobbys). Mindestens 6 Sätze.',
   'bbbbbbbb-0001-0000-0000-000000000002',
   now() - interval '12 days',
   null,
   '22222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   now() - interval '20 days'),

  ('eeeeeeee-0001-0000-0000-000000000002',
   'Hör- & Sprechaufgabe: Mein Tagesablauf',
   'Hören Sie den Audiodialog an und nehmen Sie eine kurze Sprachnachricht (1-2 Min.) über Ihren typischen Tagesablauf auf.',
   'bbbbbbbb-0001-0000-0000-000000000002',
   now() + interval '3 days',
   'materials/audio_dialog_lektion1.mp3',
   '22222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   now() - interval '7 days'),

  ('eeeeeeee-0001-0000-0000-000000000003',
   'Grammatikübung: Verben im Präsens konjugieren',
   'Ergänzen Sie die Lückensätze mit der korrekten Verbform (sein, haben, wohnen, lernen, sprechen).',
   'bbbbbbbb-0001-0000-0000-000000000002',
   now() + interval '8 days',
   null,
   '22222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   now() - interval '3 days')
on conflict (id) do update set title = excluded.title;

insert into public.group_assignments (group_id, assignment_id, assigned_at) values
  ('aaaaaaaa-0001-0000-0000-000000000001', 'eeeeeeee-0001-0000-0000-000000000001', now() - interval '20 days'),
  ('aaaaaaaa-0001-0000-0000-000000000001', 'eeeeeeee-0001-0000-0000-000000000002', now() - interval '7 days'),
  ('aaaaaaaa-0001-0000-0000-000000000001', 'eeeeeeee-0001-0000-0000-000000000003', now() - interval '3 days')
on conflict (group_id, assignment_id) do nothing;

-- Submissions for Student Demo:
-- 1. Graded submission (score 95/100)
insert into public.submissions (id, assignment_id, student_id, answer, grade, status, feedback, submitted_at) values
  ('ffffffff-0001-0000-0000-000000000001',
   'eeeeeeee-0001-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111',
   'Guten Tag! Mein Name ist Max Mustermann. Ich komme aus Alexandria und wohne in Sidi Gaber. Ich bin Softwareentwickler von Beruf. In meiner Freizeit spiele ich gerne Fußball und lerne Deutsch bei Leidenschaft Klub.',
   95.00,
   'graded',
   'Sehr gut geschrieben, Max! Der Satzbau ist fehlerfrei und der Wortschatz passt genau zum Niveau A1.1. Weiter so!',
   now() - interval '14 days')
on conflict (assignment_id, student_id) do update set
  grade = excluded.grade,
  status = excluded.status,
  feedback = excluded.feedback;

-- 2. Pending submission (Ready for Instructor Demo to review and grade!)
insert into public.submissions (id, assignment_id, student_id, answer, audio_answer_url, grade, status, submitted_at) values
  ('ffffffff-0001-0000-0000-000000000002',
   'eeeeeeee-0001-0000-0000-000000000002',
   '11111111-1111-1111-1111-111111111111',
   'Hier ist meine Audioantwort über meinen Tagesablauf. Morgens stehe ich um 7 Uhr auf, trinke Kaffee und fahre zur Arbeit. Abends besuche ich den Deutschkurs.',
   'submissions/11111111-1111-1111-1111-111111111111/audio_aufnahme_tagesablauf.webm',
   null,
   'submitted',
   now() - interval '1 day')
on conflict (assignment_id, student_id) do update set
  status = excluded.status;

-- ─── 9. EXAMS, QUESTIONS, ANSWERS & RESULTS ────────────────────────────────────
insert into public.exams (id, title, level_id, duration, created_by, instructor_id, created_at) values
  ('10101010-0001-0000-0000-000000000001', 'A1.1 Zwischentest (Lektion 1-2)', 'bbbbbbbb-0001-0000-0000-000000000002', 45, '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', now() - interval '15 days'),
  ('10101010-0001-0000-0000-000000000002', 'A1.1 Abschlusstest: Grammatik & Freies Schreiben', 'bbbbbbbb-0001-0000-0000-000000000002', 60, '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', now() - interval '5 days')
on conflict (id) do update set title = excluded.title;

insert into public.group_exams (group_id, exam_id, assigned_at) values
  ('aaaaaaaa-0001-0000-0000-000000000001', '10101010-0001-0000-0000-000000000001', now() - interval '15 days'),
  ('aaaaaaaa-0001-0000-0000-000000000001', '10101010-0001-0000-0000-000000000002', now() - interval '5 days')
on conflict (group_id, exam_id) do nothing;

-- Rich Multi-Type Exam Questions (MCQ, Grammar, Listening, Paragraph True/False, Writing)
insert into public.questions (id, exam_id, question_text, type, options, correct_answer, correct_answer_json, audio_url, content, extra_data, order_index) values
  -- Question 1: MCQ
  ('20202020-0001-0000-0000-000000000001', '10101010-0001-0000-0000-000000000001',
   'Wie heißt die Hauptstadt von Deutschland?',
   'mcq', '["Berlin", "München", "Frankfurt", "Hamburg"]'::jsonb,
   'Berlin', '"Berlin"'::jsonb, null, null, null, 1),

  -- Question 2: Grammar
  ('20202020-0001-0000-0000-000000000002', '10101010-0001-0000-0000-000000000001',
   'Er _____ jeden Morgen um 7:00 Uhr auf.',
   'grammar', '["steht", "stehe", "stehen", "stehst"]'::jsonb,
   'steht', '"steht"'::jsonb, null, null, null, 2),

  -- Question 3: Listening
  ('20202020-0001-0000-0000-000000000003', '10101010-0001-0000-0000-000000000001',
   'Hören Sie das Gespräch: Was bestellt Herr Müller im Café?',
   'listening', '["Einen Kaffee und ein Stück Kuchen", "Einen Orangensaft", "Nur Wasser", "Einen Tee"]'::jsonb,
   'Einen Kaffee und ein Stück Kuchen', '"Einen Kaffee und ein Stück Kuchen"'::jsonb,
   'materials/audio_dialog_lektion1.mp3', null, null, 3),

  -- Questions for Exam 2 (with Writing & Paragraph)
  -- Question 4: Paragraph True/False
  ('20202020-0001-0000-0000-000000000004', '10101010-0001-0000-0000-000000000002',
   'Frau Schneider arbeitet seit fünf Jahren an der Universität in Kairo.',
   'paragraph', '["Richtig", "Falsch"]'::jsonb,
   'false', 'false'::jsonb, null,
   'Frau Schneider ist Lehrerin. Sie wohnt seit drei Jahren in Alexandria und unterrichtet Deutsch an einem Sprachinstitut.',
   '{"subtype":"boolean"}'::jsonb, 1),

  -- Question 5: Writing (Requires manual grading by instructor/admin)
  ('20202020-0001-0000-0000-000000000005', '10101010-0001-0000-0000-000000000002',
   'Freies Schreiben: Mein Wochenende in Alexandria',
   'writing', null, '', null, null,
   'Schreiben Sie 5 bis 7 Sätze: Was machen Sie gerne am Wochenende? Mit wem verbringen Sie Zeit? Wo gehen Sie essen?',
   null, 2)
on conflict (id) do update set question_text = excluded.question_text;

-- Answers for Exam 1 (Auto-graded)
insert into public.exam_answers (student_id, exam_id, question_id, answer, is_correct, score, admin_grade, answer_status) values
  ('11111111-1111-1111-1111-111111111111', '10101010-0001-0000-0000-000000000001', '20202020-0001-0000-0000-000000000001', '"Berlin"'::jsonb, true, 100.0, 100.0, 'auto_graded'),
  ('11111111-1111-1111-1111-111111111111', '10101010-0001-0000-0000-000000000002', '20202020-0001-0000-0000-000000000002', '"steht"'::jsonb, true, 100.0, 100.0, 'auto_graded'),
  ('11111111-1111-1111-1111-111111111111', '10101010-0001-0000-0000-000000000003', '20202020-0001-0000-0000-000000000003', '"Einen Kaffee und ein Stück Kuchen"'::jsonb, true, 100.0, 100.0, 'auto_graded')
on conflict (student_id, exam_id, question_id) do update set is_correct = excluded.is_correct;

-- Answers for Exam 2 (Has Writing pending manual review!)
insert into public.exam_answers (student_id, exam_id, question_id, answer, is_correct, score, admin_grade, answer_status) values
  ('11111111-1111-1111-1111-111111111111', '10101010-0001-0000-0000-000000000002', '20202020-0001-0000-0000-000000000004', 'false'::jsonb, true, 100.0, 100.0, 'auto_graded'),
  ('11111111-1111-1111-1111-111111111111', '10101010-0001-0000-0000-000000000005', '"Am Wochenende gehe ich gerne mit Freunden am Meer spazieren. Wir frühstücken in einem kleinen Restaurant an der Corniche. Nachmittags lerne ich neue Vokabeln für meinen Deutschkurs. Am Sonntag besuche ich meine Großeltern."'::jsonb, null, null, null, 'pending')
on conflict (student_id, exam_id, question_id) do update set answer_status = excluded.answer_status;

-- Results Records:
-- Exam 1: 100% Passed
insert into public.results (student_id, exam_id, score, passed, review_status, taken_at) values
  ('11111111-1111-1111-1111-111111111111', '10101010-0001-0000-0000-000000000001', 100.00, true, 'completed', now() - interval '15 days')
on conflict (student_id, exam_id) do update set score = excluded.score, passed = excluded.passed;

-- Exam 2: Pending Review (Writing section awaiting manual instructor evaluation)
insert into public.results (student_id, exam_id, score, passed, review_status, taken_at) values
  ('11111111-1111-1111-1111-111111111111', '10101010-0001-0000-0000-000000000002', null, false, 'pending_review', now() - interval '1 day')
on conflict (student_id, exam_id) do update set review_status = excluded.review_status, score = excluded.score;

-- ─── 10. WEBSITE SPACES, EVENTS & BOOKINGS ─────────────────────────────────────
insert into public.website_spaces (id, title, description, category, image_path, order_index) values
  ('30303030-0001-0000-0000-000000000001', 'Vienna Language Lounge', 'Gemütlicher Lernbereich mit deutscher Literatur, Kaffee und Gruppenarbeitsplätzen', 'Lounge', 'public-assets/spaces/vienna_lounge.jpg', 1),
  ('30303030-0001-0000-0000-000000000002', 'Berlin Collaboration Lab', 'Voll ausgestatteter Medienraum mit interaktiven Smartboards und Sprachlabor-PCs', 'Studio', 'public-assets/spaces/berlin_lab.jpg', 2),
  ('30303030-0001-0000-0000-000000000003', 'Zurich Quiet Study Pods', 'Schallisolierte Einzelarbeitsplätze für fokussiertes Lernen und Audioaufnahmen', 'Quiet Zone', 'public-assets/spaces/zurich_pods.jpg', 3)
on conflict (id) do update set title = excluded.title;

insert into public.website_events (id, title, description, starts_at, ends_at, location, type, image_path, capacity, price, is_active) values
  ('40404040-0001-0000-0000-000000000001',
   'Kaffee & Konversation: Stammtisch Alexandria',
   'Offener Gesprächskreis für alle Niveaustufen (A1-B2). Muttersprachler leiten thematische Diskussionen bei traditionellem Kaffee.',
   now() + interval '5 days' + interval '18 hours',
   now() + interval '5 days' + interval '21 hours',
   'Leidenschaft Klub — Portsaid St 261, Cleopatra',
   'Cultural & Speaking',
   'public-assets/events/kaffee_stammtisch.jpg',
   30,
   'Free for enrolled students',
   true),

  ('40404040-0001-0000-0000-000000000002',
   'Deutscher Filmabend: "Das Leben der Anderen"',
   'Gemeinsamer Filmabend in Originalfassung mit deutschen Untertiteln und anschließender moderierter Diskussionsrunde.',
   now() + interval '12 days' + interval '19 hours',
   now() + interval '12 days' + interval '22 hours',
   'Berlin Collaboration Lab',
   'Film & Culture',
   'public-assets/events/filmabend.jpg',
   25,
   'Free',
   true)
on conflict (id) do update set title = excluded.title;

insert into public.website_event_bookings (id, event_id, user_id, name, email, seats, created_at) values
  ('50505050-0001-0000-0000-000000000001', '40404040-0001-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Max Mustermann', 'student.demo@leidenschaft.com', 1, now() - interval '2 days'),
  ('50505050-0001-0000-0000-000000000002', '40404040-0001-0000-0000-000000000001', null, 'Karim El-Sayed', 'karim.sayed@gmail.com', 2, now() - interval '1 day')
on conflict (id) do nothing;

-- ─── 11. NOTIFICATIONS ─────────────────────────────────────────────────────────
insert into public.notifications (id, user_id, type, title, message, is_read, priority, target_level, is_active, created_by, created_at) values
  ('60606060-0001-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111',
   'announcement',
   'Herzlich willkommen bei Leidenschaft Klub!',
   'Ihr Kurs A1.1 Abendgruppe hat offiziell begonnen. Prüfen Sie Ihren Lehrplan und Ihre Materialien.',
   true,
   'high',
   'all',
   true,
   '44444444-4444-4444-4444-444444444444',
   now() - interval '25 days'),

  ('60606060-0001-0000-0000-000000000002',
   '11111111-1111-1111-1111-111111111111',
   'material',
   'Neues Material verfügbar',
   'Herr Müller hat das Audio-Material "Begrüßung im Café" für Ihr Modul freigeschaltet.',
   true,
   'medium',
   'A1.1',
   true,
   '22222222-2222-2222-2222-222222222222',
   now() - interval '20 days'),

  ('60606060-0001-0000-0000-000000000003',
   '11111111-1111-1111-1111-111111111111',
   'review',
   'Aufgabe bewertet: 95/100',
   'Ihre Schreibaufgabe "Stellen Sie sich vor!" wurde von Herrn Müller bewertet. Hervorragende Leistung!',
   false,
   'medium',
   'all',
   true,
   '22222222-2222-2222-2222-222222222222',
   now() - interval '14 days'),

  ('60606060-0001-0000-0000-000000000004',
   '11111111-1111-1111-1111-111111111111',
   'assignment',
   'Erinnerung: Hör- & Sprechaufgabe fällig',
   'Die Abgabe für "Mein Tagesablauf" steht bevor. Bitte laden Sie Ihre Sprachnachricht hoch.',
   false,
   'high',
   'A1.1',
   true,
   '22222222-2222-2222-2222-222222222222',
   now() - interval '2 days'),

  -- Notification for Instructor Demo
  ('60606060-0001-0000-0000-000000000005',
   '22222222-2222-2222-2222-222222222222',
   'submission',
   'Neue Einreichung zur Korrektur',
   'Max Mustermann hat die Hör- & Sprechaufgabe "Mein Tagesablauf" eingereicht.',
   false,
   'high',
   'all',
   true,
   '11111111-1111-1111-1111-111111111111',
   now() - interval '1 day'),

  -- Notification for Secretary Demo
  ('60606060-0001-0000-0000-000000000006',
   '33333333-3333-3333-3333-333333333333',
   'event',
   'Neue Veranstaltungsbuchung',
   'Eine neue Anmeldung für "Kaffee & Konversation" ist eingegangen.',
   false,
   'medium',
   'all',
   true,
   '44444444-4444-4444-4444-444444444444',
   now() - interval '1 day')
on conflict (id) do nothing;

-- ==============================================================================
-- DEMO DATA SEEDING COMPLETE ✅
-- ==============================================================================
