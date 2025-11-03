-- ============================================
-- CREATE ADMINS TABLE
-- ============================================
-- Purpose: Create admin-specific table to filter out admins from profiles
-- This completes the role-specific table architecture
-- ============================================

-- ============================================
-- SECTION 1: CREATE ADMINS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS admins (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    employee_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    
    -- Admin-specific fields
    admin_level TEXT DEFAULT 'admin', -- 'super_admin', 'admin', 'limited_admin'
    department TEXT DEFAULT 'Administration',
    position TEXT, -- 'Principal', 'Vice Principal', 'Admin Officer', etc.
    
    -- Permissions and access
    permissions JSONB DEFAULT '[]'::jsonb, -- Array of specific permissions
    can_manage_users BOOLEAN DEFAULT TRUE,
    can_manage_courses BOOLEAN DEFAULT TRUE,
    can_manage_system BOOLEAN DEFAULT TRUE,
    can_view_reports BOOLEAN DEFAULT TRUE,
    
    -- Contact information
    phone TEXT,
    office_location TEXT,
    emergency_contact TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT admins_admin_level_check CHECK (
        admin_level IN ('super_admin', 'admin', 'limited_admin')
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_admins_active ON admins(is_active);
CREATE INDEX IF NOT EXISTS idx_admins_employee_id ON admins(employee_id);
CREATE INDEX IF NOT EXISTS idx_admins_admin_level ON admins(admin_level);
CREATE INDEX IF NOT EXISTS idx_admins_position ON admins(position);

-- Add comment
COMMENT ON TABLE admins IS 'Administrator-specific information with system permissions';

DO $$ 
BEGIN
    RAISE NOTICE '✅ admins table created';
END $$;

-- ============================================
-- SECTION 2: ENABLE RLS AND CREATE POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "admins_select_own" ON admins;
DROP POLICY IF EXISTS "admins_insert_own" ON admins;
DROP POLICY IF EXISTS "admins_update_own" ON admins;
DROP POLICY IF EXISTS "super_admins_manage_all" ON admins;

-- Policy 1: Admins can view their own record
CREATE POLICY "admins_select_own"
ON admins FOR SELECT
USING (id = auth.uid());

-- Policy 2: Users can insert their own admin record
CREATE POLICY "admins_insert_own"
ON admins FOR INSERT
WITH CHECK (id = auth.uid());

-- Policy 3: Admins can update their own record
CREATE POLICY "admins_update_own"
ON admins FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Policy 4: Super admins can manage all admin records
CREATE POLICY "super_admins_manage_all"
ON admins FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM admins a
        WHERE a.id = auth.uid()
        AND a.admin_level = 'super_admin'
        AND a.is_active = TRUE
    )
);

DO $$ 
BEGIN
    RAISE NOTICE '✅ RLS policies created for admins table';
END $$;

-- ============================================
-- SECTION 3: CREATE TRIGGER FOR AUTO-UPDATE
-- ============================================

-- Trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS update_admins_updated_at ON admins;
CREATE TRIGGER update_admins_updated_at
    BEFORE UPDATE ON admins
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DO $$ 
BEGIN
    RAISE NOTICE '✅ Trigger created for admins table';
END $$;

-- ============================================
-- SECTION 4: VERIFICATION
-- ============================================

-- Verify table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'admins'
ORDER BY ordinal_position;

-- Check RLS status
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'admins';

-- Check policies
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'admins'
ORDER BY policyname;

-- ============================================
-- SECTION 5: COMPLETE ROLE TABLE SUMMARY
-- ============================================

-- Show all role-specific tables
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) AS column_count,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.table_name) AS policy_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'admins',
    'teachers', 
    'students', 
    'parents', 
    'ict_coordinators', 
    'grade_coordinators',
    'hybrid_users'
  )
ORDER BY table_name;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ ADMINS TABLE CREATED!                                  ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Complete Role Architecture:';
    RAISE NOTICE '  1 = admin              → admins table';
    RAISE NOTICE '  2 = teacher            → teachers table';
    RAISE NOTICE '  3 = student            → students table';
    RAISE NOTICE '  4 = parent             → parents table';
    RAISE NOTICE '  5 = ict_coordinator    → ict_coordinators table';
    RAISE NOTICE '  6 = grade_coordinator  → grade_coordinators table';
    RAISE NOTICE '  7 = hybrid             → hybrid_users table';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security:';
    RAISE NOTICE '  ✅ RLS enabled';
    RAISE NOTICE '  ✅ Admins can view/update own record';
    RAISE NOTICE '  ✅ Super admins can manage all admins';
    RAISE NOTICE '  ✅ Users can insert own record on signup';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Update AuthService to create admin records';
    RAISE NOTICE '  2. Test admin user creation';
    RAISE NOTICE '  3. Verify admin record is created on login';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF SCRIPT
-- ============================================
