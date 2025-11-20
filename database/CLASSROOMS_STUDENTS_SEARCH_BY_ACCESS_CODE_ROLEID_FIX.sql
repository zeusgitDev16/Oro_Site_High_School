-- Fix students_search_by_access_code policy on public.classrooms
-- Move from legacy profiles.role text column to profiles.role_id + roles table.
-- Idempotent and focused: only touches this single policy.

ALTER TABLE public.classrooms ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "students_search_by_access_code" ON public.classrooms;

CREATE POLICY "students_search_by_access_code"
ON public.classrooms
FOR SELECT
TO authenticated
USING (
  is_active = true
  AND EXISTS (
    SELECT 1
    FROM public.profiles p
    JOIN public.roles r ON r.id = p.role_id
    WHERE p.id = auth.uid()
      AND r.name = 'student'
  )
);

