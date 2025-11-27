-- ============================================================================
-- RPC Functions for Fetching Classroom Students and Teachers with Profiles
-- ============================================================================
-- These functions bypass RLS complexity by using SECURITY DEFINER
-- They enforce proper access control within the function logic
-- Created: 2025-11-26
-- Purpose: Fix issue where teachers cannot see enrolled students in gradebook/classroom
-- ============================================================================

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_classroom_students_with_profile(UUID);
DROP FUNCTION IF EXISTS get_classroom_teachers_with_profile(UUID);

-- ============================================================================
-- Function: get_classroom_students_with_profile
-- ============================================================================
-- Fetches all students enrolled in a classroom with their profile information
-- Access Control:
--   - Admins: Can view all classroom students
--   - Teachers: Can view students in classrooms they own or co-teach
--   - Students: Can view students in classrooms they are enrolled in
-- ============================================================================

CREATE OR REPLACE FUNCTION get_classroom_students_with_profile(
    p_classroom_id UUID
)
RETURNS TABLE (
    student_id UUID,
    full_name TEXT,
    email TEXT,
    enrolled_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_user_role TEXT;
    v_has_access BOOLEAN := FALSE;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get user role
    SELECT role INTO v_user_role
    FROM profiles
    WHERE id = v_user_id;
    
    -- Check access based on role
    IF v_user_role = 'admin' THEN
        -- Admins can view all classroom students
        v_has_access := TRUE;
    ELSIF v_user_role = 'teacher' THEN
        -- Teachers can view students in classrooms they own or co-teach
        SELECT EXISTS (
            -- Check if teacher owns the classroom
            SELECT 1 FROM classrooms
            WHERE id = p_classroom_id AND teacher_id = v_user_id
            
            UNION
            
            -- Check if teacher co-teaches the classroom
            SELECT 1 FROM classroom_teachers
            WHERE classroom_id = p_classroom_id AND teacher_id = v_user_id
            
            UNION
            
            -- Check if teacher teaches a subject in the classroom
            SELECT 1 FROM classroom_subjects
            WHERE classroom_id = p_classroom_id AND teacher_id = v_user_id
        ) INTO v_has_access;
    ELSIF v_user_role = 'student' THEN
        -- Students can view students in classrooms they are enrolled in
        SELECT EXISTS (
            SELECT 1 FROM classroom_students
            WHERE classroom_id = p_classroom_id AND student_id = v_user_id
        ) INTO v_has_access;
    END IF;
    
    -- If no access, return empty result
    IF NOT v_has_access THEN
        RETURN;
    END IF;
    
    -- Return students with profile information
    RETURN QUERY
    SELECT 
        cs.student_id,
        p.full_name,
        p.email,
        cs.enrolled_at
    FROM classroom_students cs
    INNER JOIN profiles p ON p.id = cs.student_id
    WHERE cs.classroom_id = p_classroom_id
    ORDER BY cs.enrolled_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_classroom_students_with_profile(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_classroom_students_with_profile IS 
'Fetches all students enrolled in a classroom with their profile information. Access is controlled based on user role.';

-- ============================================================================
-- Function: get_classroom_teachers_with_profile
-- ============================================================================
-- Fetches all co-teachers in a classroom with their profile information
-- Note: This does NOT include the classroom owner (teacher_id in classrooms table)
-- Access Control: Same as get_classroom_students_with_profile
-- ============================================================================

CREATE OR REPLACE FUNCTION get_classroom_teachers_with_profile(
    p_classroom_id UUID
)
RETURNS TABLE (
    teacher_id UUID,
    full_name TEXT,
    email TEXT,
    joined_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_user_role TEXT;
    v_has_access BOOLEAN := FALSE;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get user role
    SELECT role INTO v_user_role
    FROM profiles
    WHERE id = v_user_id;
    
    -- Check access based on role (same logic as students function)
    IF v_user_role = 'admin' THEN
        v_has_access := TRUE;
    ELSIF v_user_role = 'teacher' THEN
        SELECT EXISTS (
            SELECT 1 FROM classrooms WHERE id = p_classroom_id AND teacher_id = v_user_id
            UNION
            SELECT 1 FROM classroom_teachers WHERE classroom_id = p_classroom_id AND teacher_id = v_user_id
            UNION
            SELECT 1 FROM classroom_subjects WHERE classroom_id = p_classroom_id AND teacher_id = v_user_id
        ) INTO v_has_access;
    ELSIF v_user_role = 'student' THEN
        SELECT EXISTS (
            SELECT 1 FROM classroom_students WHERE classroom_id = p_classroom_id AND student_id = v_user_id
        ) INTO v_has_access;
    END IF;
    
    -- If no access, return empty result
    IF NOT v_has_access THEN
        RETURN;
    END IF;
    
    -- Return co-teachers with profile information
    RETURN QUERY
    SELECT 
        ct.teacher_id,
        p.full_name,
        p.email,
        ct.joined_at
    FROM classroom_teachers ct
    INNER JOIN profiles p ON p.id = ct.teacher_id
    WHERE ct.classroom_id = p_classroom_id
    ORDER BY ct.joined_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_classroom_teachers_with_profile(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_classroom_teachers_with_profile IS 
'Fetches all co-teachers in a classroom with their profile information. Does not include the classroom owner. Access is controlled based on user role.';

