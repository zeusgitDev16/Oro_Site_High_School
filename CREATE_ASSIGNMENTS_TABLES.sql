-- ============================================================================
-- ASSIGNMENT MANAGEMENT SYSTEM - DATABASE SCHEMA
-- ============================================================================
-- This script creates all necessary tables for the assignment management system
-- including assignments, submissions, and related tables with proper RLS policies
-- ============================================================================

-- ============================================================================
-- TABLE: assignments
-- Stores all assignment information created by teachers
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Basic Information
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    
    -- Assignment Type
    assignment_type TEXT NOT NULL CHECK (assignment_type IN (
        'quiz', 
        'multiple_choice', 
        'identification', 
        'matching_type', 
        'file_upload', 
        'essay'
    )),
    
    -- Points and Deadline
    total_points INTEGER NOT NULL CHECK (total_points > 0),
    due_date TIMESTAMP WITH TIME ZONE,
    
    -- Late Submission Policy
    allow_late_submissions BOOLEAN DEFAULT true,
    
    -- Assignment Content (JSONB for flexibility)
    content JSONB DEFAULT '{}'::jsonb,
    
    -- Status
    is_published BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    view_count INTEGER DEFAULT 0,
    submission_count INTEGER DEFAULT 0
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_assignments_classroom_id ON public.assignments(classroom_id);
CREATE INDEX IF NOT EXISTS idx_assignments_teacher_id ON public.assignments(teacher_id);
CREATE INDEX IF NOT EXISTS idx_assignments_due_date ON public.assignments(due_date);
CREATE INDEX IF NOT EXISTS idx_assignments_assignment_type ON public.assignments(assignment_type);
CREATE INDEX IF NOT EXISTS idx_assignments_is_active ON public.assignments(is_active);

-- Add comment to table
COMMENT ON TABLE public.assignments IS 'Stores all assignments created by teachers for their classrooms';

-- ============================================================================
-- TABLE: assignment_submissions
-- Stores student submissions for assignments
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.assignment_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- References
    assignment_id UUID NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
    
    -- Submission Content
    submission_content JSONB DEFAULT '{}'::jsonb,
    
    -- Submission Status
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'graded', 'returned')),
    submitted_at TIMESTAMP WITH TIME ZONE,
    is_late BOOLEAN DEFAULT false,
    
    -- Grading
    score INTEGER,
    max_score INTEGER,
    feedback TEXT,
    graded_at TIMESTAMP WITH TIME ZONE,
    graded_by UUID REFERENCES auth.users(id),
    
    -- Metadata
    attempt_number INTEGER DEFAULT 1,
    time_spent_seconds INTEGER DEFAULT 0,
    
    -- Unique constraint: one submission per student per assignment
    UNIQUE(assignment_id, student_id)
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_submissions_assignment_id ON public.assignment_submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student_id ON public.assignment_submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_submissions_classroom_id ON public.assignment_submissions(classroom_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON public.assignment_submissions(status);
CREATE INDEX IF NOT EXISTS idx_submissions_is_late ON public.assignment_submissions(is_late);

-- Add comment
COMMENT ON TABLE public.assignment_submissions IS 'Stores student submissions for assignments';

-- ============================================================================
-- TABLE: assignment_files
-- Stores file attachments for assignments and submissions
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.assignment_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- References (either assignment or submission)
    assignment_id UUID REFERENCES public.assignments(id) ON DELETE CASCADE,
    submission_id UUID REFERENCES public.assignment_submissions(id) ON DELETE CASCADE,
    
    -- File Information
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    file_type TEXT NOT NULL,
    
    -- Uploaded by
    uploaded_by UUID NOT NULL REFERENCES auth.users(id),
    
    -- Metadata
    description TEXT,
    
    -- Check: must belong to either assignment or submission
    CHECK (
        (assignment_id IS NOT NULL AND submission_id IS NULL) OR
        (assignment_id IS NULL AND submission_id IS NOT NULL)
    )
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_assignment_files_assignment_id ON public.assignment_files(assignment_id);
CREATE INDEX IF NOT EXISTS idx_assignment_files_submission_id ON public.assignment_files(submission_id);
CREATE INDEX IF NOT EXISTS idx_assignment_files_uploaded_by ON public.assignment_files(uploaded_by);

-- Add comment
COMMENT ON TABLE public.assignment_files IS 'Stores file attachments for assignments and submissions';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignment_files ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES: assignments
-- ============================================================================

-- Policy: Teachers can view assignments in their classrooms
CREATE POLICY "Teachers can view their classroom assignments"
    ON public.assignments
    FOR SELECT
    USING (
        teacher_id = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM public.classrooms
            WHERE classrooms.id = assignments.classroom_id
            AND classrooms.teacher_id = auth.uid()
        )
    );

-- Policy: Teachers can create assignments in their classrooms
CREATE POLICY "Teachers can create assignments in their classrooms"
    ON public.assignments
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.classrooms
            WHERE classrooms.id = classroom_id
            AND classrooms.teacher_id = auth.uid()
        )
    );

-- Policy: Teachers can update their assignments
CREATE POLICY "Teachers can update their assignments"
    ON public.assignments
    FOR UPDATE
    USING (
        teacher_id = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM public.classrooms
            WHERE classrooms.id = assignments.classroom_id
            AND classrooms.teacher_id = auth.uid()
        )
    );

-- Policy: Teachers can delete their assignments
CREATE POLICY "Teachers can delete their assignments"
    ON public.assignments
    FOR DELETE
    USING (
        teacher_id = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM public.classrooms
            WHERE classrooms.id = assignments.classroom_id
            AND classrooms.teacher_id = auth.uid()
        )
    );

-- Policy: Students can view published assignments in their enrolled classrooms
CREATE POLICY "Students can view assignments in enrolled classrooms"
    ON public.assignments
    FOR SELECT
    USING (
        is_published = true
        AND is_active = true
        AND EXISTS (
            SELECT 1 FROM public.classroom_students
            WHERE classroom_students.classroom_id = assignments.classroom_id
            AND classroom_students.student_id = auth.uid()
        )
        AND (
            -- If late submissions not allowed, hide after due date
            allow_late_submissions = true
            OR due_date IS NULL
            OR due_date > NOW()
        )
    );

-- ============================================================================
-- RLS POLICIES: assignment_submissions
-- ============================================================================

-- Policy: Students can view their own submissions
CREATE POLICY "Students can view their own submissions"
    ON public.assignment_submissions
    FOR SELECT
    USING (student_id = auth.uid());

-- Policy: Students can create their own submissions
CREATE POLICY "Students can create their own submissions"
    ON public.assignment_submissions
    FOR INSERT
    WITH CHECK (
        student_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.classroom_students
            WHERE classroom_students.classroom_id = assignment_submissions.classroom_id
            AND classroom_students.student_id = auth.uid()
        )
    );

-- Policy: Students can update their own submissions (before grading)
CREATE POLICY "Students can update their own submissions"
    ON public.assignment_submissions
    FOR UPDATE
    USING (
        student_id = auth.uid()
        AND status IN ('draft', 'submitted')
    );

-- Policy: Teachers can view submissions in their classrooms
CREATE POLICY "Teachers can view classroom submissions"
    ON public.assignment_submissions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.assignments
            WHERE assignments.id = assignment_submissions.assignment_id
            AND assignments.teacher_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM public.classrooms
            WHERE classrooms.id = assignment_submissions.classroom_id
            AND classrooms.teacher_id = auth.uid()
        )
    );

-- Policy: Teachers can update submissions (for grading)
CREATE POLICY "Teachers can grade submissions"
    ON public.assignment_submissions
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.assignments
            WHERE assignments.id = assignment_submissions.assignment_id
            AND assignments.teacher_id = auth.uid()
        )
    );

-- ============================================================================
-- RLS POLICIES: assignment_files
-- ============================================================================

-- Policy: Users can view files they uploaded
CREATE POLICY "Users can view their uploaded files"
    ON public.assignment_files
    FOR SELECT
    USING (uploaded_by = auth.uid());

-- Policy: Teachers can view files in their assignments
CREATE POLICY "Teachers can view assignment files"
    ON public.assignment_files
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.assignments
            WHERE assignments.id = assignment_files.assignment_id
            AND assignments.teacher_id = auth.uid()
        )
    );

-- Policy: Students can view files in assignments they're enrolled in
CREATE POLICY "Students can view assignment files in enrolled classrooms"
    ON public.assignment_files
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.assignments
            JOIN public.classroom_students ON classroom_students.classroom_id = assignments.classroom_id
            WHERE assignments.id = assignment_files.assignment_id
            AND classroom_students.student_id = auth.uid()
        )
    );

-- Policy: Users can insert their own files
CREATE POLICY "Users can upload files"
    ON public.assignment_files
    FOR INSERT
    WITH CHECK (uploaded_by = auth.uid());

-- Policy: Users can delete their own files
CREATE POLICY "Users can delete their files"
    ON public.assignment_files
    FOR DELETE
    USING (uploaded_by = auth.uid());

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update assignments.updated_at
DROP TRIGGER IF EXISTS update_assignments_updated_at ON public.assignments;
CREATE TRIGGER update_assignments_updated_at
    BEFORE UPDATE ON public.assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Update assignment_submissions.updated_at
DROP TRIGGER IF EXISTS update_submissions_updated_at ON public.assignment_submissions;
CREATE TRIGGER update_submissions_updated_at
    BEFORE UPDATE ON public.assignment_submissions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function: Check if submission is late
CREATE OR REPLACE FUNCTION check_submission_late()
RETURNS TRIGGER AS $$
DECLARE
    assignment_due_date TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Get the assignment due date
    SELECT due_date INTO assignment_due_date
    FROM public.assignments
    WHERE id = NEW.assignment_id;
    
    -- If there's a due date and submission is after it, mark as late
    IF assignment_due_date IS NOT NULL AND NEW.submitted_at > assignment_due_date THEN
        NEW.is_late = true;
    ELSE
        NEW.is_late = false;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Check if submission is late when submitted
DROP TRIGGER IF EXISTS check_submission_late_trigger ON public.assignment_submissions;
CREATE TRIGGER check_submission_late_trigger
    BEFORE INSERT OR UPDATE OF submitted_at ON public.assignment_submissions
    FOR EACH ROW
    WHEN (NEW.submitted_at IS NOT NULL)
    EXECUTE FUNCTION check_submission_late();

-- Function: Update assignment submission count
CREATE OR REPLACE FUNCTION update_assignment_submission_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.assignments
        SET submission_count = submission_count + 1
        WHERE id = NEW.assignment_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.assignments
        SET submission_count = GREATEST(0, submission_count - 1)
        WHERE id = OLD.assignment_id;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update submission count
DROP TRIGGER IF EXISTS update_submission_count_trigger ON public.assignment_submissions;
CREATE TRIGGER update_submission_count_trigger
    AFTER INSERT OR DELETE ON public.assignment_submissions
    FOR EACH ROW
    EXECUTE FUNCTION update_assignment_submission_count();

-- ============================================================================
-- STORAGE BUCKET FOR ASSIGNMENT FILES
-- ============================================================================

-- Create storage bucket for assignment files (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('assignment_files', 'assignment_files', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: Users can upload files
CREATE POLICY "Users can upload assignment files"
    ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'assignment_files'
        AND auth.uid() IS NOT NULL
    );

-- Storage policy: Users can view files they have access to
CREATE POLICY "Users can view assignment files"
    ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'assignment_files'
        AND auth.uid() IS NOT NULL
    );

-- Storage policy: Users can delete their own files
CREATE POLICY "Users can delete their assignment files"
    ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'assignment_files'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assignments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assignment_submissions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assignment_files TO authenticated;

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- SAMPLE DATA (OPTIONAL - FOR TESTING)
-- ============================================================================

-- Uncomment below to insert sample data for testing

/*
-- Sample assignment (replace UUIDs with actual values from your database)
INSERT INTO public.assignments (
    classroom_id,
    teacher_id,
    title,
    description,
    assignment_type,
    total_points,
    due_date,
    allow_late_submissions,
    content
) VALUES (
    'your-classroom-uuid-here',
    'your-teacher-uuid-here',
    'Sample Math Quiz',
    'This is a sample quiz to test the system',
    'quiz',
    50,
    NOW() + INTERVAL '7 days',
    true,
    '{"questions": [{"question": "What is 2+2?", "answer": "4", "points": 10}]}'::jsonb
);
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if tables were created successfully
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_name IN ('assignments', 'assignment_submissions', 'assignment_files')
ORDER BY table_name;

-- Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename IN ('assignments', 'assignment_submissions', 'assignment_files')
ORDER BY tablename, policyname;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'ASSIGNMENT MANAGEMENT SYSTEM - DATABASE SETUP COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'Tables created:';
    RAISE NOTICE '  ✓ assignments';
    RAISE NOTICE '  ✓ assignment_submissions';
    RAISE NOTICE '  ✓ assignment_files';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies configured for all tables';
    RAISE NOTICE 'Triggers and functions created';
    RAISE NOTICE 'Storage bucket configured: assignment_files';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Verify tables in Supabase dashboard';
    RAISE NOTICE '  2. Test RLS policies with different user roles';
    RAISE NOTICE '  3. Integrate with Flutter application';
    RAISE NOTICE '============================================================================';
END $$;
