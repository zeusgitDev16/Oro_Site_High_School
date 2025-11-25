-- RLS policies for classroom_active_quarters
-- Safe, idempotent setup to allow classroom teachers and co-teachers
-- to manage the active quarter per classroom, and to allow reads
-- without introducing new recursion issues.

-- Enable RLS (safe if already enabled)
ALTER TABLE public.classroom_active_quarters ENABLE ROW LEVEL SECURITY;

-- ====================================================================
-- 1. Teachers (and co-teachers) can manage active quarter per classroom
-- ====================================================================
DROP POLICY IF EXISTS "classroom_active_quarters_teacher_manage" ON public.classroom_active_quarters;
CREATE POLICY "classroom_active_quarters_teacher_manage"
ON public.classroom_active_quarters
FOR ALL
TO authenticated
USING (
  -- Classroom owner
  EXISTS (
    SELECT 1
    FROM public.classrooms c
    WHERE c.id::text = public.classroom_active_quarters.classroom_id::text
      AND c.teacher_id::text = auth.uid()::text
  )
  OR
  -- Co-teacher assigned to the classroom
  EXISTS (
    SELECT 1
    FROM public.classroom_teachers ct
    WHERE ct.classroom_id::text = public.classroom_active_quarters.classroom_id::text
      AND ct.teacher_id::text = auth.uid()::text
  )
  OR
  -- Admin override
  COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.classrooms c
    WHERE c.id::text = public.classroom_active_quarters.classroom_id::text
      AND c.teacher_id::text = auth.uid()::text
  )
  OR EXISTS (
    SELECT 1
    FROM public.classroom_teachers ct
    WHERE ct.classroom_id::text = public.classroom_active_quarters.classroom_id::text
      AND ct.teacher_id::text = auth.uid()::text
  )
  OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
);

-- ====================================================================
-- 2. Authenticated users can read active quarter per classroom
--    (value is non-sensitive; this avoids extra membership joins)
-- ====================================================================
DROP POLICY IF EXISTS "classroom_active_quarters_view" ON public.classroom_active_quarters;
CREATE POLICY "classroom_active_quarters_view"
ON public.classroom_active_quarters
FOR SELECT
TO authenticated
USING (true);

