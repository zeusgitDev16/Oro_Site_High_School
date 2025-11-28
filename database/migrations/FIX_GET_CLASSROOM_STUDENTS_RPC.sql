-- ================================================================
-- FIX get_classroom_students_with_profile RPC FUNCTION
-- ================================================================
-- Date: 2025-11-27
-- Issue: RPC function checks profiles.role (NULL) instead of profiles.role_id
-- Impact: Admin cannot see enrolled students in "Manage Students" dialog
-- Solution: Replace function to use is_admin() and proper role checking
-- ================================================================

-- Drop the broken RPC function
DROP FUNCTION IF EXISTS public.get_classroom_students_with_profile(uuid);

-- Create new RPC function using proper role checking
CREATE OR REPLACE FUNCTION public.get_classroom_students_with_profile(p_classroom_id uuid)
RETURNS TABLE(student_id uuid, full_name text, email text, enrolled_at timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
    v_has_access BOOLEAN := FALSE;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();

    -- Check if user is admin using is_admin() function
    IF is_admin() THEN
        v_has_access := TRUE;
    ELSE
        -- Check if user is a teacher who manages this classroom
        SELECT EXISTS (
            -- Check if teacher owns the classroom
            SELECT 1
            FROM classrooms c
            WHERE c.id = p_classroom_id
              AND c.teacher_id = v_user_id

            UNION

            -- Check if teacher is a co-teacher
            SELECT 1
            FROM classroom_teachers ct
            WHERE ct.classroom_id = p_classroom_id
              AND ct.teacher_id = v_user_id

            UNION

            -- Check if teacher teaches a subject in this classroom
            SELECT 1
            FROM classroom_subjects csub
            WHERE csub.classroom_id = p_classroom_id
              AND csub.teacher_id = v_user_id
        ) INTO v_has_access;

        -- If not a teacher, check if user is a student enrolled in this classroom
        IF NOT v_has_access THEN
            SELECT EXISTS (
                SELECT 1
                FROM classroom_students cstud
                WHERE cstud.classroom_id = p_classroom_id
                  AND cstud.student_id = v_user_id
            ) INTO v_has_access;
        END IF;
    END IF;

    -- If user doesn't have access, return empty result
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
$function$;

-- ================================================================
-- VERIFICATION
-- ================================================================
-- Test the function with Amanpulo classroom
-- Should return 16 students for admin users
-- SELECT * FROM get_classroom_students_with_profile('a675fef0-bc95-4d3e-8eab-d1614fa376d0');
-- ================================================================

