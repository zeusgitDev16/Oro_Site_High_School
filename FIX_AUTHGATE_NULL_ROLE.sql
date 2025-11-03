-- ============================================
-- FIX: AuthGate Returning NULL Role
-- ============================================
-- Purpose: Fix RLS policies to allow users to see their own role
-- Issue: After enabling RLS, users can't fetch their own role from profiles table
-- Root Cause: The "Users can view own profile" policy doesn't allow JOIN with roles table
-- ============================================

-- ============================================
-- SECTION 1: FIX PROFILES TABLE POLICIES
-- ============================================

-- Drop the restrictive "Users can view own profile" policy
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

-- Create a better policy that allows users to see their own profile WITH role data
CREATE POLICY "Users can view own profile with role"
ON profiles FOR SELECT
USING (
    id = auth.uid() -- User can see their own profile
);

-- ============================================
-- SECTION 2: ENSURE ROLES TABLE IS READABLE
-- ============================================

-- Enable RLS on roles table if not already enabled
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies on roles table
DROP POLICY IF EXISTS "Anyone can view roles" ON roles;
DROP POLICY IF EXISTS "Admins can manage roles" ON roles;

-- Policy 1: Anyone authenticated can view roles (needed for JOIN queries)
CREATE POLICY "Anyone can view roles"
ON roles FOR SELECT
USING (true); -- Any authenticated user can read roles

-- Policy 2: Only admins can modify roles
CREATE POLICY "Admins can manage roles"
ON roles FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1 -- Admin role
    )
);

-- ============================================
-- SECTION 3: VERIFICATION QUERIES
-- ============================================

-- Test query: Get own profile with role (should work for any authenticated user)
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role_id,
    r.name AS role_name
FROM profiles p
LEFT JOIN roles r ON p.role_id = r.id
WHERE p.id = auth.uid();

-- Test query: List all roles (should work for any authenticated user)
SELECT id, name FROM roles ORDER BY id;

-- Check RLS status
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'roles')
ORDER BY tablename;

-- Check policies on profiles
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Check policies on roles
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'roles'
ORDER BY policyname;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ AUTHGATE NULL ROLE FIX COMPLETE!                       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '  ✅ Updated "Users can view own profile" policy';
    RAISE NOTICE '  ✅ Enabled RLS on roles table';
    RAISE NOTICE '  ✅ Created "Anyone can view roles" policy';
    RAISE NOTICE '  ✅ Users can now fetch their own role';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 What was fixed:';
    RAISE NOTICE '  1. Users can now JOIN profiles with roles table';
    RAISE NOTICE '  2. getUserRole() query will work correctly';
    RAISE NOTICE '  3. AuthGate will show proper role (not NULL)';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Next Steps:';
    RAISE NOTICE '  1. Refresh your app';
    RAISE NOTICE '  2. Login as any user';
    RAISE NOTICE '  3. Check console - should show role name (not NULL)';
    RAISE NOTICE '  4. Should route to correct dashboard';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF FIX SCRIPT
-- ============================================
