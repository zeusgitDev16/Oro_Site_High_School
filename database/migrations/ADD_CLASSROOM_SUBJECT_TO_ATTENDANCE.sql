-- =====================================================
-- MIGRATION: Add classroom_id and subject_id to attendance table
-- PURPOSE: Support new classroom system while maintaining backward compatibility
-- DATE: 2025-11-27
-- =====================================================

-- Add new columns for new classroom system
ALTER TABLE public.attendance
ADD COLUMN IF NOT EXISTS classroom_id UUID REFERENCES public.classrooms(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS subject_id UUID REFERENCES public.classroom_subjects(id) ON DELETE SET NULL;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_attendance_classroom ON public.attendance(classroom_id);
CREATE INDEX IF NOT EXISTS idx_attendance_subject ON public.attendance(subject_id);

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS idx_attendance_subject_date ON public.attendance(subject_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_classroom_date ON public.attendance(classroom_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_student_subject ON public.attendance(student_id, subject_id);

-- Add comments for documentation
COMMENT ON COLUMN public.attendance.classroom_id IS 'Links to classrooms table (new system). NULL for old courses.';
COMMENT ON COLUMN public.attendance.subject_id IS 'Links to classroom_subjects table (new system). NULL for old courses.';

-- =====================================================
-- BACKWARD COMPATIBILITY NOTES:
-- =====================================================
-- 1. Old attendance records use course_id (bigint) - these remain unchanged
-- 2. New attendance records use classroom_id + subject_id (UUID)
-- 3. Both systems can coexist in the same table
-- 4. Queries should check both old and new fields with OR logic
-- 5. All existing RLS policies continue to work
-- =====================================================

-- Verify migration
DO $$
BEGIN
    -- Check if columns exist
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'classroom_id'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'subject_id'
    ) THEN
        RAISE NOTICE '✅ Migration successful: classroom_id and subject_id columns added to attendance table';
    ELSE
        RAISE EXCEPTION '❌ Migration failed: columns not created';
    END IF;
END $$;

