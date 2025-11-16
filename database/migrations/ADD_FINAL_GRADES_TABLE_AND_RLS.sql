-- ============================================
-- SF9 / Form 138: FINAL GRADES TABLE & RLS
-- ============================================
-- Adds a canonical per-subject final_grades table for SF9/Form 138
-- while preserving existing grades table and logic.

-- Ensure helper functions exist (used in RLS policies)
CREATE OR REPLACE FUNCTION public.is_course_teacher(course_id BIGINT, user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.courses c
    WHERE c.id = course_id
      AND c.teacher_id = user_id
  ) OR EXISTS (
    SELECT 1
    FROM public.course_assignments ca
    WHERE ca.course_id = course_id
      AND ca.teacher_id = user_id
      AND ca.status = 'active'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_parent_of(student_id UUID, parent_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.parent_students ps
    WHERE ps.student_id = student_id
      AND ps.parent_id = parent_id
      AND ps.is_active = true
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
    AND    tablename = 'final_grades'
  ) THEN
    CREATE TABLE public.final_grades (
      id BIGSERIAL PRIMARY KEY,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

      -- Foreign keys
      student_id UUID NOT NULL REFERENCES public.students(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
      course_id  BIGINT NOT NULL REFERENCES public.courses(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

      -- Denormalized names for convenience / reporting
      student_name TEXT,
      course_name  TEXT,

      -- Academic context
      school_year TEXT NOT NULL,

      -- Quarter grades (DepEd: 4 quarters)
      quarter_1 NUMERIC,
      quarter_2 NUMERIC,
      quarter_3 NUMERIC,
      quarter_4 NUMERIC,

      -- Final result
      final_grade      NUMERIC    NOT NULL,
      transmuted_grade TEXT       NOT NULL,
      grade_remarks    TEXT       NOT NULL,
      is_passing       BOOLEAN    NOT NULL DEFAULT true,

      -- Ensure one record per student/course/school_year
      UNIQUE (student_id, course_id, school_year)
    );
  END IF;
END $$;

COMMENT ON TABLE public.final_grades IS 'Per-subject final grades for SF9/Form 138 (quarters 1-4, final grade, remarks).';

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_final_grades_student_year
  ON public.final_grades(student_id, school_year);

CREATE INDEX IF NOT EXISTS idx_final_grades_course_year
  ON public.final_grades(course_id, school_year);

-- Enable RLS on the new table
ALTER TABLE public.final_grades ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: FINAL GRADES
-- ============================================

-- Students can view their own final grades
CREATE POLICY "Students can view own final grades"
  ON public.final_grades FOR SELECT
  USING (student_id = auth.uid());

-- Teachers can manage final grades for courses they teach (or co-teach)
CREATE POLICY "Teachers can manage course final grades"
  ON public.final_grades FOR ALL
  USING (public.is_course_teacher(course_id, auth.uid()));

-- Parents can view their children's final grades
CREATE POLICY "Parents can view children final grades"
  ON public.final_grades FOR SELECT
  USING (public.is_parent_of(student_id, auth.uid()));

-- Grade level coordinators can view final grades for their assigned grade level
CREATE POLICY "Grade coordinators can view final grades for level"
  ON public.final_grades FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.coordinator_assignments ca
      JOIN public.students s ON s.id = final_grades.student_id
      WHERE ca.teacher_id = auth.uid()
        AND ca.grade_level = s.grade_level
        AND ca.school_year = final_grades.school_year
        AND ca.is_active = true
    )
  );

-- Grade level coordinators can update final grades for their assigned grade level
CREATE POLICY "Grade coordinators can update final grades for level"
  ON public.final_grades FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM public.coordinator_assignments ca
      JOIN public.students s ON s.id = final_grades.student_id
      WHERE ca.teacher_id = auth.uid()
        AND ca.grade_level = s.grade_level
        AND ca.school_year = final_grades.school_year
        AND ca.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.coordinator_assignments ca
      JOIN public.students s ON s.id = final_grades.student_id
      WHERE ca.teacher_id = auth.uid()
        AND ca.grade_level = s.grade_level
        AND ca.school_year = final_grades.school_year
        AND ca.is_active = true
    )
  );

-- Admins can manage all final grades
CREATE POLICY "Admins can manage all final grades"
  ON public.final_grades FOR ALL
  USING (public.is_admin(auth.uid()));

