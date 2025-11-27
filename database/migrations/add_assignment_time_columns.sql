-- =====================================================
-- PHASE 5: Add start_time and end_time columns to assignments table
-- =====================================================
-- Migration: Add assignment lifecycle time columns
-- Created: 2025-11-26
-- Purpose: Enable assignment scheduling and automatic archiving
--
-- Timeline:
--   [start_time] ────── [due_date] ────── [end_time]
--        │                   │                  │
--     Appears            Deadline          Disappears
--   to students          (Late?)           (History)
--
-- States:
--   1. Before start_time: NOT visible to students
--   2. start_time to due_date: ACTIVE (on-time)
--   3. due_date to end_time: ACTIVE (late, if allowed)
--   4. After end_time: HISTORY (read-only)
-- =====================================================

-- Add start_time column (when assignment becomes visible to students)
ALTER TABLE public.assignments
ADD COLUMN IF NOT EXISTS start_time timestamp with time zone;

-- Add end_time column (when assignment moves to history)
ALTER TABLE public.assignments
ADD COLUMN IF NOT EXISTS end_time timestamp with time zone;

-- Add comment to start_time column
COMMENT ON COLUMN public.assignments.start_time IS 
'Timestamp when assignment becomes visible to students. NULL = visible immediately.';

-- Add comment to end_time column
COMMENT ON COLUMN public.assignments.end_time IS 
'Timestamp when assignment moves to history (read-only). NULL = never expires.';

-- Add check constraint to ensure logical timeline
-- start_time < due_date < end_time (when all are set)
ALTER TABLE public.assignments
ADD CONSTRAINT check_assignment_timeline 
CHECK (
  (start_time IS NULL OR due_date IS NULL OR start_time <= due_date) AND
  (due_date IS NULL OR end_time IS NULL OR due_date <= end_time) AND
  (start_time IS NULL OR end_time IS NULL OR start_time < end_time)
);

-- Create index for efficient time-based queries
CREATE INDEX IF NOT EXISTS idx_assignments_start_time 
ON public.assignments(start_time) 
WHERE start_time IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_assignments_end_time 
ON public.assignments(end_time) 
WHERE end_time IS NOT NULL;

-- Create composite index for active assignments query
CREATE INDEX IF NOT EXISTS idx_assignments_active_time_range 
ON public.assignments(classroom_id, start_time, end_time, is_active) 
WHERE is_active = true;

-- =====================================================
-- Helper Function: Get assignment status based on time
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_assignment_status(
  p_start_time timestamp with time zone,
  p_due_date timestamp with time zone,
  p_end_time timestamp with time zone,
  p_allow_late boolean DEFAULT true
)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_now timestamp with time zone := now();
BEGIN
  -- Not yet visible
  IF p_start_time IS NOT NULL AND v_now < p_start_time THEN
    RETURN 'scheduled';
  END IF;
  
  -- Ended (moved to history)
  IF p_end_time IS NOT NULL AND v_now >= p_end_time THEN
    RETURN 'ended';
  END IF;
  
  -- Late period
  IF p_due_date IS NOT NULL AND v_now > p_due_date THEN
    IF p_allow_late THEN
      RETURN 'late';
    ELSE
      RETURN 'closed';
    END IF;
  END IF;
  
  -- Active (on-time)
  RETURN 'active';
END;
$$;

COMMENT ON FUNCTION public.get_assignment_status IS 
'Returns assignment status based on current time: scheduled, active, late, closed, or ended';

-- =====================================================
-- Update existing assignments (backward compatibility)
-- =====================================================
-- For existing assignments without start_time/end_time:
-- - start_time = NULL (visible immediately)
-- - end_time = NULL (never expires)
-- This ensures backward compatibility with existing assignments

-- Optional: Set start_time to created_at for existing assignments
-- Uncomment if you want existing assignments to have a start_time
-- UPDATE public.assignments
-- SET start_time = created_at
-- WHERE start_time IS NULL;

-- Optional: Set end_time to 30 days after due_date for existing assignments
-- Uncomment if you want existing assignments to auto-expire
-- UPDATE public.assignments
-- SET end_time = due_date + INTERVAL '30 days'
-- WHERE end_time IS NULL AND due_date IS NOT NULL;

-- =====================================================
-- Verification Queries
-- =====================================================
-- Run these queries to verify the migration:

-- 1. Check columns were added
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'assignments' 
-- AND column_name IN ('start_time', 'end_time');

-- 2. Check constraint was added
-- SELECT constraint_name, check_clause
-- FROM information_schema.check_constraints
-- WHERE constraint_name = 'check_assignment_timeline';

-- 3. Check indexes were created
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'assignments'
-- AND indexname LIKE '%time%';

-- 4. Test helper function
-- SELECT public.get_assignment_status(
--   now() - INTERVAL '1 day',  -- start_time (past)
--   now() + INTERVAL '7 days', -- due_date (future)
--   now() + INTERVAL '14 days', -- end_time (future)
--   true                        -- allow_late
-- ); -- Should return 'active'

-- =====================================================
-- Migration Complete
-- =====================================================

