-- ============================================
-- ENHANCE can_manage_student_grade() FOR SUBJECT SUPPORT
-- Date: 2025-11-27
-- Purpose: Add subject_id support while maintaining backward compatibility
-- Backward Compatible: YES (adds optional parameter with DEFAULT NULL)
-- ============================================

BEGIN;

-- ============================================
-- ENHANCED FUNCTION: can_manage_student_grade
-- ============================================

CREATE OR REPLACE FUNCTION public.can_manage_student_grade(
  p_classroom_id uuid,
  p_course_id bigint DEFAULT NULL,
  p_subject_id uuid DEFAULT NULL  -- NEW parameter for classroom_subjects system
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON FUNCTION public.can_manage_student_grade(uuid, bigint, uuid) IS 
'Determines if the current user can manage student grades for a given classroom/course/subject.
Supports both OLD course system (course_id) and NEW classroom_subjects system (subject_id).
Parameters:
  - p_classroom_id: Required classroom UUID
  - p_course_id: Optional course ID (bigint) for backward compatibility
  - p_subject_id: Optional subject UUID for new system
Returns true if user is:
  1. Admin
  2. Classroom teacher or co-teacher
  3. Subject teacher (NEW)
  4. Course teacher (OLD)
  5. Grade level coordinator
Backward Compatible: YES - existing calls with 2 parameters still work.';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Test 1: Verify function exists with new signature
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname = 'can_manage_student_grade'
      AND p.pronargs = 3
  ) THEN
    RAISE EXCEPTION 'Function can_manage_student_grade with 3 parameters not found!';
  END IF;
  
  RAISE NOTICE '✅ Function can_manage_student_grade enhanced successfully';
END $$;

-- Test 2: Verify backward compatibility (2-parameter calls still work)
DO $$
BEGIN
  -- This should not raise an error
  PERFORM public.can_manage_student_grade(
    '00000000-0000-0000-0000-000000000000'::uuid,
    1::bigint
  );
  
  RAISE NOTICE '✅ Backward compatibility verified (2-parameter call works)';
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Backward compatibility broken: %', SQLERRM;
END $$;

-- Test 3: Verify new 3-parameter call works
DO $$
BEGIN
  -- This should not raise an error
  PERFORM public.can_manage_student_grade(
    '00000000-0000-0000-0000-000000000000'::uuid,
    NULL::bigint,
    '00000000-0000-0000-0000-000000000000'::uuid
  );
  
  RAISE NOTICE '✅ New 3-parameter call verified';
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'New 3-parameter call failed: %', SQLERRM;
END $$;

COMMIT;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================


