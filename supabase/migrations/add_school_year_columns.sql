-- =====================================================
-- Migration: Add school_year columns to critical tables
-- Description: Add school_year tracking to classrooms, enrollments, 
--              student_grades, attendance, and announcements tables
-- Date: 2025-11-23
-- =====================================================

-- Step 1: Get the current school year to use as default
DO $$
DECLARE
    current_year TEXT;
BEGIN
    -- Get the current school year from school_years table
    SELECT year_label INTO current_year 
    FROM public.school_years 
    WHERE is_current = true 
    LIMIT 1;
    
    -- If no current year is set, use the most recent one
    IF current_year IS NULL THEN
        SELECT year_label INTO current_year 
        FROM public.school_years 
        WHERE is_active = true 
        ORDER BY start_year DESC 
        LIMIT 1;
    END IF;
    
    -- Store in a temporary variable for use in subsequent statements
    EXECUTE format('CREATE TEMP TABLE IF NOT EXISTS temp_default_year (year_label TEXT); 
                    TRUNCATE temp_default_year; 
                    INSERT INTO temp_default_year VALUES (%L);', current_year);
END $$;

-- =====================================================
-- Step 2: Add school_year column to CLASSROOMS table
-- =====================================================
ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS school_year TEXT;

-- Set default value for existing records
UPDATE public.classrooms 
SET school_year = (SELECT year_label FROM temp_default_year)
WHERE school_year IS NULL;

-- Make it NOT NULL after setting defaults
ALTER TABLE public.classrooms 
ALTER COLUMN school_year SET NOT NULL;

-- Add foreign key constraint
ALTER TABLE public.classrooms
ADD CONSTRAINT fk_classrooms_school_year 
FOREIGN KEY (school_year) 
REFERENCES public.school_years(year_label) 
ON DELETE RESTRICT 
ON UPDATE CASCADE;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_classrooms_school_year 
ON public.classrooms(school_year);

-- Add composite index for common queries
CREATE INDEX IF NOT EXISTS idx_classrooms_year_grade 
ON public.classrooms(school_year, grade_level);

COMMENT ON COLUMN public.classrooms.school_year IS 'School year this classroom belongs to (e.g., 2024-2025)';

-- =====================================================
-- Step 3: Add school_year column to ENROLLMENTS table
-- =====================================================
ALTER TABLE public.enrollments 
ADD COLUMN IF NOT EXISTS school_year TEXT;

-- Set default value for existing records
UPDATE public.enrollments 
SET school_year = (SELECT year_label FROM temp_default_year)
WHERE school_year IS NULL;

-- Make it NOT NULL after setting defaults
ALTER TABLE public.enrollments 
ALTER COLUMN school_year SET NOT NULL;

-- Add foreign key constraint
ALTER TABLE public.enrollments
ADD CONSTRAINT fk_enrollments_school_year 
FOREIGN KEY (school_year) 
REFERENCES public.school_years(year_label) 
ON DELETE RESTRICT 
ON UPDATE CASCADE;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_enrollments_school_year 
ON public.enrollments(school_year);

-- Add composite index for common queries
CREATE INDEX IF NOT EXISTS idx_enrollments_student_year 
ON public.enrollments(student_id, school_year);

COMMENT ON COLUMN public.enrollments.school_year IS 'School year for this enrollment (e.g., 2024-2025)';

-- =====================================================
-- Step 4: Add school_year column to STUDENT_GRADES table
-- =====================================================
ALTER TABLE public.student_grades 
ADD COLUMN IF NOT EXISTS school_year TEXT;

-- Set default value for existing records
UPDATE public.student_grades 
SET school_year = (SELECT year_label FROM temp_default_year)
WHERE school_year IS NULL;

-- Make it NOT NULL after setting defaults
ALTER TABLE public.student_grades 
ALTER COLUMN school_year SET NOT NULL;

-- Add foreign key constraint
ALTER TABLE public.student_grades
ADD CONSTRAINT fk_student_grades_school_year 
FOREIGN KEY (school_year) 
REFERENCES public.school_years(year_label) 
ON DELETE RESTRICT 
ON UPDATE CASCADE;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_student_grades_school_year 
ON public.student_grades(school_year);

-- Add composite index for common queries
CREATE INDEX IF NOT EXISTS idx_student_grades_student_year_quarter 
ON public.student_grades(student_id, school_year, quarter);

COMMENT ON COLUMN public.student_grades.school_year IS 'School year for this grade record (e.g., 2024-2025)';

-- =====================================================
-- Step 5: Add school_year column to ATTENDANCE table
-- =====================================================
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS school_year TEXT;

-- Set default value for existing records (nullable, so we set it but don't enforce)
UPDATE public.attendance
SET school_year = (SELECT year_label FROM temp_default_year)
WHERE school_year IS NULL;

-- Add foreign key constraint (nullable)
ALTER TABLE public.attendance
ADD CONSTRAINT fk_attendance_school_year
FOREIGN KEY (school_year)
REFERENCES public.school_years(year_label)
ON DELETE SET NULL
ON UPDATE CASCADE;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_attendance_school_year
ON public.attendance(school_year);

-- Add composite index for common queries
CREATE INDEX IF NOT EXISTS idx_attendance_student_year
ON public.attendance(student_id, school_year);

COMMENT ON COLUMN public.attendance.school_year IS 'School year for this attendance record (e.g., 2024-2025)';

-- =====================================================
-- Step 6: Add school_year column to ANNOUNCEMENTS table
-- =====================================================
ALTER TABLE public.announcements
ADD COLUMN IF NOT EXISTS school_year TEXT;

-- Set default value for existing records (nullable)
UPDATE public.announcements
SET school_year = (SELECT year_label FROM temp_default_year)
WHERE school_year IS NULL;

-- Add foreign key constraint (nullable)
ALTER TABLE public.announcements
ADD CONSTRAINT fk_announcements_school_year
FOREIGN KEY (school_year)
REFERENCES public.school_years(year_label)
ON DELETE SET NULL
ON UPDATE CASCADE;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_announcements_school_year
ON public.announcements(school_year);

COMMENT ON COLUMN public.announcements.school_year IS 'School year for this announcement (e.g., 2024-2025)';

-- =====================================================
-- Step 7: Update COURSES table foreign key (already has column)
-- =====================================================
-- Add foreign key constraint if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_courses_school_year'
        AND table_name = 'courses'
    ) THEN
        ALTER TABLE public.courses
        ADD CONSTRAINT fk_courses_school_year
        FOREIGN KEY (school_year)
        REFERENCES public.school_years(year_label)
        ON DELETE SET NULL
        ON UPDATE CASCADE;
    END IF;
END $$;

-- Add index if not exists
CREATE INDEX IF NOT EXISTS idx_courses_school_year
ON public.courses(school_year);

-- =====================================================
-- Step 8: Update COORDINATOR_ASSIGNMENTS table foreign key (already has column)
-- =====================================================
-- Add foreign key constraint if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_coordinator_assignments_school_year'
        AND table_name = 'coordinator_assignments'
    ) THEN
        ALTER TABLE public.coordinator_assignments
        ADD CONSTRAINT fk_coordinator_assignments_school_year
        FOREIGN KEY (school_year)
        REFERENCES public.school_years(year_label)
        ON DELETE SET NULL
        ON UPDATE CASCADE;
    END IF;
END $$;

-- Add index if not exists
CREATE INDEX IF NOT EXISTS idx_coordinator_assignments_school_year
ON public.coordinator_assignments(school_year);

-- =====================================================
-- Step 9: Clean up temporary table
-- =====================================================
DROP TABLE IF EXISTS temp_default_year;

-- =====================================================
-- Step 10: Create helper function to get current school year
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_current_school_year()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    current_year TEXT;
BEGIN
    -- Get the current school year
    SELECT year_label INTO current_year
    FROM public.school_years
    WHERE is_current = true
    LIMIT 1;

    -- If no current year is set, use the most recent active one
    IF current_year IS NULL THEN
        SELECT year_label INTO current_year
        FROM public.school_years
        WHERE is_active = true
        ORDER BY start_year DESC
        LIMIT 1;
    END IF;

    RETURN current_year;
END;
$$;

COMMENT ON FUNCTION public.get_current_school_year() IS 'Returns the current school year label';

-- =====================================================
-- Migration Complete
-- =====================================================
-- Summary:
-- ✅ Added school_year column to: classrooms, enrollments, student_grades, attendance, announcements
-- ✅ Added foreign key constraints to all school_year columns
-- ✅ Added indexes for performance optimization
-- ✅ Set default values for existing records
-- ✅ Created helper function to get current school year
-- =====================================================

