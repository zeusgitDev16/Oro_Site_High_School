-- ============================================================================
-- PHASE 7 ENHANCEMENTS: RLS POLICIES AND UNIQUE CONSTRAINT
-- ============================================================================
-- Date: 2025-11-27
-- Purpose: Enhance RLS policies to pass subject_id and add UNIQUE constraint for NEW system
-- 
-- ENHANCEMENTS:
-- 1. Update RLS policies to pass subject_id to can_manage_student_grade()
-- 2. Add UNIQUE constraint for NEW system (student_id, classroom_id, subject_id, quarter)
--
-- BACKWARD COMPATIBILITY: ✅ MAINTAINED
-- - OLD system continues to work (course_id)
-- - NEW system enhanced (subject_id)
-- - No breaking changes
-- ============================================================================

-- ============================================================================
-- ENHANCEMENT 1: UPDATE RLS POLICIES TO PASS SUBJECT_ID
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS student_grades_teacher_select ON public.student_grades;
DROP POLICY IF EXISTS student_grades_teacher_update ON public.student_grades;

-- Recreate SELECT policy with subject_id parameter
CREATE POLICY student_grades_teacher_select ON public.student_grades
  FOR SELECT
  USING (
    public.can_manage_student_grade(
      classroom_id,
      course_id,
      subject_id  -- NEW: Pass subject_id to function
    )
  );

-- Recreate UPDATE policy with subject_id parameter
CREATE POLICY student_grades_teacher_update ON public.student_grades
  FOR UPDATE
  USING (
    public.can_manage_student_grade(
      classroom_id,
      course_id,
      subject_id  -- NEW: Pass subject_id to function
    )
  );

-- Note: INSERT policy doesn't need update as it uses WITH CHECK clause
-- which will automatically use the enhanced function

COMMENT ON POLICY student_grades_teacher_select ON public.student_grades IS
  'Teachers can view grades they manage. Enhanced to support both course_id (OLD) and subject_id (NEW) systems.';

COMMENT ON POLICY student_grades_teacher_update ON public.student_grades IS
  'Teachers can update grades they manage. Enhanced to support both course_id (OLD) and subject_id (NEW) systems.';

-- ============================================================================
-- ENHANCEMENT 2: ADD UNIQUE CONSTRAINT FOR NEW SYSTEM
-- ============================================================================

-- Add UNIQUE constraint for NEW system
-- This prevents duplicate grades for same student/classroom/subject/quarter
ALTER TABLE public.student_grades
ADD CONSTRAINT student_grades_student_id_classroom_id_subject_id_quarter_key
UNIQUE (student_id, classroom_id, subject_id, quarter);

COMMENT ON CONSTRAINT student_grades_student_id_classroom_id_subject_id_quarter_key ON public.student_grades IS
  'Prevents duplicate grades for same student/classroom/subject/quarter in NEW system. Complements existing constraint for OLD system (course_id).';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'student_grades'
  AND policyname IN ('student_grades_teacher_select', 'student_grades_teacher_update')
ORDER BY policyname;

-- Verify UNIQUE constraints
SELECT
  conname,
  contype,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'student_grades'::regclass
  AND contype = 'u'
ORDER BY conname;

-- Verify can_manage_student_grade function signatures
SELECT
  proname,
  pronargs,
  pg_get_function_arguments(oid) as args
FROM pg_proc
WHERE proname = 'can_manage_student_grade'
ORDER BY pronargs;

-- ============================================================================
-- ROLLBACK SCRIPT (IF NEEDED)
-- ============================================================================

-- To rollback Enhancement 1 (RLS policies):
-- DROP POLICY IF EXISTS student_grades_teacher_select ON public.student_grades;
-- DROP POLICY IF EXISTS student_grades_teacher_update ON public.student_grades;
-- 
-- CREATE POLICY student_grades_teacher_select ON public.student_grades
--   FOR SELECT
--   USING (public.can_manage_student_grade(classroom_id, course_id));
-- 
-- CREATE POLICY student_grades_teacher_update ON public.student_grades
--   FOR UPDATE
--   USING (public.can_manage_student_grade(classroom_id, course_id));

-- To rollback Enhancement 2 (UNIQUE constraint):
-- ALTER TABLE public.student_grades
-- DROP CONSTRAINT IF EXISTS student_grades_student_id_classroom_id_subject_id_quarter_key;

-- ============================================================================
-- TESTING SCENARIOS
-- ============================================================================

-- Test 1: OLD system - Teacher manages grade with course_id
-- Expected: RLS passes (classroom_id, course_id, NULL) to function
-- Function checks: Course teacher permission
-- Result: Should work as before

-- Test 2: NEW system - Teacher manages grade with subject_id
-- Expected: RLS passes (classroom_id, NULL, subject_id) to function
-- Function checks: Subject teacher permission
-- Result: Should work correctly now (enhancement!)

-- Test 3: Duplicate grade prevention (OLD system)
-- Expected: Existing constraint prevents duplicate
-- Constraint: (student_id, classroom_id, course_id, quarter)
-- Result: Should work as before

-- Test 4: Duplicate grade prevention (NEW system)
-- Expected: New constraint prevents duplicate
-- Constraint: (student_id, classroom_id, subject_id, quarter)
-- Result: Should work correctly now (enhancement!)

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary:
-- ✅ Enhancement 1: RLS policies updated to pass subject_id
-- ✅ Enhancement 2: UNIQUE constraint added for NEW system
-- ✅ Backward compatibility maintained
-- ✅ No breaking changes
-- ✅ Ready for testing

SELECT 'PHASE 7 ENHANCEMENTS APPLIED SUCCESSFULLY!' as status;

