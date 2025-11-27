-- =====================================================
-- MIGRATION: Fix Admin Attendance RLS Policies
-- PURPOSE: Replace profiles.role check with is_admin() function
-- DATE: 2025-11-27
-- CRITICAL BUG FIX: Admin cannot access attendance due to wrong column check
-- =====================================================

-- PROBLEM:
-- Current policies check profiles.role (text) which is NULL for all users
-- System actually uses profiles.role_id (bigint) linked to roles table
-- The is_admin() function already exists and works correctly

-- SOLUTION:
-- Replace: EXISTS (SELECT 1 FROM profiles WHERE role = 'admin')
-- With: is_admin()

-- =====================================================
-- Drop existing admin policies
-- =====================================================
DROP POLICY IF EXISTS "attendance_admins_select" ON public.attendance;
DROP POLICY IF EXISTS "attendance_admins_insert" ON public.attendance;
DROP POLICY IF EXISTS "attendance_admins_update" ON public.attendance;
DROP POLICY IF EXISTS "attendance_admins_delete" ON public.attendance;

-- =====================================================
-- POLICY #1: Admins can SELECT all attendance
-- =====================================================
CREATE POLICY "attendance_admins_select"
  ON public.attendance
  FOR SELECT
  TO authenticated
  USING (
    -- Use existing is_admin() function
    -- This function checks: profiles.role_id → roles.name = 'admin'
    is_admin()
  );

-- =====================================================
-- POLICY #2: Admins can INSERT attendance
-- =====================================================
CREATE POLICY "attendance_admins_insert"
  ON public.attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Use existing is_admin() function
    is_admin()
  );

-- =====================================================
-- POLICY #3: Admins can UPDATE attendance
-- =====================================================
CREATE POLICY "attendance_admins_update"
  ON public.attendance
  FOR UPDATE
  TO authenticated
  USING (
    -- Use existing is_admin() function
    is_admin()
  )
  WITH CHECK (
    -- Use existing is_admin() function
    is_admin()
  );

-- =====================================================
-- POLICY #4: Admins can DELETE attendance
-- =====================================================
CREATE POLICY "attendance_admins_delete"
  ON public.attendance
  FOR DELETE
  TO authenticated
  USING (
    -- Use existing is_admin() function
    is_admin()
  );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify all admin policies are created
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'attendance'
AND policyname LIKE '%admin%'
ORDER BY policyname;

-- Expected output: 4 policies
-- 1. attendance_admins_delete
-- 2. attendance_admins_insert
-- 3. attendance_admins_select
-- 4. attendance_admins_update

-- Verify is_admin() function exists
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'is_admin';

-- Expected output: 1 or 2 functions (may have overloads)

-- =====================================================
-- BACKWARD COMPATIBILITY
-- =====================================================
-- ✅ Teacher policies unchanged (still work)
-- ✅ Student policies unchanged (still work)
-- ✅ Parent policies unchanged (still work)
-- ✅ Old attendance data continues to work
-- ✅ New attendance data continues to work
-- ✅ is_admin() function already exists and is tested

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- ✅ Admin can now SELECT attendance
-- ✅ Admin can now INSERT attendance
-- ✅ Admin can now UPDATE attendance
-- ✅ Admin can now DELETE attendance
-- ✅ All policies use correct role detection
-- ✅ 100% backward compatible
-- =====================================================

