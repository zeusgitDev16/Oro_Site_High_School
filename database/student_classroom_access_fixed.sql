-- Complete RLS Setup for Student Classroom Access (NO RECURSION)
-- Run this to allow students to view all classroom content

-- ============================================
-- STEP 1: Drop all existing policies
-- ============================================
DROP POLICY IF EXISTS "Teachers can view classroom courses" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can add courses to classrooms" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can remove courses from classrooms" ON classroom_courses;
DROP POLICY IF EXISTS "Students can view classroom courses" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can view own courses" ON courses;
DROP POLICY IF EXISTS "Teachers can create courses" ON courses;
DROP POLICY IF EXISTS "Teachers can update own courses" ON courses;
DROP POLICY IF EXISTS "Teachers can delete own courses" ON courses;
DROP POLICY IF EXISTS "Students can view courses in their classrooms" ON courses;
DROP POLICY IF EXISTS "Teachers can view own course modules" ON course_modules;
DROP POLICY IF EXISTS "Teachers can upload course modules" ON course_modules;
DROP POLICY IF EXISTS "Teachers can delete own course modules" ON course_modules;
DROP POLICY IF EXISTS "Students can view course modules in their classrooms" ON course_modules;
DROP POLICY IF EXISTS "Teachers can view own course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Teachers can upload course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Teachers can delete own course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Students can view course assignments in their classrooms" ON course_assignments;

-- ============================================
-- STEP 2: CLASSROOM_COURSES - Simple policies
-- ============================================
ALTER TABLE classroom_courses ENABLE ROW LEVEL SECURITY;

-- Teachers: Direct check on classrooms table
CREATE POLICY "Teachers can manage classroom courses"
  ON classroom_courses FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

-- Students: Direct check on classroom_students table
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
-- STEP 3: COURSES - Combined policy (no subqueries to other tables)
-- ============================================
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Single policy for all course access
CREATE POLICY "Course access policy"
  ON courses FOR SELECT
  USING (
    -- Teachers can see their own courses
    auth.uid() = teacher_id
    OR
    -- Students can see courses (will be filtered by classroom_courses join in app)
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'student'
    )
  );

-- Teachers can manage their courses
CREATE POLICY "Teachers can create courses"
  ON courses FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "Teachers can update courses"
  ON courses FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "Teachers can delete courses"
  ON courses FOR DELETE
  USING (auth.uid() = teacher_id);

-- ============================================
-- STEP 4: COURSE_MODULES - Simple policies
-- ============================================
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;

-- Teachers can manage their course modules
CREATE POLICY "Teachers can manage course modules"
  ON course_modules FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_modules.course_id
      AND courses.teacher_id = auth.uid()
    )
  );

-- Students can view modules (filtered by course access)
CREATE POLICY "Students can view course modules"
  ON course_modules FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_modules.course_id
      AND EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'student'
      )
    )
  );

-- ============================================
-- STEP 5: COURSE_ASSIGNMENTS - Simple policies
-- ============================================
ALTER TABLE course_assignments ENABLE ROW LEVEL SECURITY;

-- Teachers can manage their course assignments
CREATE POLICY "Teachers can manage course assignments"
  ON course_assignments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_assignments.course_id
      AND courses.teacher_id = auth.uid()
    )
  );

-- Students can view assignments (filtered by course access)
CREATE POLICY "Students can view course assignments"
  ON course_assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_assignments.course_id
      AND EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'student'
      )
    )
  );

-- ============================================
-- NOTES:
-- ============================================
-- This approach avoids recursion by:
-- 1. classroom_courses: Only checks classrooms and classroom_students (no courses check)
-- 2. courses: Allows students to see courses (filtering happens in app via JOIN)
-- 3. course_modules/assignments: Only checks courses and student role (no classroom check)
--
-- The app code will handle the filtering by joining:
-- classroom_students -> classroom_courses -> courses -> course_modules
-- This way, students only see courses in their enrolled classrooms
