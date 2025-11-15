-- Rollback migration: remove school_level column from classrooms table

BEGIN;

-- Drop index if it exists
DROP INDEX IF EXISTS public.idx_classrooms_school_level;

-- Remove school_level column if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'classrooms'
      AND column_name = 'school_level'
  ) THEN
    ALTER TABLE public.classrooms
      DROP COLUMN school_level;

    RAISE NOTICE 'Removed school_level column from classrooms table';
  ELSE
    RAISE NOTICE 'school_level column does not exist in classrooms table';
  END IF;
END$$;

COMMIT;

