-- teacher_classrooms_access_code_co_teachers_fix.sql
-- Purpose: Fix classroom access-code join for teachers (co-teachers)
--          while preserving existing student and owner behaviors.
--          Idempotent & additive: only adds policies, does not drop/alter.

-- ============================================================
-- 1) CLASSROOMS: allow active teachers to search by access code
--    (teachers can SELECT active classrooms; UI filters by access_code)
-- ============================================================
alter table if exists public.classrooms enable row level security;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'classrooms'
      AND policyname = 'teachers_search_by_access_code'
  ) THEN
    EXECUTE '
      create policy teachers_search_by_access_code
      on public.classrooms
      for select
      using (
        is_active = true
        and exists (
          select 1 from public.teachers t
          where t.id = auth.uid()
            and t.is_active = true
        )
      );
    ';
  END IF;
END $$;

-- ============================================================
-- 2) CLASSROOM_TEACHERS: allow teachers to insert their own
--    co-teacher membership rows without depending on classrooms RLS
-- ============================================================
alter table if exists public.classroom_teachers enable row level security;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'classroom_teachers'
      AND policyname = 'ct_insert_self_join_any'
  ) THEN
    EXECUTE '
      create policy ct_insert_self_join_any
      on public.classroom_teachers
      for insert
      with check (teacher_id = auth.uid());
    ';
  END IF;
END $$;

