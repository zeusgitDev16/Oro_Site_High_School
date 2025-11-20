-- PHASE 2: assignment_submissions + assignment_files RLS
-- Idempotent, safe to run multiple times.

-- ============================================
-- 1) assignment_submissions RLS
-- ============================================

ALTER TABLE IF EXISTS public.assignment_submissions ENABLE ROW LEVEL SECURITY;

-- Drop policies we replace
DROP POLICY IF EXISTS "Students can view their own submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Students can create their own submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Students can update their own submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Teachers can view classroom submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Teachers can grade submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Teachers can create classroom submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Teachers can create submissions in their classrooms" ON public.assignment_submissions;

-- 1.a Students: view own submissions
CREATE POLICY "Students can view their own submissions"
  ON public.assignment_submissions
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- 1.b Students: create own submissions when enrolled
CREATE POLICY "Students can create their own submissions"
  ON public.assignment_submissions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.classroom_students cs
      WHERE cs.classroom_id = assignment_submissions.classroom_id
        AND cs.student_id = auth.uid()
    )
  );

-- 1.c Students: update own submissions only before grading (no grade fields)
CREATE POLICY "Students can update their own submissions"
  ON public.assignment_submissions
  FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (
    student_id = auth.uid()
    AND status IN ('draft', 'submitted')
    AND score IS NULL
    AND graded_at IS NULL
    AND graded_by IS NULL
  );

-- 1.d Teachers / co-teachers (and admins): view submissions in their classrooms
CREATE POLICY "Teachers can view classroom submissions"
  ON public.assignment_submissions
  FOR SELECT
  TO authenticated
  USING (
    -- Owner or co-teacher via assignment
    EXISTS (
      SELECT 1
      FROM public.assignments a
      WHERE a.id = assignment_submissions.assignment_id
        AND a.classroom_id = assignment_submissions.classroom_id
        AND (
          a.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1
            FROM public.classroom_teachers ct
            WHERE ct.classroom_id = a.classroom_id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
    OR
    -- Direct classroom ownership/co-teacher via classroom_id on submission
    EXISTS (
      SELECT 1
      FROM public.classrooms c
      WHERE c.id = assignment_submissions.classroom_id
        AND (
          c.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1
            FROM public.classroom_teachers ct
            WHERE ct.classroom_id = c.id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
    OR public.is_admin()
  );

-- 1.e Teachers / co-teachers (and admins): insert submissions for their classroom's students
CREATE POLICY "Teachers can create classroom submissions"
  ON public.assignment_submissions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (
      EXISTS (
        SELECT 1
        FROM public.assignments a
        WHERE a.id = assignment_submissions.assignment_id
          AND a.classroom_id = assignment_submissions.classroom_id
          AND (
            a.teacher_id = auth.uid()
            OR EXISTS (
              SELECT 1
              FROM public.classroom_teachers ct
              WHERE ct.classroom_id = a.classroom_id
                AND ct.teacher_id = auth.uid()
            )
          )
      )
      AND EXISTS (
        SELECT 1
        FROM public.classroom_students cs
        WHERE cs.classroom_id = assignment_submissions.classroom_id
          AND cs.student_id = assignment_submissions.student_id
      )
    )
    OR public.is_admin()
  );

-- 1.f Teachers / co-teachers (and admins): grade submissions
CREATE POLICY "Teachers can grade submissions"
  ON public.assignment_submissions
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.assignments a
      WHERE a.id = assignment_submissions.assignment_id
        AND a.classroom_id = assignment_submissions.classroom_id
        AND (
          a.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1
            FROM public.classroom_teachers ct
            WHERE ct.classroom_id = a.classroom_id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
    OR public.is_admin()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.assignments a
      WHERE a.id = assignment_submissions.assignment_id
        AND a.classroom_id = assignment_submissions.classroom_id
        AND (
          a.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1
            FROM public.classroom_teachers ct
            WHERE ct.classroom_id = a.classroom_id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
    OR public.is_admin()
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.assignment_submissions TO authenticated;

-- ============================================
-- 2) assignment_files RLS tweak (co-teachers)
-- ============================================

ALTER TABLE IF EXISTS public.assignment_files ENABLE ROW LEVEL SECURITY;

-- Replace only the teacher-view policy; keep others as-is
DROP POLICY IF EXISTS "Teachers can view assignment files" ON public.assignment_files;

CREATE POLICY "Teachers can view assignment files"
  ON public.assignment_files
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.assignments a
      WHERE a.id = assignment_files.assignment_id
        AND (
          a.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1
            FROM public.classroom_teachers ct
            WHERE ct.classroom_id = a.classroom_id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
    OR public.is_admin()
  );

-- Optional verification helper (run manually)
-- SELECT schemaname, tablename, policyname, cmd, roles
-- FROM pg_policies
-- WHERE tablename IN ('assignment_submissions','assignment_files')
-- ORDER BY tablename, policyname;

