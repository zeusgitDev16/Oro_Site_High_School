-- ============================================
-- CREATE COURSE FILES TABLE AND STORAGE BUCKET
-- ============================================
-- Purpose: Store file metadata and setup Supabase Storage for course files
-- ============================================

-- ============================================
-- SECTION 1: CREATE COURSE_FILES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS course_files (
    id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_type TEXT NOT NULL CHECK (file_type IN ('module', 'assignment')),
    file_extension TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    uploaded_by TEXT NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_course_files_course_id ON course_files(course_id);
CREATE INDEX IF NOT EXISTS idx_course_files_file_type ON course_files(file_type);
CREATE INDEX IF NOT EXISTS idx_course_files_uploaded_at ON course_files(uploaded_at DESC);

-- Add comment
COMMENT ON TABLE course_files IS 'Stores metadata for files uploaded to courses (module and assignment resources)';

DO $$ 
BEGIN
    RAISE NOTICE '✅ course_files table created';
END $$;

-- ============================================
-- SECTION 2: ENABLE RLS AND CREATE POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE course_files ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "course_files_select_all" ON course_files;
DROP POLICY IF EXISTS "course_files_insert_authenticated" ON course_files;
DROP POLICY IF EXISTS "course_files_delete_authenticated" ON course_files;

-- Policy 1: Anyone authenticated can view course files
CREATE POLICY "course_files_select_all"
ON course_files FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Authenticated users can insert course files
CREATE POLICY "course_files_insert_authenticated"
ON course_files FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy 3: Authenticated users can delete course files
CREATE POLICY "course_files_delete_authenticated"
ON course_files FOR DELETE
TO authenticated
USING (true);

DO $$ 
BEGIN
    RAISE NOTICE '✅ RLS policies created for course_files table';
END $$;

-- ============================================
-- SECTION 3: STORAGE BUCKET SETUP INSTRUCTIONS
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
    RAISE NOTICE '    │   ├─ module/';
    RAISE NOTICE '    │   │   └─ {course_id}_module_{timestamp}.{ext}';
    RAISE NOTICE '    │   └─ assignment/';
    RAISE NOTICE '    │       └─ {course_id}_assignment_{timestamp}.{ext}';
    RAISE NOTICE '';
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
WHERE table_schema = 'public' AND table_name = 'course_files'
ORDER BY ordinal_position;

-- Check RLS status
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'course_files';

-- Check policies
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'course_files'
ORDER BY policyname;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ COURSE_FILES TABLE CREATED!                            ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Table Structure:';
    RAISE NOTICE '  - id (SERIAL, primary key)';
    RAISE NOTICE '  - course_id (INTEGER, required)';
    RAISE NOTICE '  - file_name (TEXT, required)';
    RAISE NOTICE '  - file_url (TEXT, required)';
    RAISE NOTICE '  - file_type (TEXT, module or assignment)';
    RAISE NOTICE '  - file_extension (TEXT, required)';
    RAISE NOTICE '  - file_size (INTEGER, in bytes)';
    RAISE NOTICE '  - uploaded_by (TEXT, user ID)';
    RAISE NOTICE '  - uploaded_at (TIMESTAMPTZ)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security:';
    RAISE NOTICE '  ✅ RLS enabled';
    RAISE NOTICE '  ✅ Authenticated users can upload/delete';
    RAISE NOTICE '  ✅ Public read access for files';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Create storage bucket "course-files" (see instructions above)';
    RAISE NOTICE '  2. Hot restart your Flutter app';
    RAISE NOTICE '  3. Go to a course';
    RAISE NOTICE '  4. Click "upload files" button';
    RAISE NOTICE '  5. Select files to upload!';
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
