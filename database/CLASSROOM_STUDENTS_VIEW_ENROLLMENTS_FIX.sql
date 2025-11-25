-- Fix SELECT visibility on classroom_students for classroom managers and teachers
-- Safe, idempotent: can be run multiple times

ALTER TABLE public.classroom_students ENABLE ROW LEVEL SECURITY;

-- Ensure the Teachers can view enrollments policy exists with the correct USING condition
DROP POLICY IF EXISTS "Teachers can view enrollments" ON public.classroom_students;
CREATE POLICY "Teachers can view enrollments"
ON public.classroom_students
FOR SELECT
TO authenticated
USING (
  -- Classroom managers (owner or co-teacher) can see enrollments for their classrooms
  public.is_classroom_manager(classroom_students.classroom_id, auth.uid())
  OR
  -- Plus any profile with role = 'teacher', preserving existing behavior
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'teacher'
  )
);

