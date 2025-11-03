-- TEMPORARY FIX: Disable RLS for classroom content tables
-- This allows students to access content while we work on proper RLS
-- WARNING: This is less secure but prevents infinite recursion

-- Disable RLS on classroom_courses (junction table)
ALTER TABLE classroom_courses DISABLE ROW LEVEL SECURITY;

-- Disable RLS on courses
ALTER TABLE courses DISABLE ROW LEVEL SECURITY;

-- Disable RLS on course_modules
ALTER TABLE course_modules DISABLE ROW LEVEL SECURITY;

-- Disable RLS on course_assignments (if exists)
ALTER TABLE course_assignments DISABLE ROW LEVEL SECURITY;

-- Note: classrooms and classroom_students still have RLS enabled
-- This provides basic security while allowing content access
