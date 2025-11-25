-- Idempotent migration: add parent_access_code column to students table
-- This supports student-generated access codes for parents/guardians.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'students'
      AND column_name = 'parent_access_code'
  ) THEN
    ALTER TABLE public.students
      ADD COLUMN parent_access_code text;
  END IF;
END$$;

-- Ensure codes are unique when present (parents should map to exactly one student by code)
CREATE UNIQUE INDEX IF NOT EXISTS students_parent_access_code_key
  ON public.students(parent_access_code)
  WHERE parent_access_code IS NOT NULL;

COMMIT;

