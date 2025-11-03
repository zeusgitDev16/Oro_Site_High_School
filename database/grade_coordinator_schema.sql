-- Grade Level Coordinator Database Schema
-- Tables and permissions for grade level coordinator features

-- =====================================================
-- Coordinator Assignments Table
-- =====================================================
CREATE TABLE IF NOT EXISTS coordinator_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID NOT NULL REFERENCES profiles(id),
    teacher_name VARCHAR(255) NOT NULL,
    grade_level INT NOT NULL CHECK (grade_level BETWEEN 7 AND 12),
    school_year VARCHAR(20) NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES profiles(id),
    is_active BOOLEAN DEFAULT TRUE,
    permissions JSONB DEFAULT '{
        "reset_passwords": true,
        "bulk_grade_entry": true,
        "verify_grades": true,
        "review_attendance": true,
        "send_announcements": true,
        "export_reports": true,
        "manage_sections": true,
        "override_grades": false
    }',
    
    -- Ensure one coordinator per grade level per school year
    UNIQUE(grade_level, school_year, is_active),
    
    -- Indexes
    INDEX idx_coordinator_teacher (teacher_id),
    INDEX idx_coordinator_grade (grade_level),
    INDEX idx_coordinator_active (is_active)
);

-- =====================================================
-- Coordinator Activity Log
-- =====================================================
CREATE TABLE IF NOT EXISTS coordinator_activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coordinator_id UUID NOT NULL REFERENCES profiles(id),
    grade_level INT NOT NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB,
    affected_student_id UUID,
    affected_section_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for queries
    INDEX idx_coord_log_coordinator (coordinator_id),
    INDEX idx_coord_log_action (action),
    INDEX idx_coord_log_date (created_at DESC)
);

-- =====================================================
-- Grade Verification Table
-- =====================================================
CREATE TABLE IF NOT EXISTS grade_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grade_level INT NOT NULL,
    section_id VARCHAR(50) NOT NULL,
    quarter VARCHAR(10) NOT NULL,
    subject_id INT,
    verified_by UUID NOT NULL REFERENCES profiles(id),
    verified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verification_status VARCHAR(20) DEFAULT 'verified',
    notes TEXT,
    
    -- Unique verification per section, quarter, subject
    UNIQUE(section_id, quarter, subject_id),
    
    -- Indexes
    INDEX idx_verification_section (section_id),
    INDEX idx_verification_quarter (quarter)
);

-- =====================================================
-- Bulk Grade Entry Sessions
-- =====================================================
CREATE TABLE IF NOT EXISTS bulk_grade_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coordinator_id UUID NOT NULL REFERENCES profiles(id),
    course_id INT NOT NULL,
    section_id VARCHAR(50),
    quarter VARCHAR(10) NOT NULL,
    total_students INT NOT NULL,
    grades_entered INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'in_progress',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Indexes
    INDEX idx_bulk_grade_coordinator (coordinator_id),
    INDEX idx_bulk_grade_status (status)
);

-- =====================================================
-- Section Performance Metrics (Cached)
-- =====================================================
CREATE TABLE IF NOT EXISTS section_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_id VARCHAR(50) NOT NULL,
    grade_level INT NOT NULL,
    quarter VARCHAR(10) NOT NULL,
    school_year VARCHAR(20) NOT NULL,
    
    -- Academic metrics
    average_grade DECIMAL(5,2),
    highest_grade DECIMAL(5,2),
    lowest_grade DECIMAL(5,2),
    passing_rate DECIMAL(5,2),
    failing_count INT DEFAULT 0,
    excellent_count INT DEFAULT 0,
    
    -- Attendance metrics
    attendance_rate DECIMAL(5,2),
    perfect_attendance_count INT DEFAULT 0,
    chronic_absence_count INT DEFAULT 0,
    
    -- Subject breakdown
    subject_performance JSONB,
    
    -- Comparative data
    grade_level_rank INT,
    improvement_from_last_quarter DECIMAL(5,2),
    
    -- Metadata
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Unique constraint
    UNIQUE(section_id, quarter, school_year),
    
    -- Indexes
    INDEX idx_section_metrics_section (section_id),
    INDEX idx_section_metrics_grade (grade_level)
);

-- =====================================================
-- Grade Level Announcements
-- =====================================================
CREATE TABLE IF NOT EXISTS grade_level_announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    grade_level INT NOT NULL,
    recipients TEXT[] DEFAULT ARRAY['students', 'parents'],
    priority VARCHAR(20) DEFAULT 'normal',
    created_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scheduled_for TIMESTAMP,
    expires_at TIMESTAMP,
    is_published BOOLEAN DEFAULT TRUE,
    view_count INT DEFAULT 0,
    
    -- Indexes
    INDEX idx_announcement_grade (grade_level),
    INDEX idx_announcement_published (is_published),
    INDEX idx_announcement_date (created_at DESC)
);

-- =====================================================
-- Student Password Reset Requests
-- =====================================================
CREATE TABLE IF NOT EXISTS student_password_resets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES profiles(id),
    student_lrn VARCHAR(12) NOT NULL,
    requested_by UUID REFERENCES profiles(id),
    reset_by UUID REFERENCES profiles(id),
    temp_password VARCHAR(255),
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reset_at TIMESTAMP,
    expires_at TIMESTAMP,
    
    -- Indexes
    INDEX idx_password_reset_student (student_id),
    INDEX idx_password_reset_status (status)
);

-- =====================================================
-- Coordinator Permissions Override
-- =====================================================
CREATE TABLE IF NOT EXISTS coordinator_permission_overrides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coordinator_id UUID NOT NULL REFERENCES profiles(id),
    permission_key VARCHAR(100) NOT NULL,
    permission_value BOOLEAN DEFAULT TRUE,
    granted_by UUID REFERENCES profiles(id),
    reason TEXT,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    
    -- Unique permission per coordinator
    UNIQUE(coordinator_id, permission_key),
    
    -- Indexes
    INDEX idx_permission_override_coordinator (coordinator_id)
);

-- =====================================================
-- Functions and Triggers
-- =====================================================

-- Function to calculate section performance metrics
CREATE OR REPLACE FUNCTION calculate_section_metrics(
    p_section_id VARCHAR(50),
    p_quarter VARCHAR(10),
    p_school_year VARCHAR(20)
)
RETURNS void AS $$
DECLARE
    v_grade_level INT;
    v_avg_grade DECIMAL(5,2);
    v_attendance_rate DECIMAL(5,2);
    v_failing_count INT;
    v_excellent_count INT;
BEGIN
    -- Get grade level from section
    SELECT CAST(SUBSTRING(p_section_id FROM 1 FOR 1) AS INT) INTO v_grade_level;
    
    -- Calculate average grade
    SELECT AVG(grade) INTO v_avg_grade
    FROM grades
    WHERE section_id = p_section_id
    AND quarter = p_quarter;
    
    -- Calculate attendance rate
    SELECT 
        (COUNT(CASE WHEN status IN ('present', 'late') THEN 1 END) * 100.0 / 
         NULLIF(COUNT(*), 0))
    INTO v_attendance_rate
    FROM attendance
    WHERE section_id = p_section_id
    AND DATE_PART('quarter', date) = CAST(SUBSTRING(p_quarter FROM 2) AS INT);
    
    -- Count failing students (below 75)
    SELECT COUNT(DISTINCT student_id) INTO v_failing_count
    FROM grades
    WHERE section_id = p_section_id
    AND quarter = p_quarter
    AND grade < 75;
    
    -- Count excellent students (90 and above)
    SELECT COUNT(DISTINCT student_id) INTO v_excellent_count
    FROM grades
    WHERE section_id = p_section_id
    AND quarter = p_quarter
    AND grade >= 90;
    
    -- Insert or update metrics
    INSERT INTO section_performance_metrics (
        section_id,
        grade_level,
        quarter,
        school_year,
        average_grade,
        attendance_rate,
        failing_count,
        excellent_count
    ) VALUES (
        p_section_id,
        v_grade_level,
        p_quarter,
        p_school_year,
        v_avg_grade,
        v_attendance_rate,
        v_failing_count,
        v_excellent_count
    )
    ON CONFLICT (section_id, quarter, school_year)
    DO UPDATE SET
        average_grade = EXCLUDED.average_grade,
        attendance_rate = EXCLUDED.attendance_rate,
        failing_count = EXCLUDED.failing_count,
        excellent_count = EXCLUDED.excellent_count,
        calculated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Function to check coordinator permissions
CREATE OR REPLACE FUNCTION check_coordinator_permission(
    p_coordinator_id UUID,
    p_permission VARCHAR(100)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_permission BOOLEAN;
BEGIN
    -- Check base permissions
    SELECT 
        (permissions->p_permission)::BOOLEAN INTO v_has_permission
    FROM coordinator_assignments
    WHERE teacher_id = p_coordinator_id
    AND is_active = TRUE;
    
    -- Check for overrides
    IF EXISTS (
        SELECT 1 FROM coordinator_permission_overrides
        WHERE coordinator_id = p_coordinator_id
        AND permission_key = p_permission
        AND (expires_at IS NULL OR expires_at > NOW())
    ) THEN
        SELECT permission_value INTO v_has_permission
        FROM coordinator_permission_overrides
        WHERE coordinator_id = p_coordinator_id
        AND permission_key = p_permission;
    END IF;
    
    RETURN COALESCE(v_has_permission, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Trigger to log coordinator actions
CREATE OR REPLACE FUNCTION log_coordinator_action()
RETURNS TRIGGER AS $$
BEGIN
    -- Log different actions based on table
    IF TG_TABLE_NAME = 'student_password_resets' THEN
        INSERT INTO coordinator_activity_log (
            coordinator_id,
            grade_level,
            action,
            details,
            affected_student_id
        )
        SELECT 
            NEW.reset_by,
            CAST(SUBSTRING(s.section FROM 1 FOR 1) AS INT),
            'password_reset',
            jsonb_build_object(
                'student_lrn', NEW.student_lrn,
                'reason', NEW.reason
            ),
            NEW.student_id
        FROM students s
        WHERE s.id = NEW.student_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for password resets
CREATE TRIGGER trigger_log_password_reset
    AFTER UPDATE ON student_password_resets
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION log_coordinator_action();

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE coordinator_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE coordinator_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE bulk_grade_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE section_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_level_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_password_resets ENABLE ROW LEVEL SECURITY;

-- Coordinator Assignments Policies
CREATE POLICY "Admins can manage coordinator assignments"
    ON coordinator_assignments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role_id = 1 -- Admin
        )
    );

CREATE POLICY "Coordinators can view their assignment"
    ON coordinator_assignments FOR SELECT
    USING (teacher_id = auth.uid());

-- Activity Log Policies
CREATE POLICY "Coordinators can view their activity log"
    ON coordinator_activity_log FOR SELECT
    USING (coordinator_id = auth.uid());

CREATE POLICY "Admins can view all activity logs"
    ON coordinator_activity_log FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role_id = 1
        )
    );

-- Grade Verification Policies
CREATE POLICY "Coordinators can verify grades for their level"
    ON grade_verifications FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM coordinator_assignments
            WHERE teacher_id = auth.uid()
            AND grade_level = grade_verifications.grade_level
            AND is_active = TRUE
        )
    );

-- Section Metrics Policies
CREATE POLICY "Coordinators can view metrics for their grade level"
    ON section_performance_metrics FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM coordinator_assignments
            WHERE teacher_id = auth.uid()
            AND grade_level = section_performance_metrics.grade_level
            AND is_active = TRUE
        )
    );

-- =====================================================
-- Sample Data for Testing
-- =====================================================

-- Assign a teacher as Grade 7 Coordinator
INSERT INTO coordinator_assignments (
    teacher_id,
    teacher_name,
    grade_level,
    school_year,
    assigned_by
)
SELECT 
    p.id,
    p.first_name || ' ' || p.last_name,
    7,
    '2023-2024',
    (SELECT id FROM profiles WHERE role_id = 1 LIMIT 1)
FROM profiles p
WHERE p.role_id = 2 -- Teacher role
AND p.email LIKE '%santos%'
LIMIT 1
ON CONFLICT DO NOTHING;

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Composite indexes for common queries
CREATE INDEX idx_coord_assignments_active_grade 
    ON coordinator_assignments(is_active, grade_level);

CREATE INDEX idx_section_metrics_lookup 
    ON section_performance_metrics(grade_level, quarter, school_year);

CREATE INDEX idx_password_resets_pending 
    ON student_password_resets(status, requested_at)
    WHERE status = 'pending';

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE coordinator_assignments IS 'Grade level coordinator role assignments';
COMMENT ON TABLE coordinator_activity_log IS 'Audit log of coordinator actions';
COMMENT ON TABLE grade_verifications IS 'Grade verification records by coordinators';
COMMENT ON TABLE section_performance_metrics IS 'Cached performance metrics for sections';
COMMENT ON TABLE grade_level_announcements IS 'Announcements sent to entire grade levels';
COMMENT ON TABLE student_password_resets IS 'Student password reset requests and history';