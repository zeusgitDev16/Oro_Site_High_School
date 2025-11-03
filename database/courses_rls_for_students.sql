-- Update RLS policies for courses table to allow students to view courses in their classrooms

-- Drop existing student policies if they exist
DROP POLICY IF EXISTS "Students can view courses in their classrooms" ON courses;

-- Enable RLS on courses table
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Students can view courses that are in classrooms they're enrolled in
CREATE POLICY "Students can view courses in their classrooms"
  ON courses FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classroom_courses
      INNER JOIN classroom_students ON classroom_courses.classroom_id = classroom_students.classroom_id
      WHERE classroom_courses.course_id = courses.id
      AND classroom_students.student_id = auth.uid()
    )
  );

-- Update course_files RLS policies to allow students to view files
DROP POLICY IF EXISTS "Students can view course files in their classrooms" ON course_files;

-- Enable RLS on course_files table
ALTER TABLE course_files ENABLE ROW LEVEL SECURITY;

-- Students can view course files from courses in their classrooms
CREATE POLICY "Students can view course files in their classrooms"
  ON course_files FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classroom_courses
      INNER JOIN classroom_students ON classroom_courses.classroom_id = classroom_students.classroom_id
      WHERE classroom_courses.course_id = course_files.course_id
      AND classroom_students.student_id = auth.uid()
    )
  );
