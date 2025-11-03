-- Classroom Students Table - SIMPLE RLS (No Recursion)

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Students can view own enrollments" ON classroom_students;
DROP POLICY IF EXISTS "Students can enroll themselves" ON classroom_students;
DROP POLICY IF EXISTS "Students can unenroll themselves" ON classroom_students;
DROP POLICY IF EXISTS "Teachers can view classroom enrollments" ON classroom_students;
DROP POLICY IF EXISTS "Admins can view all enrollments" ON classroom_students;

-- Enable RLS
ALTER TABLE classroom_students ENABLE ROW LEVEL SECURITY;

-- ⭐ Students can view their own enrollments
CREATE POLICY "Students can view own enrollments"
    ON classroom_students
    FOR SELECT
    USING (auth.uid() = student_id);

-- ⭐ Students can enroll themselves
CREATE POLICY "Students can enroll themselves"
    ON classroom_students
    FOR INSERT
    WITH CHECK (auth.uid() = student_id);

-- ⭐ Students can unenroll themselves
CREATE POLICY "Students can unenroll themselves"
    ON classroom_students
    FOR DELETE
    USING (auth.uid() = student_id);

-- ⭐ Teachers can view enrollments (simple - no recursion)
CREATE POLICY "Teachers can view enrollments"
    ON classroom_students
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM classrooms
            WHERE classrooms.id = classroom_students.classroom_id
            AND classrooms.teacher_id = auth.uid()
        )
    );
