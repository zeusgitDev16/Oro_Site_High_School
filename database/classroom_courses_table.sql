-- Classroom Courses Table
-- Links courses to classrooms (many-to-many relationship)

CREATE TABLE IF NOT EXISTS classroom_courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  classroom_id UUID NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
  course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  added_by UUID NOT NULL REFERENCES auth.users(id),
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(classroom_id, course_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_classroom_courses_classroom_id ON classroom_courses(classroom_id);
CREATE INDEX IF NOT EXISTS idx_classroom_courses_course_id ON classroom_courses(course_id);

-- RLS Policies
ALTER TABLE classroom_courses ENABLE ROW LEVEL SECURITY;

-- Teachers can view courses in their classrooms
CREATE POLICY "Teachers can view classroom courses"
  ON classroom_courses FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

-- Teachers can add courses to their classrooms
CREATE POLICY "Teachers can add courses to classrooms"
  ON classroom_courses FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

-- Teachers can remove courses from their classrooms
CREATE POLICY "Teachers can remove classroom courses"
  ON classroom_courses FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

-- Add access_code to classrooms table
ALTER TABLE classrooms ADD COLUMN IF NOT EXISTS access_code TEXT UNIQUE;

-- Function to generate random access code
CREATE OR REPLACE FUNCTION generate_access_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Update existing classrooms to have access codes
UPDATE classrooms SET access_code = generate_access_code() WHERE access_code IS NULL;
