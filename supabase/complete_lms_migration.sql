-- ==============================================================================
-- LEIDENSCHAFT KLUB LMS — MASTER DATABASE SCHEMA MIGRATION
-- Project: https://dikaqxsubzaqshwirsdh.supabase.co
-- Run this complete script in: Supabase Dashboard → SQL Editor
-- ==============================================================================

-- ─── 0. EXTENSIONS ─────────────────────────────────────────────────────────────
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ─── 1. CORE ROLE HELPER FUNCTIONS ─────────────────────────────────────────────
-- Defined early so RLS policies and triggers can reference them safely.

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.is_secretary()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'secretary'
  );
$$;

create or replace function public.is_instructor()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'instructor'
  );
$$;

create or replace function public.can_assign_materials()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select public.is_admin() or public.is_secretary();
$$;

create or replace function public.get_my_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.get_my_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

-- ─── 2. GROUPS TABLE ───────────────────────────────────────────────────────────
create table if not exists public.groups (
  id          uuid        primary key default gen_random_uuid(),
  name        text        not null,
  level       text,
  description text,
  created_at  timestamptz not null default now()
);

-- ─── 3. PROFILES TABLE ─────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid        primary key references auth.users(id) on delete cascade,
  name          text        not null default '',
  email         text        not null default '',
  phone         text,
  role          text        not null default 'student'
                            check (role in ('student', 'admin', 'instructor', 'secretary')),
  current_level text        default 'A1',
  group_id      uuid        references public.groups(id) on delete set null,
  avatar_url    text,
  created_at    timestamptz not null default now()
);

create index if not exists idx_profiles_current_level on public.profiles(current_level);

-- ─── 4. AUTH TRIGGER: Auto-provision profile on sign-up ────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, email, role, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'role', 'student'),
    nullif(btrim(coalesce(new.raw_user_meta_data->>'phone', '')), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─── 5. LEVELS TABLE ───────────────────────────────────────────────────────────
create table if not exists public.levels (
  id              uuid        primary key default gen_random_uuid(),
  name            text        not null unique,
  description     text,
  parent_level_id uuid        references public.levels(id) on delete set null,
  instructor_id   uuid        references public.profiles(id) on delete set null,
  group_id        uuid        references public.groups(id) on delete set null,
  created_at      timestamptz not null default now()
);

-- ─── 6. LEVEL_STUDENTS TABLE ───────────────────────────────────────────────────
create table if not exists public.level_students (
  id            uuid        primary key default gen_random_uuid(),
  student_id    uuid        not null references public.profiles(id) on delete cascade,
  level_id      uuid        not null references public.levels(id) on delete cascade,
  instructor_id uuid        references public.profiles(id) on delete set null,
  assigned_at   timestamptz not null default now(),
  constraint level_students_unique unique (student_id)
);

-- ─── 7. INSTRUCTOR_GROUPS TABLE ───────────────────────────────────────────────
create table if not exists public.instructor_groups (
  id            uuid        primary key default gen_random_uuid(),
  instructor_id uuid        not null references public.profiles(id) on delete cascade,
  group_id      uuid        not null references public.groups(id) on delete cascade,
  assigned_at   timestamptz not null default now(),
  unique (instructor_id, group_id)
);

-- ─── 8. LEVEL_SESSIONS & LEVEL_SETTINGS TABLE ──────────────────────────────────
create table if not exists public.level_sessions (
  id             uuid        primary key default gen_random_uuid(),
  level_id       uuid        not null references public.levels(id) on delete cascade,
  session_number integer     not null,
  session_date   date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (level_id, session_number)
);

create table if not exists public.level_settings (
  id             uuid    primary key default gen_random_uuid(),
  level_id       uuid    not null references public.levels(id) on delete cascade unique,
  total_sessions integer default 8,
  max_absences   integer default 2
);

-- ─── 9. ATTENDANCE TABLE ───────────────────────────────────────────────────────
create table if not exists public.attendance (
  id             uuid        primary key default gen_random_uuid(),
  student_id     uuid        not null references public.profiles(id) on delete cascade,
  level_id       uuid        not null references public.levels(id) on delete cascade,
  session_number integer     not null check (session_number >= 1 and session_number <= 8),
  status         text        not null check (status in ('present', 'absent')),
  session_date   date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (student_id, level_id, session_number)
);

-- ─── 10. MATERIALS TABLE ──────────────────────────────────────────────────────
create table if not exists public.materials (
  id          uuid        primary key default gen_random_uuid(),
  title       text        not null,
  description text,
  file_url    text        not null,
  level_id    uuid        not null references public.levels(id) on delete cascade,
  created_at  timestamptz not null default now()
);

-- ─── 11. STUDENT_MATERIALS TABLE ──────────────────────────────────────────────
create table if not exists public.student_materials (
  id             uuid        primary key default gen_random_uuid(),
  student_id     uuid        not null references public.profiles(id) on delete cascade,
  material_id    uuid        not null references public.materials(id) on delete cascade,
  assigned_by    uuid        references public.profiles(id) on delete set null,
  assigned_at    timestamptz not null default now(),
  available_from timestamptz not null default now(),
  visible        boolean     not null default true,
  status         text        not null default 'assigned'
                             check (status in ('assigned', 'revision')),
  notes          text,
  unique (student_id, material_id)
);

create index if not exists idx_student_materials_student  on public.student_materials(student_id);
create index if not exists idx_student_materials_material on public.student_materials(material_id);
create index if not exists idx_student_materials_status   on public.student_materials(status);

-- ─── 12. ASSIGNMENTS TABLE ────────────────────────────────────────────────────
create table if not exists public.assignments (
  id            uuid        primary key default gen_random_uuid(),
  title         text        not null,
  description   text,
  level_id      uuid        not null references public.levels(id) on delete cascade,
  deadline      timestamptz,
  audio_url     text,
  created_by    uuid        references public.profiles(id) on delete set null,
  instructor_id uuid        references public.profiles(id) on delete set null,
  created_at    timestamptz not null default now()
);

-- ─── 13. GROUP_ASSIGNMENTS TABLE ──────────────────────────────────────────────
create table if not exists public.group_assignments (
  id            uuid        primary key default gen_random_uuid(),
  group_id      uuid        not null references public.groups(id) on delete cascade,
  assignment_id uuid        not null references public.assignments(id) on delete cascade,
  assigned_at   timestamptz not null default now(),
  unique (group_id, assignment_id)
);

-- ─── 14. SUBMISSIONS TABLE ────────────────────────────────────────────────────
create table if not exists public.submissions (
  id               uuid         primary key default gen_random_uuid(),
  assignment_id    uuid         not null references public.assignments(id) on delete cascade,
  student_id       uuid         not null references public.profiles(id) on delete cascade,
  file_url         text,
  answer           text,
  audio_answer_url text,
  grade            numeric(5,2),
  status           text         not null default 'pending'
                                check (status in ('pending', 'submitted', 'graded', 'returned')),
  feedback         text,
  submitted_at     timestamptz  not null default now(),
  unique (assignment_id, student_id)
);

-- ─── 15. EXAMS TABLE ──────────────────────────────────────────────────────────
create table if not exists public.exams (
  id            uuid        primary key default gen_random_uuid(),
  title         text        not null,
  level_id      uuid        not null references public.levels(id) on delete cascade,
  duration      integer     not null default 60,
  created_by    uuid        references public.profiles(id) on delete set null,
  instructor_id uuid        references public.profiles(id) on delete set null,
  created_at    timestamptz not null default now()
);

-- ─── 16. GROUP_EXAMS TABLE ────────────────────────────────────────────────────
create table if not exists public.group_exams (
  id          uuid        primary key default gen_random_uuid(),
  group_id    uuid        not null references public.groups(id) on delete cascade,
  exam_id     uuid        not null references public.exams(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  unique (group_id, exam_id)
);

-- ─── 17. QUESTIONS TABLE ──────────────────────────────────────────────────────
create table if not exists public.questions (
  id                  uuid        primary key default gen_random_uuid(),
  exam_id             uuid        not null references public.exams(id) on delete cascade,
  question_text       text        not null,
  type                text        not null default 'mcq'
                                  check (type in ('mcq', 'text', 'paragraph', 'grammar', 'writing', 'listening')),
  options             jsonb,
  correct_answer      text        not null default '',
  correct_answer_json jsonb,
  audio_url           text,
  content             text,
  extra_data          jsonb,
  order_index         integer     not null default 0,
  created_at          timestamptz not null default now()
);

-- ─── 18. EXAM_ANSWERS TABLE ───────────────────────────────────────────────────
create table if not exists public.exam_answers (
  id             uuid         primary key default gen_random_uuid(),
  student_id     uuid         not null references public.profiles(id) on delete cascade,
  exam_id        uuid         not null references public.exams(id) on delete cascade,
  question_id    uuid         not null references public.questions(id) on delete cascade,
  answer         jsonb,
  is_correct     boolean,
  score          numeric(5,2),
  admin_grade    numeric(5,2),
  admin_feedback text,
  answer_status  text         not null default 'pending'
                              check (answer_status in ('pending', 'auto_graded', 'reviewed')),
  created_at     timestamptz  not null default now(),
  updated_at     timestamptz  not null default now(),
  unique (student_id, exam_id, question_id)
);

create index if not exists exam_answers_exam_student_q on public.exam_answers(exam_id, student_id, question_id);
create index if not exists exam_answers_student        on public.exam_answers(student_id, exam_id);

create or replace function public.set_exam_answers_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists exam_answers_updated_at on public.exam_answers;
create trigger exam_answers_updated_at
  before update on public.exam_answers
  for each row execute function public.set_exam_answers_updated_at();

-- ─── 19. RESULTS TABLE ────────────────────────────────────────────────────────
create table if not exists public.results (
  id            uuid         primary key default gen_random_uuid(),
  student_id    uuid         not null references public.profiles(id) on delete cascade,
  exam_id       uuid         not null references public.exams(id) on delete cascade,
  score         numeric(5,2),
  passed        boolean      not null default false,
  review_status text         not null default 'completed'
                             check (review_status in ('pending_review', 'completed')),
  taken_at      timestamptz  not null default now(),
  unique (student_id, exam_id)
);

-- ─── 20. WEBSITE TABLES (Spaces, Events, Bookings) ─────────────────────────────
create table if not exists public.website_spaces (
  id          uuid        primary key default gen_random_uuid(),
  title       text        not null,
  description text,
  category    text,
  image_path  text        not null,
  order_index integer     not null default 0,
  created_at  timestamptz not null default now()
);

create table if not exists public.website_events (
  id          uuid        primary key default gen_random_uuid(),
  title       text        not null,
  description text,
  starts_at   timestamptz not null,
  ends_at     timestamptz,
  location    text,
  type        text,
  image_path  text,
  capacity    integer,
  price       text,
  is_active   boolean     not null default true,
  created_at  timestamptz not null default now()
);

create table if not exists public.website_event_bookings (
  id         uuid        primary key default gen_random_uuid(),
  event_id   uuid        not null references public.website_events(id) on delete cascade,
  user_id    uuid        references public.profiles(id) on delete set null,
  name       text,
  email      text,
  seats      integer     not null default 1,
  created_at timestamptz not null default now()
);

-- ─── 21. NOTIFICATIONS TABLE ───────────────────────────────────────────────────
create table if not exists public.notifications (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references public.profiles(id) on delete cascade,
  type            text        not null check (type in ('material','assignment','exam','review','submission','announcement','reminder','alert','event')),
  title           text        not null,
  message         text        not null,
  related_id      uuid,
  is_read         boolean     not null default false,
  announcement_id uuid        not null default gen_random_uuid(),
  target_level    text        not null default 'all',
  priority        text        not null default 'medium' check (priority in ('low','medium','high')),
  expires_at      timestamptz,
  is_active       boolean     not null default true,
  created_by      uuid        references public.profiles(id) on delete set null,
  created_at      timestamptz not null default now()
);

create index if not exists idx_notifications_user_created on public.notifications(user_id, created_at desc);
create index if not exists idx_notifications_user_read    on public.notifications(user_id, is_read);
create index if not exists idx_notifications_announcement on public.notifications(announcement_id);

-- ─── 22. STORED FUNCTIONS & RPCS ───────────────────────────────────────────────

-- Exam access validation
create or replace function public.can_access_exam(p_exam_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.exams e
    join public.levels l on l.id = e.level_id
    join public.profiles p on p.id = auth.uid()
    where e.id = p_exam_id
      and (
        p.role = 'admin'
        or lower(btrim(p.current_level)) = lower(btrim(l.name))
      )
  );
$$;

-- Autosave student answer
create or replace function public.upsert_student_exam_answer(
  p_exam_id uuid,
  p_question_id uuid,
  p_answer jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.can_access_exam(p_exam_id) then
    raise exception 'Exam not accessible';
  end if;

  if exists (
    select 1 from public.results r
    where r.exam_id = p_exam_id and r.student_id = v_uid
  ) then
    raise exception 'Exam already submitted';
  end if;

  insert into public.exam_answers (student_id, exam_id, question_id, answer, is_correct)
  values (v_uid, p_exam_id, p_question_id, p_answer, null)
  on conflict (student_id, exam_id, question_id)
  do update set
    answer = excluded.answer,
    updated_at = now();
end;
$$;

-- Batch submit graded exam answers
create or replace function public.submit_exam_answers_graded(
  p_exam_id uuid,
  p_rows jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  r jsonb;
  v_correct boolean;
  v_ans_status text;
  v_qscore numeric;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.can_access_exam(p_exam_id) then
    raise exception 'Exam not accessible';
  end if;

  if exists (
    select 1 from public.results r2
    where r2.exam_id = p_exam_id and r2.student_id = v_uid
  ) then
    raise exception 'Exam already submitted';
  end if;

  for r in select * from jsonb_array_elements(p_rows)
  loop
    if not (r ? 'is_correct') or jsonb_typeof(r -> 'is_correct') = 'null' then
      v_correct := null;
    else
      v_correct := (r ->> 'is_correct')::boolean;
    end if;

    v_ans_status := coalesce(r ->> 'answer_status', 'pending');
    if r ? 'score' and jsonb_typeof(r -> 'score') != 'null' then
      v_qscore := (r ->> 'score')::numeric;
    else
      v_qscore := null;
    end if;

    insert into public.exam_answers (
      student_id,
      exam_id,
      question_id,
      answer,
      is_correct,
      answer_status,
      score,
      admin_grade
    )
    values (
      v_uid,
      p_exam_id,
      (r ->> 'question_id')::uuid,
      r -> 'answer',
      v_correct,
      v_ans_status,
      v_qscore,
      case when v_ans_status = 'reviewed' then v_qscore else null end
    )
    on conflict (student_id, exam_id, question_id)
    do update set
      answer = excluded.answer,
      is_correct = excluded.is_correct,
      answer_status = excluded.answer_status,
      score = excluded.score,
      admin_grade = excluded.admin_grade,
      updated_at = now();
  end loop;
end;
$$;

-- Notification dispatchers
create or replace function public.notify_admins(
  p_type text,
  p_title text,
  p_message text,
  p_related_id uuid default null,
  p_priority text default 'medium'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, type, title, message, related_id, priority, is_active)
  select p.id, p_type, p_title, p_message, p_related_id, p_priority, true
  from public.profiles p
  where p.role = 'admin';
end;
$$;

create or replace function public.notify_user(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_message text,
  p_related_id uuid default null,
  p_priority text default 'medium',
  p_created_by uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not (public.is_admin() or public.can_assign_materials()) then
    raise exception 'not authorized to send notifications';
  end if;

  if not exists (
    select 1 from public.profiles p where p.id = p_user_id and p.role = 'student'
  ) then
    raise exception 'target user must be a student';
  end if;

  insert into public.notifications (
    user_id,
    type,
    title,
    message,
    related_id,
    priority,
    is_active,
    created_by,
    target_level
  )
  values (
    p_user_id,
    p_type,
    p_title,
    p_message,
    p_related_id,
    coalesce(p_priority, 'medium'),
    true,
    p_created_by,
    'all'
  );
end;
$$;

grant execute on function public.upsert_student_exam_answer(uuid, uuid, jsonb) to authenticated;
grant execute on function public.submit_exam_answers_graded(uuid, jsonb) to authenticated;
grant execute on function public.notify_admins(text, text, text, uuid, text) to authenticated;
grant execute on function public.notify_user(uuid, text, text, text, uuid, text, uuid) to authenticated;

-- ─── 23. ROW LEVEL SECURITY (RLS) POLICIES ─────────────────────────────────────

-- Enable RLS on all tables
alter table public.profiles              enable row level security;
alter table public.levels                enable row level security;
alter table public.level_students        enable row level security;
alter table public.groups                enable row level security;
alter table public.instructor_groups     enable row level security;
alter table public.level_sessions        enable row level security;
alter table public.level_settings        enable row level security;
alter table public.attendance            enable row level security;
alter table public.materials             enable row level security;
alter table public.student_materials     enable row level security;
alter table public.assignments           enable row level security;
alter table public.group_assignments     enable row level security;
alter table public.submissions           enable row level security;
alter table public.exams                 enable row level security;
alter table public.group_exams           enable row level security;
alter table public.questions             enable row level security;
alter table public.exam_answers          enable row level security;
alter table public.results               enable row level security;
alter table public.website_spaces        enable row level security;
alter table public.website_events        enable row level security;
alter table public.website_event_bookings enable row level security;
alter table public.notifications         enable row level security;

-- PROFILES
create policy "profiles: select"
  on public.profiles for select
  using (
    auth.uid() = id
    or public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
  );

create policy "profiles: insert"
  on public.profiles for insert
  with check (
    auth.uid() = id
    or public.is_admin()
  );

create policy "profiles: update"
  on public.profiles for update
  using (
    auth.uid() = id
    or public.is_admin()
    or (public.is_secretary() and role = 'student')
  )
  with check (
    auth.uid() = id
    or public.is_admin()
    or (public.is_secretary() and role = 'student')
  );

create policy "profiles: admin delete"
  on public.profiles for delete
  using (public.is_admin());

-- LEVELS
create policy "levels: select all"
  on public.levels for select
  using (true);

create policy "levels: staff manage"
  on public.levels for all
  using (public.is_admin() or public.is_secretary())
  with check (public.is_admin() or public.is_secretary());

-- LEVEL_STUDENTS
create policy "level_students: select"
  on public.level_students for select
  using (
    public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
    or student_id = auth.uid()
  );

create policy "level_students: staff write"
  on public.level_students for all
  using (public.is_admin() or public.is_secretary())
  with check (public.is_admin() or public.is_secretary());

-- GROUPS
create policy "groups: select"
  on public.groups for select
  using (
    public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
    or id = (select group_id from public.profiles where id = auth.uid())
  );

create policy "groups: staff manage"
  on public.groups for all
  using (public.is_admin() or public.is_secretary())
  with check (public.is_admin() or public.is_secretary());

-- INSTRUCTOR_GROUPS
create policy "instructor_groups: select"
  on public.instructor_groups for select
  using (
    public.is_admin()
    or instructor_id = auth.uid()
  );

create policy "instructor_groups: admin write"
  on public.instructor_groups for all
  using (public.is_admin())
  with check (public.is_admin());

-- LEVEL_SESSIONS & SETTINGS
create policy "level_sessions: select"
  on public.level_sessions for select
  using (
    public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
    or exists (select 1 from public.level_students where student_id = auth.uid() and level_id = level_sessions.level_id)
  );

create policy "level_sessions: staff write"
  on public.level_sessions for all
  using (public.is_admin() or public.is_secretary())
  with check (public.is_admin() or public.is_secretary());

create policy "level_settings: select all"
  on public.level_settings for select
  using (true);

create policy "level_settings: admin write"
  on public.level_settings for all
  using (public.is_admin())
  with check (public.is_admin());

-- ATTENDANCE
create policy "attendance: select"
  on public.attendance for select
  using (
    public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
    or student_id = auth.uid()
  );

create policy "attendance: staff write"
  on public.attendance for all
  using (public.is_admin() or public.is_secretary() or public.is_instructor())
  with check (public.is_admin() or public.is_secretary() or public.is_instructor());

-- MATERIALS
create policy "materials: select"
  on public.materials for select
  using (
    public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
    or exists (
      select 1 from public.profiles p
      join public.levels l on l.name = p.current_level
      where p.id = auth.uid() and p.role = 'student' and l.id = materials.level_id
    )
    or exists (
      select 1 from public.student_materials sm
      where sm.material_id = materials.id
        and sm.student_id = auth.uid()
        and coalesce(sm.visible, true) = true
    )
  );

create policy "materials: admin write"
  on public.materials for all
  using (public.is_admin())
  with check (public.is_admin());

-- STUDENT_MATERIALS
create policy "student_materials: select"
  on public.student_materials for select
  using (
    student_id = auth.uid()
    or public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
  );

create policy "student_materials: staff insert"
  on public.student_materials for insert
  with check (public.can_assign_materials());

create policy "student_materials: staff update"
  on public.student_materials for update
  using (public.can_assign_materials() or public.is_instructor())
  with check (public.can_assign_materials() or public.is_instructor());

create policy "student_materials: staff delete"
  on public.student_materials for delete
  using (public.can_assign_materials());

-- ASSIGNMENTS & GROUP_ASSIGNMENTS
create policy "assignments: select"
  on public.assignments for select
  using (true);

create policy "assignments: staff manage"
  on public.assignments for all
  using (public.is_admin() or public.is_instructor())
  with check (public.is_admin() or public.is_instructor());

create policy "group_assignments: select"
  on public.group_assignments for select
  using (
    public.is_admin()
    or group_id in (select group_id from public.instructor_groups where instructor_id = auth.uid())
    or group_id = (select group_id from public.profiles where id = auth.uid())
  );

create policy "group_assignments: admin manage"
  on public.group_assignments for all
  using (public.is_admin())
  with check (public.is_admin());

-- SUBMISSIONS
create policy "submissions: select"
  on public.submissions for select
  using (
    auth.uid() = student_id
    or public.is_admin()
    or public.is_instructor()
  );

create policy "submissions: student insert own"
  on public.submissions for insert
  with check (auth.uid() = student_id);

create policy "submissions: student update own pending"
  on public.submissions for update
  using (
    (auth.uid() = student_id and status = 'pending')
    or public.is_admin()
    or public.is_instructor()
  )
  with check (
    (auth.uid() = student_id and status = 'pending')
    or public.is_admin()
    or public.is_instructor()
  );

create policy "submissions: admin manage"
  on public.submissions for all
  using (public.is_admin())
  with check (public.is_admin());

-- EXAMS & GROUP_EXAMS
create policy "exams: select"
  on public.exams for select
  using (true);

create policy "exams: staff manage"
  on public.exams for all
  using (public.is_admin() or public.is_instructor())
  with check (public.is_admin() or public.is_instructor());

create policy "group_exams: select"
  on public.group_exams for select
  using (
    public.is_admin()
    or group_id in (select group_id from public.instructor_groups where instructor_id = auth.uid())
    or group_id = (select group_id from public.profiles where id = auth.uid())
  );

create policy "group_exams: admin manage"
  on public.group_exams for all
  using (public.is_admin())
  with check (public.is_admin());

-- QUESTIONS
create policy "questions: select"
  on public.questions for select
  using (true);

create policy "questions: staff manage"
  on public.questions for all
  using (public.is_admin() or public.is_instructor())
  with check (public.is_admin() or public.is_instructor());

-- EXAM_ANSWERS
create policy "exam_answers: student select"
  on public.exam_answers for select
  using (
    (auth.uid() = student_id and public.can_access_exam(exam_id))
    or public.is_admin()
    or public.is_instructor()
  );

create policy "exam_answers: student insert"
  on public.exam_answers for insert
  with check (
    auth.uid() = student_id
    and public.can_access_exam(exam_id)
    and not exists (
      select 1 from public.results r
      where r.exam_id = exam_answers.exam_id
        and r.student_id = exam_answers.student_id
    )
  );

create policy "exam_answers: student update"
  on public.exam_answers for update
  using (
    (
      auth.uid() = student_id
      and public.can_access_exam(exam_id)
      and not exists (
        select 1 from public.results r
        where r.exam_id = exam_answers.exam_id
          and r.student_id = exam_answers.student_id
      )
    )
    or public.is_admin()
    or public.is_instructor()
  )
  with check (
    (
      auth.uid() = student_id
      and public.can_access_exam(exam_id)
      and not exists (
        select 1 from public.results r
        where r.exam_id = exam_answers.exam_id
          and r.student_id = exam_answers.student_id
      )
    )
    or public.is_admin()
    or public.is_instructor()
  );

create policy "exam_answers: admin full"
  on public.exam_answers for all
  using (public.is_admin() or public.is_instructor())
  with check (public.is_admin() or public.is_instructor());

-- RESULTS
create policy "results: select"
  on public.results for select
  using (
    auth.uid() = student_id
    or public.is_admin()
    or public.is_instructor()
  );

create policy "results: insert own"
  on public.results for insert
  with check (
    auth.uid() = student_id
    or public.is_admin()
  );

create policy "results: admin manage"
  on public.results for all
  using (public.is_admin())
  with check (public.is_admin());

-- WEBSITE CONTENT
create policy "website_spaces: public read"
  on public.website_spaces for select
  using (true);

create policy "website_spaces: admin full"
  on public.website_spaces for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "website_events: public read"
  on public.website_events for select
  using (is_active = true or public.is_admin());

create policy "website_events: admin full"
  on public.website_events for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "website_event_bookings: public insert"
  on public.website_event_bookings for insert
  with check (true);

create policy "website_event_bookings: read"
  on public.website_event_bookings for select
  using (public.is_admin() or user_id = auth.uid());

create policy "website_event_bookings: admin full"
  on public.website_event_bookings for all
  using (public.is_admin())
  with check (public.is_admin());

-- NOTIFICATIONS
create policy "notifications: select own"
  on public.notifications for select
  using (auth.uid() = user_id or public.is_admin());

create policy "notifications: insert staff"
  on public.notifications for insert
  with check (
    public.can_assign_materials()
    or public.is_admin()
    or (
      auth.role() = 'authenticated'
      and type in ('submission', 'event')
    )
  );

create policy "notifications: update own"
  on public.notifications for update
  using (auth.uid() = user_id or public.is_admin())
  with check (auth.uid() = user_id or public.is_admin());

create policy "notifications: admin delete"
  on public.notifications for delete
  using (public.is_admin());

-- ─── 24. STORAGE BUCKETS & STORAGE RLS ─────────────────────────────────────────

insert into storage.buckets (id, name, public)
values
  ('materials', 'materials', false),
  ('submissions', 'submissions', false),
  ('avatars', 'avatars', false),
  ('public-assets', 'public-assets', true)
on conflict (id) do update set public = excluded.public;

-- Materials storage policies
drop policy if exists "materials bucket read authenticated" on storage.objects;
drop policy if exists "materials bucket admin write" on storage.objects;

create policy "materials bucket read authenticated"
  on storage.objects for select
  using (bucket_id = 'materials' and auth.role() = 'authenticated');

create policy "materials bucket admin write"
  on storage.objects for all
  using (bucket_id = 'materials' and (public.is_admin() or public.is_instructor()))
  with check (bucket_id = 'materials' and (public.is_admin() or public.is_instructor()));

-- Submissions storage policies
drop policy if exists "submissions bucket read authenticated" on storage.objects;
drop policy if exists "submissions bucket staff write" on storage.objects;
drop policy if exists "submissions bucket student write own folder" on storage.objects;

create policy "submissions bucket read authenticated"
  on storage.objects for select
  using (bucket_id = 'submissions' and auth.role() = 'authenticated');

create policy "submissions bucket staff write"
  on storage.objects for all
  using (bucket_id = 'submissions' and (public.is_admin() or public.is_instructor()))
  with check (bucket_id = 'submissions' and (public.is_admin() or public.is_instructor()));

create policy "submissions bucket student write own folder"
  on storage.objects for all
  using (
    bucket_id = 'submissions'
    and auth.role() = 'authenticated'
    and split_part(name, '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'submissions'
    and auth.role() = 'authenticated'
    and split_part(name, '/', 1) = auth.uid()::text
  );

-- Avatars storage policies
drop policy if exists "avatars bucket read authenticated" on storage.objects;
drop policy if exists "avatars bucket owner write" on storage.objects;

create policy "avatars bucket read authenticated"
  on storage.objects for select
  using (bucket_id = 'avatars' and auth.role() = 'authenticated');

create policy "avatars bucket owner write"
  on storage.objects for all
  using (bucket_id = 'avatars' and auth.role() = 'authenticated')
  with check (bucket_id = 'avatars' and auth.role() = 'authenticated');

-- Public assets storage policies
drop policy if exists "public-assets bucket read all" on storage.objects;
drop policy if exists "public-assets bucket admin write" on storage.objects;

create policy "public-assets bucket read all"
  on storage.objects for select
  using (bucket_id = 'public-assets');

create policy "public-assets bucket admin write"
  on storage.objects for all
  using (bucket_id = 'public-assets' and public.is_admin())
  with check (bucket_id = 'public-assets' and public.is_admin());

-- ─── 25. REALTIME PUBLICATION ──────────────────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

alter table public.notifications replica identity full;

-- ─── 26. SEED DEFAULT LEVELS ───────────────────────────────────────────────────
insert into public.levels (name, description) values
  ('A1', 'Absolute Beginner — basic greetings and introductions'),
  ('A2', 'Elementary — everyday expressions and simple sentences'),
  ('B1', 'Intermediate — clear language on familiar topics'),
  ('B2', 'Upper-Intermediate — complex texts and fluent interaction')
on conflict (name) do nothing;

-- ─── 27. PERMISSIONS & SCHEMA GRANTS ───────────────────────────────────────────
grant usage on schema public to anon, authenticated;
grant select on public.levels to anon, authenticated;
grant select on public.website_spaces to anon, authenticated;
grant select on public.website_events to anon, authenticated;
grant insert on public.website_event_bookings to anon, authenticated;
grant select on public.website_event_bookings to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

-- ==============================================================================
-- COMPLETED MASTER SCHEMA SETUP ✅
-- ==============================================================================
