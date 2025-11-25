-- ASSIGNMENTS_RLS_OWNER_ONLY_VIEW.sql
-- Instruction: Run this script once in Supabase SQL editor for this project.
-- Purpose: Tighten public.assignments RLS so only the assignment owner (teacher_id) and admins can see/modify rows.
-- Idempotent: Safe to run multiple times.

-- Ensure RLS is enabled on assignments
ALTER TABLE IF EXISTS public.assignments ENABLE ROW LEVEL SECURITY;

-- Drop legacy/select-all or conflicting policies we replace
DROP POLICY IF EXISTS "assignments_select_all" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can view their classroom assignments" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can manage classroom assignments" ON public.assignments;
DROP POLICY IF EXISTS "authenticated_can_view_assignments" ON public.assignments;

-- SELECT: Only assignment owner (teacher_id) or admins can see rows
CREATE POLICY "assignments_select_owner_only"
ON public.assignments
FOR SELECT
TO authenticated
USING (
  -- Admins can see all
  public.is_admin()
  OR
  -- Assignment owner (teacher_id) only
  teacher_id = auth.uid()
);

-- INSERT: Only owner teacher or admin can insert
CREATE POLICY "assignments_insert_owner_only"
ON public.assignments
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR teacher_id = auth.uid()
);

-- UPDATE: Only owner teacher or admin can update
CREATE POLICY "assignments_update_owner_only"
ON public.assignments
FOR UPDATE
TO authenticated
USING (
  public.is_admin()
  OR teacher_id = auth.uid()
)
WITH CHECK (
  public.is_admin()
  OR teacher_id = auth.uid()
);

-- DELETE: Only owner teacher or admin can delete
CREATE POLICY "assignments_delete_owner_only"
ON public.assignments
FOR DELETE
TO authenticated
USING (
  public.is_admin()
  OR teacher_id = auth.uid()
);

