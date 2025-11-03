-- Add course_id to assignments to scope assignments to a subject (course) within a classroom
ALTER TABLE public.assignments
ADD COLUMN IF NOT EXISTS course_id UUID REFERENCES public.courses(id) ON DELETE SET NULL;

-- Index for course_id lookups
CREATE INDEX IF NOT EXISTS idx_assignments_course_id ON public.assignments(course_id);

-- Optional: tighten student view policy to published + active + enrollment (already enforced)
-- No RLS change is necessary because access remains constrained by classroom enrollment and publish/active flags.

-- Verification
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'assignments' AND column_name = 'course_id';
