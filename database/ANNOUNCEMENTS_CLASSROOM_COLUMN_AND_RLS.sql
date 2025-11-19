-- Add classroom_id to announcements + classroom-scoped RLS (Idempotent)
-- This script:
--  1) Adds classroom_id (text) to public.announcements if missing
--  2) Creates indexes for fast lookups
--  3) Enables RLS and defines classroom-scoped policies
--     - Teachers who own the classroom can manage announcements
--     - Students enrolled in the classroom can read announcements
--     - Admins (public.is_admin(auth.uid())) can read/write all
-- Notes:
--  - We use ::text casts to avoid uuid/text operator mismatches
--  - If your classrooms.id is uuid, storing classroom_id as text still works with casts
--  - Existing rows will have classroom_id = NULL; these will not be visible under RLS.
--    Backfill as needed after running (see guidance at the bottom).

begin;

-- 1) Add classroom_id column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name   = 'announcements'
       AND column_name  = 'classroom_id'
  ) THEN
    ALTER TABLE public.announcements ADD COLUMN classroom_id text;
  END IF;
END$$;

-- 2) Helpful indexes
create index if not exists idx_announcements_classroom_id on public.announcements(classroom_id);
create index if not exists idx_announcements_course_classroom on public.announcements(course_id, classroom_id);
create index if not exists idx_announcements_created_at on public.announcements(created_at desc);

-- Ensure RLS is enabled
alter table if exists public.announcements enable row level security;

-- Drop existing policies to keep this script idempotent
DROP POLICY IF EXISTS "Announcements select visible to teachers and students" ON public.announcements;
DROP POLICY IF EXISTS "Announcements select visible to classroom members" ON public.announcements;
DROP POLICY IF EXISTS "Teachers insert course announcements" ON public.announcements;
DROP POLICY IF EXISTS "Teachers insert classroom announcements" ON public.announcements;
DROP POLICY IF EXISTS "Teachers update course announcements" ON public.announcements;
DROP POLICY IF EXISTS "Teachers update classroom announcements" ON public.announcements;
DROP POLICY IF EXISTS "Teachers delete course announcements" ON public.announcements;
DROP POLICY IF EXISTS "Teachers delete classroom announcements" ON public.announcements;

-- 3) Classroom-scoped policies
-- SELECT: classroom owner (teacher), co-teachers, classroom students, or admin
CREATE POLICY "Announcements select visible to classroom members"
  ON public.announcements
  FOR SELECT
  TO authenticated
  USING (
    -- Teacher who owns the classroom
    EXISTS (
      SELECT 1
      FROM public.classrooms c
      WHERE c.id::text = public.announcements.classroom_id::text
        AND c.teacher_id::text = auth.uid()::text
    )
    OR
    -- Co-teacher assigned to the classroom
    EXISTS (
      SELECT 1
      FROM public.classroom_teachers ct
      WHERE ct.classroom_id::text = public.announcements.classroom_id::text
        AND ct.teacher_id::text = auth.uid()::text
    )
    OR
    -- Student enrolled in the classroom
    EXISTS (
      SELECT 1
      FROM public.classroom_students cs
      WHERE cs.classroom_id::text = public.announcements.classroom_id::text
        AND cs.student_id::text = auth.uid()::text
    )
    OR
    -- Admin override
    COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
  );

-- INSERT: classroom owner, co-teachers, or admin
CREATE POLICY "Teachers insert classroom announcements"
  ON public.announcements
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Classroom owner
    EXISTS (
      SELECT 1
      FROM public.classrooms c
      WHERE c.id::text = public.announcements.classroom_id::text
        AND c.teacher_id::text = auth.uid()::text
    )
    OR
    -- Co-teacher assigned to the classroom
    EXISTS (
      SELECT 1
      FROM public.classroom_teachers ct
      WHERE ct.classroom_id::text = public.announcements.classroom_id::text
        AND ct.teacher_id::text = auth.uid()::text
    )
    OR
    COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
  );

-- UPDATE: classroom owner, co-teachers, or admin
CREATE POLICY "Teachers update classroom announcements"
  ON public.announcements
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.classrooms c
      WHERE c.id::text = public.announcements.classroom_id::text
        AND c.teacher_id::text = auth.uid()::text
    )
    OR EXISTS (
      SELECT 1
      FROM public.classroom_teachers ct
      WHERE ct.classroom_id::text = public.announcements.classroom_id::text
        AND ct.teacher_id::text = auth.uid()::text
    )
    OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.classrooms c
      WHERE c.id::text = public.announcements.classroom_id::text
        AND c.teacher_id::text = auth.uid()::text
    )
    OR EXISTS (
      SELECT 1
      FROM public.classroom_teachers ct
      WHERE ct.classroom_id::text = public.announcements.classroom_id::text
        AND ct.teacher_id::text = auth.uid()::text
    )
    OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
  );

-- DELETE: classroom owner, co-teachers, or admin
CREATE POLICY "Teachers delete classroom announcements"
  ON public.announcements
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.classrooms c
      WHERE c.id::text = public.announcements.classroom_id::text
        AND c.teacher_id::text = auth.uid()::text
    )
    OR EXISTS (
      SELECT 1
      FROM public.classroom_teachers ct
      WHERE ct.classroom_id::text = public.announcements.classroom_id::text
        AND ct.teacher_id::text = auth.uid()::text
    )
    OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
  );

commit;

-- OPTIONAL BACKFILL (Run separately after deciding mapping):
-- Example: If you have a single classroom per course for each teacher and want to assign historic rows:
-- UPDATE public.announcements a
-- SET classroom_id = (
--   SELECT c.id::text
--   FROM public.classrooms c
--   WHERE c.teacher_id::text = auth.uid()::text
--   LIMIT 1
-- )
-- WHERE a.classroom_id IS NULL;
