-- CLEANUP: Remove ALL existing policies and create clean ones
-- This fixes the infinite recursion by removing conflicting policies

-- ============================================
-- STEP 1: Drop ALL existing policies on courses
-- ============================================
DROP POLICY IF EXISTS "Admins can manage courses" ON courses;
DROP POLICY IF EXISTS "Allow authenticated users to view courses" ON courses;
DROP POLICY IF EXISTS "Anyone can view active courses" ON courses;
DROP POLICY IF EXISTS "courses_all" ON courses;
DROP POLICY IF EXISTS "courses_delete_authenticated" ON courses;
DROP POLICY IF EXISTS "courses_insert_authenticated" ON courses;
DROP POLICY IF EXISTS "courses_select_active" ON courses;
DROP POLICY IF EXISTS "courses_update_authenticated" ON courses;
DROP POLICY IF EXISTS "Teachers can manage own courses" ON courses;
DROP POLICY IF EXISTS "Teachers can view assigned courses" ON courses;
DROP POLICY IF EXISTS "Course access policy" ON courses;
DROP POLICY IF EXISTS "Teachers can create courses" ON courses;
DROP POLICY IF EXISTS "Teachers can update courses" ON courses;
DROP POLICY IF EXISTS "Teachers can delete courses" ON courses;

-- ============================================
-- STEP 2: Drop ALL existing policies on classroom_courses
-- ============================================
DROP POLICY IF EXISTS "Teachers can manage classroom courses" ON classroom_courses;
DROP POLICY IF EXISTS "Students can view classroom courses" ON classroom_courses;
DROP POLICY IF EXISTS "Allow authenticated users to view classroom courses" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can view classroom courses" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can add courses to classrooms" ON classroom_courses;
DROP POLICY IF EXISTS "Teachers can remove courses from classrooms" ON classroom_courses;

-- ============================================
-- STEP 3: Drop ALL existing policies on course_modules
-- ============================================
DROP POLICY IF EXISTS "Teachers can manage course modules" ON course_modules;
DROP POLICY IF EXISTS "Students can view course modules" ON course_modules;
DROP POLICY IF EXISTS "Allow authenticated users to view modules" ON course_modules;
DROP POLICY IF EXISTS "Teachers can view own course modules" ON course_modules;
DROP POLICY IF EXISTS "Teachers can upload course modules" ON course_modules;
DROP POLICY IF EXISTS "Teachers can delete own course modules" ON course_modules;

-- ============================================
-- STEP 4: Drop ALL existing policies on course_assignments
-- ============================================
DROP POLICY IF EXISTS "Teachers can manage course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Students can view course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Allow authenticated users to view assignments" ON course_assignments;
DROP POLICY IF EXISTS "Teachers can view own course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Teachers can upload course assignments" ON course_assignments;
DROP POLICY IF EXISTS "Teachers can delete own course assignments" ON course_assignments;

-- ============================================
-- STEP 5: Create SIMPLE, NON-CONFLICTING policies
-- ============================================

-- COURSES TABLE
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Single SELECT policy for all authenticated users
CREATE POLICY "authenticated_can_view_courses"
  ON courses FOR SELECT
  TO authenticated
  USING (true);

-- Teachers can INSERT their own courses
CREATE POLICY "teachers_can_insert_courses"
  ON courses FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = teacher_id);

-- Teachers can UPDATE their own courses
CREATE POLICY "teachers_can_update_courses"
  ON courses FOR UPDATE
  TO authenticated
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

-- Teachers can DELETE their own courses
CREATE POLICY "teachers_can_delete_courses"
  ON courses FOR DELETE
  TO authenticated
  USING (auth.uid() = teacher_id);

-- CLASSROOM_COURSES TABLE
ALTER TABLE classroom_courses ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view
CREATE POLICY "authenticated_can_view_classroom_courses"
  ON classroom_courses FOR SELECT
  TO authenticated
  USING (true);

-- Teachers can manage (INSERT/DELETE) their classroom courses
CREATE POLICY "teachers_can_manage_classroom_courses"
  ON classroom_courses FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM classrooms
      WHERE classrooms.id = classroom_courses.classroom_id
      AND classrooms.teacher_id = auth.uid()
    )
  );

-- COURSE_MODULES TABLE
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view
CREATE POLICY "authenticated_can_view_modules"
  ON course_modules FOR SELECT
  TO authenticated
  USING (true);

-- Teachers can manage their course modules
CREATE POLICY "teachers_can_manage_modules"
  ON course_modules FOR ALL
  TO authenticated
  USING (
    course_id IN (
      SELECT id FROM courses WHERE teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    course_id IN (
      SELECT id FROM courses WHERE teacher_id = auth.uid()
    )
  );

-- COURSE_ASSIGNMENTS TABLE
ALTER TABLE course_assignments ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view
CREATE POLICY "authenticated_can_view_assignments"
  ON course_assignments FOR SELECT
  TO authenticated
  USING (true);

-- Teachers can manage their course assignments
CREATE POLICY "teachers_can_manage_assignments"
  ON course_assignments FOR ALL
  TO authenticated
  USING (
    course_id IN (
      SELECT id FROM courses WHERE teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    course_id IN (
      SELECT id FROM courses WHERE teacher_id = auth.uid()
    )
  );

-- ============================================
-- VERIFICATION
-- ============================================
-- After running this, you should have:
-- - courses: 4 policies (1 SELECT, 1 INSERT, 1 UPDATE, 1 DELETE)
-- - classroom_courses: 2 policies (1 SELECT, 1 ALL for teachers)
-- - course_modules: 2 policies (1 SELECT, 1 ALL for teachers)
-- - course_assignments: 2 policies (1 SELECT, 1 ALL for teachers)
