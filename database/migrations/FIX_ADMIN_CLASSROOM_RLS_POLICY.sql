-- ================================================================
-- FIX ADMIN CLASSROOM RLS POLICY
-- ================================================================
-- Date: 2025-11-27
-- Issue: Admin RLS policy checks profiles.role (NULL) instead of 
--        using is_admin() function that checks role_id → roles.name
-- Impact: Admins CANNOT view any classrooms in the UI
-- Solution: Drop broken policy and create new one using is_admin()
-- ================================================================

-- Drop the broken admin SELECT policy
DROP POLICY IF EXISTS "admins_view_all_classrooms" ON public.classrooms;

-- Create new admin SELECT policy using is_admin() function
CREATE POLICY "admins_view_all_classrooms"
  ON public.classrooms
  FOR SELECT
  TO authenticated
  USING (is_admin());

-- ================================================================
-- ADD MISSING ADMIN INSERT AND UPDATE POLICIES
-- ================================================================
-- Admins need to be able to create and update classrooms
-- These policies were missing, preventing admins from managing classrooms
-- ================================================================

-- Drop existing admin policies if they exist (cleanup)
DROP POLICY IF EXISTS "admins_insert_classrooms" ON public.classrooms;
DROP POLICY IF EXISTS "admins_update_classrooms" ON public.classrooms;
DROP POLICY IF EXISTS "admins_delete_classrooms" ON public.classrooms;

-- Create admin INSERT policy
CREATE POLICY "admins_insert_classrooms"
  ON public.classrooms
  FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

-- Create admin UPDATE policy
CREATE POLICY "admins_update_classrooms"
  ON public.classrooms
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Create admin DELETE policy
CREATE POLICY "admins_delete_classrooms"
  ON public.classrooms
  FOR DELETE
  TO authenticated
  USING (is_admin());

-- ================================================================
-- VERIFICATION
-- ================================================================
-- After running this migration:
-- 1. Admin should see all classrooms in Classroom Management screen
-- 2. Admin should see Amanpulo classroom when 2025-2026 is selected
-- 3. Admin should be able to create new classrooms
-- 4. Admin should be able to update existing classrooms
-- 5. Admin should be able to delete classrooms
-- 6. Backward compatibility maintained (teachers still see their classrooms)
-- ================================================================

-- Verify all admin policies were created correctly
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'classrooms'
AND policyname LIKE 'admins_%'
ORDER BY policyname;

