-- Classrooms Table
-- Stores classroom information created by teachers

CREATE TABLE IF NOT EXISTS classrooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  grade_level INTEGER NOT NULL CHECK (grade_level >= 7 AND grade_level <= 12),
  max_students INTEGER NOT NULL CHECK (max_students >= 1 AND max_students <= 100),
  current_students INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_classrooms_teacher_id ON classrooms(teacher_id);
CREATE INDEX IF NOT EXISTS idx_classrooms_grade_level ON classrooms(grade_level);
CREATE INDEX IF NOT EXISTS idx_classrooms_is_active ON classrooms(is_active);

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

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_classrooms_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_classrooms_timestamp
  BEFORE UPDATE ON classrooms
  FOR EACH ROW
  EXECUTE FUNCTION update_classrooms_updated_at();
