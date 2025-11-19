-- Idempotent migration: Fix INSERT RLS policy on classrooms table
-- This ensures teachers can create classrooms with the school_level column
-- Safe to run multiple times

BEGIN;

-- Drop existing INSERT policy if it exists
DROP POLICY IF EXISTS "Teachers can create classrooms" ON public.classrooms;

-- Recreate the INSERT policy with proper WITH CHECK clause
-- This allows authenticated teachers to insert rows where they are the teacher_id
CREATE POLICY "Teachers can create classrooms"
  ON public.classrooms
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = teacher_id);

COMMIT;

