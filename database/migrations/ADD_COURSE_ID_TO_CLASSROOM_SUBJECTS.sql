-- ============================================
-- ADD COURSE_ID TO CLASSROOM_SUBJECTS TABLE
-- ============================================
-- Purpose: Link classroom_subjects to courses table for attendance compatibility
-- Idempotent: Safe to run multiple times
-- Date: 2025-11-26
-- Related: Phase 3 - Attendance System Revamp
-- ============================================

BEGIN;

-- Add course_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'classroom_subjects'
      AND column_name = 'course_id'
  ) THEN
    -- Add column as nullable BIGINT referencing courses table
    ALTER TABLE public.classroom_subjects
      ADD COLUMN course_id BIGINT REFERENCES public.courses(id) ON DELETE SET NULL;

    -- Create index for faster lookups
    CREATE INDEX idx_classroom_subjects_course_id 
      ON public.classroom_subjects(course_id);

    RAISE NOTICE 'Added course_id column to classroom_subjects table';
  ELSE
    RAISE NOTICE 'course_id column already exists in classroom_subjects table';
  END IF;
END$$;

COMMIT;

-- ============================================
-- VERIFICATION QUERY
-- ============================================
-- Run this to verify the column was added:
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'classroom_subjects'
--   AND column_name = 'course_id';

-- ============================================
-- NOTES
-- ============================================
-- 1. The course_id field is nullable to allow gradual migration
-- 2. Existing classroom_subjects will have NULL course_id initially
-- 3. New classroom_subjects can be linked to courses during creation
-- 4. This enables attendance system to work with both old (courses) and new (classroom_subjects) systems
-- 5. The attendance table expects course_id as BIGINT, so this field must match that type
-- 6. Foreign key constraint ensures referential integrity with courses table
-- 7. ON DELETE SET NULL ensures classroom_subjects remain if course is deleted

