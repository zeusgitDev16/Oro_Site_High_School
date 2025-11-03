-- ============================================
-- FIX ADMINS TABLE RLS - REMOVE INFINITE RECURSION
-- ============================================
-- Issue: super_admins_manage_all policy causes infinite recursion
-- Solution: Simplify policies to avoid self-referencing
-- ============================================

-- Drop all existing policies on admins table
DROP POLICY IF EXISTS "admins_select_own" ON admins;
DROP POLICY IF EXISTS "admins_insert_own" ON admins;
DROP POLICY IF EXISTS "admins_update_own" ON admins;
DROP POLICY IF EXISTS "super_admins_manage_all" ON admins;

-- Policy 1: Admins can view their own record (no recursion)
CREATE POLICY "admins_select_own"
ON admins FOR SELECT
USING (id = auth.uid());

-- Policy 2: Users can insert their own admin record (no recursion)
CREATE POLICY "admins_insert_own"
ON admins FOR INSERT
WITH CHECK (id = auth.uid());

-- Policy 3: Admins can update their own record (no recursion)
CREATE POLICY "admins_update_own"
ON admins FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Policy 4: Admins can delete their own record (no recursion)
CREATE POLICY "admins_delete_own"
ON admins FOR DELETE
USING (id = auth.uid());

-- Note: For super admin management of other admins, use service role key
-- This avoids the infinite recursion issue

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ ADMINS TABLE RLS FIXED!                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Changes Made:';
    RAISE NOTICE '  ✅ Removed recursive super_admins_manage_all policy';
    RAISE NOTICE '  ✅ Simplified policies to avoid self-referencing';
    RAISE NOTICE '  ✅ Admins can now manage their own records';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Current Policies:';
    RAISE NOTICE '  1. admins_select_own - View own record';
    RAISE NOTICE '  2. admins_insert_own - Create own record';
    RAISE NOTICE '  3. admins_update_own - Update own record';
    RAISE NOTICE '  4. admins_delete_own - Delete own record';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Note:';
    RAISE NOTICE '  - For managing other admins, use service role key';
    RAISE NOTICE '  - This prevents infinite recursion';
    RAISE NOTICE '';
END $$;

-- Verify policies
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'admins'
ORDER BY policyname;
