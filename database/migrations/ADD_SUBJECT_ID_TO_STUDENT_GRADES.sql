-- =====================================================
-- Migration: Add subject_id to student_grades table
-- Purpose: Support new classroom_subjects system (UUID)
-- Date: 2025-11-27
-- Backward Compatible: YES (keeps course_id for old system)
-- =====================================================

-- Add subject_id column (UUID) to link to classroom_subjects
ALTER TABLE public.student_grades
ADD COLUMN IF NOT EXISTS subject_id UUID REFERENCES public.classroom_subjects(id) ON DELETE SET NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_student_grades_subject_id ON public.student_grades(subject_id);

-- Add comment
COMMENT ON COLUMN public.student_grades.subject_id IS 'Links to classroom_subjects table (new system). NULL for old classrooms using course_id.';

-- =====================================================
-- BACKWARD COMPATIBILITY NOTES:
-- =====================================================
-- 1. Old classrooms will continue using course_id (bigint)
-- 2. New classrooms will use subject_id (UUID)
-- 3. Both columns can coexist - application logic handles both
-- 4. No data migration needed - new grades will use subject_id
-- =====================================================

