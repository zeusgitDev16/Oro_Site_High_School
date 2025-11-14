-- Idempotent migration: add custom component weight override columns to student_grades
begin;

-- Persist custom weight overrides as FRACTIONS (0.0 - 1.0)
ALTER TABLE public.student_grades
  ADD COLUMN IF NOT EXISTS ww_weight_override numeric,
  ADD COLUMN IF NOT EXISTS pt_weight_override numeric,
  ADD COLUMN IF NOT EXISTS qa_weight_override numeric;

commit;

