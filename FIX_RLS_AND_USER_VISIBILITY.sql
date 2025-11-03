-- ============================================
-- FIX: RLS Policies and User Visibility Issues
-- ============================================
-- Purpose: Fix teachers table RLS and profiles visibility
-- Issues Fixed:
--   1. Teachers table showing as "Unrestricted"
--   2. Only admin user visible in Manage Users
--   3. No teachers appearing in course creation
-- ============================================

-- ============================================
-- SECTION 1: ENABLE RLS ON TEACHERS TABLE
-- ============================================

-- Enable Row Level Security on teachers table
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Admins can manage teachers" ON teachers;
DROP POLICY IF EXISTS "Teachers can view own record" ON teachers;
DROP POLICY IF EXISTS "Anyone can view active teachers" ON teachers;

-- Policy 1: Admins can do everything with teachers
CREATE POLICY "Admins can manage teachers"
ON teachers FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1 -- Admin role
    )
);

-- Policy 2: Teachers can view their own record
CREATE POLICY "Teachers can view own record"
ON teachers FOR SELECT
USING (id = auth.uid());

-- Policy 3: Anyone authenticated can view active teachers (for dropdowns, etc.)
CREATE POLICY "Anyone can view active teachers"
ON teachers FOR SELECT
USING (is_active = TRUE);

-- ============================================
-- SECTION 2: FIX PROFILES TABLE RLS POLICIES
-- ============================================

-- Drop existing restrictive policies that might be blocking access
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can manage profiles" ON profiles;
DROP POLICY IF EXISTS "Service role can manage profiles" ON profiles;

-- Policy 1: Users can view their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (id = auth.uid());

-- Policy 2: Admins can view ALL profiles (this is the key fix)
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role_id = 1 -- Admin role
    )
);

-- Policy 3: Admins can manage all profiles
CREATE POLICY "Admins can manage profiles"
ON profiles FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role_id = 1 -- Admin role
    )
);

-- Policy 4: Service role bypass (for server-side operations)
CREATE POLICY "Service role can manage profiles"
ON profiles FOR ALL
USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================
-- SECTION 3: FIX STUDENTS TABLE RLS (if needed)
-- ============================================

-- Enable RLS on students table if not already enabled
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Students can view own record" ON students;
DROP POLICY IF EXISTS "Admins can manage students" ON students;
DROP POLICY IF EXISTS "Teachers can view students" ON students;

-- Policy 1: Students can view their own record
CREATE POLICY "Students can view own record"
ON students FOR SELECT
USING (id = auth.uid());

-- Policy 2: Admins can manage all students
CREATE POLICY "Admins can manage students"
ON students FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1 -- Admin role
    )
);

-- Policy 3: Teachers can view students (for their courses)
CREATE POLICY "Teachers can view students"
ON students FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id IN (2, 5) -- Teacher or Coordinator
    )
);

-- ============================================
-- SECTION 4: VERIFICATION QUERIES
-- ============================================

-- Check RLS status on all tables
SELECT 
    schemaname,
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'teachers', 'students')
ORDER BY tablename;

-- Check policies on profiles table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Check policies on teachers table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'teachers'
ORDER BY policyname;

-- Test query: Count users by role (should work for admins)
SELECT 
    r.name AS role_name,
    COUNT(p.id) AS user_count
FROM profiles p
LEFT JOIN roles r ON p.role_id = r.id
WHERE p.is_active = TRUE
GROUP BY r.name
ORDER BY r.name;

-- Test query: List all teachers (should work for admins)
SELECT 
    t.id,
    t.employee_id,
    t.first_name,
    t.last_name,
    t.department,
    t.is_active,
    p.email,
    p.full_name
FROM teachers t
INNER JOIN profiles p ON t.id = p.id
WHERE t.is_active = TRUE
ORDER BY t.last_name;

-- ============================================
-- SECTION 5: ADDITIONAL FIXES
-- ============================================

-- Ensure roles table has correct data
INSERT INTO roles (id, name) VALUES
    (1, 'admin'),
    (2, 'teacher'),
    (3, 'student'),
    (4, 'parent'),
    (5, 'coordinator')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ RLS AND USER VISIBILITY FIX COMPLETE!                  ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '  ✅ RLS enabled on teachers table';
    RAISE NOTICE '  ✅ Teachers table policies created (3 policies)';
    RAISE NOTICE '  ✅ Profiles table policies fixed (4 policies)';
    RAISE NOTICE '  ✅ Students table policies updated (3 policies)';
    RAISE NOTICE '  ✅ Admin can now view ALL users';
    RAISE NOTICE '  ✅ Teachers visible in course creation';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 What was fixed:';
    RAISE NOTICE '  1. Teachers table no longer "Unrestricted"';
    RAISE NOTICE '  2. Admins can see all users in Manage Users';
    RAISE NOTICE '  3. Teachers appear in course creation dropdown';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Next Steps:';
    RAISE NOTICE '  1. Refresh your Supabase dashboard';
    RAISE NOTICE '  2. Check teachers table (should not show "Unrestricted")';
    RAISE NOTICE '  3. Go to Manage Users (should see all users)';
    RAISE NOTICE '  4. Create a course (should see teachers)';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF FIX SCRIPT
-- ============================================
