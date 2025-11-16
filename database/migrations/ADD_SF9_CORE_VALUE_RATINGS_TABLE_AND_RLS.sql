-- ============================================
-- SF9 / Form 138: CORE VALUE RATINGS TABLE & RLS
-- ============================================
-- Stores quarterly behavior/core value ratings (AO/SO/RO/NO) per student.

-- Helper functions for SF9 access control
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
    AND    tablename = 'sf9_core_value_ratings'
  ) THEN
    CREATE TABLE public.sf9_core_value_ratings (
      id BIGSERIAL PRIMARY KEY,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

      student_id   UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
      recorded_by  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
      school_year  TEXT NOT NULL,
      quarter      INTEGER NOT NULL CHECK (quarter BETWEEN 1 AND 4),

      core_value_code TEXT NOT NULL,
      indicator_code  TEXT NOT NULL,
      rating          TEXT NOT NULL,

      UNIQUE (student_id, school_year, quarter, indicator_code)
    );
  END IF;
END $$;

COMMENT ON TABLE public.sf9_core_value_ratings IS 'Quarterly ratings for SF9 core values / behavior indicators.';
COMMENT ON COLUMN public.sf9_core_value_ratings.core_value_code IS 'Core value code (e.g. MAKA_DIYOS, MAKATAO, MAKAKALIKASAN, MAKABANSA).';
COMMENT ON COLUMN public.sf9_core_value_ratings.indicator_code IS 'Behavior indicator code (e.g. MD1, MT1, MK1, MB1).';
COMMENT ON COLUMN public.sf9_core_value_ratings.rating IS 'Rating: AO (Always), SO (Sometimes), RO (Rarely), NO (Not observed).';

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_sf9_core_values_student_year
  ON public.sf9_core_value_ratings(student_id, school_year);

CREATE INDEX IF NOT EXISTS idx_sf9_core_values_year_quarter
  ON public.sf9_core_value_ratings(school_year, quarter);

-- Enable RLS on the new table
ALTER TABLE public.sf9_core_value_ratings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: CORE VALUE RATINGS
-- ============================================

-- Students can view their own ratings
CREATE POLICY "Students can view own core value ratings"
  ON public.sf9_core_value_ratings FOR SELECT
  USING (student_id = auth.uid());

-- Parents can view their children's ratings
CREATE POLICY "Parents can view children core value ratings"
  ON public.sf9_core_value_ratings FOR SELECT
  USING (public.is_parent_of(student_id, auth.uid()));

-- Class advisers can manage ratings for their advisory students
CREATE POLICY "Class advisers manage core value ratings"
  ON public.sf9_core_value_ratings FOR ALL
  USING (public.is_class_adviser(student_id, auth.uid(), school_year))
  WITH CHECK (public.is_class_adviser(student_id, auth.uid(), school_year));

-- Grade level coordinators can view ratings for their grade level
CREATE POLICY "Grade coordinators can view core value ratings"
  ON public.sf9_core_value_ratings FOR SELECT
  USING (public.is_grade_coordinator_for_student(student_id, auth.uid(), school_year));

-- Admins can manage all ratings
CREATE POLICY "Admins can manage all core value ratings"
  ON public.sf9_core_value_ratings FOR ALL
  USING (public.is_admin(auth.uid()));

