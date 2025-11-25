-- =====================================================
-- Supabase Storage Bucket for Subject Resources
-- Purpose: Store uploaded files (modules, assignment resources, assignments)
-- =====================================================

-- Create storage bucket for subject resources
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'subject-resources',
  'subject-resources',
  false, -- Not public, requires authentication
  104857600, -- 100 MB in bytes
  ARRAY[
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document', -- docx
    'application/vnd.openxmlformats-officedocument.presentationml.presentation', -- pptx
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', -- xlsx
    'image/png',
    'image/jpeg',
    'video/mp4'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- Storage RLS Policies
-- =====================================================

-- Policy 1: Admins can upload all resource types
CREATE POLICY "Admins can upload all resources"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'subject-resources'
    AND EXISTS (
      SELECT 1 FROM admins
      WHERE admins.id = auth.uid()
      AND admins.is_active = true
    )
  );

-- Policy 2: Teachers can upload assignments only
CREATE POLICY "Teachers can upload assignments"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'subject-resources'
    AND (storage.foldername(name))[1] = 'assignments' -- Must be in assignments folder
    AND EXISTS (
      SELECT 1 FROM teachers
      WHERE teachers.id = auth.uid()
      AND teachers.is_active = true
    )
  );

-- Policy 3: Admins can update/delete all files
CREATE POLICY "Admins can manage all files"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (
    bucket_id = 'subject-resources'
    AND EXISTS (
      SELECT 1 FROM admins
      WHERE admins.id = auth.uid()
      AND admins.is_active = true
    )
  );

-- Policy 4: Teachers can update/delete their own assignment files
CREATE POLICY "Teachers can manage their assignment files"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'subject-resources'
    AND (storage.foldername(name))[1] = 'assignments'
    AND owner = auth.uid()
    AND EXISTS (
      SELECT 1 FROM teachers
      WHERE teachers.id = auth.uid()
      AND teachers.is_active = true
    )
  );

CREATE POLICY "Teachers can delete their assignment files"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'subject-resources'
    AND (storage.foldername(name))[1] = 'assignments'
    AND owner = auth.uid()
    AND EXISTS (
      SELECT 1 FROM teachers
      WHERE teachers.id = auth.uid()
      AND teachers.is_active = true
    )
  );

-- Policy 5: Admins and Teachers can view all files
CREATE POLICY "Admins and Teachers can view all files"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'subject-resources'
    AND (
      EXISTS (
        SELECT 1 FROM admins
        WHERE admins.id = auth.uid()
        AND admins.is_active = true
      )
      OR EXISTS (
        SELECT 1 FROM teachers
        WHERE teachers.id = auth.uid()
        AND teachers.is_active = true
      )
    )
  );

-- Policy 6: Students can view modules and assignments only
CREATE POLICY "Students can view modules and assignments"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'subject-resources'
    AND (
      (storage.foldername(name))[1] = 'modules'
      OR (storage.foldername(name))[1] = 'assignments'
    )
    AND EXISTS (
      SELECT 1 FROM students
      WHERE students.user_id = auth.uid()
      AND students.is_active = true
    )
  );

-- =====================================================
-- Storage Folder Structure
-- =====================================================
-- Files will be organized as:
-- subject-resources/
--   ├── modules/
--   │   ├── {classroom_id}/
--   │   │   ├── {subject_id}/
--   │   │   │   ├── q1/
--   │   │   │   │   └── {file_name}
--   │   │   │   ├── q2/
--   │   │   │   ├── q3/
--   │   │   │   └── q4/
--   ├── assignment_resources/
--   │   └── (same structure)
--   └── assignments/
--       └── (same structure)
-- =====================================================

COMMENT ON POLICY "Admins can upload all resources" ON storage.objects IS 'Admins can upload modules, assignment resources, and view assignments';
COMMENT ON POLICY "Teachers can upload assignments" ON storage.objects IS 'Teachers can only upload files to the assignments folder';
COMMENT ON POLICY "Students can view modules and assignments" ON storage.objects IS 'Students cannot access assignment_resources folder';

