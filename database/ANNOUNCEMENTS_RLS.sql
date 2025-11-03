-- ANNOUNCEMENTS RLS POLICIES (Idempotent, with safe type casts)
-- Enables RLS and defines policies so:
--  - Teachers assigned to the course can INSERT/SELECT/UPDATE/DELETE announcements for that course
--  - Students enrolled in any classroom that uses the course can SELECT announcements
--  - Admins can manage all announcements via public.is_admin(auth.uid())
-- Casting to text is used in identity comparisons to avoid text vs uuid operator errors.

begin;

-- Enable RLS
alter table if exists public.announcements enable row level security;

-- Default timestamp and helpful indexes (safe if columns exist)
alter table if exists public.announcements
  alter column created_at set default now();

create index if not exists idx_announcements_course_id on public.announcements(course_id);
create index if not exists idx_announcements_created_at on public.announcements(created_at desc);

-- Drop existing policies for idempotency
drop policy if exists "Announcements select visible to teachers and students" on public.announcements;
drop policy if exists "Teachers insert course announcements" on public.announcements;
drop policy if exists "Teachers update course announcements" on public.announcements;
drop policy if exists "Teachers delete course announcements" on public.announcements;

-- SELECT policy
create policy "Announcements select visible to teachers and students"
  on public.announcements
  for select
  to authenticated
  using (
    -- Teacher assigned to the course
    exists (
      select 1
      from public.course_teachers ct
      where ct.course_id = public.announcements.course_id
        and ct.teacher_id::text = auth.uid()::text
    )
    or
    -- Student enrolled in a classroom that includes the course
    exists (
      select 1
      from public.classroom_courses cc
      join public.classroom_students cs on cs.classroom_id = cc.classroom_id
      where cc.course_id = public.announcements.course_id
        and cs.student_id::text = auth.uid()::text
    )
    or
    -- Admin override
    coalesce((select public.is_admin(auth.uid())), false)
  );

-- INSERT policy (teachers or admins)
create policy "Teachers insert course announcements"
  on public.announcements
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.course_teachers ct
      where ct.course_id = public.announcements.course_id
        and ct.teacher_id::text = auth.uid()::text
    )
    or coalesce((select public.is_admin(auth.uid())), false)
  );

-- UPDATE policy (teachers or admins)
create policy "Teachers update course announcements"
  on public.announcements
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.course_teachers ct
      where ct.course_id = public.announcements.course_id
        and ct.teacher_id::text = auth.uid()::text
    )
    or coalesce((select public.is_admin(auth.uid())), false)
  )
  with check (
    exists (
      select 1
      from public.course_teachers ct
      where ct.course_id = public.announcements.course_id
        and ct.teacher_id::text = auth.uid()::text
    )
    or coalesce((select public.is_admin(auth.uid())), false)
  );

-- DELETE policy (teachers or admins)
create policy "Teachers delete course announcements"
  on public.announcements
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.course_teachers ct
      where ct.course_id = public.announcements.course_id
        and ct.teacher_id::text = auth.uid()::text
    )
    or coalesce((select public.is_admin(auth.uid())), false)
  );

commit;
