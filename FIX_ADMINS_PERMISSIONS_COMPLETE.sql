-- ============================================
-- COMPLETE FIX: ADMINS TABLE PERMISSIONS
-- ============================================
-- This script ensures the admins table exists with correct RLS policies
-- ============================================

-- ============================================
-- STEP 1: ENSURE TABLE EXISTS
-- ============================================

CREATE TABLE IF NOT EXISTS admins (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    employee_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    admin_level TEXT DEFAULT 'admin',
    department TEXT DEFAULT 'Administration',
    position TEXT,
    permissions JSONB DEFAULT '[]'::jsonb,
    can_manage_users BOOLEAN DEFAULT TRUE,
    can_manage_courses BOOLEAN DEFAULT TRUE,
    can_manage_system BOOLEAN DEFAULT TRUE,
    can_view_reports BOOLEAN DEFAULT TRUE,
    phone TEXT,
    office_location TEXT,
    emergency_contact TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT admins_admin_level_check CHECK (
        admin_level IN ('super_admin', 'admin', 'limited_admin')
    )
);

-- ============================================
-- STEP 2: ENABLE RLS
-- ============================================

ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 3: DROP ALL EXISTING POLICIES
-- ============================================

DROP POLICY IF EXISTS "admins_select_own" ON admins;
DROP POLICY IF EXISTS "admins_insert_own" ON admins;
DROP POLICY IF EXISTS "admins_update_own" ON admins;
DROP POLICY IF EXISTS "admins_delete_own" ON admins;
DROP POLICY IF EXISTS "super_admins_manage_all" ON admins;
DROP POLICY IF EXISTS "Anyone can view admins" ON admins;
DROP POLICY IF EXISTS "Admins can manage admins" ON admins;

-- ============================================
-- STEP 4: CREATE SIMPLE, NON-RECURSIVE POLICIES
-- ============================================

-- Policy 1: Anyone authenticated can view admins (for lookups)
CREATE POLICY "admins_select_all"
ON admins FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Users can insert their own admin record
CREATE POLICY "admins_insert_own"
ON admins FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- Policy 3: Admins can update their own record
CREATE POLICY "admins_update_own"
ON admins FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Policy 4: Admins can delete their own record
CREATE POLICY "admins_delete_own"
ON admins FOR DELETE
TO authenticated
USING (id = auth.uid());

-- ============================================
-- STEP 5: CREATE TRIGGER
-- ============================================

DROP TRIGGER IF EXISTS update_admins_updated_at ON admins;
CREATE TRIGGER update_admins_updated_at
    BEFORE UPDATE ON admins
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 6: VERIFICATION
-- ============================================

-- Check table exists
SELECT 
    'admins' AS table_name,
    EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'admins'
    ) AS exists;

-- Check RLS is enabled
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE tablename = 'admins';

-- Check policies
SELECT 
    policyname,
    cmd,
    roles,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'admins'
ORDER BY policyname;

-- ============================================
-- FINAL MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ ADMINS TABLE PERMISSIONS FIXED!                        ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Table: admins exists';
    RAISE NOTICE '✅ RLS: Enabled';
    RAISE NOTICE '✅ Policies: 4 policies created';
    RAISE NOTICE '  1. admins_select_all - Anyone can view';
    RAISE NOTICE '  2. admins_insert_own - Users can insert own record';
    RAISE NOTICE '  3. admins_update_own - Users can update own record';
    RAISE NOTICE '  4. admins_delete_own - Users can delete own record';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Hot restart your Flutter app';
    RAISE NOTICE '  2. Login with admin account';
    RAISE NOTICE '  3. Admin record should be created successfully';
    RAISE NOTICE '';
END $$;
