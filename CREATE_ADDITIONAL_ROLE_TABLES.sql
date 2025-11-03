-- ============================================
-- CREATE ADDITIONAL ROLE-SPECIFIC TABLES
-- ============================================
-- Purpose: Create tables for ICT Coordinator, Hybrid User, and Parent
-- These tables extend the profiles table with role-specific data
-- ============================================

-- ============================================
-- SECTION 1: CREATE ICT_COORDINATORS TABLE
-- ============================================
-- ICT Coordinators are special teachers with tech responsibilities

CREATE TABLE IF NOT EXISTS ict_coordinators (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    employee_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    department TEXT DEFAULT 'ICT',
    
    -- ICT-specific fields
    specialization TEXT, -- e.g., "Network Administration", "Software Development"
    certifications JSONB DEFAULT '[]'::jsonb, -- Array of certifications
    tech_skills JSONB DEFAULT '[]'::jsonb, -- Array of technical skills
    
    -- Coordinator responsibilities
    is_system_admin BOOLEAN DEFAULT FALSE, -- Can manage system settings
    managed_systems JSONB DEFAULT '[]'::jsonb, -- Systems they manage
    
    -- Contact and status
    phone TEXT,
    emergency_contact TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_ict_coordinators_active ON ict_coordinators(is_active);
CREATE INDEX IF NOT EXISTS idx_ict_coordinators_employee_id ON ict_coordinators(employee_id);
CREATE INDEX IF NOT EXISTS idx_ict_coordinators_system_admin ON ict_coordinators(is_system_admin);

-- Add comment
COMMENT ON TABLE ict_coordinators IS 'ICT Coordinator-specific information with technical responsibilities';

-- Enable RLS
ALTER TABLE ict_coordinators ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "ict_coordinators_select_all" ON ict_coordinators;
DROP POLICY IF EXISTS "ict_coordinators_insert_own" ON ict_coordinators;
DROP POLICY IF EXISTS "ict_coordinators_update_own" ON ict_coordinators;
DROP POLICY IF EXISTS "admins_manage_ict_coordinators" ON ict_coordinators;

-- Anyone can view active ICT coordinators
CREATE POLICY "ict_coordinators_select_all"
ON ict_coordinators FOR SELECT
USING (is_active = TRUE);

-- Users can insert their own record
CREATE POLICY "ict_coordinators_insert_own"
ON ict_coordinators FOR INSERT
WITH CHECK (id = auth.uid());

-- Users can update their own record
CREATE POLICY "ict_coordinators_update_own"
ON ict_coordinators FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Admins can manage all ICT coordinators
CREATE POLICY "admins_manage_ict_coordinators"
ON ict_coordinators FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1 -- Admin role
    )
);

-- Verify table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'ict_coordinators'
ORDER BY ordinal_position;

DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 1 COMPLETE: ict_coordinators table created';
END $$;

-- ============================================
-- SECTION 2: CREATE HYBRID_USERS TABLE
-- ============================================
-- Hybrid users have multiple roles (e.g., Admin + Teacher)

CREATE TABLE IF NOT EXISTS hybrid_users (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    employee_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    
    -- Primary role info
    primary_role TEXT NOT NULL, -- 'admin', 'teacher', 'coordinator'
    secondary_roles JSONB DEFAULT '[]'::jsonb, -- Array of additional roles
    
    -- Admin capabilities (if admin role)
    admin_level TEXT, -- 'super_admin', 'admin', 'limited_admin'
    admin_permissions JSONB DEFAULT '[]'::jsonb, -- Specific admin permissions
    
    -- Teacher capabilities (if teacher role)
    department TEXT,
    subjects JSONB DEFAULT '[]'::jsonb,
    is_grade_coordinator BOOLEAN DEFAULT FALSE,
    coordinator_grade_level TEXT,
    
    -- Contact and status
    phone TEXT,
    office_location TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT hybrid_users_primary_role_check CHECK (
        primary_role IN ('admin', 'teacher', 'coordinator', 'ict_coordinator')
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_hybrid_users_active ON hybrid_users(is_active);
CREATE INDEX IF NOT EXISTS idx_hybrid_users_employee_id ON hybrid_users(employee_id);
CREATE INDEX IF NOT EXISTS idx_hybrid_users_primary_role ON hybrid_users(primary_role);

-- Add comment
COMMENT ON TABLE hybrid_users IS 'Users with multiple roles (e.g., Admin who also teaches)';

-- Enable RLS
ALTER TABLE hybrid_users ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "hybrid_users_select_all" ON hybrid_users;
DROP POLICY IF EXISTS "hybrid_users_insert_own" ON hybrid_users;
DROP POLICY IF EXISTS "hybrid_users_update_own" ON hybrid_users;
DROP POLICY IF EXISTS "admins_manage_hybrid_users" ON hybrid_users;

-- Anyone can view active hybrid users
CREATE POLICY "hybrid_users_select_all"
ON hybrid_users FOR SELECT
USING (is_active = TRUE);

-- Users can insert their own record
CREATE POLICY "hybrid_users_insert_own"
ON hybrid_users FOR INSERT
WITH CHECK (id = auth.uid());

-- Users can update their own record
CREATE POLICY "hybrid_users_update_own"
ON hybrid_users FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Admins can manage all hybrid users
CREATE POLICY "admins_manage_hybrid_users"
ON hybrid_users FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1
    )
);

-- Verify table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'hybrid_users'
ORDER BY ordinal_position;

DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 2 COMPLETE: hybrid_users table created';
END $$;

-- ============================================
-- SECTION 3: CREATE PARENTS TABLE
-- ============================================
-- Parents/Guardians linked to students

CREATE TABLE IF NOT EXISTS parents (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Personal information
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    
    -- Contact information
    email TEXT NOT NULL,
    phone TEXT,
    alternate_phone TEXT,
    address TEXT,
    
    -- Guardian information
    relationship_to_student TEXT, -- 'father', 'mother', 'guardian', 'other'
    occupation TEXT,
    employer TEXT,
    work_phone TEXT,
    
    -- Emergency contact
    is_emergency_contact BOOLEAN DEFAULT TRUE,
    emergency_contact_priority INT DEFAULT 1, -- 1 = primary, 2 = secondary, etc.
    
    -- Access and permissions
    can_pickup_student BOOLEAN DEFAULT TRUE,
    can_view_grades BOOLEAN DEFAULT TRUE,
    can_receive_notifications BOOLEAN DEFAULT TRUE,
    preferred_contact_method TEXT DEFAULT 'email', -- 'email', 'sms', 'call'
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT parents_relationship_check CHECK (
        relationship_to_student IN ('father', 'mother', 'guardian', 'grandfather', 'grandmother', 'aunt', 'uncle', 'sibling', 'other')
    ),
    CONSTRAINT parents_contact_method_check CHECK (
        preferred_contact_method IN ('email', 'sms', 'call', 'app')
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_parents_active ON parents(is_active);
CREATE INDEX IF NOT EXISTS idx_parents_email ON parents(email);
CREATE INDEX IF NOT EXISTS idx_parents_phone ON parents(phone);
CREATE INDEX IF NOT EXISTS idx_parents_emergency ON parents(is_emergency_contact);

-- Add comment
COMMENT ON TABLE parents IS 'Parent/Guardian information linked to students';

-- Enable RLS
ALTER TABLE parents ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "parents_select_own" ON parents;
DROP POLICY IF EXISTS "parents_insert_own" ON parents;
DROP POLICY IF EXISTS "parents_update_own" ON parents;
DROP POLICY IF EXISTS "teachers_view_parents" ON parents;
DROP POLICY IF EXISTS "admins_manage_parents" ON parents;

-- Parents can view their own record
CREATE POLICY "parents_select_own"
ON parents FOR SELECT
USING (id = auth.uid());

-- Users can insert their own record
CREATE POLICY "parents_insert_own"
ON parents FOR INSERT
WITH CHECK (id = auth.uid());

-- Parents can update their own record
CREATE POLICY "parents_update_own"
ON parents FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Teachers can view parents (for their students)
CREATE POLICY "teachers_view_parents"
ON parents FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id IN (2, 5) -- Teacher or Coordinator
    )
);

-- Admins can manage all parents
CREATE POLICY "admins_manage_parents"
ON parents FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1
    )
);

-- Verify table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'parents'
ORDER BY ordinal_position;

DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 3 COMPLETE: parents table created';
END $$;

-- ============================================
-- SECTION 4: CREATE PARENT_STUDENT_LINKS TABLE
-- ============================================
-- Links parents to their children (students)

CREATE TABLE IF NOT EXISTS parent_student_links (
    id BIGSERIAL PRIMARY KEY,
    parent_id UUID NOT NULL REFERENCES parents(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    relationship TEXT NOT NULL, -- 'father', 'mother', 'guardian', etc.
    is_primary_contact BOOLEAN DEFAULT FALSE,
    is_emergency_contact BOOLEAN DEFAULT TRUE,
    can_pickup BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Prevent duplicate links
    CONSTRAINT parent_student_unique UNIQUE (parent_id, student_id),
    
    -- Constraint for relationship
    CONSTRAINT parent_student_relationship_check CHECK (
        relationship IN ('father', 'mother', 'guardian', 'grandfather', 'grandmother', 'aunt', 'uncle', 'sibling', 'other')
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_parent_student_parent ON parent_student_links(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_student_student ON parent_student_links(student_id);
CREATE INDEX IF NOT EXISTS idx_parent_student_primary ON parent_student_links(is_primary_contact);

-- Add comment
COMMENT ON TABLE parent_student_links IS 'Links parents to their children (students)';

-- Enable RLS
ALTER TABLE parent_student_links ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "parents_view_own_links" ON parent_student_links;
DROP POLICY IF EXISTS "students_view_own_links" ON parent_student_links;
DROP POLICY IF EXISTS "teachers_view_links" ON parent_student_links;
DROP POLICY IF EXISTS "admins_manage_links" ON parent_student_links;

-- Parents can view their own links
CREATE POLICY "parents_view_own_links"
ON parent_student_links FOR SELECT
USING (parent_id = auth.uid());

-- Students can view their own links
CREATE POLICY "students_view_own_links"
ON parent_student_links FOR SELECT
USING (student_id = auth.uid());

-- Teachers can view links
CREATE POLICY "teachers_view_links"
ON parent_student_links FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id IN (2, 5)
    )
);

-- Admins can manage all links
CREATE POLICY "admins_manage_links"
ON parent_student_links FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1
    )
);

-- Verify table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'parent_student_links'
ORDER BY ordinal_position;

DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 4 COMPLETE: parent_student_links table created';
END $$;

-- ============================================
-- SECTION 5: CREATE TRIGGERS FOR AUTO-UPDATE
-- ============================================

-- Trigger for ict_coordinators
DROP TRIGGER IF EXISTS update_ict_coordinators_updated_at ON ict_coordinators;
CREATE TRIGGER update_ict_coordinators_updated_at
    BEFORE UPDATE ON ict_coordinators
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for hybrid_users
DROP TRIGGER IF EXISTS update_hybrid_users_updated_at ON hybrid_users;
CREATE TRIGGER update_hybrid_users_updated_at
    BEFORE UPDATE ON hybrid_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for parents
DROP TRIGGER IF EXISTS update_parents_updated_at ON parents;
CREATE TRIGGER update_parents_updated_at
    BEFORE UPDATE ON parents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for parent_student_links
DROP TRIGGER IF EXISTS update_parent_student_links_updated_at ON parent_student_links;
CREATE TRIGGER update_parent_student_links_updated_at
    BEFORE UPDATE ON parent_student_links
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 5 COMPLETE: Triggers created';
END $$;

-- ============================================
-- SECTION 6: VERIFICATION
-- ============================================

-- Check all new tables exist
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('ict_coordinators', 'hybrid_users', 'parents', 'parent_student_links')
ORDER BY table_name;

-- Check RLS is enabled
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('ict_coordinators', 'hybrid_users', 'parents', 'parent_student_links')
ORDER BY tablename;

-- Check policies exist
SELECT 
    tablename,
    COUNT(*) AS policy_count
FROM pg_policies
WHERE tablename IN ('ict_coordinators', 'hybrid_users', 'parents', 'parent_student_links')
GROUP BY tablename
ORDER BY tablename;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔═════════════════════════════════════════���══════════════════╗';
    RAISE NOTICE '║  ✅ ADDITIONAL ROLE TABLES CREATED!                        ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Tables Created:';
    RAISE NOTICE '  ✅ ict_coordinators - ICT Coordinator-specific data';
    RAISE NOTICE '  ✅ hybrid_users - Users with multiple roles';
    RAISE NOTICE '  ✅ parents - Parent/Guardian information';
    RAISE NOTICE '  ✅ parent_student_links - Parent-Student relationships';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security:';
    RAISE NOTICE '  ✅ RLS enabled on all tables';
    RAISE NOTICE '  ✅ INSERT policies allow self-registration';
    RAISE NOTICE '  ✅ UPDATE policies allow self-management';
    RAISE NOTICE '  ✅ Admin policies for full management';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Update AuthService to create these records';
    RAISE NOTICE '  2. Create Dart models for each table';
    RAISE NOTICE '  3. Test user creation for each role';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF SCRIPT
-- ============================================
