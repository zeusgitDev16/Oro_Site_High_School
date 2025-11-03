-- Scanner Integration Database Schema
-- Tables for integrating with the external attendance scanner subsystem

-- =====================================================
-- Scanner Data Table (populated by scanner subsystem)
-- =====================================================
CREATE TABLE IF NOT EXISTS scanner_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_lrn VARCHAR(12) NOT NULL,
    scan_time TIMESTAMP NOT NULL,
    scan_type VARCHAR(10) NOT NULL CHECK (scan_type IN ('in', 'out')),
    device_id VARCHAR(100),
    location VARCHAR(100),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for performance
    INDEX idx_scanner_data_lrn (student_lrn),
    INDEX idx_scanner_data_time (scan_time),
    INDEX idx_scanner_data_created (created_at DESC)
);

-- =====================================================
-- Scanner Sessions Table (shared with scanner subsystem)
-- =====================================================
CREATE TABLE IF NOT EXISTS scanner_sessions (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL REFERENCES attendance_sessions(id),
    course_id INT NOT NULL,
    section_id INT,
    teacher_id UUID NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    scan_deadline TIMESTAMP NOT NULL,
    allow_student_scanning BOOLEAN DEFAULT FALSE,
    authorized_scanners TEXT[], -- Array of student IDs allowed to scan
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_scanner_sessions_status (status),
    INDEX idx_scanner_sessions_time (start_time, end_time)
);

-- =====================================================
-- Scan Activity Log (audit trail)
-- =====================================================
CREATE TABLE IF NOT EXISTS scan_activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL,
    student_lrn VARCHAR(12) NOT NULL,
    session_id INT,
    scan_time TIMESTAMP NOT NULL,
    scan_type VARCHAR(10) NOT NULL,
    device_id VARCHAR(100),
    location VARCHAR(100),
    is_late BOOLEAN DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_scan_log_student (student_id),
    INDEX idx_scan_log_session (session_id),
    INDEX idx_scan_log_time (scan_time DESC),
    INDEX idx_scan_log_lrn (student_lrn)
);

-- =====================================================
-- Scanner Device Registry
-- =====================================================
CREATE TABLE IF NOT EXISTS scanner_devices (
    id VARCHAR(100) PRIMARY KEY,
    device_name VARCHAR(255) NOT NULL,
    device_type VARCHAR(50), -- 'mobile', 'tablet', 'kiosk', 'handheld'
    location VARCHAR(100),
    assigned_to UUID, -- User ID if assigned to specific person
    is_active BOOLEAN DEFAULT TRUE,
    last_seen TIMESTAMP,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- =====================================================
-- Scanner Queue (for offline/failed scans)
-- =====================================================
CREATE TABLE IF NOT EXISTS scanner_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scan_data JSONB NOT NULL,
    retry_count INT DEFAULT 0,
    max_retries INT DEFAULT 3,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    
    -- Index for queue processing
    INDEX idx_scanner_queue_status (status, created_at)
);

-- =====================================================
-- Scanner Statistics (aggregated data)
-- =====================================================
CREATE TABLE IF NOT EXISTS scanner_statistics (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    session_id INT,
    total_scans INT DEFAULT 0,
    successful_scans INT DEFAULT 0,
    failed_scans INT DEFAULT 0,
    on_time_scans INT DEFAULT 0,
    late_scans INT DEFAULT 0,
    unique_students INT DEFAULT 0,
    average_scan_time INTERVAL,
    peak_hour TIME,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Unique constraint for daily stats
    UNIQUE(date, session_id),
    
    -- Index for queries
    INDEX idx_scanner_stats_date (date DESC)
);

-- =====================================================
-- Real-time Subscriptions Setup
-- =====================================================

-- Enable real-time for scanner_data table
ALTER TABLE scanner_data REPLICA IDENTITY FULL;

-- Enable real-time for scanner_sessions table
ALTER TABLE scanner_sessions REPLICA IDENTITY FULL;

-- Enable real-time for scan_activity_log table
ALTER TABLE scan_activity_log REPLICA IDENTITY FULL;

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE scanner_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE scanner_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE scan_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE scanner_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE scanner_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE scanner_statistics ENABLE ROW LEVEL SECURITY;

-- Scanner Data Policies
CREATE POLICY "Scanner devices can insert scan data"
    ON scanner_data FOR INSERT
    WITH CHECK (true); -- Scanner subsystem has full insert access

CREATE POLICY "Teachers can view scan data for their sessions"
    ON scanner_data FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM scanner_sessions ss
            WHERE ss.teacher_id = auth.uid()
            AND ss.start_time <= scanner_data.scan_time
            AND ss.end_time >= scanner_data.scan_time
        )
    );

CREATE POLICY "Admins can view all scan data"
    ON scanner_data FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role_id = 1 -- Admin role
        )
    );

-- Scanner Sessions Policies
CREATE POLICY "Teachers can create scanner sessions"
    ON scanner_sessions FOR INSERT
    WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can view their scanner sessions"
    ON scanner_sessions FOR SELECT
    USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can update their scanner sessions"
    ON scanner_sessions FOR UPDATE
    USING (teacher_id = auth.uid());

-- Scan Activity Log Policies
CREATE POLICY "System can insert scan logs"
    ON scan_activity_log FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Teachers can view scan logs for their sessions"
    ON scan_activity_log FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM scanner_sessions ss
            WHERE ss.session_id = scan_activity_log.session_id
            AND ss.teacher_id = auth.uid()
        )
    );

CREATE POLICY "Students can view their own scan logs"
    ON scan_activity_log FOR SELECT
    USING (student_id = auth.uid());

-- =====================================================
-- Functions and Triggers
-- =====================================================

-- Function to process scanner data and create attendance record
CREATE OR REPLACE FUNCTION process_scanner_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Log the scan activity
    INSERT INTO scan_activity_log (
        student_id,
        student_lrn,
        session_id,
        scan_time,
        scan_type,
        device_id,
        location,
        metadata
    )
    SELECT 
        s.id,
        NEW.student_lrn,
        ss.session_id,
        NEW.scan_time,
        NEW.scan_type,
        NEW.device_id,
        NEW.location,
        NEW.metadata
    FROM students s
    LEFT JOIN scanner_sessions ss ON (
        NEW.scan_time BETWEEN ss.start_time AND ss.end_time
        AND ss.status = 'active'
    )
    WHERE s.lrn = NEW.student_lrn;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to process scanner data
CREATE TRIGGER trigger_process_scanner_data
    AFTER INSERT ON scanner_data
    FOR EACH ROW
    EXECUTE FUNCTION process_scanner_data();

-- Function to update scanner statistics
CREATE OR REPLACE FUNCTION update_scanner_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update or insert daily statistics
    INSERT INTO scanner_statistics (
        date,
        session_id,
        total_scans,
        successful_scans,
        on_time_scans,
        late_scans
    )
    VALUES (
        DATE(NEW.scan_time),
        NEW.session_id,
        1,
        1,
        CASE WHEN NEW.is_late THEN 0 ELSE 1 END,
        CASE WHEN NEW.is_late THEN 1 ELSE 0 END
    )
    ON CONFLICT (date, session_id) DO UPDATE
    SET 
        total_scans = scanner_statistics.total_scans + 1,
        successful_scans = scanner_statistics.successful_scans + 1,
        on_time_scans = scanner_statistics.on_time_scans + 
            CASE WHEN NEW.is_late THEN 0 ELSE 1 END,
        late_scans = scanner_statistics.late_scans + 
            CASE WHEN NEW.is_late THEN 1 ELSE 0 END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update statistics
CREATE TRIGGER trigger_update_scanner_statistics
    AFTER INSERT ON scan_activity_log
    FOR EACH ROW
    EXECUTE FUNCTION update_scanner_statistics();

-- Function to auto-expire scanner sessions
CREATE OR REPLACE FUNCTION auto_expire_scanner_sessions()
RETURNS void AS $$
BEGIN
    UPDATE scanner_sessions
    SET status = 'completed'
    WHERE status = 'active'
    AND end_time < NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Sample Data for Testing
-- =====================================================

-- Insert sample scanner device
INSERT INTO scanner_devices (id, device_name, device_type, location)
VALUES 
    ('SCANNER-001', 'Main Entrance Scanner', 'kiosk', 'Main Gate'),
    ('SCANNER-002', 'Library Scanner', 'tablet', 'Library Entrance'),
    ('SCANNER-003', 'Gym Scanner', 'mobile', 'Gymnasium')
ON CONFLICT DO NOTHING;

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Composite indexes for common queries
CREATE INDEX idx_scanner_data_session_lookup 
    ON scanner_data(scan_time, student_lrn);

CREATE INDEX idx_scan_log_daily_stats 
    ON scan_activity_log(DATE(scan_time), session_id, is_late);

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE scanner_data IS 'Raw scan data from the external scanner subsystem';
COMMENT ON TABLE scanner_sessions IS 'Active scanning sessions shared with scanner subsystem';
COMMENT ON TABLE scan_activity_log IS 'Processed scan records with attendance context';
COMMENT ON TABLE scanner_devices IS 'Registry of authorized scanner devices';
COMMENT ON TABLE scanner_queue IS 'Queue for offline or failed scans to be reprocessed';
COMMENT ON TABLE scanner_statistics IS 'Aggregated statistics for reporting and analytics';