-- =====================================================
-- Subject Resources Table
-- Purpose: Store modules, assignment resources, and assignments per quarter
-- =====================================================

-- Create the subject_resources table
CREATE TABLE IF NOT EXISTS subject_resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subject_id UUID NOT NULL REFERENCES classroom_subjects(id) ON DELETE CASCADE,
  
  -- Resource metadata
  resource_name TEXT NOT NULL,
  resource_type TEXT NOT NULL CHECK (resource_type IN ('module', 'assignment_resource', 'assignment')),
  quarter INTEGER NOT NULL CHECK (quarter BETWEEN 1 AND 4),
  
  -- File information
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size BIGINT NOT NULL, -- in bytes
  file_type TEXT NOT NULL, -- pdf, docx, pptx, xlsx, png, jpeg, mp4
  
  -- Versioning support
  version INTEGER DEFAULT 1,
  is_latest_version BOOLEAN DEFAULT true,
  previous_version_id UUID REFERENCES subject_resources(id),
  
  -- Ordering and organization
  display_order INTEGER DEFAULT 0,
  
  -- Metadata
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  
  -- Audit fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  uploaded_by UUID REFERENCES auth.users(id)
);

-- Create partial unique index for latest versions only
CREATE UNIQUE INDEX unique_latest_resource_idx
  ON subject_resources(subject_id, quarter, resource_name, resource_type)
  WHERE is_latest_version = true;

-- =====================================================
-- Indexes for Performance
-- =====================================================

CREATE INDEX idx_subject_resources_subject_id ON subject_resources(subject_id);
CREATE INDEX idx_subject_resources_quarter ON subject_resources(quarter);
CREATE INDEX idx_subject_resources_type ON subject_resources(resource_type);
CREATE INDEX idx_subject_resources_active ON subject_resources(is_active);
CREATE INDEX idx_subject_resources_latest ON subject_resources(is_latest_version) WHERE is_latest_version = true;
CREATE INDEX idx_subject_resources_created_by ON subject_resources(created_by);

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS
ALTER TABLE subject_resources ENABLE ROW LEVEL SECURITY;

-- Policy 1: Admins have full access to all resources
CREATE POLICY "Admins have full access to subject resources"
  ON subject_resources
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admins
      WHERE admins.id = auth.uid()
      AND admins.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admins
      WHERE admins.id = auth.uid()
      AND admins.is_active = true
    )
  );

-- Policy 2: Teachers can view modules and assignment resources
CREATE POLICY "Teachers can view modules and assignment resources"
  ON subject_resources
  FOR SELECT
  TO authenticated
  USING (
    resource_type IN ('module', 'assignment_resource')
    AND EXISTS (
      SELECT 1 FROM teachers
      WHERE teachers.id = auth.uid()
      AND teachers.is_active = true
    )
  );

-- Policy 3: Teachers can CRUD their own assignments
CREATE POLICY "Teachers can manage their own assignments"
  ON subject_resources
  FOR ALL
  TO authenticated
  USING (
    resource_type = 'assignment'
    AND EXISTS (
      SELECT 1 FROM teachers
      WHERE teachers.id = auth.uid()
      AND teachers.is_active = true
    )
  )
  WITH CHECK (
    resource_type = 'assignment'
    AND EXISTS (
      SELECT 1 FROM teachers
      WHERE teachers.id = auth.uid()
      AND teachers.is_active = true
    )
  );

-- Policy 4: Students can view modules and assignments only
CREATE POLICY "Students can view modules and assignments"
  ON subject_resources
  FOR SELECT
  TO authenticated
  USING (
    resource_type IN ('module', 'assignment')
    AND is_active = true
    AND EXISTS (
      SELECT 1 FROM students
      WHERE students.user_id = auth.uid()
      AND students.is_active = true
    )
  );

-- =====================================================
-- Trigger: Update updated_at timestamp
-- =====================================================

CREATE OR REPLACE FUNCTION update_subject_resources_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_subject_resources_updated_at
  BEFORE UPDATE ON subject_resources
  FOR EACH ROW
  EXECUTE FUNCTION update_subject_resources_updated_at();

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE subject_resources IS 'Stores modules, assignment resources, and assignments organized by quarter';
COMMENT ON COLUMN subject_resources.resource_type IS 'Type: module (admin), assignment_resource (admin), assignment (teacher)';
COMMENT ON COLUMN subject_resources.quarter IS 'Academic quarter: 1, 2, 3, or 4';
COMMENT ON COLUMN subject_resources.version IS 'Version number for file versioning support';
COMMENT ON COLUMN subject_resources.is_latest_version IS 'Flag to identify the latest version of a resource';
COMMENT ON COLUMN subject_resources.previous_version_id IS 'Reference to the previous version of this resource';

