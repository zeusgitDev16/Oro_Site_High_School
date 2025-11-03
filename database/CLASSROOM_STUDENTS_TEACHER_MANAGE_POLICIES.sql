-- Idempotent RLS fixes for classroom_students to allow teachers to manage enrollments
-- Problem: Only students could insert/delete (self-enroll/unenroll) which blocks teacher actions in UI
-- Fix: Add teacher-managed INSERT and DELETE policies scoped to their own classrooms

-- Ensure RLS is enabled (safe to run repeatedly)
ALTER TABLE public.classroom_students ENABLE ROW LEVEL SECURITY;

-- Allow teachers to add students to their own classrooms
DROP POLICY IF EXISTS "Teachers can add students to own classrooms" ON public.classroom_students;
CREATE POLICY "Teachers can add students to own classrooms"
ON public.classroom_students
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.classrooms c
    WHERE c.id = public.classroom_students.classroom_id
      AND c.teacher_id = auth.uid()
  )
);

-- Allow teachers to remove students from their own classrooms
DROP POLICY IF EXISTS "Teachers can remove students from own classrooms" ON public.classroom_students;
CREATE POLICY "Teachers can remove students from own classrooms"
ON public.classroom_students
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.classrooms c
    WHERE c.id = public.classroom_students.classroom_id
      AND c.teacher_id = auth.uid()
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
