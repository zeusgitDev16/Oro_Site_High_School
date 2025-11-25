-- Idempotent migration: restore school_level column to classrooms table
-- This migration re-adds school level classification (JHS/SHS) to support different SF9 templates
-- Safe to run multiple times - checks if column exists before adding
-- RLS-safe: Uses a security definer function to bypass RLS during backfill

BEGIN;

-- Create a temporary security definer function to perform the backfill
-- This function runs with the privileges of the function owner (superuser/service role)
-- bypassing RLS policies during the migration only
CREATE OR REPLACE FUNCTION public.temp_backfill_classroom_school_level()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Backfill existing records based on grade_level
  UPDATE public.classrooms
  SET school_level = CASE
    WHEN grade_level >= 7 AND grade_level <= 10 THEN 'JHS'
    WHEN grade_level >= 11 AND grade_level <= 12 THEN 'SHS'
    ELSE 'JHS' -- Fallback for any out-of-range values
  END
  WHERE school_level IS NULL OR school_level = '';

  RAISE NOTICE 'Backfilled school_level for % rows', FOUND;
END;
$$;

-- Add school_level column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'classrooms'
      AND column_name = 'school_level'
  ) THEN
    -- Add column with default value and constraint
    ALTER TABLE public.classrooms
      ADD COLUMN school_level TEXT NOT NULL DEFAULT 'JHS'
      CHECK (school_level IN ('JHS', 'SHS'));

    -- Call the security definer function to backfill data
    PERFORM public.temp_backfill_classroom_school_level();

    RAISE NOTICE 'Added school_level column to classrooms table';
  ELSE
    RAISE NOTICE 'school_level column already exists in classrooms table';
  END IF;
END$$;

-- Drop the temporary function after use
DROP FUNCTION IF EXISTS public.temp_backfill_classroom_school_level();

-- Create index for school_level lookups if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_classrooms_school_level
  ON public.classrooms (school_level);

COMMIT;

