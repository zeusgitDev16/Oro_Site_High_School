-- ============================================
-- SUB-SUBJECT TREE RLS POLICIES
-- Date: 2025-11-28
-- Purpose: RLS policies for sub-subject management and student enrollments
-- Dependencies: ADD_SUB_SUBJECT_TYPES_AND_ENROLLMENT.sql and ADD_SUB_SUBJECT_RPC_FUNCTIONS.sql must be run first
-- Safe: YES (idempotent, no conflicts with existing policies)
-- ============================================

BEGIN;

-- ============================================
-- STEP 1: RLS POLICIES FOR student_subject_enrollments
-- ============================================

-- Drop existing policies if they exist (idempotent)
DROP POLICY IF EXISTS "Students can view own TLE enrollments" ON public.student_subject_enrollments;
DROP POLICY IF EXISTS "Teachers can view classroom TLE enrollments" ON public.student_subject_enrollments;
DROP POLICY IF EXISTS "Teachers can manage classroom TLE enrollments" ON public.student_subject_enrollments;
DROP POLICY IF EXISTS "Students can self-enroll in TLE" ON public.student_subject_enrollments;
DROP POLICY IF EXISTS "Admins can manage all TLE enrollments" ON public.student_subject_enrollments;

-- Policy 1: Students can view their own TLE enrollments
CREATE POLICY "Students can view own TLE enrollments"
  ON public.student_subject_enrollments
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Policy 2: Teachers can view TLE enrollments in their classrooms
CREATE POLICY "Teachers can view classroom TLE enrollments"
  ON public.student_subject_enrollments
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms c
      WHERE c.id = student_subject_enrollments.classroom_id
        AND (
          c.teacher_id = auth.uid()  -- Classroom owner
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = c.id
              AND ct.teacher_id = auth.uid()  -- Co-teacher
          )
        )
    )
    OR
    -- Subject teacher can view enrollments for their TLE sub-subject
    EXISTS (
      SELECT 1 FROM public.classroom_subjects cs
      WHERE cs.id = student_subject_enrollments.enrolled_subject_id
        AND cs.teacher_id = auth.uid()
    )
  );

-- Policy 3: Teachers can manage (INSERT/UPDATE) TLE enrollments in their classrooms
CREATE POLICY "Teachers can manage classroom TLE enrollments"
  ON public.student_subject_enrollments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms c
      WHERE c.id = student_subject_enrollments.classroom_id
        AND (
          c.teacher_id = auth.uid()  -- Classroom owner
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = c.id
              AND ct.teacher_id = auth.uid()  -- Co-teacher
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.classrooms c
      WHERE c.id = student_subject_enrollments.classroom_id
        AND (
          c.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = c.id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
  );

-- Policy 4: Students (grades 9-10) can self-enroll in TLE
CREATE POLICY "Students can self-enroll in TLE"
  ON public.student_subject_enrollments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    AND self_enrolled = true
    AND EXISTS (
      SELECT 1 FROM public.students s
      WHERE s.id = auth.uid()
        AND s.grade_level >= 9
        AND s.grade_level <= 10
    )
    AND EXISTS (
      SELECT 1 FROM public.classroom_students cs
      WHERE cs.student_id = auth.uid()
        AND cs.classroom_id = student_subject_enrollments.classroom_id
    )
  );

-- Policy 5: Admins can manage all TLE enrollments
CREATE POLICY "Admins can manage all TLE enrollments"
  ON public.student_subject_enrollments
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

RAISE NOTICE '✅ Created RLS policies for student_subject_enrollments table';

-- ============================================
-- STEP 2: ENHANCE can_manage_student_grade FOR SUB-SUBJECTS
-- ============================================

-- Update the existing can_manage_student_grade function to handle sub-subjects
-- This function already exists and supports subject_id, but we need to ensure
-- it handles parent-child relationships for sub-subjects

CREATE OR REPLACE FUNCTION public.can_manage_student_grade(
  p_classroom_id uuid,
  p_course_id bigint DEFAULT NULL,
  p_subject_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_parent_subject_id UUID;
BEGIN
  -- ============================================
  -- 1. ADMIN OVERRIDE
  -- ============================================
  IF public.is_admin() THEN
    RETURN true;
  END IF;

  -- ============================================
  -- 2. CLASSROOM TEACHER OR CO-TEACHER
  -- ============================================
  IF p_classroom_id IS NOT NULL AND EXISTS (
    SELECT 1
    FROM public.classrooms c
    WHERE c.id = p_classroom_id
      AND (
        c.teacher_id = auth.uid()
        OR EXISTS (
          SELECT 1
          FROM public.classroom_teachers ct
          WHERE ct.classroom_id = c.id
            AND ct.teacher_id = auth.uid()
        )
      )
  ) THEN
    RETURN true;
  END IF;

  -- ============================================
  -- 3. SUBJECT TEACHER (NEW SYSTEM)
  -- ============================================
  IF p_subject_id IS NOT NULL THEN
    -- Check if user is the subject teacher
    IF EXISTS (
      SELECT 1
      FROM public.classroom_subjects cs
      WHERE cs.id = p_subject_id
        AND cs.classroom_id = p_classroom_id
        AND cs.teacher_id = auth.uid()
        AND cs.is_active = true
    ) THEN
      RETURN true;
    END IF;

    -- NEW: Check if user is the PARENT subject teacher (for sub-subjects)
    -- Example: If grading Music (sub-subject), check if user is MAPEH teacher
    SELECT parent_subject_id INTO v_parent_subject_id
    FROM public.classroom_subjects
    WHERE id = p_subject_id;

    IF v_parent_subject_id IS NOT NULL THEN
      IF EXISTS (
        SELECT 1
        FROM public.classroom_subjects cs
        WHERE cs.id = v_parent_subject_id
          AND cs.classroom_id = p_classroom_id
          AND cs.teacher_id = auth.uid()
          AND cs.is_active = true
      ) THEN
        RETURN true;
      END IF;
    END IF;
  END IF;

  -- ============================================
  -- 4. COURSE TEACHER (OLD SYSTEM - BACKWARD COMPATIBILITY)
  -- ============================================
  IF p_course_id IS NOT NULL AND public.is_course_teacher(p_course_id, auth.uid()) THEN
    RETURN true;
  END IF;

  -- ============================================
  -- 5. GRADE LEVEL COORDINATOR
  -- ============================================
  IF EXISTS (
    SELECT 1
    FROM public.coordinator_assignments ca
    WHERE ca.teacher_id = auth.uid()
      AND ca.is_active = true
      AND (
        (
          p_classroom_id IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.classrooms c2
            WHERE c2.id = p_classroom_id
              AND c2.grade_level = ca.grade_level
          )
        )
        OR
        (
          p_classroom_id IS NULL
          AND p_course_id IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.courses co
            WHERE co.id = p_course_id
              AND co.grade_level = ca.grade_level
          )
        )
      )
  ) THEN
    RETURN true;
  END IF;

  -- ============================================
  -- 6. DEFAULT: NO ACCESS
  -- ============================================
  RETURN false;
END;
$$;

COMMENT ON FUNCTION public.can_manage_student_grade(uuid, bigint, uuid) IS
'ENHANCED: Determines if the current user can manage student grades for a given classroom/course/subject.
NOW SUPPORTS: Parent-child subject relationships (e.g., MAPEH teacher can manage Music/Arts/PE/Health grades).
Supports both OLD course system (course_id) and NEW classroom_subjects system (subject_id).
Parameters:
  - p_classroom_id: Required classroom UUID
  - p_course_id: Optional course ID (bigint) for backward compatibility
  - p_subject_id: Optional subject UUID for new system (supports sub-subjects)
Returns true if user is:
  1. Admin
  2. Classroom teacher or co-teacher
  3. Subject teacher (including parent subject teacher for sub-subjects)
  4. Course teacher (OLD)
  5. Grade level coordinator
Backward Compatible: YES - existing calls with 2 parameters still work.';

RAISE NOTICE '✅ Enhanced can_manage_student_grade function to support sub-subjects';

-- ============================================
-- STEP 3: ADDITIONAL POLICIES FOR classroom_subjects
-- ============================================

-- Drop existing policies if they exist (idempotent)
DROP POLICY IF EXISTS "Prevent deletion of MAPEH sub-subjects" ON public.classroom_subjects;
DROP POLICY IF EXISTS "Teachers can insert TLE sub-subjects" ON public.classroom_subjects;

-- Policy: Prevent deletion of MAPEH hardcoded sub-subjects
CREATE POLICY "Prevent deletion of MAPEH sub-subjects"
  ON public.classroom_subjects
  FOR DELETE
  TO authenticated
  USING (
    subject_type != 'mapeh_sub'  -- Cannot delete MAPEH sub-subjects
    OR public.is_admin()  -- Admins can override (for cleanup)
  );

-- Policy: Teachers can insert TLE sub-subjects in their classrooms
CREATE POLICY "Teachers can insert TLE sub-subjects"
  ON public.classroom_subjects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    subject_type = 'tle_sub'
    AND EXISTS (
      SELECT 1 FROM public.classrooms c
      WHERE c.id = classroom_subjects.classroom_id
        AND (
          c.teacher_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id = c.id
              AND ct.teacher_id = auth.uid()
          )
        )
    )
    OR public.is_admin()
  );

RAISE NOTICE '✅ Created additional RLS policies for classroom_subjects table';

COMMIT;

-- ============================================
-- RLS POLICIES STEP 3 COMPLETE
-- ============================================

RAISE NOTICE '✅✅✅ MIGRATION STEP 3 COMPLETE: RLS policies created successfully';
RAISE NOTICE '🎉 SUB-SUBJECT TREE ENHANCEMENT MIGRATION COMPLETE!';
RAISE NOTICE '';
RAISE NOTICE '📋 SUMMARY:';
RAISE NOTICE '  ✅ Added subject_type column to classroom_subjects';
RAISE NOTICE '  ✅ Added is_sub_subject_grade column to student_grades';
RAISE NOTICE '  ✅ Created student_subject_enrollments table';
RAISE NOTICE '  ✅ Created 6 RPC functions for sub-subject management';
RAISE NOTICE '  ✅ Created 7 RLS policies for security';
RAISE NOTICE '  ✅ Enhanced can_manage_student_grade for sub-subjects';
RAISE NOTICE '';
RAISE NOTICE '🚀 NEXT STEPS:';
RAISE NOTICE '  1. Update Dart models (ClassroomSubject, StudentGrade)';
RAISE NOTICE '  2. Update service layer (ClassroomSubjectService, DepEdGradeService)';
RAISE NOTICE '  3. Update UI components (classroom editor, gradebook, assignments)';
RAISE NOTICE '  4. Test MAPEH sub-subject creation and grading';
RAISE NOTICE '  5. Test TLE enrollment and grading';
