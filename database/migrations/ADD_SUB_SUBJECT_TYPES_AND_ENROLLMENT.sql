-- ============================================
-- SUB-SUBJECT TREE ENHANCEMENT: MAPEH & TLE
-- Date: 2025-11-28
-- Purpose: Add sub-subject types (MAPEH hardcoded, TLE free-form) with student enrollment
-- Backward Compatible: YES (all columns nullable with defaults)
-- Safe: YES (idempotent, no data loss, no RLS conflicts)
-- ============================================

BEGIN;

-- ============================================
-- STEP 1: ADD COLUMNS TO classroom_subjects
-- ============================================

-- Add subject_type column to distinguish between different subject behaviors
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'classroom_subjects'
      AND column_name = 'subject_type'
  ) THEN
    ALTER TABLE public.classroom_subjects
      ADD COLUMN subject_type TEXT DEFAULT 'standard'
      CHECK (subject_type IN ('standard', 'mapeh_parent', 'mapeh_sub', 'tle_parent', 'tle_sub'));
    
    RAISE NOTICE '✅ Added subject_type column to classroom_subjects';
  ELSE
    RAISE NOTICE '⚠️ subject_type column already exists in classroom_subjects';
  END IF;
END $$;

-- Add index for subject_type for performance
CREATE INDEX IF NOT EXISTS idx_classroom_subjects_subject_type 
  ON public.classroom_subjects(subject_type);

-- Add index for parent_subject_id for performance (if not exists)
CREATE INDEX IF NOT EXISTS idx_classroom_subjects_parent_subject_id 
  ON public.classroom_subjects(parent_subject_id);

-- ============================================
-- STEP 2: ADD COLUMNS TO student_grades
-- ============================================

-- Add subject_id column if it doesn't exist (for NEW system support)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'student_grades'
      AND column_name = 'subject_id'
  ) THEN
    ALTER TABLE public.student_grades
      ADD COLUMN subject_id UUID REFERENCES public.classroom_subjects(id) ON DELETE CASCADE;
    
    CREATE INDEX idx_student_grades_subject_id ON public.student_grades(subject_id);
    
    RAISE NOTICE '✅ Added subject_id column to student_grades';
  ELSE
    RAISE NOTICE '⚠️ subject_id column already exists in student_grades';
  END IF;
END $$;

-- Add is_sub_subject_grade column to distinguish sub-subject grades from parent grades
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'student_grades'
      AND column_name = 'is_sub_subject_grade'
  ) THEN
    ALTER TABLE public.student_grades
      ADD COLUMN is_sub_subject_grade BOOLEAN DEFAULT false;
    
    CREATE INDEX idx_student_grades_is_sub_subject ON public.student_grades(is_sub_subject_grade);
    
    RAISE NOTICE '✅ Added is_sub_subject_grade column to student_grades';
  ELSE
    RAISE NOTICE '⚠️ is_sub_subject_grade column already exists in student_grades';
  END IF;
END $$;

-- ============================================
-- STEP 3: CREATE student_subject_enrollments TABLE
-- ============================================

-- Table to track which TLE sub-subject each student is enrolled in
CREATE TABLE IF NOT EXISTS public.student_subject_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
  parent_subject_id UUID NOT NULL REFERENCES public.classroom_subjects(id) ON DELETE CASCADE,
  enrolled_subject_id UUID NOT NULL REFERENCES public.classroom_subjects(id) ON DELETE CASCADE,
  enrolled_by UUID REFERENCES public.profiles(id),  -- Teacher who enrolled (Grades 7-8)
  self_enrolled BOOLEAN DEFAULT false,  -- True if student chose (Grades 9-10)
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- One enrollment per student per parent subject per classroom
  CONSTRAINT unique_student_parent_subject_enrollment 
    UNIQUE(student_id, classroom_id, parent_subject_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_student_subject_enrollments_student 
  ON public.student_subject_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_student_subject_enrollments_enrolled_subject 
  ON public.student_subject_enrollments(enrolled_subject_id);
CREATE INDEX IF NOT EXISTS idx_student_subject_enrollments_parent_subject 
  ON public.student_subject_enrollments(parent_subject_id);
CREATE INDEX IF NOT EXISTS idx_student_subject_enrollments_classroom 
  ON public.student_subject_enrollments(classroom_id);

-- Enable RLS on student_subject_enrollments
ALTER TABLE public.student_subject_enrollments ENABLE ROW LEVEL SECURITY;

RAISE NOTICE '✅ Created student_subject_enrollments table with indexes and RLS enabled';

-- ============================================
-- STEP 4: ADD COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON COLUMN public.classroom_subjects.subject_type IS 
'Type of subject: standard (regular), mapeh_parent (MAPEH parent), mapeh_sub (Music/Arts/PE/Health), tle_parent (TLE parent), tle_sub (TLE components)';

COMMENT ON COLUMN public.student_grades.is_sub_subject_grade IS 
'True if grade is for a sub-subject (Music, Arts, PE, Health, TLE component). False if grade is for parent subject (MAPEH, TLE) or standard subject.';

COMMENT ON TABLE public.student_subject_enrollments IS 
'Tracks which TLE sub-subject each student is enrolled in. Used for Grades 7-10 where students take ONE TLE specialization.';

COMMIT;

-- ============================================
-- MIGRATION STEP 1 COMPLETE
-- ============================================

RAISE NOTICE '✅✅✅ MIGRATION STEP 1 COMPLETE: Schema changes applied successfully';
RAISE NOTICE 'Next steps: Run STEP 2 (RPC Functions) and STEP 3 (RLS Policies)';

