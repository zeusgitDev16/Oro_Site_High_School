-- Complete RLS Setup for Student Classroom Access
-- Run this to allow students to view all classroom content

-- ============================================
-- 1. CLASSROOMS TABLE
-- ============================================
-- Already configured in classroom_table_simple.sql
-- Students can see all active classrooms

-- ============================================
-- 2. CLASSROOM_STUDENTS TABLE
-- ============================================
-- Already configured in classroom_students_table_simple.sql
-- Students can view their own enrollments

-- ============================================
-- 3. CLASSROOM_COURSES TABLE (Junction Table)
-- ============================================
DROP POLICY IF EXISTS "Teachers can view classroom courses" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can add courses to classrooms" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can remove courses from classrooms" ON classroom_courses;
DROP POLICY IF EXISTS "Students can view classroom courses" ON classroom_courses;

ALTER TABLE classroom_courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teachers can view classroom courses"
  ON classroom_courses FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can add courses to classrooms"
  ON classroom_courses FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can remove courses from classrooms"
  ON classroom_courses FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Students can view classroom courses"
  ON classroom_courses FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classroom_students
      WHERE classroom_students.classroom_id = classroom_courses.classroom_id
      AND classroom_students.student_id = auth.uid()
    )
  );

-- ============================================
-- 4. COURSES TABLE
-- ============================================
DROP POLICY IF EXISTS "Teachers can view own courses" ON courses;
DROP POLICY IF EXISTS "Teachers can create courses" ON courses;
DROP POLICY IF EXISTS "Teachers can update own courses" ON courses;
DROP POLICY IF EXISTS "Teachers can delete own courses" ON courses;
DROP POLICY IF EXISTS "Students can view courses in their classrooms" ON courses;

ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teachers can view own courses"
  ON courses FOR SELECT
  USING (auth.uid() = teacher_id);

CREATE POLICY "Teachers can create courses"
  ON courses FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "Teachers can update own courses"
  ON courses FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "Teachers can delete own courses"
  ON courses FOR DELETE
  USING (auth.uid() = teacher_id);

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

-- ============================================
-- 5. COURSE_MODULES TABLE (Module Files)
-- ============================================
DROP POLICY IF EXISTS "Teachers can view own course modules" ON course_modules;
DROP POLICY IF EXISTS "Teachers can upload course modules" ON course_modules;
DROP POLICY IF EXISTS "Teachers can delete own course modules" ON course_modules;
DROP POLICY IF EXISTS "Students can view course modules in their classrooms" ON course_modules;

ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teachers can view own course modules"
  ON course_modules FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_modules.course_id
      AND courses.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can upload course modules"
  ON course_modules FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_modules.course_id
      AND courses.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can delete own course modules"
  ON course_modules FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_modules.course_id
      AND courses.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Students can view course modules in their classrooms"
  ON course_modules FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classroom_courses
      INNER JOIN classroom_students ON classroom_courses.classroom_id = classroom_students.classroom_id
      WHERE classroom_courses.course_id = course_modules.course_id
      AND classroom_students.student_id = auth.uid()
    )
  );

-- ============================================
-- 6. COURSE_ASSIGNMENTS TABLE (Assignment Files)
-- ============================================
DROP POLICY IF EXISTS "Teachers can view own course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Teachers can upload course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Teachers can delete own course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Students can view course assignments in their classrooms" ON course_assignments;

ALTER TABLE course_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teachers can view own course assignments"
  ON course_assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_assignments.course_id
      AND courses.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can upload course assignments"
  ON course_assignments FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_assignments.course_id
      AND courses.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can delete own course assignments"
  ON course_assignments FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_assignments.course_id
      AND courses.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Students can view course assignments in their classrooms"
  ON course_assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classroom_courses
      INNER JOIN classroom_students ON classroom_courses.classroom_id = classroom_students.classroom_id
      WHERE classroom_courses.course_id = course_assignments.course_id
      AND classroom_students.student_id = auth.uid()
    )
  );
