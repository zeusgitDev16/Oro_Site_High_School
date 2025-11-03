-- RLS policies for classroom_courses table

-- Drop existing policies
DROP POLICY IF EXISTS "Teachers can view classroom courses" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can add courses to classrooms" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can remove courses from classrooms" ON classroom_courses;
DROP POLICY IF EXISTS "Students can view classroom courses" ON classroom_courses;

-- Enable RLS
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
CREATE POLICY "Teachers can remove courses from classrooms"
  ON classroom_courses FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

-- ⭐ Students can view courses in classrooms they're enrolled in
CREATE POLICY "Students can view classroom courses"
  ON classroom_courses FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classroom_students
      WHERE classroom_students.classroom_id = classroom_courses.classroom_id
      AND classroom_students.student_id = auth.uid()
    )
  );
