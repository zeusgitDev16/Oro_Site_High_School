-- ASSIGNMENTS_RLS_STUDENT_VISIBLE_PUBLISHED_CLASSROOM.sql
-- Purpose: Allow enrolled students to view published, active assignments for their classrooms
--          without weakening owner/admin controls for write operations.
-- Idempotent and safe to run multiple times.

-- Ensure RLS is enabled on assignments (defensive)
ALTER TABLE IF EXISTS public.assignments ENABLE ROW LEVEL SECURITY;

-- Drop prior student-view policy if it exists
DROP POLICY IF EXISTS "students_can_view_published_classroom_assignments" ON public.assignments;

-- Students can view published, active assignments in classrooms where they are enrolled
CREATE POLICY "students_can_view_published_classroom_assignments"
ON public.assignments
FOR SELECT
TO authenticated
USING (
  -- Keep existing owner/admin semantics implicitly via other policies;
  -- this policy only *adds* visibility for enrolled students.
  EXISTS (
    SELECT 1
    FROM public.classroom_students cs
    WHERE cs.classroom_id = public.assignments.classroom_id
      AND cs.student_id = auth.uid()
  )
  AND public.assignments.is_active = TRUE
  AND public.assignments.is_published = TRUE
);

