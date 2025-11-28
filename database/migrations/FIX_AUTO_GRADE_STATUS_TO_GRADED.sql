-- ============================================
-- FIX: Auto-Graded Submissions Should Have Status 'graded'
-- ============================================
-- Issue: Auto-graded assignments (quiz, multiple_choice, identification, matching_type)
--        are marked as 'submitted' instead of 'graded', causing gradebook to show
--        orange "submitted" icon instead of displaying the score.
--
-- Solution: Update RPC to set status = 'graded' for auto-graded types
--           and status = 'submitted' for manual-graded types (file_upload, essay)
--
-- Date: 2025-11-27
-- ============================================

-- Drop and recreate the function with fixed status logic
CREATE OR REPLACE FUNCTION public.auto_grade_and_submit_assignment(
  p_assignment_id bigint  -- Changed from uuid to bigint (assignments.id is bigint)
)
RETURNS TABLE (
  assignment_id bigint,
  student_id uuid,
  score integer,
  max_score integer,
  status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_assignment public.assignments%rowtype;
  v_submission public.assignment_submissions%rowtype;
  v_type text;
  v_content jsonb;
  v_questions jsonb;
  v_pairs jsonb;
  v_answers jsonb;
  i integer;
  q jsonb;
  p jsonb;
  pts integer;
  v_score integer := 0;
  v_max integer := 0;
  ans_text text;
  corr text;
  got text;
  corr_idx integer;
  ans_int integer;
  v_now timestamptz := now();
  v_status text;  -- NEW: Variable to hold status
BEGIN
  -- Require authenticated user
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Load assignment
  SELECT *
  INTO v_assignment
  FROM public.assignments a
  WHERE a.id = p_assignment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Assignment not found';
  END IF;

  -- Ensure caller is enrolled as student in the classroom
  IF NOT EXISTS (
    SELECT 1
    FROM public.classroom_students cs
    WHERE cs.classroom_id = v_assignment.classroom_id
      AND cs.student_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not allowed for this assignment';
  END IF;

  -- Load submission for this student + assignment
  SELECT *
  INTO v_submission
  FROM public.assignment_submissions s
  WHERE s.assignment_id = v_assignment.id
    AND s.student_id = auth.uid()
  ORDER BY s.created_at
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Submission not found for this assignment';
  END IF;

  -- Prevent re-grading already graded submissions
  IF v_submission.score IS NOT NULL
     OR v_submission.graded_at IS NOT NULL
     OR v_submission.status = 'graded' THEN
    RAISE EXCEPTION 'Submission already graded';
  END IF;

  v_type := COALESCE(v_assignment.assignment_type::text, '');
  v_content := COALESCE(v_assignment.content, '{}'::jsonb);
  v_answers := COALESCE(v_submission.submission_content->'answers', '[]'::jsonb);

  -- Objective types: compute score/max_score server-side
  IF v_type IN ('multiple_choice','quiz','identification','matching_type') THEN
    IF v_type IN ('multiple_choice','quiz','identification') THEN
      v_questions := COALESCE(v_content->'questions', '[]'::jsonb);
      FOR i IN 0..COALESCE(jsonb_array_length(v_questions), 0) - 1 LOOP
        q := v_questions->i;
        pts := COALESCE((q->>'points')::int, 0);
        v_max := v_max + pts;
        ans_text := CASE
          WHEN i < jsonb_array_length(v_answers) THEN v_answers->>i
          ELSE ''
        END;

        IF v_type = 'multiple_choice' THEN
          -- MCQ: answer index vs correctIndex or answer value
          BEGIN
            ans_int := NULL;
            IF ans_text <> '' THEN
              ans_int := ans_text::int;
            END IF;
          EXCEPTION WHEN OTHERS THEN
            ans_int := NULL;
          END;

          BEGIN
            corr_idx := NULL;
            IF COALESCE(q->>'correctIndex', '') <> '' THEN
              corr_idx := (q->>'correctIndex')::int;
            END IF;
          EXCEPTION WHEN OTHERS THEN
            corr_idx := NULL;
          END;

          IF ans_int IS NOT NULL AND corr_idx IS NOT NULL AND ans_int = corr_idx THEN
            v_score := v_score + pts;
          ELSIF (q ? 'answer') AND (q->>'answer') = ans_text THEN
            v_score := v_score + pts;
          END IF;
        ELSE
          -- quiz/identification: case-insensitive comparison
          corr := lower(btrim(COALESCE(q->>'answer', '')));
          got := lower(btrim(COALESCE(ans_text, '')));
          IF corr <> '' AND got <> '' AND corr = got THEN
            v_score := v_score + pts;
          END IF;
        END IF;
      END LOOP;
    ELSE
      -- matching_type
      v_pairs := COALESCE(v_content->'pairs', '[]'::jsonb);
      FOR i IN 0..COALESCE(jsonb_array_length(v_pairs), 0) - 1 LOOP
        p := v_pairs->i;
        pts := COALESCE((p->>'points')::int, 0);
        v_max := v_max + pts;
        ans_text := CASE
          WHEN i < jsonb_array_length(v_answers) THEN v_answers->>i
          ELSE ''
        END;
        corr := lower(btrim(COALESCE(p->>'columnB', '')));
        got := lower(btrim(COALESCE(ans_text, '')));
        IF corr <> '' AND got <> '' AND corr = got THEN
          v_score := v_score + pts;
        END IF;
      END LOOP;
    END IF;

    -- ✅ FIX: Auto-graded types should have status 'graded'
    v_status := 'graded';
  ELSE
    -- Non-objective types (file_upload, essay): keep score/max_score NULL
    v_score := NULL;
    v_max := NULL;

    -- ✅ FIX: Manual-graded types should have status 'submitted' (waiting for teacher)
    v_status := 'submitted';
  END IF;

  -- Update submission row (bypassing client-side RLS restrictions on grade fields)
  UPDATE public.assignment_submissions s
  SET
    status = v_status,  -- ✅ FIX: Use calculated status
    submitted_at = COALESCE(s.submitted_at, v_now),
    score = v_score,
    max_score = v_max,
    graded_at = CASE WHEN v_status = 'graded' THEN v_now ELSE NULL END  -- ✅ FIX: Set graded_at for auto-graded
  WHERE s.id = v_submission.id
  RETURNING s.assignment_id, s.student_id, s.score, s.max_score, s.status
  INTO assignment_id, student_id, score, max_score, status;

  RETURN NEXT;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.auto_grade_and_submit_assignment(bigint) TO authenticated;

-- ============================================
-- DATA MIGRATION: Fix Existing Auto-Graded Submissions
-- ============================================
-- Update existing submissions that were auto-graded but have status 'submitted'
-- to status 'graded' so they display correctly in gradebook

UPDATE public.assignment_submissions s
SET
  status = 'graded',
  graded_at = COALESCE(s.graded_at, s.submitted_at, s.updated_at, s.created_at)
FROM public.assignments a
WHERE s.assignment_id = a.id
  AND a.assignment_type IN ('quiz', 'multiple_choice', 'identification', 'matching_type')
  AND s.status = 'submitted'
  AND s.score IS NOT NULL  -- Only update if score was already calculated
  AND s.max_score IS NOT NULL;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON FUNCTION public.auto_grade_and_submit_assignment(bigint) IS
'Auto-grades objective assignments (quiz, multiple_choice, identification, matching_type)
and sets status to ''graded''. For manual-graded types (file_upload, essay), sets status
to ''submitted'' and leaves score NULL for teacher grading.';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check auto-graded submissions (should have status = 'graded' and score set)
-- SELECT
--   s.id,
--   s.student_id,
--   a.title,
--   a.assignment_type,
--   s.status,
--   s.score,
--   s.max_score,
--   s.submitted_at,
--   s.graded_at
-- FROM assignment_submissions s
-- JOIN assignments a ON s.assignment_id = a.id
-- WHERE a.assignment_type IN ('quiz', 'multiple_choice', 'identification', 'matching_type')
--   AND s.status = 'graded'
-- ORDER BY s.submitted_at DESC
-- LIMIT 10;

-- Check manual-graded submissions (should have status = 'submitted' and score NULL)
-- SELECT
--   s.id,
--   s.student_id,
--   a.title,
--   a.assignment_type,
--   s.status,
--   s.score,
--   s.max_score,
--   s.submitted_at,
--   s.graded_at
-- FROM assignment_submissions s
-- JOIN assignments a ON s.assignment_id = a.id
-- WHERE a.assignment_type IN ('file_upload', 'essay')
--   AND s.status = 'submitted'
-- ORDER BY s.submitted_at DESC
-- LIMIT 10;

