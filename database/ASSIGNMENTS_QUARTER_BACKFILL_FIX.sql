-- ASSIGNMENTS_QUARTER_BACKFILL_FIX.sql
-- Instruction: Run once in Supabase SQL editor to normalize quarter_no from content.meta for existing rows.
-- Purpose: Ensure all assignments with meta.quarter_no also have the quarter_no column set so quarter tabs work.
-- Idempotent: All updates are conditional and safe to re-run.

SET search_path TO public;

BEGIN;

-- 1) Backfill quarter_no from content.meta when column is still NULL
UPDATE public.assignments a
SET quarter_no = NULLIF((a.content->'meta'->>'quarter_no'), '')::smallint
WHERE a.quarter_no IS NULL
  AND (a.content->'meta'->>'quarter_no') IS NOT NULL;

COMMIT;

