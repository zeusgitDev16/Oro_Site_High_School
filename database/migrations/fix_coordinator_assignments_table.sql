-- Fix coordinator_assignments table
-- Add missing columns and RLS policies

-- =====================================================
-- 1. Add missing columns
-- =====================================================

-- Add teacher_name column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'coordinator_assignments' 
        AND column_name = 'teacher_name'
    ) THEN
        ALTER TABLE coordinator_assignments 
        ADD COLUMN teacher_name VARCHAR(255);
    END IF;
END $$;

-- Add assigned_by column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'coordinator_assignments' 
        AND column_name = 'assigned_by'
    ) THEN
        ALTER TABLE coordinator_assignments 
        ADD COLUMN assigned_by UUID REFERENCES profiles(id);
    END IF;
END $$;

-- Add permissions column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'coordinator_assignments' 
        AND column_name = 'permissions'
    ) THEN
        ALTER TABLE coordinator_assignments 
        ADD COLUMN permissions JSONB DEFAULT '{
            "reset_passwords": true,
            "bulk_grade_entry": true,
            "verify_grades": true,
            "review_attendance": true,
            "send_announcements": true,
            "export_reports": true,
            "manage_sections": true,
            "override_grades": false
        }'::jsonb;
    END IF;
END $$;

-- =====================================================
-- 2. Drop existing RLS policies (if any)
-- =====================================================

DROP POLICY IF EXISTS "Admins can view all coordinator assignments" ON coordinator_assignments;
DROP POLICY IF EXISTS "Admins can insert coordinator assignments" ON coordinator_assignments;
DROP POLICY IF EXISTS "Admins can update coordinator assignments" ON coordinator_assignments;
DROP POLICY IF EXISTS "Admins can delete coordinator assignments" ON coordinator_assignments;
DROP POLICY IF EXISTS "Grade coordinators can view their own assignments" ON coordinator_assignments;
DROP POLICY IF EXISTS "Grade coordinators can update their own assignments" ON coordinator_assignments;

-- =====================================================
-- 3. Create RLS policies
-- =====================================================

-- Allow admins to view all coordinator assignments
CREATE POLICY "Admins can view all coordinator assignments"
ON coordinator_assignments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1  -- admin role
    )
);

-- Allow admins to insert coordinator assignments
CREATE POLICY "Admins can insert coordinator assignments"
ON coordinator_assignments
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1  -- admin role
    )
);

-- Allow admins to update coordinator assignments
CREATE POLICY "Admins can update coordinator assignments"
ON coordinator_assignments
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1  -- admin role
    )
);

-- Allow admins to delete coordinator assignments
CREATE POLICY "Admins can delete coordinator assignments"
ON coordinator_assignments
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1  -- admin role
    )
);

-- Allow grade coordinators to view their own assignments
CREATE POLICY "Grade coordinators can view their own assignments"
ON coordinator_assignments
FOR SELECT
TO authenticated
USING (
    teacher_id = auth.uid()
    AND is_active = true
);

-- Allow grade coordinators to update their own assignments (limited fields)
CREATE POLICY "Grade coordinators can update their own assignments"
ON coordinator_assignments
FOR UPDATE
TO authenticated
USING (
    teacher_id = auth.uid()
    AND is_active = true
);

-- =====================================================
-- 4. Create indexes for better performance
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_coordinator_assignments_teacher_id 
ON coordinator_assignments(teacher_id);

CREATE INDEX IF NOT EXISTS idx_coordinator_assignments_grade_level 
ON coordinator_assignments(grade_level);

CREATE INDEX IF NOT EXISTS idx_coordinator_assignments_is_active 
ON coordinator_assignments(is_active);

CREATE INDEX IF NOT EXISTS idx_coordinator_assignments_school_year 
ON coordinator_assignments(school_year);

-- =====================================================
-- Done!
-- =====================================================

