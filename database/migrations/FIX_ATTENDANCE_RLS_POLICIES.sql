-- =====================================================
-- MIGRATION: Fix Attendance RLS Policies for New System
-- PURPOSE: Update RLS policies to support classroom_id + subject_id
--          while maintaining backward compatibility with course_id
-- DATE: 2025-11-27
-- CRITICAL BUG FIX: Teachers cannot save attendance for new classrooms
-- =====================================================

-- Drop all existing attendance RLS policies
DROP POLICY IF EXISTS "attendance_select_own_or_admin" ON public.attendance;
DROP POLICY IF EXISTS "attendance_teachers_select_by_course" ON public.attendance;
DROP POLICY IF EXISTS "attendance_teachers_insert_by_course" ON public.attendance;
DROP POLICY IF EXISTS "attendance_teachers_update_by_course" ON public.attendance;
DROP POLICY IF EXISTS "attendance_teachers_delete_by_course" ON public.attendance;
DROP POLICY IF EXISTS "attendance_teachers_manage_by_classroom" ON public.attendance;
DROP POLICY IF EXISTS "attendance_insert_admin" ON public.attendance;
DROP POLICY IF EXISTS "attendance_update_admin" ON public.attendance;

-- =====================================================
-- POLICY #1: Students can view their own attendance
-- =====================================================
CREATE POLICY "attendance_students_select_own"
  ON public.attendance
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- =====================================================
-- POLICY #2: Teachers can SELECT attendance
-- Supports BOTH old system (course_id) AND new system (classroom_id + subject_id)
-- =====================================================
CREATE POLICY "attendance_teachers_select"
  ON public.attendance
  FOR SELECT
  TO authenticated
  USING (
    -- OLD SYSTEM: Teacher owns the course
    (
      course_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM courses c
        WHERE c.id = attendance.course_id
        AND c.teacher_id = auth.uid()
      )
    )
    OR
    -- OLD SYSTEM: Teacher is assigned to course via classroom_courses
    (
      course_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM classroom_courses cc
        JOIN classroom_teachers ct ON ct.classroom_id = cc.classroom_id
        WHERE cc.course_id = attendance.course_id
        AND ct.teacher_id = auth.uid()
      )
    )
    OR
    -- NEW SYSTEM: Teacher owns the classroom (advisory teacher)
    (
      classroom_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM classrooms cl
        WHERE cl.id = attendance.classroom_id
        AND cl.teacher_id = auth.uid()
      )
    )
    OR
    -- NEW SYSTEM: Teacher is assigned to classroom via classroom_teachers
    (
      classroom_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM classroom_teachers ct
        WHERE ct.classroom_id = attendance.classroom_id
        AND ct.teacher_id = auth.uid()
      )
    )
    OR
    -- NEW SYSTEM: Teacher owns the subject
    (
      subject_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM classroom_subjects cs
        WHERE cs.id = attendance.subject_id
        AND cs.teacher_id = auth.uid()
      )
    )
  );

-- =====================================================
-- POLICY #3: Teachers can INSERT attendance
-- =====================================================
CREATE POLICY "attendance_teachers_insert"
  ON public.attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- OLD SYSTEM: Teacher owns the course
    (
      course_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM courses c
        WHERE c.id = attendance.course_id
        AND c.teacher_id = auth.uid()
      )
    )
    OR
    -- OLD SYSTEM: Teacher is assigned to course via classroom_courses
    (
      course_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM classroom_courses cc
        JOIN classroom_teachers ct ON ct.classroom_id = cc.classroom_id
        WHERE cc.course_id = attendance.course_id
        AND ct.teacher_id = auth.uid()
      )
    )
    OR
    -- NEW SYSTEM: Teacher owns the classroom (advisory teacher)
    (
      classroom_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM classrooms cl
        WHERE cl.id = attendance.classroom_id
        AND cl.teacher_id = auth.uid()
      )
    )
    OR
    -- NEW SYSTEM: Teacher is assigned to classroom via classroom_teachers
    (
      classroom_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM classroom_teachers ct
        WHERE ct.classroom_id = attendance.classroom_id
        AND ct.teacher_id = auth.uid()
      )
    )
    OR
    -- NEW SYSTEM: Teacher owns the subject
    (
      subject_id IS NOT NULL AND
      EXISTS (
        SELECT 1 FROM classroom_subjects cs
        WHERE cs.id = attendance.subject_id
        AND cs.teacher_id = auth.uid()
      )
    )
  );

-- =====================================================
-- POLICY #4: Teachers can UPDATE attendance
-- =====================================================
CREATE POLICY "attendance_teachers_update"
  ON public.attendance
  FOR UPDATE
  TO authenticated
  USING (
    -- Same logic as SELECT
    (course_id IS NOT NULL AND EXISTS (SELECT 1 FROM courses c WHERE c.id = attendance.course_id AND c.teacher_id = auth.uid()))
    OR (course_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_courses cc JOIN classroom_teachers ct ON ct.classroom_id = cc.classroom_id WHERE cc.course_id = attendance.course_id AND ct.teacher_id = auth.uid()))
    OR (classroom_id IS NOT NULL AND EXISTS (SELECT 1 FROM classrooms cl WHERE cl.id = attendance.classroom_id AND cl.teacher_id = auth.uid()))
    OR (classroom_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_teachers ct WHERE ct.classroom_id = attendance.classroom_id AND ct.teacher_id = auth.uid()))
    OR (subject_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_subjects cs WHERE cs.id = attendance.subject_id AND cs.teacher_id = auth.uid()))
  )
  WITH CHECK (
    -- Same logic as INSERT
    (course_id IS NOT NULL AND EXISTS (SELECT 1 FROM courses c WHERE c.id = attendance.course_id AND c.teacher_id = auth.uid()))
    OR (course_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_courses cc JOIN classroom_teachers ct ON ct.classroom_id = cc.classroom_id WHERE cc.course_id = attendance.course_id AND ct.teacher_id = auth.uid()))
    OR (classroom_id IS NOT NULL AND EXISTS (SELECT 1 FROM classrooms cl WHERE cl.id = attendance.classroom_id AND cl.teacher_id = auth.uid()))
    OR (classroom_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_teachers ct WHERE ct.classroom_id = attendance.classroom_id AND ct.teacher_id = auth.uid()))
    OR (subject_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_subjects cs WHERE cs.id = attendance.subject_id AND cs.teacher_id = auth.uid()))
  );

-- =====================================================
-- POLICY #5: Teachers can DELETE attendance
-- =====================================================
CREATE POLICY "attendance_teachers_delete"
  ON public.attendance
  FOR DELETE
  TO authenticated
  USING (
    -- OLD SYSTEM: Teacher owns the course
    (course_id IS NOT NULL AND EXISTS (SELECT 1 FROM courses c WHERE c.id = attendance.course_id AND c.teacher_id = auth.uid()))
    OR (course_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_courses cc JOIN classroom_teachers ct ON ct.classroom_id = cc.classroom_id WHERE cc.course_id = attendance.course_id AND ct.teacher_id = auth.uid()))
    -- NEW SYSTEM: Teacher owns the classroom (advisory teacher)
    OR (classroom_id IS NOT NULL AND EXISTS (SELECT 1 FROM classrooms cl WHERE cl.id = attendance.classroom_id AND cl.teacher_id = auth.uid()))
    OR (classroom_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_teachers ct WHERE ct.classroom_id = attendance.classroom_id AND ct.teacher_id = auth.uid()))
    OR (subject_id IS NOT NULL AND EXISTS (SELECT 1 FROM classroom_subjects cs WHERE cs.id = attendance.subject_id AND cs.teacher_id = auth.uid()))
  );

-- =====================================================
-- POLICY #6: Parents can view their children's attendance
-- =====================================================
CREATE POLICY "attendance_parents_select"
  ON public.attendance
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM parent_student_links psl
      WHERE psl.student_id = attendance.student_id
      AND psl.parent_id = auth.uid()
    )
  );

-- =====================================================
-- POLICY #7: Admins can SELECT all attendance
-- =====================================================
CREATE POLICY "attendance_admins_select"
  ON public.attendance
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND (p.role = 'admin' OR p.role ILIKE '%admin%')
    )
  );

-- =====================================================
-- POLICY #8: Admins can INSERT attendance
-- =====================================================
CREATE POLICY "attendance_admins_insert"
  ON public.attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND (p.role = 'admin' OR p.role ILIKE '%admin%')
    )
  );

-- =====================================================
-- POLICY #9: Admins can UPDATE attendance
-- =====================================================
CREATE POLICY "attendance_admins_update"
  ON public.attendance
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND (p.role = 'admin' OR p.role ILIKE '%admin%')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND (p.role = 'admin' OR p.role ILIKE '%admin%')
    )
  );

-- =====================================================
-- POLICY #10: Admins can DELETE attendance
-- =====================================================
CREATE POLICY "attendance_admins_delete"
  ON public.attendance
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND (p.role = 'admin' OR p.role ILIKE '%admin%')
    )
  );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify all policies are created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd
FROM pg_policies
WHERE tablename = 'attendance'
ORDER BY policyname;

-- Expected output: 10 policies
-- 1. attendance_admins_delete
-- 2. attendance_admins_insert
-- 3. attendance_admins_select
-- 4. attendance_admins_update
-- 5. attendance_parents_select
-- 6. attendance_students_select_own
-- 7. attendance_teachers_delete
-- 8. attendance_teachers_insert
-- 9. attendance_teachers_select
-- 10. attendance_teachers_update

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- ✅ All RLS policies updated to support new system
-- ✅ Backward compatibility maintained for old system
-- ✅ Teachers can now save attendance for new classrooms
-- ✅ Students can view their own attendance
-- ✅ Parents can view children's attendance
-- ✅ Admins have full access
-- =====================================================

