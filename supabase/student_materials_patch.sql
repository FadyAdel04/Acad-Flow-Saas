-- ============================================================
-- Student materials assignment system + secretary RBAC
-- Safe to re-run: drops policies/constraints before recreating.
-- Run in Supabase SQL Editor after base schema patches.
-- ============================================================

-- ─── Role helpers ───────────────────────────────────────────────────────────

create or replace function public.is_secretary()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'secretary'
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
    select 1 from public.profiles
    where id = auth.uid() and role = 'instructor'
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

-- Allow secretary role on profiles
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('student', 'admin', 'instructor', 'secretary'));

-- ─── student_materials table ────────────────────────────────────────────────

create table if not exists public.student_materials (
  id             uuid        primary key default gen_random_uuid(),
  student_id     uuid        not null references public.profiles(id) on delete cascade,
  material_id    uuid        not null references public.materials(id) on delete cascade,
  assigned_by    uuid        references public.profiles(id) on delete set null,
  assigned_at    timestamptz not null default now(),
  available_from timestamptz not null default now(),
  visible        boolean     not null default true,
  status         text        not null default 'assigned',
  notes          text,
  unique (student_id, material_id)
);

-- Columns if table was created earlier without them
alter table public.student_materials add column if not exists status text;
alter table public.student_materials add column if not exists notes text;
alter table public.student_materials add column if not exists assigned_by uuid references public.profiles(id) on delete set null;
alter table public.student_materials add column if not exists assigned_at timestamptz default now();
alter table public.student_materials add column if not exists available_from timestamptz default now();
alter table public.student_materials add column if not exists visible boolean default true;

update public.student_materials set status = 'assigned' where status is null;
alter table public.student_materials alter column status set default 'assigned';
alter table public.student_materials alter column status set not null;

create index if not exists idx_student_materials_student on public.student_materials(student_id);
create index if not exists idx_student_materials_material on public.student_materials(material_id);
create index if not exists idx_student_materials_status on public.student_materials(status);

-- Migrate legacy material_assignments rows (once)
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'material_assignments'
  ) then
    insert into public.student_materials (
      student_id, material_id, assigned_at, available_from, visible, status
    )
    select
      ma.student_id,
      ma.material_id,
      coalesce(ma.created_at, now()),
      coalesce(ma.available_from, now()),
      coalesce(ma.visible, true),
      'assigned'
    from public.material_assignments ma
    on conflict (student_id, material_id) do nothing;
  end if;
end $$;

-- Status values: assigned (current level) | revision (previous levels)
update public.student_materials
set status = 'revision'
where status = 'completed';

update public.student_materials
set status = 'assigned'
where status is null or status not in ('assigned', 'revision');

alter table public.student_materials drop constraint if exists student_materials_status_check;
alter table public.student_materials
  add constraint student_materials_status_check
  check (status in ('assigned', 'revision'));

alter table public.student_materials enable row level security;

-- ─── RLS: student_materials ─────────────────────────────────────────────────

drop policy if exists "student_materials_select_own" on public.student_materials;
create policy "student_materials_select_own"
  on public.student_materials for select
  using (
    student_id = auth.uid()
    or public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
  );

drop policy if exists "student_materials_insert_staff" on public.student_materials;
create policy "student_materials_insert_staff"
  on public.student_materials for insert
  with check (public.can_assign_materials());

drop policy if exists "student_materials_update_staff" on public.student_materials;
create policy "student_materials_update_staff"
  on public.student_materials for update
  using (public.can_assign_materials() or public.is_instructor())
  with check (public.can_assign_materials() or public.is_instructor());

drop policy if exists "student_materials_delete_staff" on public.student_materials;
create policy "student_materials_delete_staff"
  on public.student_materials for delete
  using (public.can_assign_materials());

-- ─── RLS: materials ───────────────────────────────────────────────────────────
-- Students must read materials assigned via student_materials (including past-level revision).

drop policy if exists "materials_select_staff" on public.materials;
drop policy if exists "materials: student reads assigned" on public.materials;

create policy "materials_select_staff"
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

create policy "materials: student reads assigned"
  on public.materials for select
  using (
    exists (
      select 1 from public.student_materials sm
      where sm.material_id = materials.id
        and sm.student_id = auth.uid()
        and coalesce(sm.visible, true) = true
    )
  );

-- ─── RLS: profiles (secretary read students) ────────────────────────────────

drop policy if exists "profiles_select_secretary" on public.profiles;
create policy "profiles_select_secretary"
  on public.profiles for select
  using (
    auth.uid() = id
    or public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
  );

-- ─── RLS: levels (everyone read) ────────────────────────────────────────────

drop policy if exists "levels_select_secretary" on public.levels;
create policy "levels_select_secretary"
  on public.levels for select
  using (true);

-- ─── RLS: level_students (enrollment) ───────────────────────────────────────
-- Drop every known policy name (old + new) before recreate.

drop policy if exists "level_students_secretary" on public.level_students;
drop policy if exists "level_students_secretary_select" on public.level_students;
drop policy if exists "level_students_secretary_write" on public.level_students;

create policy "level_students_secretary_select"
  on public.level_students for select
  using (public.is_admin() or public.is_secretary() or public.is_instructor());

create policy "level_students_secretary_write"
  on public.level_students for all
  using (public.is_admin() or public.is_secretary())
  with check (public.is_admin() or public.is_secretary());

-- ─── Notifications: allow admin/secretary to notify students ────────────────
-- Fixes 403 on POST /rest/v1/notifications when secretary assigns materials.
-- (Existing "notifications: insert system" only allows is_admin() or student→admin.)

drop policy if exists "notifications: insert staff" on public.notifications;

create policy "notifications: insert staff"
  on public.notifications for insert
  with check (
    public.can_assign_materials()
    and exists (
      select 1 from public.profiles p
      where p.id = user_id and p.role = 'student'
    )
  );

-- Security-definer RPC (optional path; bypasses RLS safely for staff)
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

  if p_type not in (
    'material', 'assignment', 'exam', 'review', 'submission',
    'announcement', 'reminder', 'alert', 'event'
  ) then
    raise exception 'invalid notification type: %', p_type;
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

revoke all on function public.notify_user(uuid, text, text, text, uuid, text, uuid) from public;
grant execute on function public.notify_user(uuid, text, text, text, uuid, text, uuid) to authenticated;

-- ─── RLS: profiles (secretary update students) ──────────────────────────────

drop policy if exists "profiles_update_secretary" on public.profiles;
create policy "profiles_update_secretary"
  on public.profiles for update
  using (
    (public.is_secretary() and role = 'student')
    or public.is_admin()
  )
  with check (
    (public.is_secretary() and role = 'student')
    or public.is_admin()
  );

-- ─── RLS: groups (secretary select) ─────────────────────────────────────────

drop policy if exists "groups_select_secretary" on public.groups;
create policy "groups_select_secretary"
  on public.groups for select
  using (
    public.is_admin()
    or public.is_secretary()
    or public.is_instructor()
    or id = (select group_id from public.profiles where id = auth.uid())
  );

