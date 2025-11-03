-- Fix course_assignments table - Remove unique constraint on course_id
-- A course should be able to have multiple assignments

-- Drop the incorrect unique constraint
ALTER TABLE course_assignments 
DROP CONSTRAINT IF EXISTS course_assignments_course_id_key;

-- Verify the table structure
-- The table should allow multiple assignments per course
-- Only the primary key (id) should be unique

-- Check if there are any other constraints that might cause issues
-- You can run this query to see all constraints:
-- SELECT conname, contype FROM pg_constraint WHERE conrelid = 'course_assignments'::regclass;
