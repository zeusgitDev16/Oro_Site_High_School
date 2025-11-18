-- teacher_courses_modules_classrooms_rls_fix.sql
-- Purpose: Enable teacher course feature:
--   - Teacher sees modules & assignment resources for assigned courses
--   - Teacher can share/unshare courses to classrooms they own or co-teach
-- Idempotent & additive (no drops).

-- ============================================================
-- 0) COURSES: teacher can SELECT courses assigned via course_teachers
-- ============================================================
alter table if exists public.courses enable row level security;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'courses'
      AND policyname = 'courses_select_course_teachers'
  ) THEN
    EXECUTE '
      create policy courses_select_course_teachers
      on public.courses
      for select
      using (
        exists (
          select 1 from public.course_teachers ct
          where ct.course_id = courses.id
            and ct.teacher_id::text = auth.uid()::text
        )
      );
    ';
  END IF;
END $$;

-- ============================================================
-- 1) COURSE_MODULES: teacher can view modules for assigned courses
-- ============================================================
alter table if exists public.course_modules enable row level security;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'course_modules'
      AND policyname = 'course_modules_select_course_teachers'
  ) THEN
    EXECUTE '
      create policy course_modules_select_course_teachers
      on public.course_modules
      for select
      using (
        exists (
          select 1 from public.course_teachers ct
          where ct.course_id = course_modules.course_id
            and ct.teacher_id::text = auth.uid()::text
        )
      );
    ';
  END IF;
END $$;

-- ============================================================
-- 2) COURSE_ASSIGNMENTS: teacher can view assignment resources
-- ============================================================
alter table if exists public.course_assignments enable row level security;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'course_assignments'
      AND policyname = 'course_assignments_select_course_teachers'
  ) THEN
    EXECUTE '
      create policy course_assignments_select_course_teachers
      on public.course_assignments
      for select
      using (
        exists (
          select 1 from public.course_teachers ct
          where ct.course_id = course_assignments.course_id
            and ct.teacher_id::text = auth.uid()::text
        )
      );
    ';
  END IF;
END $$;

-- ============================================================
-- 3) CLASSROOM_COURSES: share/unshare courses to owned/co-taught classrooms
--    (matches RLS_CO_TEACHER_FEATURES membership logic)
-- ============================================================
alter table if exists public.classroom_courses enable row level security;

-- SELECT
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'classroom_courses'
      AND policyname = 'classroom_courses_select_memberships'
  ) THEN
    EXECUTE '
      create policy classroom_courses_select_memberships
      on public.classroom_courses
      for select
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (
              c.teacher_id = auth.uid()
              or exists (
                select 1 from public.classroom_teachers ct
                where ct.classroom_id = classroom_id
                  and ct.teacher_id = auth.uid()
              )
            )
        )
      );
    ';
  END IF;
END $$;

-- INSERT (share course to classroom)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'classroom_courses'
      AND policyname = 'classroom_courses_insert_memberships'
  ) THEN
    EXECUTE '
      create policy classroom_courses_insert_memberships
      on public.classroom_courses
      for insert
      with check (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (
              c.teacher_id = auth.uid()
              or exists (
                select 1 from public.classroom_teachers ct
                where ct.classroom_id = classroom_id
                  and ct.teacher_id = auth.uid()
              )
            )
        )
      );
    ';
  END IF;
END $$;

-- DELETE (optional un-share)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'classroom_courses'
      AND policyname = 'classroom_courses_delete_memberships'
  ) THEN
    EXECUTE '
      create policy classroom_courses_delete_memberships
      on public.classroom_courses
      for delete
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and (
              c.teacher_id = auth.uid()
              or exists (
                select 1 from public.classroom_teachers ct
                where ct.classroom_id = classroom_id
                  and ct.teacher_id = auth.uid()
              )
            )
        )
      );
    ';
  END IF;
END $$;

-- Note: this script does NOT add teacher DELETE on course_modules/course_assignments,
-- it only ensures visibility and classroom sharing. Admin DELETE remains controlled
-- by your existing admin policies.