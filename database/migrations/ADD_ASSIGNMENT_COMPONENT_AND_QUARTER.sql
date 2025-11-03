-- ADD_ASSIGNMENT_COMPONENT_AND_QUARTER.sql
-- Idempotent migration for adding grading tags to assignments
-- - assignment_component ENUM ('written_works','performance_task','quarterly_assessment')
-- - assignments.component assignment_component
-- - assignments.quarter_no smallint CHECK 1..4
-- - indexes for fast filtering
-- - safe backfill from existing fields (assignment_type and content.meta)

SET search_path TO public;

BEGIN;

-- 1) Ensure enum type exists, and contains all required values
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'assignment_component'
  ) THEN
    CREATE TYPE assignment_component AS ENUM ('written_works','performance_task','quarterly_assessment');
  END IF;

  -- Ensure each enum value exists (for environments where the type exists but lacks values)
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'assignment_component' AND e.enumlabel = 'written_works'
  ) THEN
    ALTER TYPE assignment_component ADD VALUE IF NOT EXISTS 'written_works';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'assignment_component' AND e.enumlabel = 'performance_task'
  ) THEN
    ALTER TYPE assignment_component ADD VALUE IF NOT EXISTS 'performance_task';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'assignment_component' AND e.enumlabel = 'quarterly_assessment'
  ) THEN
    ALTER TYPE assignment_component ADD VALUE IF NOT EXISTS 'quarterly_assessment';
  END IF;
END $$;

-- 2) Add columns if not exist
ALTER TABLE IF EXISTS assignments
  ADD COLUMN IF NOT EXISTS component assignment_component;

ALTER TABLE IF EXISTS assignments
  ADD COLUMN IF NOT EXISTS quarter_no smallint;

-- 3) Ensure quarter_no check constraint (1..4)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'assignments_quarter_no_check'
      AND conrelid = 'public.assignments'::regclass
  ) THEN
    ALTER TABLE public.assignments
      ADD CONSTRAINT assignments_quarter_no_check CHECK (quarter_no BETWEEN 1 AND 4);
  END IF;
END $$;

-- 4) If component column exists but not of enum type, attempt to convert to enum safely
DO $$
DECLARE
  col_udt text;
BEGIN
  SELECT udt_name INTO col_udt
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'assignments' AND column_name = 'component';

  IF col_udt IS NOT NULL AND col_udt <> 'assignment_component' THEN
    -- Try to convert text/varchar/user-defined to our enum for valid values; leave others as NULL
    BEGIN
      ALTER TABLE public.assignments
        ALTER COLUMN component TYPE assignment_component
        USING CASE
          WHEN component::text IN ('written_works','performance_task','quarterly_assessment')
            THEN component::text::assignment_component
          ELSE NULL
        END;
    EXCEPTION WHEN OTHERS THEN
      -- If conversion fails for any reason, ignore; the column remains as-is.
      NULL;
    END;
  END IF;
END $$;

-- 5) Indexes to speed up filters
CREATE INDEX IF NOT EXISTS idx_assignments_component ON public.assignments (component);
CREATE INDEX IF NOT EXISTS idx_assignments_quarter_no ON public.assignments (quarter_no);

-- 6) Backfill component from content.meta when available (safe to re-run)
UPDATE public.assignments a
SET component = (a.content->'meta'->>'component')::assignment_component
WHERE a.component IS NULL
  AND (a.content->'meta'->>'component') IN ('written_works','performance_task','quarterly_assessment');

-- 7) Backfill component from assignment_type mapping when still NULL (objective → WW, essay/file → PT)
UPDATE public.assignments a
SET component = CASE
  WHEN a.assignment_type IN ('quiz','multiple_choice','identification','matching_type') THEN 'written_works'::assignment_component
  WHEN a.assignment_type IN ('essay','file_upload') THEN 'performance_task'::assignment_component
  ELSE a.component
END
WHERE a.component IS NULL;

-- 8) Backfill quarter_no from content.meta when available (safe to re-run)
UPDATE public.assignments a
SET quarter_no = NULLIF((a.content->'meta'->>'quarter_no'), '')::smallint
WHERE a.quarter_no IS NULL
  AND (a.content->'meta'->>'quarter_no') IS NOT NULL;

-- NOTE: Optional heuristic backfill based on due_date month can be added if desired.
-- Example (adjust to your school calendar):
-- UPDATE public.assignments SET quarter_no = 1
--   WHERE quarter_no IS NULL AND due_date IS NOT NULL AND EXTRACT(MONTH FROM due_date) BETWEEN 8 AND 10;  -- Aug-Oct
-- UPDATE public.assignments SET quarter_no = 2
--   WHERE quarter_no IS NULL AND due_date IS NOT NULL AND EXTRACT(MONTH FROM due_date) BETWEEN 11 AND 12; -- Nov-Dec
-- UPDATE public.assignments SET quarter_no = 3
--   WHERE quarter_no IS NULL AND due_date IS NOT NULL AND EXTRACT(MONTH FROM due_date) BETWEEN 1 AND 3;   -- Jan-Mar
-- UPDATE public.assignments SET quarter_no = 4
--   WHERE quarter_no IS NULL AND due_date IS NOT NULL AND EXTRACT(MONTH FROM due_date) BETWEEN 4 AND 6;   -- Apr-Jun

COMMIT;

-- ROLLBACK strategy: This migration is additive and idempotent. If you must revert,
-- drop the columns and type manually only if nothing depends on them:
--   ALTER TABLE public.assignments DROP COLUMN IF EXISTS component;
--   ALTER TABLE public.assignments DROP COLUMN IF EXISTS quarter_no;
--   DROP TYPE IF EXISTS assignment_component;
