-- ============================================
-- FIX STORAGE BUCKET RLS POLICIES
-- ============================================
-- Purpose: Add proper RLS policies to course_files bucket
-- ============================================

-- ============================================
-- SECTION 1: STORAGE POLICIES FOR course_files BUCKET
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to upload files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to read files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete files" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to read files" ON storage.objects;

-- Policy 1: Allow authenticated users to upload files to course_files bucket
CREATE POLICY "Allow authenticated users to upload files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'course_files');

-- Policy 2: Allow authenticated users to read files from course_files bucket
CREATE POLICY "Allow authenticated users to read files"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'course_files');

-- Policy 3: Allow authenticated users to delete files from course_files bucket
CREATE POLICY "Allow authenticated users to delete files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'course_files');

-- Policy 4: Allow public to read files (for downloads)
CREATE POLICY "Allow public to read files"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'course_files');

DO $$ 
BEGIN
    RAISE NOTICE '✅ Storage policies created for course_files bucket';
END $$;

-- ============================================
-- SECTION 2: VERIFY BUCKET EXISTS AND IS PUBLIC
-- ============================================

-- Check if bucket exists
DO $$
DECLARE
    bucket_exists BOOLEAN;
    bucket_public BOOLEAN;
BEGIN
    -- Check if bucket exists
    SELECT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'course_files'
    ) INTO bucket_exists;
    
    IF bucket_exists THEN
        RAISE NOTICE '✅ Bucket "course_files" exists';
        
        -- Check if bucket is public
        SELECT public FROM storage.buckets WHERE id = 'course_files' INTO bucket_public;
        
        IF bucket_public THEN
            RAISE NOTICE '✅ Bucket "course_files" is PUBLIC';
        ELSE
            RAISE NOTICE '⚠️  Bucket "course_files" is PRIVATE - making it public...';
            UPDATE storage.buckets SET public = true WHERE id = 'course_files';
            RAISE NOTICE '✅ Bucket "course_files" is now PUBLIC';
        END IF;
    ELSE
        RAISE NOTICE '❌ Bucket "course_files" does NOT exist!';
        RAISE NOTICE '📋 Please create it manually:';
        RAISE NOTICE '   1. Go to Supabase Dashboard → Storage';
        RAISE NOTICE '   2. Click "New bucket"';
        RAISE NOTICE '   3. Name: course_files';
        RAISE NOTICE '   4. Public: YES (check the box)';
        RAISE NOTICE '   5. Click "Create bucket"';
    END IF;
END $$;

-- ============================================
-- SECTION 3: VERIFY POLICIES
-- ============================================

-- List all policies for storage.objects related to course_files
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND (qual LIKE '%course_files%' OR with_check LIKE '%course_files%')
ORDER BY policyname;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔═══���════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ STORAGE BUCKET POLICIES FIXED!                         ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📦 Bucket: course_files';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Policies Created:';
    RAISE NOTICE '  ✅ Authenticated users can UPLOAD files';
    RAISE NOTICE '  ✅ Authenticated users can READ files';
    RAISE NOTICE '  ✅ Authenticated users can DELETE files';
    RAISE NOTICE '  ✅ Public can READ files (for downloads)';
    RAISE NOTICE '';
    RAISE NOTICE '👥 Who Can Upload:';
    RAISE NOTICE '  ✅ Admin users';
    RAISE NOTICE '  ✅ ICT Coordinator users';
    RAISE NOTICE '  ✅ Teacher users';
    RAISE NOTICE '  ✅ ANY authenticated user';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Hot restart your Flutter app';
    RAISE NOTICE '  2. Login with your ICT Coordinator account';
    RAISE NOTICE '  3. Go to Courses';
    RAISE NOTICE '  4. Try uploading a file';
    RAISE NOTICE '  5. Should work now! ✅';
    RAISE NOTICE '';
    RAISE NOTICE '🔍 If still not working, check:';
    RAISE NOTICE '  - Is your user authenticated? (logged in)';
    RAISE NOTICE '  - Does the bucket "course_files" exist?';
    RAISE NOTICE '  - Is the bucket PUBLIC?';
    RAISE NOTICE '  - Check browser console for errors';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF SCRIPT
-- ============================================
