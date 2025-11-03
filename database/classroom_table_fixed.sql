-- Classrooms Table - Fixed RLS Policies (No Recursion)
-- Run this to fix the infinite recursion error

-- Add access_code column if it doesn't exist
ALTER TABLE classrooms ADD COLUMN IF NOT EXISTS access_code TEXT UNIQUE;

-- Create index for access_code lookups
CREATE INDEX IF NOT EXISTS idx_classrooms_access_code ON classrooms(access_code);

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Teachers can view own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can create classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can update own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can delete own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Students can search classrooms by access code" ON classrooms;
DROP POLICY IF EXISTS "Students can view enrolled classrooms" ON classrooms;
DROP POLICY IF EXISTS "Admins can view all classrooms" ON classrooms;

-- Enable RLS
ALTER TABLE classrooms ENABLE ROW LEVEL SECURITY;

-- ⭐ SINGLE SELECT POLICY - Combines all read permissions
CREATE POLICY "Classroom read access"
  ON classrooms FOR SELECT
  USING (
    -- Teachers can see their own classrooms
    auth.uid() = teacher_id
    OR
    -- Students can see active classrooms (for searching by access code)
    (
      is_active = true
      AND EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'student'
      )
    )
    OR
    -- Students can see classrooms they're enrolled in
    EXISTS (
      SELECT 1 FROM classroom_students
      WHERE classroom_students.classroom_id = classrooms.id
      AND classroom_students.student_id = auth.uid()
    )
    OR
    -- Admins can see all classrooms
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Teachers can create classrooms
CREATE POLICY "Teachers can create classrooms"
  ON classrooms FOR INSERT
  WITH CHECK (
    auth.uid() = teacher_id
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'teacher'
    )
  );

-- Teachers can update their own classrooms
CREATE POLICY "Teachers can update own classrooms"
  ON classrooms FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

-- Teachers can delete their own classrooms (soft delete)
CREATE POLICY "Teachers can delete own classrooms"
  ON classrooms FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);
