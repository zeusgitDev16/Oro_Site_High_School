-- Idempotent migration: add school_level column to classrooms table
-- This migration adds school level classification (JHS/SHS) to support different SF9 templates

BEGIN;

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

    -- Backfill existing records based on grade_level
    UPDATE public.classrooms
    SET school_level = CASE
      WHEN grade_level >= 7 AND grade_level <= 10 THEN 'JHS'
      WHEN grade_level >= 11 AND grade_level <= 12 THEN 'SHS'
      ELSE 'JHS' -- Fallback for any out-of-range values
    END;

    RAISE NOTICE 'Added school_level column to classrooms table';
  ELSE
    RAISE NOTICE 'school_level column already exists in classrooms table';
  END IF;
END$$;

-- Create index for school_level lookups if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_classrooms_school_level
  ON public.classrooms (school_level);

COMMIT;

