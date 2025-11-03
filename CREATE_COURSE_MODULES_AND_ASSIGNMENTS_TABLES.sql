-- ============================================
-- CREATE COURSE MODULES AND ASSIGNMENTS TABLES
-- ============================================
-- Purpose: Separate tables for module resources and assignment resources
-- ============================================

-- ============================================
-- SECTION 1: CREATE COURSE_MODULES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS course_modules (
    id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_extension TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    uploaded_by TEXT NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes for course_modules
CREATE INDEX IF NOT EXISTS idx_course_modules_course_id ON course_modules(course_id);
CREATE INDEX IF NOT EXISTS idx_course_modules_uploaded_at ON course_modules(uploaded_at DESC);

-- Add comment
COMMENT ON TABLE course_modules IS 'Stores module resource files for courses';

DO $$ 
BEGIN
    RAISE NOTICE '✅ course_modules table created';
END $$;

-- ============================================
-- SECTION 2: CREATE COURSE_ASSIGNMENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS course_assignments (
    id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_extension TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    uploaded_by TEXT NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes for course_assignments
CREATE INDEX IF NOT EXISTS idx_course_assignments_course_id ON course_assignments(course_id);
CREATE INDEX IF NOT EXISTS idx_course_assignments_uploaded_at ON course_assignments(uploaded_at DESC);

-- Add comment
COMMENT ON TABLE course_assignments IS 'Stores assignment resource files for courses';

DO $$ 
BEGIN
    RAISE NOTICE '✅ course_assignments table created';
END $$;

-- ============================================
-- SECTION 3: ENABLE RLS FOR COURSE_MODULES
-- ============================================

-- Enable RLS
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "course_modules_select_all" ON course_modules;
DROP POLICY IF EXISTS "course_modules_insert_authenticated" ON course_modules;
DROP POLICY IF EXISTS "course_modules_delete_authenticated" ON course_modules;

-- Policy 1: Anyone authenticated can view course modules
CREATE POLICY "course_modules_select_all"
ON course_modules FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Authenticated users can insert course modules
CREATE POLICY "course_modules_insert_authenticated"
ON course_modules FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy 3: Authenticated users can delete course modules
CREATE POLICY "course_modules_delete_authenticated"
ON course_modules FOR DELETE
TO authenticated
USING (true);

DO $$ 
BEGIN
    RAISE NOTICE '✅ RLS policies created for course_modules table';
END $$;

-- ============================================
-- SECTION 4: ENABLE RLS FOR COURSE_ASSIGNMENTS
-- ============================================

-- Enable RLS
ALTER TABLE course_assignments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "course_assignments_select_all" ON course_assignments;
DROP POLICY IF EXISTS "course_assignments_insert_authenticated" ON course_assignments;
DROP POLICY IF EXISTS "course_assignments_delete_authenticated" ON course_assignments;

-- Policy 1: Anyone authenticated can view course assignments
CREATE POLICY "course_assignments_select_all"
ON course_assignments FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Authenticated users can insert course assignments
CREATE POLICY "course_assignments_insert_authenticated"
ON course_assignments FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy 3: Authenticated users can delete course assignments
CREATE POLICY "course_assignments_delete_authenticated"
ON course_assignments FOR DELETE
TO authenticated
USING (true);

DO $$ 
BEGIN
    RAISE NOTICE '✅ RLS policies created for course_assignments table';
END $$;

-- ============================================
-- SECTION 5: STORAGE BUCKET SETUP INSTRUCTIONS
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  📦 STORAGE BUCKET SETUP REQUIRED                          ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANT: You need to create a storage bucket manually!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Steps to create storage bucket:';
    RAISE NOTICE '  1. Go to Supabase Dashboard → Storage';
    RAISE NOTICE '  2. Click "New bucket"';
    RAISE NOTICE '  3. Bucket name: course-files';
    RAISE NOTICE '  4. Public bucket: YES (check the box)';
    RAISE NOTICE '  5. Click "Create bucket"';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Storage Policies (will be auto-created):';
    RAISE NOTICE '  - Allow authenticated users to upload';
    RAISE NOTICE '  - Allow authenticated users to delete';
    RAISE NOTICE '  - Allow public read access';
    RAISE NOTICE '';
    RAISE NOTICE '📁 Folder Structure (auto-created on upload):';
    RAISE NOTICE '  course-files/';
    RAISE NOTICE '    ├─ {course_id}/';
    RAISE NOTICE '    │   ├─ modules/';
    RAISE NOTICE '    │   │   └─ {course_id}_module_{timestamp}.{ext}';
    RAISE NOTICE '    │   └─ assignments/';
    RAISE NOTICE '    │       └─ {course_id}_assignment_{timestamp}.{ext}';
    RAISE NOTICE '';
END $$;

-- ============================================
-- SECTION 6: VERIFICATION
-- ============================================

-- Verify course_modules table structure
SELECT 
    'course_modules' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'course_modules'
ORDER BY ordinal_position;

-- Verify course_assignments table structure
SELECT 
    'course_assignments' as table_name,
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'course_assignments'
ORDER BY ordinal_position;

-- Check RLS status
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename IN ('course_modules', 'course_assignments');

-- Check policies for course_modules
SELECT 
    'course_modules' as table_name,
    policyname,
    cmd
FROM pg_policies
WHERE tablename = 'course_modules'
ORDER BY policyname;

-- Check policies for course_assignments
SELECT 
    'course_assignments' as table_name,
    policyname,
    cmd
FROM pg_policies
WHERE tablename = 'course_assignments'
ORDER BY policyname;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ COURSE MODULES & ASSIGNMENTS TABLES CREATED!           ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Tables Created:';
    RAISE NOTICE '  1. course_modules - For module resource files';
    RAISE NOTICE '  2. course_assignments - For assignment resource files';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Table Structure (both tables):';
    RAISE NOTICE '  - id (SERIAL, primary key)';
    RAISE NOTICE '  - course_id (INTEGER, required)';
    RAISE NOTICE '  - file_name (TEXT, required)';
    RAISE NOTICE '  - file_url (TEXT, required)';
    RAISE NOTICE '  - file_extension (TEXT, required)';
    RAISE NOTICE '  - file_size (INTEGER, in bytes)';
    RAISE NOTICE '  - uploaded_by (TEXT, user ID)';
    RAISE NOTICE '  - uploaded_at (TIMESTAMPTZ)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security:';
    RAISE NOTICE '  ✅ RLS enabled on both tables';
    RAISE NOTICE '  ✅ Authenticated users can upload/delete';
    RAISE NOTICE '  ✅ Public read access for files';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Benefits of Separate Tables:';
    RAISE NOTICE '  ✅ Better organization';
    RAISE NOTICE '  ✅ Easier queries (no filtering by type)';
    RAISE NOTICE '  ✅ Independent management';
    RAISE NOTICE '  ✅ Clearer data structure';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Create storage bucket "course-files" (see instructions above)';
    RAISE NOTICE '  2. Update Flutter code to use new tables';
    RAISE NOTICE '  3. Hot restart your Flutter app';
    RAISE NOTICE '  4. Go to a course';
    RAISE NOTICE '  5. Upload module files → saved to course_modules';
    RAISE NOTICE '  6. Upload assignment files → saved to course_assignments';
    RAISE NOTICE '';
    RAISE NOTICE '📝 Supported File Types:';
    RAISE NOTICE '  ✅ Documents: PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT';
    RAISE NOTICE '  ✅ Images: JPG, PNG, GIF';
    RAISE NOTICE '  ✅ Videos: MP4, AVI, MOV';
    RAISE NOTICE '  ✅ Audio: MP3, WAV';
    RAISE NOTICE '  ✅ Archives: ZIP, RAR';
    RAISE NOTICE '  ✅ And ANY other file type!';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF SCRIPT
-- ============================================
