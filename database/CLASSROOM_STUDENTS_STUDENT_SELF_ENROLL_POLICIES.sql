-- RLS policies for student self-enrollment in classroom_students
-- Safe and idempotent: can be run multiple times.

-- Ensure RLS is enabled (defensive; already enabled in other scripts)
ALTER TABLE public.classroom_students ENABLE ROW LEVEL SECURITY;

-- Students can view their own enrollments
DROP POLICY IF EXISTS "Students can view own enrollments" ON public.classroom_students;
CREATE POLICY "Students can view own enrollments"
ON public.classroom_students
FOR SELECT
TO authenticated
USING (
  auth.uid() = student_id
);

-- Students can enroll themselves into classrooms they join via access code
DROP POLICY IF EXISTS "Students can enroll themselves" ON public.classroom_students;
CREATE POLICY "Students can enroll themselves"
ON public.classroom_students
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = student_id
);

