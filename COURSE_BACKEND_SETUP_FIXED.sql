-- ============================================
-- COURSE CREATION FEATURE - COMPLETE BACKEND SETUP (FIXED)
-- ============================================
-- Purpose: Prepare Supabase database for Course Creation feature
-- Date: January 2025
-- Status: Ready for execution
-- 
-- INSTRUCTIONS:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Copy and paste this entire file
-- 3. Execute (or run section by section)
-- 4. Verify each step completes successfully
-- ============================================

-- ============================================
-- SECTION 1: ALTER COURSES TABLE
-- ============================================
-- Add missing columns to support full course management

-- Check current structure first
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'courses'
ORDER BY ordinal_position;

-- Add new columns (with IF NOT EXISTS logic)
DO $$ 
BEGIN
    -- Add course_code column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'course_code'
    ) THEN
        ALTER TABLE courses ADD COLUMN course_code TEXT;
        RAISE NOTICE 'Added column: course_code';
    END IF;

    -- Add grade_level column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'grade_level'
    ) THEN
        ALTER TABLE courses ADD COLUMN grade_level INT4;
        RAISE NOTICE 'Added column: grade_level';
    END IF;

    -- Add section column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'section'
    ) THEN
        ALTER TABLE courses ADD COLUMN section TEXT;
        RAISE NOTICE 'Added column: section';
    END IF;

    -- Add subject column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'subject'
    ) THEN
        ALTER TABLE courses ADD COLUMN subject TEXT;
        RAISE NOTICE 'Added column: subject';
    END IF;

    -- Add school_year column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'school_year'
    ) THEN
        ALTER TABLE courses ADD COLUMN school_year TEXT DEFAULT '2024-2025';
        RAISE NOTICE 'Added column: school_year';
    END IF;

    -- Add status column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'status'
    ) THEN
        ALTER TABLE courses ADD COLUMN status TEXT DEFAULT 'active';
        RAISE NOTICE 'Added column: status';
    END IF;

    -- Add room_number column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'room_number'
    ) THEN
        ALTER TABLE courses ADD COLUMN room_number TEXT;
        RAISE NOTICE 'Added column: room_number';
    END IF;

    -- Add is_active column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE courses ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
        RAISE NOTICE 'Added column: is_active';
    END IF;

    -- Add updated_at column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE courses ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added column: updated_at';
    END IF;
END $$;

-- Add constraints
DO $$
BEGIN
    -- Make course_code UNIQUE (if not already)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'courses_course_code_unique'
    ) THEN
        ALTER TABLE courses ADD CONSTRAINT courses_course_code_unique UNIQUE (course_code);
        RAISE NOTICE 'Added constraint: courses_course_code_unique';
    END IF;

    -- Add check constraint for grade_level (7-12)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'courses_grade_level_check'
    ) THEN
        ALTER TABLE courses ADD CONSTRAINT courses_grade_level_check 
        CHECK (grade_level >= 7 AND grade_level <= 12);
        RAISE NOTICE 'Added constraint: courses_grade_level_check';
    END IF;

    -- Add check constraint for status
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'courses_status_check'
    ) THEN
        ALTER TABLE courses ADD CONSTRAINT courses_status_check 
        CHECK (status IN ('active', 'inactive', 'archived'));
        RAISE NOTICE 'Added constraint: courses_status_check';
    END IF;
END $$;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_courses_grade_level ON courses(grade_level);
CREATE INDEX IF NOT EXISTS idx_courses_subject ON courses(subject);
CREATE INDEX IF NOT EXISTS idx_courses_status ON courses(status);
CREATE INDEX IF NOT EXISTS idx_courses_school_year ON courses(school_year);
CREATE INDEX IF NOT EXISTS idx_courses_code ON courses(course_code);
CREATE INDEX IF NOT EXISTS idx_courses_active ON courses(is_active);

-- Verify courses table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'courses'
ORDER BY ordinal_position;

-- Section 1 complete message
DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 1 COMPLETE: courses table updated';
END $$;

-- ============================================
-- SECTION 2: ALTER ENROLLMENTS TABLE
-- ============================================
-- Add columns to track enrollment status and type

DO $$ 
BEGIN
    -- Add status column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'enrollments' AND column_name = 'status'
    ) THEN
        ALTER TABLE enrollments ADD COLUMN status TEXT DEFAULT 'active';
        RAISE NOTICE 'Added column: status';
    END IF;

    -- Add enrolled_at column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'enrollments' AND column_name = 'enrolled_at'
    ) THEN
        ALTER TABLE enrollments ADD COLUMN enrolled_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added column: enrolled_at';
    END IF;

    -- Add enrollment_type column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'enrollments' AND column_name = 'enrollment_type'
    ) THEN
        ALTER TABLE enrollments ADD COLUMN enrollment_type TEXT DEFAULT 'manual';
        RAISE NOTICE 'Added column: enrollment_type';
    END IF;
END $$;

-- Add constraints
DO $$
BEGIN
    -- Add check constraint for status
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'enrollments_status_check'
    ) THEN
        ALTER TABLE enrollments ADD CONSTRAINT enrollments_status_check 
        CHECK (status IN ('active', 'dropped', 'completed', 'pending'));
        RAISE NOTICE 'Added constraint: enrollments_status_check';
    END IF;

    -- Add check constraint for enrollment_type
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'enrollments_type_check'
    ) THEN
        ALTER TABLE enrollments ADD CONSTRAINT enrollments_type_check 
        CHECK (enrollment_type IN ('manual', 'auto', 'section_based'));
        RAISE NOTICE 'Added constraint: enrollments_type_check';
    END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON enrollments(status);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_type ON enrollments(enrollment_type);

-- Create unique index to prevent duplicate active enrollments
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_enrollment 
ON enrollments(student_id, course_id) 
WHERE status = 'active';

-- Verify enrollments table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'enrollments'
ORDER BY ordinal_position;

-- Section 2 complete message
DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 2 COMPLETE: enrollments table updated';
END $$;

-- ============================================
-- SECTION 3: CREATE COURSE_SCHEDULES TABLE
-- ============================================
-- New table to store course schedules (day, time, room)

CREATE TABLE IF NOT EXISTS course_schedules (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    day_of_week TEXT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_number TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT course_schedules_day_check CHECK (
        day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
    ),
    CONSTRAINT course_schedules_time_check CHECK (end_time > start_time)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_course_schedules_course ON course_schedules(course_id);
CREATE INDEX IF NOT EXISTS idx_course_schedules_day ON course_schedules(day_of_week);
CREATE INDEX IF NOT EXISTS idx_course_schedules_active ON course_schedules(is_active);

-- Add comment
COMMENT ON TABLE course_schedules IS 'Stores course schedules with day, time, and room information';

-- Verify course_schedules table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'course_schedules'
ORDER BY ordinal_position;

-- Section 3 complete message
DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 3 COMPLETE: course_schedules table created';
END $$;

-- ============================================
-- SECTION 4: VERIFY/CREATE TEACHERS TABLE
-- ============================================
-- Ensure teachers table exists with proper structure

CREATE TABLE IF NOT EXISTS teachers (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    employee_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    department TEXT,
    subjects JSONB DEFAULT '[]'::jsonb, -- Array of subjects
    is_grade_coordinator BOOLEAN DEFAULT FALSE,
    coordinator_grade_level TEXT,
    is_shs_teacher BOOLEAN DEFAULT FALSE,
    shs_track TEXT,
    shs_strands JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_teachers_active ON teachers(is_active);
CREATE INDEX IF NOT EXISTS idx_teachers_department ON teachers(department);
CREATE INDEX IF NOT EXISTS idx_teachers_employee_id ON teachers(employee_id);
CREATE INDEX IF NOT EXISTS idx_teachers_coordinator ON teachers(is_grade_coordinator);

-- Add comment
COMMENT ON TABLE teachers IS 'Teacher-specific information linked to profiles table';

-- Verify teachers table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'teachers'
ORDER BY ordinal_position;

-- Section 4 complete message
DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 4 COMPLETE: teachers table verified/created';
END $$;

-- ============================================
-- SECTION 5: VERIFY COURSE_ASSIGNMENTS TABLE
-- ============================================
-- This table should already exist (Table #21 from SUPABASE_TABLES_PART2.md)
-- Just verify it exists and has correct structure

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'course_assignments'
    ) THEN
        -- Create if missing
        CREATE TABLE course_assignments (
            id BIGSERIAL PRIMARY KEY,
            created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
            teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
            course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
            status TEXT DEFAULT 'active' NOT NULL,
            assigned_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
            
            -- Prevent duplicate assignments
            CONSTRAINT course_assignments_unique UNIQUE (teacher_id, course_id)
        );
        
        -- Create indexes
        CREATE INDEX idx_course_assignments_teacher ON course_assignments(teacher_id);
        CREATE INDEX idx_course_assignments_course ON course_assignments(course_id);
        CREATE INDEX idx_course_assignments_status ON course_assignments(status);
        
        RAISE NOTICE 'Created table: course_assignments';
    ELSE
        RAISE NOTICE 'Table course_assignments already exists';
    END IF;
    
    RAISE NOTICE '✅ SECTION 5 COMPLETE: course_assignments table verified';
END $$;

-- Verify course_assignments table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'course_assignments'
ORDER BY ordinal_position;

-- ============================================
-- SECTION 6: CREATE HELPER FUNCTIONS
-- ============================================
-- Useful functions for course management

-- Function to get students by grade and section
CREATE OR REPLACE FUNCTION get_students_by_section(
    p_grade_level INT,
    p_section TEXT
)
RETURNS TABLE (
    student_id UUID,
    lrn TEXT,
    first_name TEXT,
    last_name TEXT,
    email TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.lrn,
        s.first_name,
        s.last_name,
        p.email
    FROM students s
    INNER JOIN profiles p ON s.id = p.id
    WHERE s.grade_level = p_grade_level
      AND s.section = p_section
      AND s.is_active = TRUE
      AND p.is_active = TRUE
    ORDER BY s.last_name, s.first_name;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-enroll students in a course
CREATE OR REPLACE FUNCTION auto_enroll_students(
    p_course_id BIGINT,
    p_grade_level INT,
    p_section TEXT
)
RETURNS INT AS $$
DECLARE
    v_enrolled_count INT := 0;
    v_student RECORD;
BEGIN
    -- Loop through students in the section
    FOR v_student IN 
        SELECT id FROM students 
        WHERE grade_level = p_grade_level 
          AND section = p_section 
          AND is_active = TRUE
    LOOP
        -- Insert enrollment (ignore if already exists)
        INSERT INTO enrollments (student_id, course_id, status, enrollment_type, enrolled_at)
        VALUES (v_student.id, p_course_id, 'active', 'section_based', NOW())
        ON CONFLICT (student_id, course_id) WHERE status = 'active'
        DO NOTHING;
        
        -- Increment counter if inserted
        IF FOUND THEN
            v_enrolled_count := v_enrolled_count + 1;
        END IF;
    END LOOP;
    
    RETURN v_enrolled_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get course enrollment count
CREATE OR REPLACE FUNCTION get_course_enrollment_count(p_course_id BIGINT)
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM enrollments
    WHERE course_id = p_course_id
      AND status = 'active';
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Function to check course code uniqueness
CREATE OR REPLACE FUNCTION is_course_code_unique(p_course_code TEXT, p_exclude_id BIGINT DEFAULT NULL)
RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM courses 
        WHERE course_code = p_course_code 
          AND (p_exclude_id IS NULL OR id != p_exclude_id)
    ) INTO v_exists;
    
    RETURN NOT v_exists;
END;
$$ LANGUAGE plpgsql;

-- Section 6 complete message
DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 6 COMPLETE: Helper functions created';
END $$;

-- ============================================
-- SECTION 7: CREATE TRIGGERS
-- ============================================
-- Automatic timestamp updates

-- Trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to courses table
DROP TRIGGER IF EXISTS update_courses_updated_at ON courses;
CREATE TRIGGER update_courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to course_schedules table
DROP TRIGGER IF EXISTS update_course_schedules_updated_at ON course_schedules;
CREATE TRIGGER update_course_schedules_updated_at
    BEFORE UPDATE ON course_schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to teachers table
DROP TRIGGER IF EXISTS update_teachers_updated_at ON teachers;
CREATE TRIGGER update_teachers_updated_at
    BEFORE UPDATE ON teachers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Section 7 complete message
DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 7 COMPLETE: Triggers created';
END $$;

-- ============================================
-- SECTION 8: INSERT SAMPLE DATA (OPTIONAL)
-- ============================================
-- Uncomment to insert sample data for testing

/*
-- Sample DepEd subjects
INSERT INTO courses (name, course_code, description, grade_level, subject, school_year, status, is_active)
VALUES 
    ('Mathematics 7', 'MATH7', 'Basic mathematics for Grade 7', 7, 'Mathematics', '2024-2025', 'active', TRUE),
    ('Science 7', 'SCI7', 'General science for Grade 7', 7, 'Science', '2024-2025', 'active', TRUE),
    ('English 7', 'ENG7', 'English language and literature', 7, 'English', '2024-2025', 'active', TRUE),
    ('Filipino 7', 'FIL7', 'Filipino language and culture', 7, 'Filipino', '2024-2025', 'active', TRUE),
    ('Mathematics 8', 'MATH8', 'Intermediate mathematics for Grade 8', 8, 'Mathematics', '2024-2025', 'active', TRUE),
    ('Science 8', 'SCI8', 'Physical science for Grade 8', 8, 'Science', '2024-2025', 'active', TRUE)
ON CONFLICT (course_code) DO NOTHING;
*/

-- ============================================
-- SECTION 9: VERIFICATION QUERIES
-- ============================================
-- Run these to verify everything is set up correctly

-- Check courses table structure
SELECT 'courses' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'courses';

-- Check enrollments table structure
SELECT 'enrollments' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'enrollments';

-- Check course_schedules table exists
SELECT 'course_schedules' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'course_schedules';

-- Check teachers table exists
SELECT 'teachers' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'teachers';

-- Check course_assignments table exists
SELECT 'course_assignments' AS table_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'course_assignments';

-- List all indexes on courses table
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'courses'
ORDER BY indexname;

-- List all constraints on courses table
SELECT conname, contype, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'courses'::regclass
ORDER BY conname;

-- Check helper functions exist
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'get_students_by_section',
    'auto_enroll_students',
    'get_course_enrollment_count',
    'is_course_code_unique'
  )
ORDER BY routine_name;

-- Check triggers exist
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN ('courses', 'course_schedules', 'teachers')
ORDER BY event_object_table, trigger_name;

-- ============================================
-- SECTION 10: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================
-- Enable RLS and create policies for secure access

-- Enable RLS on courses table
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Anyone can view active courses" ON courses;
DROP POLICY IF EXISTS "Admins can manage courses" ON courses;
DROP POLICY IF EXISTS "Teachers can view assigned courses" ON courses;

-- Policy: Anyone can view active courses
CREATE POLICY "Anyone can view active courses"
ON courses FOR SELECT
USING (is_active = TRUE);

-- Policy: Admins can do everything
CREATE POLICY "Admins can manage courses"
ON courses FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1 -- Admin role
    )
);

-- Policy: Teachers can view their assigned courses
CREATE POLICY "Teachers can view assigned courses"
ON courses FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM course_assignments
        WHERE course_assignments.course_id = courses.id
        AND course_assignments.teacher_id = auth.uid()
        AND course_assignments.status = 'active'
    )
);

-- Enable RLS on course_schedules
ALTER TABLE course_schedules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view course schedules" ON course_schedules;
DROP POLICY IF EXISTS "Admins can manage schedules" ON course_schedules;

-- Policy: Anyone can view schedules for active courses
CREATE POLICY "Anyone can view course schedules"
ON course_schedules FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM courses
        WHERE courses.id = course_schedules.course_id
        AND courses.is_active = TRUE
    )
);

-- Policy: Admins can manage schedules
CREATE POLICY "Admins can manage schedules"
ON course_schedules FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1
    )
);

-- Enable RLS on enrollments
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Students can view own enrollments" ON enrollments;
DROP POLICY IF EXISTS "Teachers can view course enrollments" ON enrollments;
DROP POLICY IF EXISTS "Admins can manage enrollments" ON enrollments;

-- Policy: Students can view their own enrollments
CREATE POLICY "Students can view own enrollments"
ON enrollments FOR SELECT
USING (student_id = auth.uid());

-- Policy: Teachers can view enrollments for their courses
CREATE POLICY "Teachers can view course enrollments"
ON enrollments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM course_assignments
        WHERE course_assignments.course_id = enrollments.course_id
        AND course_assignments.teacher_id = auth.uid()
        AND course_assignments.status = 'active'
    )
);

-- Policy: Admins can manage all enrollments
CREATE POLICY "Admins can manage enrollments"
ON enrollments FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1
    )
);

-- Enable RLS on course_assignments
ALTER TABLE course_assignments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Teachers can view own assignments" ON course_assignments;
DROP POLICY IF EXISTS "Admins can manage assignments" ON course_assignments;

-- Policy: Teachers can view their own assignments
CREATE POLICY "Teachers can view own assignments"
ON course_assignments FOR SELECT
USING (teacher_id = auth.uid());

-- Policy: Admins can manage assignments
CREATE POLICY "Admins can manage assignments"
ON course_assignments FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1
    )
);

-- Section 10 complete message
DO $$ 
BEGIN
    RAISE NOTICE '✅ SECTION 10 COMPLETE: RLS policies created';
END $$;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ BACKEND SETUP COMPLETE!                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '  ✅ courses table: 9 new columns added';
    RAISE NOTICE '  ✅ enrollments table: 3 new columns added';
    RAISE NOTICE '  ✅ course_schedules table: created';
    RAISE NOTICE '  ✅ teachers table: verified/created';
    RAISE NOTICE '  ✅ course_assignments table: verified';
    RAISE NOTICE '  ✅ Indexes: created for performance';
    RAISE NOTICE '  ✅ Constraints: added for data integrity';
    RAISE NOTICE '  ✅ Helper functions: 4 functions created';
    RAISE NOTICE '  ✅ Triggers: auto-update timestamps';
    RAISE NOTICE '  ✅ RLS policies: secure access control';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next Steps:';
    RAISE NOTICE '  1. Verify all tables in Supabase Table Editor';
    RAISE NOTICE '  2. Test helper functions with sample data';
    RAISE NOTICE '  3. Proceed to Dart model updates';
    RAISE NOTICE '  4. Implement CourseService methods';
    RAISE NOTICE '  5. Wire up UI to backend';
    RAISE NOTICE '';
    RAISE NOTICE '📝 Notes:';
    RAISE NOTICE '  - All changes are idempotent (safe to re-run)';
    RAISE NOTICE '  - Sample data insertion is commented out';
    RAISE NOTICE '  - RLS policies protect data by role';
    RAISE NOTICE '  - Indexes optimize query performance';
    RAISE NOTICE '';
END $$;

-- ============================================
-- END OF SETUP SCRIPT
-- ============================================
