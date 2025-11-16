-- Idempotent migration: add school_level column to students table
-- This migration adds school level classification (JHS/SHS) to support SF9 templates

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'students'
      AND column_name = 'school_level'
  ) THEN
    ALTER TABLE public.students
      ADD COLUMN school_level TEXT
      CHECK (school_level IN ('JHS', 'SHS'));

    -- Backfill existing records based on grade_level
    UPDATE public.students
    SET school_level = CASE
      WHEN grade_level >= 7 AND grade_level <= 10 THEN 'JHS'
      WHEN grade_level >= 11 AND grade_level <= 12 THEN 'SHS'
      ELSE NULL
    END
    WHERE school_level IS NULL;

    RAISE NOTICE 'Added school_level column to students table';
  ELSE
    RAISE NOTICE 'school_level column already exists in students table';
  END IF;
END$$;

COMMIT;

