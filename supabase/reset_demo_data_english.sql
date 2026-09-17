-- ============================================================
-- AcadFlow LMS — Demo Data Reset Script
-- Removes ALL existing demo data and inserts fresh English demo
-- Run this in Supabase SQL Editor (Settings → SQL Editor)
-- ============================================================

-- ─── 1. CLEAN UP EXISTING DEMO DATA ────────────────────────

-- Order matters: child tables first, then parents

DELETE FROM public.exam_answers;
DELETE FROM public.exam_results;
DELETE FROM public.submissions;
DELETE FROM public.exam_writing_questions;
DELETE FROM public.exam_listening_questions;
DELETE FROM public.exam_grammar_questions;
DELETE FROM public.exam_mcq_questions;
DELETE FROM public.exams;
DELETE FROM public.assignments;
DELETE FROM public.student_materials;
DELETE FROM public.materials;
DELETE FROM public.attendance;
DELETE FROM public.sessions;
DELETE FROM public.notifications;
DELETE FROM public.events;
DELETE FROM public.level_students;
DELETE FROM public.levels;
DELETE FROM public.groups;
DELETE FROM public.profiles;

-- Clean auth tables for demo accounts
DELETE FROM auth.identities
  WHERE identity_data->>'email' ILIKE '%@acadflow-demo.com';

DELETE FROM auth.users
  WHERE email ILIKE '%@acadflow-demo.com';

-- ─── 2. INSERT DEMO AUTH USERS ──────────────────────────────

-- UUIDs for demo accounts (fixed so FKs work)
DO $$
DECLARE
  admin_id     UUID := 'a0000001-0000-0000-0000-000000000001';
  instructor_id UUID := 'a0000002-0000-0000-0000-000000000002';
  secretary_id  UUID := 'a0000003-0000-0000-0000-000000000003';
  student1_id   UUID := 'a0000004-0000-0000-0000-000000000004';
  student2_id   UUID := 'a0000005-0000-0000-0000-000000000005';
  student3_id   UUID := 'a0000006-0000-0000-0000-000000000006';
  student4_id   UUID := 'a0000007-0000-0000-0000-000000000007';
BEGIN

-- Insert into auth.users
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, role,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
VALUES
  (admin_id,      'admin.demo@acadflow-demo.com',      crypt('Demo12345!', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"name":"Alex Morgan"}', false, 'authenticated',
   '', '', '', ''),
  (instructor_id, 'instructor.demo@acadflow-demo.com', crypt('Demo12345!', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"name":"Dr. Sarah Johnson"}', false, 'authenticated',
   '', '', '', ''),
  (secretary_id,  'secretary.demo@acadflow-demo.com',  crypt('Demo12345!', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"name":"Emily Carter"}', false, 'authenticated',
   '', '', '', ''),
  (student1_id,   'student.demo@acadflow-demo.com',    crypt('Demo12345!', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"name":"James Wilson"}', false, 'authenticated',
   '', '', '', ''),
  (student2_id,   'student2.demo@acadflow-demo.com',   crypt('Demo12345!', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"name":"Sophia Lee"}', false, 'authenticated',
   '', '', '', ''),
  (student3_id,   'student3.demo@acadflow-demo.com',   crypt('Demo12345!', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"name":"Noah Martinez"}', false, 'authenticated',
   '', '', '', ''),
  (student4_id,   'student4.demo@acadflow-demo.com',   crypt('Demo12345!', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{"name":"Olivia Brown"}', false, 'authenticated',
   '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Insert into auth.identities
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES
  (gen_random_uuid(), admin_id,      jsonb_build_object('sub', admin_id::text,      'email', 'admin.demo@acadflow-demo.com'),      'email', 'admin.demo@acadflow-demo.com',      now(), now(), now()),
  (gen_random_uuid(), instructor_id, jsonb_build_object('sub', instructor_id::text, 'email', 'instructor.demo@acadflow-demo.com'), 'email', 'instructor.demo@acadflow-demo.com', now(), now(), now()),
  (gen_random_uuid(), secretary_id,  jsonb_build_object('sub', secretary_id::text,  'email', 'secretary.demo@acadflow-demo.com'),  'email', 'secretary.demo@acadflow-demo.com',  now(), now(), now()),
  (gen_random_uuid(), student1_id,   jsonb_build_object('sub', student1_id::text,   'email', 'student.demo@acadflow-demo.com'),    'email', 'student.demo@acadflow-demo.com',    now(), now(), now()),
  (gen_random_uuid(), student2_id,   jsonb_build_object('sub', student2_id::text,   'email', 'student2.demo@acadflow-demo.com'),   'email', 'student2.demo@acadflow-demo.com',   now(), now(), now()),
  (gen_random_uuid(), student3_id,   jsonb_build_object('sub', student3_id::text,   'email', 'student3.demo@acadflow-demo.com'),   'email', 'student3.demo@acadflow-demo.com',   now(), now(), now()),
  (gen_random_uuid(), student4_id,   jsonb_build_object('sub', student4_id::text,   'email', 'student4.demo@acadflow-demo.com'),   'email', 'student4.demo@acadflow-demo.com',   now(), now(), now())
ON CONFLICT DO NOTHING;

-- ─── 3. PROFILES ────────────────────────────────────────────

INSERT INTO public.profiles (id, email, name, role, current_level, bio, phone, created_at)
VALUES
  (admin_id,      'admin.demo@acadflow-demo.com',      'Alex Morgan',        'admin',      NULL,  'Academy administrator and system manager.',          '+1-555-0100', now()),
  (instructor_id, 'instructor.demo@acadflow-demo.com', 'Dr. Sarah Johnson',  'instructor', NULL,  'Senior instructor specialising in language & skills.', '+1-555-0101', now()),
  (secretary_id,  'secretary.demo@acadflow-demo.com',  'Emily Carter',       'secretary',  NULL,  'Academic coordinator and student records manager.',   '+1-555-0102', now()),
  (student1_id,   'student.demo@acadflow-demo.com',    'James Wilson',       'student',    'A1',  'Enthusiastic learner starting the A1 programme.',    '+1-555-0103', now()),
  (student2_id,   'student2.demo@acadflow-demo.com',   'Sophia Lee',         'student',    'A2',  'Progress to intermediate with strong listening skills.','+1-555-0104', now()),
  (student3_id,   'student3.demo@acadflow-demo.com',   'Noah Martinez',      'student',    'B1',  'Aiming for B2 certification this semester.',          '+1-555-0105', now()),
  (student4_id,   'student4.demo@acadflow-demo.com',   'Olivia Brown',       'student',    'B2',  'Advanced learner focused on writing proficiency.',    '+1-555-0106', now())
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email, name = EXCLUDED.name, role = EXCLUDED.role;

-- ─── 4. GROUPS ──────────────────────────────────────────────

INSERT INTO public.groups (id, name, description, created_at)
VALUES
  ('g0000001-0000-0000-0000-000000000001', 'Alpha',   'Morning group — Mon/Wed/Fri',   now()),
  ('g0000002-0000-0000-0000-000000000002', 'Beta',    'Evening group — Tue/Thu',       now()),
  ('g0000003-0000-0000-0000-000000000003', 'Gamma',   'Weekend intensive group',       now())
ON CONFLICT (id) DO NOTHING;

-- ─── 5. LEVELS ──────────────────────────────────────────────

INSERT INTO public.levels (id, name, description, instructor_id, group_id, order_index, created_at)
VALUES
  ('lv000001-0000-0000-0000-000000000001', 'A1', 'Beginner — foundations of communication',    instructor_id, 'g0000001-0000-0000-0000-000000000001', 1, now()),
  ('lv000002-0000-0000-0000-000000000002', 'A2', 'Elementary — expanding vocabulary & grammar', instructor_id, 'g0000002-0000-0000-0000-000000000002', 2, now()),
  ('lv000003-0000-0000-0000-000000000003', 'B1', 'Intermediate — confident conversations',      instructor_id, 'g0000001-0000-0000-0000-000000000001', 3, now()),
  ('lv000004-0000-0000-0000-000000000004', 'B2', 'Upper-Intermediate — complex topics',         instructor_id, 'g0000003-0000-0000-0000-000000000003', 4, now())
ON CONFLICT (id) DO NOTHING;

-- ─── 6. LEVEL_STUDENTS (enrollment) ─────────────────────────

INSERT INTO public.level_students (id, level_id, student_id, enrolled_at)
VALUES
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, now()),
  (gen_random_uuid(), 'lv000002-0000-0000-0000-000000000002', student2_id, now()),
  (gen_random_uuid(), 'lv000003-0000-0000-0000-000000000003', student3_id, now()),
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, now())
ON CONFLICT DO NOTHING;

-- ─── 7. MATERIALS ───────────────────────────────────────────

INSERT INTO public.materials (id, title, description, file_url, level_id, created_by, created_at)
VALUES
  ('mt000001-0000-0000-0000-000000000001', 'Introduction to A1 Grammar',        'Core grammar rules for beginners',      'https://example.com/materials/a1-grammar.pdf',    'lv000001-0000-0000-0000-000000000001', instructor_id, now()),
  ('mt000002-0000-0000-0000-000000000002', 'A1 Vocabulary: Daily Life',          'Essential 300 words for everyday use',  'https://example.com/materials/a1-vocab.pdf',      'lv000001-0000-0000-0000-000000000001', instructor_id, now()),
  ('mt000003-0000-0000-0000-000000000003', 'A2 Reading Comprehension Pack',      'Short passages with exercises',         'https://example.com/materials/a2-reading.pdf',    'lv000002-0000-0000-0000-000000000002', instructor_id, now()),
  ('mt000004-0000-0000-0000-000000000004', 'B1 Conversation Scripts',            'Dialogue scripts for fluency practice', 'https://example.com/materials/b1-scripts.pdf',    'lv000003-0000-0000-0000-000000000003', instructor_id, now()),
  ('mt000005-0000-0000-0000-000000000005', 'B2 Essay Writing Guide',             'Academic writing structures & tips',    'https://example.com/materials/b2-essay.pdf',      'lv000004-0000-0000-0000-000000000004', instructor_id, now()),
  ('mt000006-0000-0000-0000-000000000006', 'Listening Exercises — A1',           'Audio transcripts and tasks',           'https://example.com/materials/a1-listening.pdf',  'lv000001-0000-0000-0000-000000000001', instructor_id, now())
ON CONFLICT (id) DO NOTHING;

-- ─── 8. STUDENT_MATERIALS (assignment of materials to students) ──

INSERT INTO public.student_materials (id, student_id, material_id, assigned_at)
VALUES
  (gen_random_uuid(), student1_id, 'mt000001-0000-0000-0000-000000000001', now()),
  (gen_random_uuid(), student1_id, 'mt000002-0000-0000-0000-000000000002', now()),
  (gen_random_uuid(), student1_id, 'mt000006-0000-0000-0000-000000000006', now()),
  (gen_random_uuid(), student2_id, 'mt000003-0000-0000-0000-000000000003', now()),
  (gen_random_uuid(), student3_id, 'mt000004-0000-0000-0000-000000000004', now()),
  (gen_random_uuid(), student4_id, 'mt000005-0000-0000-0000-000000000005', now())
ON CONFLICT DO NOTHING;

-- ─── 9. ASSIGNMENTS ─────────────────────────────────────────

INSERT INTO public.assignments (id, title, description, level_id, instructor_id, deadline, created_at)
VALUES
  ('as000001-0000-0000-0000-000000000001', 'A1 Grammar Practice Sheet',      'Complete exercises 1-20 from the grammar pack',  'lv000001-0000-0000-0000-000000000001', instructor_id, now() + interval '7 days',  now()),
  ('as000002-0000-0000-0000-000000000002', 'A1 Vocabulary Quiz Preparation', 'Study the 300-word list, focus on verbs',        'lv000001-0000-0000-0000-000000000001', instructor_id, now() + interval '5 days',  now()),
  ('as000003-0000-0000-0000-000000000003', 'A2 Reading Response',            'Answer comprehension questions on passage 3',    'lv000002-0000-0000-0000-000000000002', instructor_id, now() + interval '10 days', now()),
  ('as000004-0000-0000-0000-000000000004', 'B1 Dialogue Recording',          'Record a 3-minute conversation using scripts',   'lv000003-0000-0000-0000-000000000003', instructor_id, now() + interval '6 days',  now()),
  ('as000005-0000-0000-0000-000000000005', 'B2 Argumentative Essay',         'Write a 500-word essay on a given topic',        'lv000004-0000-0000-0000-000000000004', instructor_id, now() + interval '14 days', now())
ON CONFLICT (id) DO NOTHING;

-- ─── 10. SUBMISSIONS ────────────────────────────────────────

INSERT INTO public.submissions (id, assignment_id, student_id, content, file_url, grade, feedback, submitted_at)
VALUES
  (gen_random_uuid(), 'as000001-0000-0000-0000-000000000001', student1_id,
   'I completed all exercises. Found compound nouns challenging but improved by the end.',
   NULL, 85, 'Good effort! Focus more on verb conjugation.', now() - interval '2 days'),
  (gen_random_uuid(), 'as000002-0000-0000-0000-000000000002', student1_id,
   'Studied all 300 words. Created flashcards for verbs.',
   NULL, 90, 'Excellent preparation strategy!', now() - interval '1 day'),
  (gen_random_uuid(), 'as000003-0000-0000-0000-000000000003', student2_id,
   'Answered all 5 comprehension questions with examples from the text.',
   NULL, 78, 'Good analysis. Improve inference skills.', now() - interval '3 days'),
  (gen_random_uuid(), 'as000004-0000-0000-0000-000000000004', student3_id,
   'Recorded conversation with a classmate, uploaded audio file.',
   'https://example.com/submissions/b1-dialogue.mp3', 88, 'Natural flow! Work on pronunciation.', now() - interval '1 day')
ON CONFLICT DO NOTHING;

-- ─── 11. EXAMS ──────────────────────────────────────────────

INSERT INTO public.exams (id, title, description, level_id, instructor_id, duration_minutes, total_marks, is_published, created_at)
VALUES
  ('ex000001-0000-0000-0000-000000000001', 'A1 Mid-Term Exam',   'Covers grammar + vocabulary from weeks 1-4',  'lv000001-0000-0000-0000-000000000001', instructor_id, 60,  100, true,  now() - interval '30 days'),
  ('ex000002-0000-0000-0000-000000000002', 'A1 Final Exam',      'Comprehensive end-of-level assessment',       'lv000001-0000-0000-0000-000000000001', instructor_id, 90,  100, true,  now() - interval '5 days'),
  ('ex000003-0000-0000-0000-000000000003', 'A2 Progress Check',  'Reading + listening skills assessment',       'lv000002-0000-0000-0000-000000000002', instructor_id, 45,  100, true,  now() - interval '20 days'),
  ('ex000004-0000-0000-0000-000000000004', 'B1 Speaking Exam',   'Oral examination + dialogue evaluation',      'lv000003-0000-0000-0000-000000000003', instructor_id, 30,  100, true,  now() - interval '15 days'),
  ('ex000005-0000-0000-0000-000000000005', 'B2 Writing Exam',    'Essay + advanced writing structures',         'lv000004-0000-0000-0000-000000000004', instructor_id, 120, 100, true,  now() - interval '10 days'),
  ('ex000006-0000-0000-0000-000000000006', 'B1 Monthly Quiz',    'Quick assessment — grammar & vocabulary',     'lv000003-0000-0000-0000-000000000003', instructor_id, 30,  50,  false, now())
ON CONFLICT (id) DO NOTHING;

-- ─── 12. MCQ QUESTIONS ──────────────────────────────────────

INSERT INTO public.exam_mcq_questions (id, exam_id, question_text, option_a, option_b, option_c, option_d, correct_option, marks, order_index)
VALUES
  (gen_random_uuid(), 'ex000001-0000-0000-0000-000000000001', 'Which sentence is grammatically correct?',
   'She go to school every day.', 'She goes to school every day.', 'She going to school every day.', 'She gone to school every day.',
   'B', 5, 1),
  (gen_random_uuid(), 'ex000001-0000-0000-0000-000000000001', 'What is the plural of "child"?',
   'childs', 'childes', 'children', 'childrens',
   'C', 5, 2),
  (gen_random_uuid(), 'ex000001-0000-0000-0000-000000000001', 'Choose the correct article: "___ apple a day keeps the doctor away."',
   'A', 'An', 'The', 'No article',
   'B', 5, 3),
  (gen_random_uuid(), 'ex000003-0000-0000-0000-000000000003', 'What does "frequently" mean?',
   'rarely', 'sometimes', 'often', 'never',
   'C', 5, 1),
  (gen_random_uuid(), 'ex000003-0000-0000-0000-000000000003', 'Choose the correct preposition: "She is interested ___ art."',
   'at', 'in', 'on', 'of',
   'B', 5, 2)
ON CONFLICT DO NOTHING;

-- ─── 13. GRAMMAR QUESTIONS ──────────────────────────────────

INSERT INTO public.exam_grammar_questions (id, exam_id, question_text, correct_answer, marks, order_index)
VALUES
  (gen_random_uuid(), 'ex000001-0000-0000-0000-000000000001',
   'Fill in the blank: "He ___ (not/eat) breakfast this morning."',
   'did not eat', 10, 4),
  (gen_random_uuid(), 'ex000002-0000-0000-0000-000000000002',
   'Transform to passive: "The teacher corrected the tests."',
   'The tests were corrected by the teacher.', 10, 1)
ON CONFLICT DO NOTHING;

-- ─── 14. WRITING QUESTIONS ──────────────────────────────────

INSERT INTO public.exam_writing_questions (id, exam_id, question_text, min_words, marks, order_index)
VALUES
  (gen_random_uuid(), 'ex000002-0000-0000-0000-000000000002',
   'Write a short paragraph (50-80 words) describing your daily routine.',
   50, 25, 1),
  (gen_random_uuid(), 'ex000005-0000-0000-0000-000000000005',
   'Write an argumentative essay (500 words): "Technology has improved education more than it has harmed it." Do you agree?',
   400, 50, 1)
ON CONFLICT DO NOTHING;

-- ─── 15. LISTENING QUESTIONS ────────────────────────────────

INSERT INTO public.exam_listening_questions (id, exam_id, question_text, audio_url, correct_answer, marks, order_index)
VALUES
  (gen_random_uuid(), 'ex000003-0000-0000-0000-000000000003',
   'Listen to the audio and answer: What time does the meeting start?',
   'https://example.com/audio/a2-listening-1.mp3',
   'At 3:00 PM', 10, 1),
  (gen_random_uuid(), 'ex000003-0000-0000-0000-000000000003',
   'Listen and complete: The speaker mentions ___ reasons for being late.',
   'https://example.com/audio/a2-listening-2.mp3',
   'three', 10, 2)
ON CONFLICT DO NOTHING;

-- ─── 16. EXAM RESULTS ───────────────────────────────────────

INSERT INTO public.exam_results (id, exam_id, student_id, score, percentage, passed, graded_at, created_at)
VALUES
  (gen_random_uuid(), 'ex000001-0000-0000-0000-000000000001', student1_id, 82, 82, true,  now() - interval '28 days', now() - interval '28 days'),
  (gen_random_uuid(), 'ex000002-0000-0000-0000-000000000002', student1_id, 88, 88, true,  now() - interval '3 days',  now() - interval '3 days'),
  (gen_random_uuid(), 'ex000003-0000-0000-0000-000000000003', student2_id, 75, 75, true,  now() - interval '18 days', now() - interval '18 days'),
  (gen_random_uuid(), 'ex000004-0000-0000-0000-000000000004', student3_id, 91, 91, true,  now() - interval '13 days', now() - interval '13 days'),
  (gen_random_uuid(), 'ex000005-0000-0000-0000-000000000005', student4_id, 79, 79, true,  now() - interval '8 days',  now() - interval '8 days')
ON CONFLICT DO NOTHING;

-- ─── 17. ATTENDANCE ─────────────────────────────────────────

INSERT INTO public.attendance (id, level_id, student_id, session_number, status, date, notes, created_at)
VALUES
  -- James Wilson (A1)
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, 1, 'present', now() - interval '42 days', NULL, now()),
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, 2, 'present', now() - interval '40 days', NULL, now()),
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, 3, 'absent',  now() - interval '38 days', 'Medical appointment', now()),
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, 4, 'present', now() - interval '35 days', NULL, now()),
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, 5, 'present', now() - interval '33 days', NULL, now()),
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, 6, 'present', now() - interval '31 days', NULL, now()),
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, 7, 'present', now() - interval '28 days', NULL, now()),
  (gen_random_uuid(), 'lv000001-0000-0000-0000-000000000001', student1_id, 8, 'present', now() - interval '26 days', NULL, now()),
  -- Sophia Lee (A2)
  (gen_random_uuid(), 'lv000002-0000-0000-0000-000000000002', student2_id, 1, 'present', now() - interval '42 days', NULL, now()),
  (gen_random_uuid(), 'lv000002-0000-0000-0000-000000000002', student2_id, 2, 'present', now() - interval '40 days', NULL, now()),
  (gen_random_uuid(), 'lv000002-0000-0000-0000-000000000002', student2_id, 3, 'present', now() - interval '38 days', NULL, now()),
  (gen_random_uuid(), 'lv000002-0000-0000-0000-000000000002', student2_id, 4, 'absent',  now() - interval '35 days', NULL, now()),
  (gen_random_uuid(), 'lv000002-0000-0000-0000-000000000002', student2_id, 5, 'present', now() - interval '33 days', NULL, now()),
  (gen_random_uuid(), 'lv000002-0000-0000-0000-000000000002', student2_id, 6, 'present', now() - interval '31 days', NULL, now()),
  -- Noah Martinez (B1)
  (gen_random_uuid(), 'lv000003-0000-0000-0000-000000000003', student3_id, 1, 'present', now() - interval '42 days', NULL, now()),
  (gen_random_uuid(), 'lv000003-0000-0000-0000-000000000003', student3_id, 2, 'present', now() - interval '40 days', NULL, now()),
  (gen_random_uuid(), 'lv000003-0000-0000-0000-000000000003', student3_id, 3, 'present', now() - interval '38 days', NULL, now()),
  (gen_random_uuid(), 'lv000003-0000-0000-0000-000000000003', student3_id, 4, 'present', now() - interval '35 days', NULL, now()),
  (gen_random_uuid(), 'lv000003-0000-0000-0000-000000000003', student3_id, 5, 'absent',  now() - interval '33 days', 'Family emergency', now()),
  (gen_random_uuid(), 'lv000003-0000-0000-0000-000000000003', student3_id, 6, 'present', now() - interval '31 days', NULL, now()),
  (gen_random_uuid(), 'lv000003-0000-0000-0000-000000000003', student3_id, 7, 'present', now() - interval '28 days', NULL, now()),
  -- Olivia Brown (B2)
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, 1, 'present', now() - interval '42 days', NULL, now()),
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, 2, 'present', now() - interval '40 days', NULL, now()),
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, 3, 'present', now() - interval '38 days', NULL, now()),
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, 4, 'present', now() - interval '35 days', NULL, now()),
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, 5, 'present', now() - interval '33 days', NULL, now()),
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, 6, 'absent',  now() - interval '31 days', NULL, now()),
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, 7, 'present', now() - interval '28 days', NULL, now()),
  (gen_random_uuid(), 'lv000004-0000-0000-0000-000000000004', student4_id, 8, 'present', now() - interval '26 days', NULL, now())
ON CONFLICT DO NOTHING;

-- ─── 18. NOTIFICATIONS ──────────────────────────────────────

INSERT INTO public.notifications (id, user_id, title, body, is_read, created_at)
VALUES
  (gen_random_uuid(), student1_id, 'New Assignment Posted',      'Grammar Practice Sheet has been assigned. Due in 7 days.',           false, now() - interval '1 day'),
  (gen_random_uuid(), student1_id, 'Exam Result Available',      'Your A1 Final Exam result is ready. You scored 88%!',                true,  now() - interval '3 days'),
  (gen_random_uuid(), student1_id, 'Material Added',             'New material: Listening Exercises A1 has been added to your level.', false, now() - interval '2 days'),
  (gen_random_uuid(), student2_id, 'Assignment Graded',          'Your A2 Reading Response has been graded. Grade: 78/100.',           true,  now() - interval '2 days'),
  (gen_random_uuid(), student2_id, 'Upcoming Exam',              'A2 Progress Check is scheduled for next week. Prepare well!',        false, now() - interval '4 days'),
  (gen_random_uuid(), student3_id, 'Exam Result Available',      'B1 Speaking Exam result: 91/100. Excellent work!',                   true,  now() - interval '12 days'),
  (gen_random_uuid(), student4_id, 'Assignment Due Soon',        'B2 Argumentative Essay is due in 2 weeks. Start planning!',          false, now() - interval '1 day'),
  (gen_random_uuid(), instructor_id,'New Submission',            'James Wilson submitted: A1 Grammar Practice Sheet.',                 false, now() - interval '2 days'),
  (gen_random_uuid(), admin_id,    'Demo Account Ready',         'The demo LMS environment has been fully configured and is live.',    true,  now() - interval '5 days')
ON CONFLICT DO NOTHING;

-- ─── 19. EVENTS ─────────────────────────────────────────────

INSERT INTO public.events (id, title, description, start_date, end_date, event_type, created_by, created_at)
VALUES
  (gen_random_uuid(), 'A1 Mid-Term Exams Week',    'Mid-term examinations for all A1 groups',             now() + interval '7 days',  now() + interval '9 days',  'exam',    admin_id, now()),
  (gen_random_uuid(), 'Open Day — Academy Demo',   'Showcase the LMS platform to prospective clients',    now() + interval '14 days', now() + interval '14 days', 'event',   admin_id, now()),
  (gen_random_uuid(), 'B2 Graduation Ceremony',    'Graduation for students completing the B2 programme', now() + interval '21 days', now() + interval '21 days', 'event',   admin_id, now()),
  (gen_random_uuid(), 'Instructor Training Day',   'Annual instructor development and calibration day',   now() + interval '30 days', now() + interval '30 days', 'training',admin_id, now()),
  (gen_random_uuid(), 'New Semester Enrollment',   'Registration open for next semester classes',         now() + interval '35 days', now() + interval '42 days', 'admin',   admin_id, now())
ON CONFLICT DO NOTHING;

END $$;

-- ─── 20. VERIFY ─────────────────────────────────────────────

SELECT 'profiles'      AS tbl, COUNT(*) FROM public.profiles       UNION ALL
SELECT 'groups'        AS tbl, COUNT(*) FROM public.groups          UNION ALL
SELECT 'levels'        AS tbl, COUNT(*) FROM public.levels          UNION ALL
SELECT 'level_students',       COUNT(*) FROM public.level_students  UNION ALL
SELECT 'materials'     AS tbl, COUNT(*) FROM public.materials       UNION ALL
SELECT 'assignments'   AS tbl, COUNT(*) FROM public.assignments     UNION ALL
SELECT 'submissions'   AS tbl, COUNT(*) FROM public.submissions     UNION ALL
SELECT 'exams'         AS tbl, COUNT(*) FROM public.exams           UNION ALL
SELECT 'attendance'    AS tbl, COUNT(*) FROM public.attendance      UNION ALL
SELECT 'notifications' AS tbl, COUNT(*) FROM public.notifications   UNION ALL
SELECT 'events'        AS tbl, COUNT(*) FROM public.events;
