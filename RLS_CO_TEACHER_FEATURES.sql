-- RLS_CO_TEACHER_FEATURES.sql
-- Purpose: Idempotent RLS policies to grant co-teachers (classroom_teachers)
--          full access to classroom courses (subjects), modules, assignments,
--          announcements, and replies.
-- Note: This script assumes the following tables exist:
--   classrooms(id, teacher_id, ...), classroom_teachers(classroom_id, teacher_id, ...),
--   classroom_courses(classroom_id, course_id, added_by, ...),
--   assignments(classroom_id, ...), announcements(classroom_id, ...),
--   announcement_replies(announcement_id, author_id, ...),
--   course_modules(course_id, ...), course_assignments(course_id, ...)
-- Run safely multiple times.

-- =============================
-- CLASSROOMS (co-teacher view)
-- =============================
alter table if exists public.classrooms enable row level security;

DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'classrooms_select_co_teachers'
      AND schemaname = 'public'
      AND tablename = 'classrooms'
  ) THEN
    EXECUTE $$
      create policy classrooms_select_co_teachers
      on public.classrooms
      for select
      using (
        exists (
          select 1 from public.classroom_teachers ct
          where ct.classroom_id = classrooms.id
            and ct.teacher_id = auth.uid()
        )
        or classrooms.teacher_id = auth.uid()
      );
    $$;
  END IF;
END $rls$;

-- =============================================
-- CLASSROOM_COURSES (manage subjects in classroom)
-- =============================================
alter table if exists public.classroom_courses enable row level security;

-- SELECT
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'classroom_courses_select_memberships'
      AND schemaname = 'public'
      AND tablename = 'classroom_courses'
  ) THEN
    EXECUTE $$
      create policy classroom_courses_select_memberships
      on public.classroom_courses
      for select
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- INSERT (allow owner or co-teacher to add a course to the classroom)
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'classroom_courses_insert_memberships'
      AND schemaname = 'public'
      AND tablename = 'classroom_courses'
  ) THEN
    EXECUTE $$
      create policy classroom_courses_insert_memberships
      on public.classroom_courses
      for insert
      with check (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- UPDATE (optional, mirror SELECT rules)
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'classroom_courses_update_memberships'
      AND schemaname = 'public'
      AND tablename = 'classroom_courses'
  ) THEN
    EXECUTE $$
      create policy classroom_courses_update_memberships
      on public.classroom_courses
      for update
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      )
      with check (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- DELETE (allow owner or co-teacher)
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'classroom_courses_delete_memberships'
      AND schemaname = 'public'
      AND tablename = 'classroom_courses'
  ) THEN
    EXECUTE $$
      create policy classroom_courses_delete_memberships
      on public.classroom_courses
      for delete
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- =====================
-- ASSIGNMENTS (4 tabs)
-- =====================
alter table if exists public.assignments enable row level security;

-- SELECT
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'assignments_select_memberships'
      AND schemaname = 'public'
      AND tablename = 'assignments'
  ) THEN
    EXECUTE $$
      create policy assignments_select_memberships
      on public.assignments
      for select
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- INSERT
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'assignments_insert_memberships'
      AND schemaname = 'public'
      AND tablename = 'assignments'
  ) THEN
    EXECUTE $$
      create policy assignments_insert_memberships
      on public.assignments
      for insert
      with check (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- UPDATE
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'assignments_update_memberships'
      AND schemaname = 'public'
      AND tablename = 'assignments'
  ) THEN
    EXECUTE $$
      create policy assignments_update_memberships
      on public.assignments
      for update
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      )
      with check (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- DELETE
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'assignments_delete_memberships'
      AND schemaname = 'public'
      AND tablename = 'assignments'
  ) THEN
    EXECUTE $$
      create policy assignments_delete_memberships
      on public.assignments
      for delete
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- ======================
-- ANNOUNCEMENTS (4 tabs)
-- ======================
alter table if exists public.announcements enable row level security;

-- SELECT
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'announcements_select_memberships'
      AND schemaname = 'public'
      AND tablename = 'announcements'
  ) THEN
    EXECUTE $$
      create policy announcements_select_memberships
      on public.announcements
      for select
      using (
        exists (
          select 1 from public.classrooms c
          where c.id::text = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- INSERT
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'announcements_insert_memberships'
      AND schemaname = 'public'
      AND tablename = 'announcements'
  ) THEN
    EXECUTE $$
      create policy announcements_insert_memberships
      on public.announcements
      for insert
      with check (
        exists (
          select 1 from public.classrooms c
          where c.id::text = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- UPDATE
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'announcements_update_memberships'
      AND schemaname = 'public'
      AND tablename = 'announcements'
  ) THEN
    EXECUTE $$
      create policy announcements_update_memberships
      on public.announcements
      for update
      using (
        exists (
          select 1 from public.classrooms c
          where c.id::text = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      )
      with check (
        exists (
          select 1 from public.classrooms c
          where c.id::text = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- DELETE
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'announcements_delete_memberships'
      AND schemaname = 'public'
      AND tablename = 'announcements'
  ) THEN
    EXECUTE $$
      create policy announcements_delete_memberships
      on public.announcements
      for delete
      using (
        exists (
          select 1 from public.classrooms c
          where c.id::text = classroom_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- ============================
-- ANNOUNCEMENT_REPLIES (4 tabs)
-- ============================
alter table if exists public.announcement_replies enable row level security;

-- SELECT (allowed if member of the parent announcement's classroom)
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'announcement_replies_select_memberships'
      AND schemaname = 'public'
      AND tablename = 'announcement_replies'
  ) THEN
    EXECUTE $$
      create policy announcement_replies_select_memberships
      on public.announcement_replies
      for select
      using (
        exists (
          select 1 from public.announcements a
          join public.classrooms c on c.id::text = a.classroom_id
          where a.id = announcement_replies.announcement_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = c.id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- INSERT (author must be current user and member of the parent classroom)
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'announcement_replies_insert_memberships'
      AND schemaname = 'public'
      AND tablename = 'announcement_replies'
  ) THEN
    EXECUTE $$
      create policy announcement_replies_insert_memberships
      on public.announcement_replies
      for insert
      with check (
        author_id_uuid = auth.uid()
        and exists (
          select 1 from public.announcements a
          join public.classrooms c on c.id::text = a.classroom_id
          where a.id = announcement_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = c.id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- DELETE (author OR owner/co-teacher of the parent classroom)
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'announcement_replies_delete_memberships'
      AND schemaname = 'public'
      AND tablename = 'announcement_replies'
  ) THEN
    EXECUTE $$
      create policy announcement_replies_delete_memberships
      on public.announcement_replies
      for delete
      using (
        announcement_replies.author_id_uuid = auth.uid()
        or exists (
          select 1 from public.announcements a
          join public.classrooms c on c.id::text = a.classroom_id
          where a.id = announcement_replies.announcement_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = c.id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- ======================
-- COURSE_MODULES (modules)
-- ======================
alter table if exists public.course_modules enable row level security;

-- SELECT (member of any classroom that links to this course)
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'course_modules_select_memberships'
      AND schemaname = 'public'
      AND tablename = 'course_modules'
  ) THEN
    EXECUTE $$
      create policy course_modules_select_memberships
      on public.course_modules
      for select
      using (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_modules.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- INSERT
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'course_modules_insert_memberships'
      AND schemaname = 'public'
      AND tablename = 'course_modules'
  ) THEN
    EXECUTE $$
      create policy course_modules_insert_memberships
      on public.course_modules
      for insert
      with check (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_modules.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- UPDATE
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'course_modules_update_memberships'
      AND schemaname = 'public'
      AND tablename = 'course_modules'
  ) THEN
    EXECUTE $$
      create policy course_modules_update_memberships
      on public.course_modules
      for update
      using (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_modules.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      )
      with check (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_modules.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- DELETE
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'course_modules_delete_memberships'
      AND schemaname = 'public'
      AND tablename = 'course_modules'
  ) THEN
    EXECUTE $$
      create policy course_modules_delete_memberships
      on public.course_modules
      for delete
      using (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_modules.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- ===========================
-- COURSE_ASSIGNMENTS (helper)
-- ===========================
alter table if exists public.course_assignments enable row level security;

-- SELECT / INSERT / UPDATE / DELETE share same membership logic as course_modules
DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'course_assignments_select_memberships'
      AND schemaname = 'public'
      AND tablename = 'course_assignments'
  ) THEN
    EXECUTE $$
      create policy course_assignments_select_memberships
      on public.course_assignments
      for select
      using (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_assignments.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'course_assignments_insert_memberships'
      AND schemaname = 'public'
      AND tablename = 'course_assignments'
  ) THEN
    EXECUTE $$
      create policy course_assignments_insert_memberships
      on public.course_assignments
      for insert
      with check (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_assignments.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'course_assignments_update_memberships'
      AND schemaname = 'public'
      AND tablename = 'course_assignments'
  ) THEN
    EXECUTE $$
      create policy course_assignments_update_memberships
      on public.course_assignments
      for update
      using (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_assignments.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      )
      with check (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_assignments.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

DO $rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'course_assignments_delete_memberships'
      AND schemaname = 'public'
      AND tablename = 'course_assignments'
  ) THEN
    EXECUTE $$
      create policy course_assignments_delete_memberships
      on public.course_assignments
      for delete
      using (
        exists (
          select 1 from public.classroom_courses cc
          join public.classrooms c on c.id = cc.classroom_id
          where cc.course_id = course_assignments.course_id
            and (c.teacher_id = auth.uid()
                 or exists (
                   select 1 from public.classroom_teachers ct
                   where ct.classroom_id = cc.classroom_id
                     and ct.teacher_id = auth.uid()
                 ))
        )
      );
    $$;
  END IF;
END $rls$;

-- End of script