-- ============================================
-- SUB-SUBJECT TREE RPC FUNCTIONS
-- Date: 2025-11-28
-- Purpose: RPC functions for MAPEH/TLE sub-subject management and grading
-- Dependencies: ADD_SUB_SUBJECT_TYPES_AND_ENROLLMENT.sql must be run first
-- ============================================

BEGIN;

-- ============================================
-- FUNCTION 1: Initialize MAPEH Sub-Subjects
-- ============================================

CREATE OR REPLACE FUNCTION public.initialize_mapeh_sub_subjects(
  p_classroom_id UUID,
  p_mapeh_subject_id UUID,
  p_created_by UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sub_subjects TEXT[] := ARRAY['Music', 'Arts', 'Physical Education (PE)', 'Health'];
  v_sub_name TEXT;
BEGIN
  -- Verify parent subject is MAPEH
  IF NOT EXISTS (
    SELECT 1 FROM public.classroom_subjects
    WHERE id = p_mapeh_subject_id
      AND classroom_id = p_classroom_id
      AND subject_type = 'mapeh_parent'
  ) THEN
    RAISE EXCEPTION 'Subject % is not a MAPEH parent subject', p_mapeh_subject_id;
  END IF;

  -- Insert hardcoded MAPEH sub-subjects
  FOREACH v_sub_name IN ARRAY v_sub_subjects
  LOOP
    INSERT INTO public.classroom_subjects (
      classroom_id,
      subject_name,
      subject_type,
      parent_subject_id,
      is_active,
      created_by,
      created_at,
      updated_at
    ) VALUES (
      p_classroom_id,
      v_sub_name,
      'mapeh_sub',
      p_mapeh_subject_id,
      true,
      p_created_by,
      NOW(),
      NOW()
    )
    ON CONFLICT DO NOTHING;  -- Prevent duplicates if already exists
  END LOOP;

  RAISE NOTICE '✅ Initialized MAPEH sub-subjects for classroom %', p_classroom_id;
END;
$$;

COMMENT ON FUNCTION public.initialize_mapeh_sub_subjects(UUID, UUID, UUID) IS
'Auto-creates the 4 hardcoded MAPEH sub-subjects (Music, Arts, PE, Health) when MAPEH is added to a classroom.';

-- ============================================
-- FUNCTION 2: Compute Parent Subject Grade (MAPEH/TLE)
-- ============================================

CREATE OR REPLACE FUNCTION public.compute_parent_subject_grade(
  p_student_id UUID,
  p_classroom_id UUID,
  p_parent_subject_id UUID,
  p_quarter INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_avg_grade NUMERIC;
  v_sub_count INT;
BEGIN
  -- Validate quarter
  IF p_quarter < 1 OR p_quarter > 4 THEN
    RAISE EXCEPTION 'Invalid quarter: %. Must be 1-4', p_quarter;
  END IF;

  -- Get average of all sub-subject transmuted grades
  SELECT 
    AVG(sg.transmuted_grade),
    COUNT(*)
  INTO v_avg_grade, v_sub_count
  FROM public.student_grades sg
  JOIN public.classroom_subjects cs ON sg.subject_id = cs.id
  WHERE sg.student_id = p_student_id
    AND sg.classroom_id = p_classroom_id
    AND sg.quarter = p_quarter
    AND sg.is_sub_subject_grade = true
    AND cs.parent_subject_id = p_parent_subject_id
    AND cs.is_active = true;
  
  -- Return rounded average (or 0 if no sub-subject grades found)
  IF v_sub_count = 0 THEN
    RAISE NOTICE 'No sub-subject grades found for parent subject %', p_parent_subject_id;
    RETURN 0;
  END IF;

  RETURN COALESCE(ROUND(v_avg_grade, 0), 0);
END;
$$;

COMMENT ON FUNCTION public.compute_parent_subject_grade(UUID, UUID, UUID, INT) IS
'Computes the parent subject grade (MAPEH or TLE) as the average of all sub-subject transmuted grades for a given student and quarter.';

-- ============================================
-- FUNCTION 3: Enroll Student in TLE Sub-Subject (Teacher)
-- ============================================

CREATE OR REPLACE FUNCTION public.enroll_student_in_tle(
  p_student_id UUID,
  p_classroom_id UUID,
  p_tle_parent_id UUID,
  p_tle_sub_id UUID,
  p_enrolled_by UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verify parent subject is TLE
  IF NOT EXISTS (
    SELECT 1 FROM public.classroom_subjects
    WHERE id = p_tle_parent_id
      AND classroom_id = p_classroom_id
      AND subject_type = 'tle_parent'
  ) THEN
    RAISE EXCEPTION 'Subject % is not a TLE parent subject', p_tle_parent_id;
  END IF;

  -- Verify sub-subject is TLE sub and belongs to parent
  IF NOT EXISTS (
    SELECT 1 FROM public.classroom_subjects
    WHERE id = p_tle_sub_id
      AND classroom_id = p_classroom_id
      AND subject_type = 'tle_sub'
      AND parent_subject_id = p_tle_parent_id
  ) THEN
    RAISE EXCEPTION 'Subject % is not a valid TLE sub-subject under parent %', p_tle_sub_id, p_tle_parent_id;
  END IF;

  -- Verify student is enrolled in classroom
  IF NOT EXISTS (
    SELECT 1 FROM public.classroom_students
    WHERE student_id = p_student_id
      AND classroom_id = p_classroom_id
  ) THEN
    RAISE EXCEPTION 'Student % is not enrolled in classroom %', p_student_id, p_classroom_id;
  END IF;

  -- Insert or update enrollment
  INSERT INTO public.student_subject_enrollments (
    student_id, classroom_id, parent_subject_id, 
    enrolled_subject_id, enrolled_by, self_enrolled
  ) VALUES (
    p_student_id, p_classroom_id, p_tle_parent_id,
    p_tle_sub_id, p_enrolled_by, false
  )
  ON CONFLICT (student_id, classroom_id, parent_subject_id)
  DO UPDATE SET 
    enrolled_subject_id = p_tle_sub_id,
    enrolled_by = p_enrolled_by,
    enrolled_at = NOW(),
    updated_at = NOW();

  RAISE NOTICE '✅ Enrolled student % in TLE sub-subject %', p_student_id, p_tle_sub_id;
END;
$$;

COMMENT ON FUNCTION public.enroll_student_in_tle(UUID, UUID, UUID, UUID, UUID) IS
'Enrolls a student in a specific TLE sub-subject. Used by teachers for Grades 7-8.';

-- ============================================
-- FUNCTION 4: Self-Enroll in TLE Sub-Subject (Student)
-- ============================================

CREATE OR REPLACE FUNCTION public.self_enroll_in_tle(
  p_student_id UUID,
  p_classroom_id UUID,
  p_tle_parent_id UUID,
  p_tle_sub_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_grade_level INT;
BEGIN
  -- Get student's grade level
  SELECT s.grade_level INTO v_grade_level
  FROM public.students s
  WHERE s.id = p_student_id;

  -- Check if student is in grades 9-10 (allowed to self-enroll)
  IF v_grade_level IS NULL THEN
    RAISE EXCEPTION 'Student % not found', p_student_id;
  END IF;

  IF v_grade_level < 9 OR v_grade_level > 10 THEN
    RAISE EXCEPTION 'Only students in grades 9-10 can self-enroll in TLE. Student is in grade %', v_grade_level;
  END IF;

  -- Verify parent subject is TLE
  IF NOT EXISTS (
    SELECT 1 FROM public.classroom_subjects
    WHERE id = p_tle_parent_id
      AND classroom_id = p_classroom_id
      AND subject_type = 'tle_parent'
  ) THEN
    RAISE EXCEPTION 'Subject % is not a TLE parent subject', p_tle_parent_id;
  END IF;

  -- Verify sub-subject is TLE sub and belongs to parent
  IF NOT EXISTS (
    SELECT 1 FROM public.classroom_subjects
    WHERE id = p_tle_sub_id
      AND classroom_id = p_classroom_id
      AND subject_type = 'tle_sub'
      AND parent_subject_id = p_tle_parent_id
  ) THEN
    RAISE EXCEPTION 'Subject % is not a valid TLE sub-subject under parent %', p_tle_sub_id, p_tle_parent_id;
  END IF;

  -- Verify student is enrolled in classroom
  IF NOT EXISTS (
    SELECT 1 FROM public.classroom_students
    WHERE student_id = p_student_id
      AND classroom_id = p_classroom_id
  ) THEN
    RAISE EXCEPTION 'Student % is not enrolled in classroom %', p_student_id, p_classroom_id;
  END IF;

  -- Insert or update enrollment
  INSERT INTO public.student_subject_enrollments (
    student_id, classroom_id, parent_subject_id,
    enrolled_subject_id, self_enrolled
  ) VALUES (
    p_student_id, p_classroom_id, p_tle_parent_id,
    p_tle_sub_id, true
  )
  ON CONFLICT (student_id, classroom_id, parent_subject_id)
  DO UPDATE SET
    enrolled_subject_id = p_tle_sub_id,
    self_enrolled = true,
    enrolled_at = NOW(),
    updated_at = NOW();

  RAISE NOTICE '✅ Student % self-enrolled in TLE sub-subject %', p_student_id, p_tle_sub_id;
END;
$$;

COMMENT ON FUNCTION public.self_enroll_in_tle(UUID, UUID, UUID, UUID) IS
'Allows students in grades 9-10 to self-enroll in a specific TLE sub-subject.';

-- ============================================
-- FUNCTION 5: Get Student's Enrolled TLE Sub-Subject
-- ============================================

CREATE OR REPLACE FUNCTION public.get_student_tle_enrollment(
  p_student_id UUID,
  p_classroom_id UUID,
  p_tle_parent_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_enrolled_subject_id UUID;
BEGIN
  SELECT enrolled_subject_id INTO v_enrolled_subject_id
  FROM public.student_subject_enrollments
  WHERE student_id = p_student_id
    AND classroom_id = p_classroom_id
    AND parent_subject_id = p_tle_parent_id
    AND is_active = true;

  RETURN v_enrolled_subject_id;
END;
$$;

COMMENT ON FUNCTION public.get_student_tle_enrollment(UUID, UUID, UUID) IS
'Returns the TLE sub-subject ID that a student is enrolled in, or NULL if not enrolled.';

-- ============================================
-- FUNCTION 6: Bulk Enroll Students in TLE
-- ============================================

CREATE OR REPLACE FUNCTION public.bulk_enroll_students_in_tle(
  p_enrollments JSONB,  -- Array of {student_id, tle_sub_id}
  p_classroom_id UUID,
  p_tle_parent_id UUID,
  p_enrolled_by UUID
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_enrollment JSONB;
  v_count INT := 0;
BEGIN
  -- Loop through enrollments
  FOR v_enrollment IN SELECT * FROM jsonb_array_elements(p_enrollments)
  LOOP
    -- Call enroll function for each student
    PERFORM public.enroll_student_in_tle(
      (v_enrollment->>'student_id')::UUID,
      p_classroom_id,
      p_tle_parent_id,
      (v_enrollment->>'tle_sub_id')::UUID,
      p_enrolled_by
    );

    v_count := v_count + 1;
  END LOOP;

  RAISE NOTICE '✅ Bulk enrolled % students in TLE sub-subjects', v_count;
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.bulk_enroll_students_in_tle(JSONB, UUID, UUID, UUID) IS
'Bulk enrolls multiple students in TLE sub-subjects. Expects JSONB array: [{student_id, tle_sub_id}, ...]';

COMMIT;

-- ============================================
-- RPC FUNCTIONS STEP 2 COMPLETE
-- ============================================

RAISE NOTICE '✅✅✅ MIGRATION STEP 2 COMPLETE: RPC functions created successfully';

