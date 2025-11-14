-- Idempotent migration: add QA override fields used by grade explanation and persistence paths
begin;

-- Store the manual Quarterly Assessment override the teacher may input when computing grades
ALTER TABLE public.student_grades
  ADD COLUMN IF NOT EXISTS qa_score_override numeric,
  ADD COLUMN IF NOT EXISTS qa_max_override numeric;

commit;

