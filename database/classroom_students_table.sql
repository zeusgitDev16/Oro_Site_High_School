-- Classroom Students Table
-- Tracks student enrollment in classrooms

CREATE TABLE IF NOT EXISTS classroom_students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure a student can only enroll once per classroom
    UNIQUE(classroom_id, student_id)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_classroom_students_classroom ON classroom_students(classroom_id);
CREATE INDEX IF NOT EXISTS idx_classroom_students_student ON classroom_students(student_id);
CREATE INDEX IF NOT EXISTS idx_classroom_students_enrolled_at ON classroom_students(enrolled_at);

-- Enable Row Level Security
ALTER TABLE classroom_students ENABLE ROW LEVEL SECURITY;

-- Policy: Students can view their own enrollments
CREATE POLICY "Students can view own enrollments"
    ON classroom_students
    FOR SELECT
    USING (auth.uid() = student_id);

-- Policy: Students can enroll themselves
CREATE POLICY "Students can enroll themselves"
    ON classroom_students
    FOR INSERT
    WITH CHECK (auth.uid() = student_id);

-- Policy: Students can unenroll themselves
CREATE POLICY "Students can unenroll themselves"
    ON classroom_students
    FOR DELETE
    USING (auth.uid() = student_id);

-- Policy: Teachers can view classroom enrollments (non-recursive: no classrooms reference)
CREATE POLICY "Teachers can view classroom enrollments"
    ON classroom_students
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'teacher'
        )
    );

-- Policy: Admins can view all enrollments
CREATE POLICY "Admins can view all enrollments"
    ON classroom_students
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );
