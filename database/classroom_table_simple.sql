-- Classrooms Table - SIMPLE RLS (No Recursion)
-- This removes the circular dependency

-- Add access_code column if it doesn't exist
ALTER TABLE classrooms ADD COLUMN IF NOT EXISTS access_code TEXT UNIQUE;

-- Create index for access_code lookups
CREATE INDEX IF NOT EXISTS idx_classrooms_access_code ON classrooms(access_code);

-- Drop ALL existing policies on classrooms
DROP POLICY IF EXISTS "Teachers can view own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can create classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can update own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can delete own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Students can search classrooms by access code" ON classrooms;
DROP POLICY IF EXISTS "Students can view enrolled classrooms" ON classrooms;
DROP POLICY IF EXISTS "Admins can view all classrooms" ON classrooms;
DROP POLICY IF EXISTS "Classroom read access" ON classrooms;

-- Enable RLS
ALTER TABLE classrooms ENABLE ROW LEVEL SECURITY;

-- ⭐ SIMPLE SELECT POLICY - No subqueries to other tables
CREATE POLICY "Classroom read access"
  ON classrooms FOR SELECT
  USING (
    -- Teachers can see their own classrooms
    auth.uid() = teacher_id
    OR
    -- Students can see ALL active classrooms (for searching by access code)
    is_active = true
  );

-- Teachers can create classrooms
CREATE POLICY "Teachers can create classrooms"
  ON classrooms FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

-- Teachers can update their own classrooms
CREATE POLICY "Teachers can update own classrooms"
  ON classrooms FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

-- Teachers can delete their own classrooms
CREATE POLICY "Teachers can delete own classrooms"
  ON classrooms FOR DELETE
  USING (auth.uid() = teacher_id);
