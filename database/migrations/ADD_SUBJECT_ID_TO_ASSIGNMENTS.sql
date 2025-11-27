-- ============================================================================
-- Migration: Add subject_id to assignments table
-- Date: 2025-11-27
-- Purpose: Link assignments to classroom_subjects (new system) instead of courses (old system)
-- ============================================================================

-- Add subject_id column to assignments table
-- This links assignments to the new classroom_subjects table (UUID-based)
-- instead of the old courses table (bigint-based)
ALTER TABLE public.assignments
ADD COLUMN IF NOT EXISTS subject_id UUID REFERENCES public.classroom_subjects(id) ON DELETE SET NULL;

-- Create index for performance (assignments filtered by subject_id frequently)
CREATE INDEX IF NOT EXISTS idx_assignments_subject_id ON public.assignments(subject_id);

-- Add comment for documentation
COMMENT ON COLUMN public.assignments.subject_id IS 'Links assignment to classroom_subjects table (new system). Replaces course_id for new classroom implementation.';

-- ============================================================================
-- Verification Query
-- ============================================================================
-- Run this to verify the column was added successfully:
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'assignments' AND column_name = 'subject_id';

-- Expected result:
-- column_name | data_type | is_nullable
-- subject_id  | uuid      | YES

-- ============================================================================
-- Backward Compatibility Notes
-- ============================================================================
-- - course_id column is KEPT for backward compatibility with old classrooms
-- - New classrooms (using classroom_subjects) will use subject_id
-- - Old classrooms (using courses) will continue using course_id
-- - Both columns can coexist safely

-- ============================================================================
-- Migration Status: READY TO APPLY
-- ============================================================================

