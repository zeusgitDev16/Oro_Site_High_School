-- ============================================
-- SF9 / Form 138: ATTENDANCE MONTHLY SUMMARY TABLE & RLS
-- ============================================
-- Stores per-student monthly attendance totals for SF9.

-- Helper functions for SF9 access control (duplicated here for self-containment)
CREATE OR REPLACE FUNCTION public.is_class_adviser(student_id UUID, teacher_id UUID, p_school_year TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.students s
    JOIN public.section_assignments sa
      ON sa.grade_level = s.grade_level
     AND sa.section = s.section
     AND sa.school_year = p_school_year
     AND sa.is_active = true
    WHERE s.id = student_id
      AND sa.teacher_id = teacher_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_grade_coordinator_for_student(student_id UUID, coordinator_id UUID, p_school_year TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.students s
    JOIN public.coordinator_assignments ca
      ON ca.grade_level = s.grade_level
     AND ca.school_year = p_school_year
     AND ca.is_active = true
    WHERE s.id = student_id
      AND ca.teacher_id = coordinator_id
  );
END;
$$;

-- Create table only if it does not already exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM   pg_tables
    WHERE  schemaname = 'public'
    AND    tablename = 'attendance_monthly_summary'
  ) THEN
    CREATE TABLE public.attendance_monthly_summary (
      id BIGSERIAL PRIMARY KEY,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

      student_id  UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
      school_year TEXT NOT NULL,
      month       INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),

      school_days  INTEGER NOT NULL DEFAULT 0,
      days_present INTEGER NOT NULL DEFAULT 0,
      days_absent  INTEGER NOT NULL DEFAULT 0,

      CHECK (school_days >= 0 AND days_present >= 0 AND days_absent >= 0),
      CHECK (days_present + days_absent <= school_days),

      UNIQUE (student_id, school_year, month)
    );
  END IF;
END $$;

COMMENT ON TABLE public.attendance_monthly_summary IS 'Monthly attendance totals for SF9 (school days, days present, days absent).';

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_attendance_monthly_student_year
  ON public.attendance_monthly_summary(student_id, school_year);

CREATE INDEX IF NOT EXISTS idx_attendance_monthly_year_month
  ON public.attendance_monthly_summary(school_year, month);

-- Enable RLS on the new table
ALTER TABLE public.attendance_monthly_summary ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: ATTENDANCE MONTHLY SUMMARY
-- ============================================

-- Students can view their own monthly attendance
CREATE POLICY "Students can view own attendance monthly summary"
  ON public.attendance_monthly_summary FOR SELECT
  USING (student_id = auth.uid());

-- Parents can view their children's monthly attendance
CREATE POLICY "Parents can view children attendance monthly summary"
  ON public.attendance_monthly_summary FOR SELECT
  USING (public.is_parent_of(student_id, auth.uid()));

-- Class advisers can manage monthly attendance for their advisory students
CREATE POLICY "Class advisers manage attendance monthly summary"
  ON public.attendance_monthly_summary FOR ALL
  USING (public.is_class_adviser(student_id, auth.uid(), school_year))
  WITH CHECK (public.is_class_adviser(student_id, auth.uid(), school_year));

-- Grade level coordinators can view monthly attendance for their grade level
CREATE POLICY "Grade coordinators can view attendance monthly summary"
  ON public.attendance_monthly_summary FOR SELECT
  USING (public.is_grade_coordinator_for_student(student_id, auth.uid(), school_year));

-- Admins can manage all monthly attendance summaries
CREATE POLICY "Admins can manage all attendance monthly summary"
  ON public.attendance_monthly_summary FOR ALL
  USING (public.is_admin(auth.uid()));

