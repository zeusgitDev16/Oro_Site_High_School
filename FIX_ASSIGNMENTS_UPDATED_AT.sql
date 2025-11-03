-- Fix assignments updated_at column and triggers to resolve update failures
-- This script is idempotent and safe to run multiple times.

-- 1) Ensure the shared trigger function exists
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2) Ensure assignments.updated_at column exists
ALTER TABLE public.assignments
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 3) Ensure BEFORE UPDATE trigger exists on assignments
DROP TRIGGER IF EXISTS update_assignments_updated_at ON public.assignments;
CREATE TRIGGER update_assignments_updated_at
  BEFORE UPDATE ON public.assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 4) Ensure assignment_submissions.updated_at column and trigger also exist (defensive)
ALTER TABLE public.assignment_submissions
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

DROP TRIGGER IF EXISTS update_submissions_updated_at ON public.assignment_submissions;
CREATE TRIGGER update_submissions_updated_at
  BEFORE UPDATE ON public.assignment_submissions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 5) Verification queries
-- Run as needed to verify the column/trigger state
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'assignments' AND column_name = 'updated_at';
-- SELECT tgname, tgtype FROM pg_trigger WHERE tgrelid = 'public.assignments'::regclass;

-- Completion notice
DO $$ BEGIN
  RAISE NOTICE 'Assignments updated_at column and triggers ensured.';
END $$;