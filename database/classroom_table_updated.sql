-- Classrooms Table (Updated with access_code and student policies)
-- Stores classroom information created by teachers

-- Add access_code column if it doesn't exist
ALTER TABLE classrooms ADD COLUMN IF NOT EXISTS access_code TEXT UNIQUE;

-- Create index for access_code lookups
CREATE INDEX IF NOT EXISTS idx_classrooms_access_code ON classrooms(access_code);

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Teachers can view own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can create classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can update own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Teachers can delete own classrooms" ON classrooms;
DROP POLICY IF EXISTS "Students can search classrooms by access code" ON classrooms;
DROP POLICY IF EXISTS "Students can view enrolled classrooms" ON classrooms;

-- RLS Policies
ALTER TABLE classrooms ENABLE ROW LEVEL SECURITY;

-- Teachers can view their own classrooms
CREATE POLICY "Teachers can view own classrooms"
  ON classrooms FOR SELECT
  USING (auth.uid() = teacher_id);

-- Teachers can create classrooms
CREATE POLICY "Teachers can create classrooms"
  ON classrooms FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

-- Teachers can update their own classrooms
CREATE POLICY "Teachers can update own classrooms"
  ON classrooms FOR UPDATE
  USING (auth.uid() = teacher_id);

-- Teachers can delete their own classrooms
CREATE POLICY "Teachers can delete own classrooms"
  ON classrooms FOR DELETE
  USING (auth.uid() = teacher_id);

-- ⭐ NEW: Students can search for active classrooms (for access code lookup)
CREATE POLICY "Students can search classrooms by access code"
  ON classrooms FOR SELECT
  USING (
    is_active = true
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'student'
    )
  );

-- ⭐ NEW: Students can view classrooms they are enrolled in
CREATE POLICY "Students can view enrolled classrooms"
  ON classrooms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classroom_students
      WHERE classroom_students.classroom_id = classrooms.id
      AND classroom_students.student_id = auth.uid()
    )
  );

-- Admins can view all classrooms
CREATE POLICY "Admins can view all classrooms"
  ON classrooms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
