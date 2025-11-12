-- ============================================================================
-- FIX_ASSIGNMENT_SUBMISSIONS_RLS_FOR_TEACHERS.sql
-- Purpose: Fix RLS so teachers/co-teachers can INSERT and UPDATE (grade)
--          assignment_submissions for students in their classrooms, while
--          students can only view their own and update content before grading.
-- Idempotent: Safe to run multiple times.
-- ============================================================================

-- Ensure RLS is enabled
ALTER TABLE IF EXISTS public.assignment_submissions ENABLE ROW LEVEL SECURITY;

-- Drop/replace existing policies we are redefining (idempotent)
DROP POLICY IF EXISTS "Teachers can view classroom submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Teachers can grade submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Teachers can create classroom submissions" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Teachers can create submissions in their classrooms" ON public.assignment_submissions;
DROP POLICY IF EXISTS "Students can update their own submissions" ON public.assignment_submissions;

-- Keep or (re)create student read policy: students may view their own submissions
DROP POLICY IF EXISTS "Students can view their own submissions" ON public.assignment_submissions;
CREATE POLICY "Students can view their own submissions"
  ON public.assignment_submissions
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Students can create their own submissions when enrolled in the classroom
DROP POLICY IF EXISTS "Students can create their own submissions" ON public.assignment_submissions;
CREATE POLICY "Students can create their own submissions"
  ON public.assignment_submissions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.classroom_students cs
      WHERE cs.classroom_id = assignment_submissions.classroom_id
        AND cs.student_id = auth.uid()
    )
  );

-- Students can update their own submissions only before grading and without touching grade fields
-- Rationale: Prevent students from setting score/graded_at/graded_by or moving to 'graded'
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

-- Teachers/co-teachers can view submissions for assignments in classrooms they own or co-teach
CREATE POLICY "Teachers can view classroom submissions"
  ON public.assignment_submissions
  FOR SELECT
  TO authenticated
  USING (
    -- Owner of the assignment's classroom
    EXISTS (
      SELECT 1 FROM public.assignments a
      WHERE a.id = assignment_submissions.assignment_id
        AND a.classroom_id = assignment_submissions.classroom_id
        AND (
          a.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = a.classroom_id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
    OR
    -- Direct classroom ownership check using the classroom_id on the submission
    EXISTS (
      SELECT 1 FROM public.classrooms c
      WHERE c.id = assignment_submissions.classroom_id
        AND (
          c.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = c.id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
  );

-- Teachers/co-teachers can INSERT submissions for students enrolled in their classroom
CREATE POLICY "Teachers can create classroom submissions"
  ON public.assignment_submissions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- The assignment belongs to the classroom AND user is owner/co-teacher
    EXISTS (
      SELECT 1 FROM public.assignments a
      WHERE a.id = assignment_submissions.assignment_id
        AND a.classroom_id = assignment_submissions.classroom_id
        AND (
          a.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = a.classroom_id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
    AND
    -- The target student is enrolled in the same classroom
    EXISTS (
      SELECT 1 FROM public.classroom_students cs
      WHERE cs.classroom_id = assignment_submissions.classroom_id
        AND cs.student_id = assignment_submissions.student_id
    )
  );

-- Teachers/co-teachers can UPDATE (grade) submissions in their classrooms
CREATE POLICY "Teachers can grade submissions"
  ON public.assignment_submissions
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.assignments a
      WHERE a.id = assignment_submissions.assignment_id
        AND a.classroom_id = assignment_submissions.classroom_id
        AND (
          a.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = a.classroom_id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.assignments a
      WHERE a.id = assignment_submissions.assignment_id
        AND a.classroom_id = assignment_submissions.classroom_id
        AND (
          a.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = a.classroom_id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
  );

-- Optional: sanity grants (usually already present)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assignment_submissions TO authenticated;

-- Verification helper: list the effective policies on assignment_submissions
-- (Run in Supabase SQL editor to verify)
-- SELECT schemaname, tablename, policyname, roles, cmd, permissive
-- FROM pg_policies
-- WHERE tablename = 'assignment_submissions'
-- ORDER BY policyname;

