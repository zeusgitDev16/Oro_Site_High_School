-- ================================================================
-- FIX CLASSROOM_STUDENTS RLS POLICIES
-- ================================================================
-- Date: 2025-11-27
-- Issue: Admin and teacher RLS policies on classroom_students are broken
--        1. Admin policy uses is_admin(auth.uid()) instead of is_admin()
--        2. Teacher policy checks profiles.role (NULL) instead of using proper function
-- Impact: Admin cannot see enrolled students in Amanpulo classroom
-- Solution: Fix both policies to use correct functions
-- ================================================================

-- ================================================================
-- FIX ADMIN SELECT POLICY
-- ================================================================

-- Drop the broken admin SELECT policy
DROP POLICY IF EXISTS "Admins can view all enrollments" ON public.classroom_students;

-- Create new admin SELECT policy using is_admin() (no parameter)
CREATE POLICY "Admins can view all enrollments"
  ON public.classroom_students
  FOR SELECT
  TO authenticated
  USING (is_admin());

-- ================================================================
-- FIX TEACHER SELECT POLICY
-- ================================================================

-- Drop the broken teacher SELECT policy
DROP POLICY IF EXISTS "Teachers can view enrollments" ON public.classroom_students;

-- Create new teacher SELECT policy using is_classroom_manager() only
CREATE POLICY "Teachers can view enrollments"
  ON public.classroom_students
  FOR SELECT
  TO authenticated
  USING (is_classroom_manager(classroom_id, auth.uid()));

-- ================================================================
-- FIX OTHER ADMIN POLICIES (if they have the same issue)
-- ================================================================

-- Check and fix admin UPDATE policy
DROP POLICY IF EXISTS "Admins can update enrollments" ON public.classroom_students;

CREATE POLICY "Admins can update enrollments"
  ON public.classroom_students
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Check and fix admin DELETE policy
DROP POLICY IF EXISTS "Admins can remove students" ON public.classroom_students;

CREATE POLICY "Admins can remove students"
  ON public.classroom_students
  FOR DELETE
  TO authenticated
  USING (is_admin());

-- ================================================================
-- VERIFICATION
-- ================================================================
-- After running this migration:
-- 1. Admin should see all 16 enrolled students in Amanpulo classroom
-- 2. Teachers should see students in their managed classrooms
-- 3. Backward compatibility maintained (students can still view own enrollments)
-- ================================================================

-- Verify all policies were created correctly
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'classroom_students'
ORDER BY policyname;

