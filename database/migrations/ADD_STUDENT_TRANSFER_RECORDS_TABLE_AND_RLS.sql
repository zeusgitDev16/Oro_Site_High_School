-- ============================================
-- SF9 / Form 138: STUDENT TRANSFER RECORDS TABLE & RLS
-- ============================================
-- Stores administrative transfer / admission data used in SF9.

-- Create table only if it does not already exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM   pg_tables
    WHERE  schemaname = 'public'
    AND    tablename = 'student_transfer_records'
  ) THEN
    CREATE TABLE public.student_transfer_records (
      id BIGSERIAL PRIMARY KEY,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

      student_id  UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
      school_year TEXT NOT NULL,

      -- Admission / eligibility information (fields mapped from SF9)
      eligibility_for_admission_grade TEXT,       -- e.g. 'Grade 8'
      admitted_grade                  INTEGER,
      admitted_section                TEXT,
      admission_date                  DATE,

      -- Transfer-out / cancellation fields
      from_school     TEXT,                      -- name of previous school
      to_school       TEXT,                      -- name of receiving school
      canceled_in     TEXT,                      -- place or school where eligibility was cancelled
      cancellation_date DATE,

      -- Administrative metadata
      created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
      approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

      is_active BOOLEAN NOT NULL DEFAULT true,

      UNIQUE (student_id, school_year, is_active)
    );
  END IF;
END $$;

COMMENT ON TABLE public.student_transfer_records IS 'Administrative transfer and admission data for SF9 (eligibility, admission, cancellation).';

-- Helpful index
CREATE INDEX IF NOT EXISTS idx_student_transfer_records_student_year
  ON public.student_transfer_records(student_id, school_year);

-- Enable RLS on the new table
ALTER TABLE public.student_transfer_records ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: STUDENT TRANSFER RECORDS
-- ============================================

-- Admins can manage all transfer records
CREATE POLICY "Admins can manage student transfer records"
  ON public.student_transfer_records FOR ALL
  USING (public.is_admin(auth.uid()));

-- Grade level coordinators can view transfer records for their grade level
CREATE POLICY "Grade coordinators can view student transfer records"
  ON public.student_transfer_records FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.coordinator_assignments ca
      JOIN public.students s ON s.id = student_transfer_records.student_id
      WHERE ca.teacher_id = auth.uid()
        AND ca.grade_level = s.grade_level
        AND ca.school_year = student_transfer_records.school_year
        AND ca.is_active = true
    )
  );

