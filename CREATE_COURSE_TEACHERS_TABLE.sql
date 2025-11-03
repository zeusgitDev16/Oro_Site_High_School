-- ============================================
-- CREATE COURSE_TEACHERS TABLE
-- ============================================
-- Purpose: Link table for many-to-many relationship between courses and teachers
-- ============================================

-- ============================================
-- SECTION 1: CREATE COURSE_TEACHERS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS course_teachers (
    id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    teacher_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(course_id, teacher_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_course_teachers_course_id ON course_teachers(course_id);
CREATE INDEX IF NOT EXISTS idx_course_teachers_teacher_id ON course_teachers(teacher_id);

-- Add comment
COMMENT ON TABLE course_teachers IS 'Links teachers to courses - many-to-many relationship';

DO $$ 
BEGIN
    RAISE NOTICE '✅ course_teachers table created';
END $$;

-- ============================================
-- SECTION 2: ENABLE RLS AND CREATE POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE course_teachers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "course_teachers_select_all" ON course_teachers;
DROP POLICY IF EXISTS "course_teachers_insert_authenticated" ON course_teachers;
DROP POLICY IF EXISTS "course_teachers_delete_authenticated" ON course_teachers;

-- Policy 1: Anyone authenticated can view course-teacher links
CREATE POLICY "course_teachers_select_all"
ON course_teachers FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Authenticated users can insert course-teacher links
CREATE POLICY "course_teachers_insert_authenticated"
ON course_teachers FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy 3: Authenticated users can delete course-teacher links
CREATE POLICY "course_teachers_delete_authenticated"
ON course_teachers FOR DELETE
TO authenticated
USING (true);

DO $$ 
BEGIN
    RAISE NOTICE '✅ RLS policies created for course_teachers table';
END $$;

-- ============================================
-- SECTION 3: VERIFICATION
-- ============================================

-- Verify table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'course_teachers'
ORDER BY ordinal_position;

-- Check RLS status
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'course_teachers';

-- Check policies
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'course_teachers'
ORDER BY policyname;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ COURSE_TEACHERS TABLE CREATED!                         ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Table Structure:';
    RAISE NOTICE '  - id (SERIAL, primary key)';
    RAISE NOTICE '  - course_id (INTEGER, required)';
    RAISE NOTICE '  - teacher_id (TEXT, required)';
    RAISE NOTICE '  - created_at (TIMESTAMPTZ)';
    RAISE NOTICE '  - UNIQUE constraint on (course_id, teacher_id)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security:';
    RAISE NOTICE '  ✅ RLS enabled';
    RAISE NOTICE '  ✅ Authenticated users can view/add/remove';
    RAISE NOTICE '  ✅ Prevents duplicate assignments';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Hot restart your Flutter app';
    RAISE NOTICE '  2. Create a course';
    RAISE NOTICE '  3. Click "add teachers" button';
    RAISE NOTICE '  4. Assign a teacher to the course!';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF SCRIPT
-- ============================================
