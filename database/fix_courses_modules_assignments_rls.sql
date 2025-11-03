-- fix_courses_modules_assignments_rls.sql
-- Purpose: Establish role-based RLS policies for course management system
--
-- Permission Model:
-- - ADMINS: Full CRUD operations on all tables (courses, course_modules, course_assignments)
-- - TEACHERS: Read-only access (SELECT) - can view, access, and download
-- - STUDENTS: Read-only access (SELECT) - can view, access, and download
--
-- Tables involved:
--  - courses (id, teacher_id, is_active, ...)
--  - course_modules (id, course_id, ...)
--  - course_assignments (id, course_id, ...)
--  - admins (id, is_active) - for admin role checking
--  - teachers (id, is_active) - for teacher role checking
--  - students (id, is_active) - for student role checking

-- ============================================================
-- STEP 1: DROP ALL EXISTING POLICIES
-- ============================================================

-- Drop all existing COURSES policies
DROP POLICY IF EXISTS "authenticated_can_view_courses" ON courses;
DROP POLICY IF EXISTS "courses_select_active" ON courses;
DROP POLICY IF EXISTS "teachers_can_insert_courses" ON courses;
DROP POLICY IF EXISTS "teachers_can_update_courses" ON courses;
DROP POLICY IF EXISTS "teachers_can_delete_courses" ON courses;
DROP POLICY IF EXISTS "Admins can manage all courses" ON courses;
DROP POLICY IF EXISTS "Teachers can view their courses" ON courses;
DROP POLICY IF EXISTS "Students can view enrolled courses" ON courses;

-- Drop all existing COURSE_MODULES policies
DROP POLICY IF EXISTS "course_modules_select_all" ON course_modules;
DROP POLICY IF EXISTS "course_modules_insert_authenticated" ON course_modules;
DROP POLICY IF EXISTS "course_modules_delete_authenticated" ON course_modules;
DROP POLICY IF EXISTS "course_modules_insert_by_teachers" ON course_modules;
DROP POLICY IF EXISTS "course_modules_update_by_teachers" ON course_modules;
DROP POLICY IF EXISTS "course_modules_delete_by_teachers" ON course_modules;
DROP POLICY IF EXISTS "teachers_can_manage_modules" ON course_modules;
DROP POLICY IF EXISTS "authenticated_can_view_modules" ON course_modules;

-- Drop all existing COURSE_ASSIGNMENTS policies
DROP POLICY IF EXISTS "authenticated_can_view_assignments" ON course_assignments;
DROP POLICY IF EXISTS "course_assignments_select_all" ON course_assignments;
DROP POLICY IF EXISTS "course_assignments_insert_authenticated" ON course_assignments;
DROP POLICY IF EXISTS "course_assignments_delete_authenticated" ON course_assignments;
DROP POLICY IF EXISTS "course_assignments_insert_by_teachers" ON course_assignments;
DROP POLICY IF EXISTS "course_assignments_update_by_teachers" ON course_assignments;
DROP POLICY IF EXISTS "course_assignments_delete_by_teachers" ON course_assignments;
DROP POLICY IF EXISTS "teachers_can_manage_assignments" ON course_assignments;
DROP POLICY IF EXISTS "Admins can manage assignments" ON course_assignments;
DROP POLICY IF EXISTS "Teachers can view own assignments" ON course_assignments;

-- ============================================================
-- STEP 2: CREATE NEW COURSES POLICIES
-- ============================================================

-- ADMINS: Full CRUD on courses
CREATE POLICY "admins_full_access_courses"
ON courses FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admins 
    WHERE id = auth.uid() AND is_active = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admins 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- TEACHERS: Read-only access to courses
CREATE POLICY "teachers_read_courses"
ON courses FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM teachers 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- STUDENTS: Read-only access to courses
CREATE POLICY "students_read_courses"
ON courses FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM students 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- ============================================================
-- STEP 3: CREATE NEW COURSE_MODULES POLICIES
-- ============================================================

-- ADMINS: Full CRUD on course_modules
CREATE POLICY "admins_full_access_modules"
ON course_modules FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admins 
    WHERE id = auth.uid() AND is_active = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admins 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- TEACHERS: Read-only access to course_modules
CREATE POLICY "teachers_read_modules"
ON course_modules FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM teachers 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- STUDENTS: Read-only access to course_modules
CREATE POLICY "students_read_modules"
ON course_modules FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM students 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- ============================================================
-- STEP 4: CREATE NEW COURSE_ASSIGNMENTS POLICIES
-- ============================================================

-- ADMINS: Full CRUD on course_assignments
CREATE POLICY "admins_full_access_assignments"
ON course_assignments FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admins 
    WHERE id = auth.uid() AND is_active = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admins 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- TEACHERS: Read-only access to course_assignments
CREATE POLICY "teachers_read_assignments"
ON course_assignments FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM teachers 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- STUDENTS: Read-only access to course_assignments
CREATE POLICY "students_read_assignments"
ON course_assignments FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM students 
    WHERE id = auth.uid() AND is_active = true
  )
);

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
-- After running this script, verify the policies are correct:
--
-- SELECT schemaname, tablename, policyname, cmd, roles, qual, with_check
-- FROM pg_policies
-- WHERE tablename IN ('courses', 'course_modules', 'course_assignments')
-- ORDER BY tablename, cmd, policyname;
--
-- Expected result:
-- - 3 policies per table (admins_full_access, teachers_read, students_read)
-- - Admins have ALL command
-- - Teachers and Students have SELECT command only

-- End of script
