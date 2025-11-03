-- ============================================
-- CREATE COURSES TABLE
-- ============================================
-- Purpose: Store course information for the simplified course management system
-- ============================================

-- ============================================
-- SECTION 1: CREATE COURSES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_courses_active ON courses(is_active);
CREATE INDEX IF NOT EXISTS idx_courses_created_at ON courses(created_at DESC);

-- Add comment
COMMENT ON TABLE courses IS 'Simplified course management - stores course basic information';

DO $$ 
BEGIN
    RAISE NOTICE '✅ courses table created';
END $$;

-- ============================================
-- SECTION 2: ENABLE RLS AND CREATE POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "courses_select_active" ON courses;
DROP POLICY IF EXISTS "courses_insert_authenticated" ON courses;
DROP POLICY IF EXISTS "courses_update_authenticated" ON courses;
DROP POLICY IF EXISTS "courses_delete_authenticated" ON courses;

-- Policy 1: Anyone authenticated can view active courses
CREATE POLICY "courses_select_active"
ON courses FOR SELECT
TO authenticated
USING (is_active = TRUE);

-- Policy 2: Authenticated users can insert courses
CREATE POLICY "courses_insert_authenticated"
ON courses FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy 3: Authenticated users can update courses
CREATE POLICY "courses_update_authenticated"
ON courses FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy 4: Authenticated users can delete courses (soft delete)
CREATE POLICY "courses_delete_authenticated"
ON courses FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

DO $$ 
BEGIN
    RAISE NOTICE '✅ RLS policies created for courses table';
END $$;

-- ============================================
-- SECTION 3: CREATE TRIGGER FOR AUTO-UPDATE
-- ============================================

-- Trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS update_courses_updated_at ON courses;
CREATE TRIGGER update_courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DO $$ 
BEGIN
    RAISE NOTICE '✅ Trigger created for courses table';
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
WHERE table_schema = 'public' AND table_name = 'courses'
ORDER BY ordinal_position;

-- Check RLS status
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'courses';

-- Check policies
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'courses'
ORDER BY policyname;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ COURSES TABLE CREATED!                                 ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Table Structure:';
    RAISE NOTICE '  - id (UUID, primary key)';
    RAISE NOTICE '  - title (TEXT, required)';
    RAISE NOTICE '  - description (TEXT, optional)';
    RAISE NOTICE '  - is_active (BOOLEAN, default true)';
    RAISE NOTICE '  - created_at (TIMESTAMPTZ)';
    RAISE NOTICE '  - updated_at (TIMESTAMPTZ)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security:';
    RAISE NOTICE '  ✅ RLS enabled';
    RAISE NOTICE '  ✅ Authenticated users can CRUD courses';
    RAISE NOTICE '  ✅ Only active courses visible';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Hot restart your Flutter app';
    RAISE NOTICE '  2. Login as admin';
    RAISE NOTICE '  3. Click Courses in sidebar';
    RAISE NOTICE '  4. Create your first course!';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF SCRIPT
-- ============================================
