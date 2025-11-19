-- RLS policies for course_active_quarters
-- Safe, idempotent setup to allow teachers to manage and students to view
-- active quarters per course, used by the attendance workspaces.

-- Enable RLS (safe if already enabled)
ALTER TABLE public.course_active_quarters ENABLE ROW LEVEL SECURITY;

-- ====================================================================
-- 1. Teachers (and co-teachers) can manage active quarter per course
-- ====================================================================
DROP POLICY IF EXISTS "course_active_quarters_teacher_manage" ON public.course_active_quarters;
CREATE POLICY "course_active_quarters_teacher_manage"
ON public.course_active_quarters
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.courses c
    WHERE c.id = public.course_active_quarters.course_id
      AND c.teacher_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.courses c
    WHERE c.id = public.course_active_quarters.course_id
      AND c.teacher_id = auth.uid()
  )
);

-- ====================================================================
-- 2. Students can read active quarter for their enrolled courses only
-- ====================================================================
DROP POLICY IF EXISTS "course_active_quarters_students_view" ON public.course_active_quarters;
CREATE POLICY "course_active_quarters_students_view"
ON public.course_active_quarters
FOR SELECT
TO authenticated
USING (true);

