-- ============================================
-- UPDATE ROLES TABLE - REORGANIZE AND ADD NEW ROLES
-- ============================================
-- Purpose: Update existing roles and add new role types
-- Changes:
--   1. Rename 'coordinator' to 'ict_coordinator'
--   2. Add 'grade_coordinator' role
--   3. Add 'hybrid' role
-- ============================================

-- ============================================
-- SECTION 1: BACKUP CURRENT STATE
-- ============================================

-- Show current roles
SELECT 
    id,
    name,
    created_at
FROM roles
ORDER BY id;

DO $$ 
BEGIN
    RAISE NOTICE '📊 Current roles shown above';
END $$;

-- ============================================
-- SECTION 2: UPDATE EXISTING ROLE
-- ============================================

-- Update 'coordinator' to 'ict_coordinator'
UPDATE roles
SET name = 'ict_coordinator'
WHERE id = 5 AND name = 'coordinator';

DO $$ 
BEGIN
    IF FOUND THEN
        RAISE NOTICE '✅ Updated role ID 5: coordinator → ict_coordinator';
    ELSE
        RAISE NOTICE '⚠️  Role ID 5 not found or already updated';
    END IF;
END $$;

-- ============================================
-- SECTION 3: ADD NEW ROLES
-- ============================================

-- Add 'grade_coordinator' role (ID 6)
INSERT INTO roles (id, name, created_at)
VALUES (6, 'grade_coordinator', NOW())
ON CONFLICT (id) DO UPDATE
SET name = 'grade_coordinator';

DO $$ 
BEGIN
    RAISE NOTICE '✅ Added/Updated role ID 6: grade_coordinator';
END $$;

-- Add 'hybrid' role (ID 7)
INSERT INTO roles (id, name, created_at)
VALUES (7, 'hybrid', NOW())
ON CONFLICT (id) DO UPDATE
SET name = 'hybrid';

DO $$ 
BEGIN
    RAISE NOTICE '✅ Added/Updated role ID 7: hybrid';
END $$;

-- ============================================
-- SECTION 4: CREATE GRADE_COORDINATORS TABLE
-- ============================================
-- Grade coordinators are teachers with additional responsibilities

CREATE TABLE IF NOT EXISTS grade_coordinators (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    employee_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    
    -- Coordinator-specific fields
    grade_level INT NOT NULL, -- 7, 8, 9, 10, 11, or 12
    department TEXT DEFAULT 'Academic Affairs',
    
    -- Also a teacher
    subjects JSONB DEFAULT '[]'::jsonb, -- Array of subjects they teach
    is_also_teaching BOOLEAN DEFAULT TRUE, -- Most coordinators also teach
    
    -- Coordinator responsibilities
    responsibilities JSONB DEFAULT '[]'::jsonb, -- Array of responsibilities
    managed_sections JSONB DEFAULT '[]'::jsonb, -- Sections they manage
    
    -- Contact
    phone TEXT,
    office_location TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT grade_coordinators_grade_check CHECK (
        grade_level >= 7 AND grade_level <= 12
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_grade_coordinators_active ON grade_coordinators(is_active);
CREATE INDEX IF NOT EXISTS idx_grade_coordinators_employee_id ON grade_coordinators(employee_id);
CREATE INDEX IF NOT EXISTS idx_grade_coordinators_grade_level ON grade_coordinators(grade_level);

-- Add comment
COMMENT ON TABLE grade_coordinators IS 'Grade Level Coordinators - Teachers with grade-level management responsibilities';

-- Enable RLS
ALTER TABLE grade_coordinators ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "grade_coordinators_select_all" ON grade_coordinators;
DROP POLICY IF EXISTS "grade_coordinators_insert_own" ON grade_coordinators;
DROP POLICY IF EXISTS "grade_coordinators_update_own" ON grade_coordinators;
DROP POLICY IF EXISTS "admins_manage_grade_coordinators" ON grade_coordinators;

-- Anyone can view active grade coordinators
CREATE POLICY "grade_coordinators_select_all"
ON grade_coordinators FOR SELECT
USING (is_active = TRUE);

-- Users can insert their own record
CREATE POLICY "grade_coordinators_insert_own"
ON grade_coordinators FOR INSERT
WITH CHECK (id = auth.uid());

-- Users can update their own record
CREATE POLICY "grade_coordinators_update_own"
ON grade_coordinators FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Admins can manage all grade coordinators
CREATE POLICY "admins_manage_grade_coordinators"
ON grade_coordinators FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1
    )
);

-- Trigger for auto-update
DROP TRIGGER IF EXISTS update_grade_coordinators_updated_at ON grade_coordinators;
CREATE TRIGGER update_grade_coordinators_updated_at
    BEFORE UPDATE ON grade_coordinators
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DO $$ 
BEGIN
    RAISE NOTICE '✅ grade_coordinators table created with RLS policies';
END $$;

-- ============================================
-- SECTION 5: UPDATE EXISTING PROFILES (IF NEEDED)
-- ============================================

-- If you have existing users with role_id = 5 (coordinator),
-- they will automatically use the renamed 'ict_coordinator' role
-- No profile updates needed!

DO $$ 
DECLARE
    v_count INT;
BEGIN
    -- Count profiles with coordinator role
    SELECT COUNT(*) INTO v_count
    FROM profiles
    WHERE role_id = 5;
    
    IF v_count > 0 THEN
        RAISE NOTICE '📊 Found % profiles with ICT Coordinator role (ID 5)', v_count;
        RAISE NOTICE '   These will automatically use the renamed role';
    ELSE
        RAISE NOTICE '📊 No profiles with ICT Coordinator role found';
    END IF;
END $$;

-- ============================================
-- SECTION 6: VERIFICATION
-- ============================================

-- Show updated roles table
SELECT 
    id,
    name,
    created_at,
    CASE 
        WHEN id = 1 THEN 'System administrators'
        WHEN id = 2 THEN 'Regular teachers'
        WHEN id = 3 THEN 'Students'
        WHEN id = 4 THEN 'Parents/Guardians'
        WHEN id = 5 THEN 'ICT Coordinators (renamed)'
        WHEN id = 6 THEN 'Grade Level Coordinators (NEW)'
        WHEN id = 7 THEN 'Hybrid users (NEW)'
        ELSE 'Unknown'
    END AS description
FROM roles
ORDER BY id;

-- Check all role-specific tables exist
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'teachers', 
    'students', 
    'parents', 
    'ict_coordinators', 
    'grade_coordinators',
    'hybrid_users'
  )
ORDER BY table_name;

-- Check RLS status on all role tables
SELECT 
    tablename,
    rowsecurity AS rls_enabled,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.tablename) AS policy_count
FROM pg_tables t
WHERE schemaname = 'public'
  AND tablename IN (
    'teachers', 
    'students', 
    'parents', 
    'ict_coordinators', 
    'grade_coordinators',
    'hybrid_users'
  )
ORDER BY tablename;

-- ============================================
-- SECTION 7: ROLE MAPPING REFERENCE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ ROLES TABLE UPDATE COMPLETE!                           ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════��═══════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Updated Role Mapping:';
    RAISE NOTICE '  1 = admin              → (no separate table)';
    RAISE NOTICE '  2 = teacher            → teachers table';
    RAISE NOTICE '  3 = student            → students table';
    RAISE NOTICE '  4 = parent             → parents table';
    RAISE NOTICE '  5 = ict_coordinator    → ict_coordinators table (RENAMED)';
    RAISE NOTICE '  6 = grade_coordinator  → grade_coordinators table (NEW)';
    RAISE NOTICE '  7 = hybrid             → hybrid_users table (NEW)';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Changes Made:';
    RAISE NOTICE '  ✅ Renamed: coordinator → ict_coordinator';
    RAISE NOTICE '  ✅ Added: grade_coordinator role';
    RAISE NOTICE '  ✅ Added: hybrid role';
    RAISE NOTICE '  ✅ Created: grade_coordinators table';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Update AuthService to handle new roles';
    RAISE NOTICE '  2. Test user creation for each role';
    RAISE NOTICE '  3. Verify role-specific records are created';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF SCRIPT
-- ============================================
