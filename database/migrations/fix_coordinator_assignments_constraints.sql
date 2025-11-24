-- =====================================================
-- Fix Coordinator Assignments Table Constraints
-- =====================================================
-- This migration fixes incorrect unique constraints that were preventing
-- historical records and proper coordinator reassignments.
--
-- PROBLEM:
-- 1. coordinator_assignments_grade_level_key - Prevented ANY record with same grade_level (even inactive)
-- 2. coordinator_assignments_school_year_key - Prevented ANY record with same school_year (completely wrong)
--
-- SOLUTION:
-- Replace with partial unique indexes that only apply to active records
-- =====================================================

-- Drop incorrect unique constraints
ALTER TABLE coordinator_assignments 
DROP CONSTRAINT IF EXISTS coordinator_assignments_grade_level_key;

ALTER TABLE coordinator_assignments 
DROP CONSTRAINT IF EXISTS coordinator_assignments_school_year_key;

-- Create correct partial unique indexes (only for active records)

-- Ensure only one active coordinator per grade level
CREATE UNIQUE INDEX IF NOT EXISTS idx_coordinator_assignments_active_grade 
ON coordinator_assignments(grade_level) 
WHERE is_active = true;

-- Ensure only one active assignment per teacher (already exists, but included for completeness)
CREATE UNIQUE INDEX IF NOT EXISTS idx_coordinator_assignments_active_teacher 
ON coordinator_assignments(teacher_id) 
WHERE is_active = true;

-- =====================================================
-- RESULT:
-- ✅ Allows historical records (inactive assignments)
-- ✅ Prevents duplicate active assignments for same grade
-- ✅ Prevents duplicate active assignments for same teacher
-- ✅ Allows proper reassignment workflow (deactivate old, create new)
-- =====================================================

-- Verify constraints
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition 
FROM pg_constraint 
WHERE conrelid = 'coordinator_assignments'::regclass
ORDER BY conname;

-- Verify indexes
SELECT 
    indexname,
    indexdef 
FROM pg_indexes 
WHERE tablename = 'coordinator_assignments' 
ORDER BY indexname;

