-- Idempotent migration: Add advisory_teacher_id to classrooms table
-- This migration adds support for assigning an advisory teacher to each classroom
-- Safe to run multiple times

BEGIN;

-- Add advisory_teacher_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'classrooms'
      AND column_name = 'advisory_teacher_id'
  ) THEN
    -- Add column as nullable UUID referencing teachers table
    ALTER TABLE public.classrooms
      ADD COLUMN advisory_teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL;

    -- Create index for faster lookups
    CREATE INDEX idx_classrooms_advisory_teacher_id 
      ON public.classrooms(advisory_teacher_id);

    RAISE NOTICE 'Added advisory_teacher_id column to classrooms table';
  ELSE
    RAISE NOTICE 'advisory_teacher_id column already exists in classrooms table';
  END IF;
END$$;

COMMIT;

-- Verification query (uncomment to test):
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'classrooms'
--   AND column_name = 'advisory_teacher_id';

