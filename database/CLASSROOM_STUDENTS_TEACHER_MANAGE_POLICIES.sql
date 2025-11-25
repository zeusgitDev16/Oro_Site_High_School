-- Idempotent RLS fixes for classroom_students to allow teachers to manage enrollments
-- Problem: Only students could insert/delete (self-enroll/unenroll) which blocks teacher actions in UI
-- Fix: Add teacher-managed INSERT and DELETE policies scoped to their own classrooms

-- Ensure RLS is enabled (safe to run repeatedly)
ALTER TABLE public.classroom_students ENABLE ROW LEVEL SECURITY;

-- Helper: check if a user is the owner or co-teacher of a classroom without triggering RLS recursion
CREATE OR REPLACE FUNCTION public.is_classroom_manager(p_classroom_id uuid, p_user_id uuid)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.classrooms c
    WHERE c.id = p_classroom_id
      AND c.teacher_id = p_user_id
  ) OR EXISTS (
    SELECT 1 FROM public.classroom_teachers ct
    WHERE ct.classroom_id = p_classroom_id
      AND ct.teacher_id = p_user_id
  );
END;
$$;


-- Allow teachers and co-teachers to add students to classrooms they manage
DROP POLICY IF EXISTS "Teachers can add students to own classrooms" ON public.classroom_students;
CREATE POLICY "Teachers can add students to own classrooms"
ON public.classroom_students
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_classroom_manager(classroom_students.classroom_id, auth.uid())
);

-- Allow teachers and co-teachers to remove students from classrooms they manage
DROP POLICY IF EXISTS "Teachers can remove students from own classrooms" ON public.classroom_students;
CREATE POLICY "Teachers can remove students from own classrooms"
ON public.classroom_students
FOR DELETE
TO authenticated
USING (
  public.is_classroom_manager(classroom_students.classroom_id, auth.uid())
);

-- Allow teachers (and co-teachers) to view enrollments (non-recursive: no classrooms reference)
DROP POLICY IF EXISTS "Teachers can view classroom enrollments" ON public.classroom_students;
DROP POLICY IF EXISTS "Teachers can view enrollments" ON public.classroom_students;
CREATE POLICY "Teachers can view enrollments"
ON public.classroom_students
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'teacher'
  )
);


-- Optional: Admins can manage all enrollments (uncomment if you use public.is_admin)
-- DROP POLICY IF EXISTS "Admins can manage enrollments" ON public.classroom_students;
-- CREATE POLICY "Admins can manage enrollments"
-- ON public.classroom_students
-- FOR ALL
-- TO authenticated
-- USING (public.is_admin(auth.uid()))
-- WITH CHECK (public.is_admin(auth.uid()));
