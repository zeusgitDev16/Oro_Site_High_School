-- FIX: Align auto_grade_and_submit_assignment() with bigint assignments.id
-- Idempotent and safe to run multiple times.

-- 1) Remove old UUID-based version if it exists
drop function if exists public.auto_grade_and_submit_assignment(uuid);

-- 2) Recreate function using bigint assignment id
create or replace function public.auto_grade_and_submit_assignment(
  p_assignment_id bigint
)
returns table (
  assignment_id bigint,
  student_id uuid,
  score integer,
  max_score integer,
  status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
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
begin
  -- Require authenticated user
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- Load assignment
  select *
  into v_assignment
  from public.assignments a
  where a.id = p_assignment_id;

  if not found then
    raise exception 'Assignment not found';
  end if;

  -- Ensure caller is enrolled as student in the classroom
  if not exists (
    select 1
    from public.classroom_students cs
    where cs.classroom_id = v_assignment.classroom_id
      and cs.student_id = auth.uid()
  ) then
    raise exception 'Not allowed for this assignment';
  end if;

  -- Load submission for this student + assignment
  select *
  into v_submission
  from public.assignment_submissions s
  where s.assignment_id = v_assignment.id
    and s.student_id = auth.uid()
  order by s.created_at
  limit 1;

  if not found then
    raise exception 'Submission not found for this assignment';
  end if;

  -- Prevent re-grading already graded submissions
  if v_submission.score is not null
     or v_submission.graded_at is not null
     or v_submission.status = 'graded' then
    raise exception 'Submission already graded';
  end if;

  v_type := coalesce(v_assignment.assignment_type::text, '');
  v_content := coalesce(v_assignment.content, '{}'::jsonb);
  v_answers := coalesce(v_submission.submission_content->'answers', '[]'::jsonb);

  -- Objective types: compute score/max_score server-side
  if v_type in ('multiple_choice','quiz','identification','matching_type') then
    if v_type in ('multiple_choice','quiz','identification') then
      v_questions := coalesce(v_content->'questions', '[]'::jsonb);
      for i in 0..coalesce(jsonb_array_length(v_questions), 0) - 1 loop
        q := v_questions->i;
        pts := coalesce((q->>'points')::int, 0);
        v_max := v_max + pts;
        ans_text := case
          when i < jsonb_array_length(v_answers) then v_answers->>i
          else ''
        end;

        if v_type = 'multiple_choice' then
          -- MCQ: answer index vs correctIndex or answer value
          begin
            ans_int := null;
            if ans_text <> '' then
              ans_int := ans_text::int;
            end if;
          exception when others then
            ans_int := null;
          end;

          begin
            corr_idx := null;
            if coalesce(q->>'correctIndex', '') <> '' then
              corr_idx := (q->>'correctIndex')::int;
            end if;
          exception when others then
            corr_idx := null;
          end;

          if ans_int is not null and corr_idx is not null and ans_int = corr_idx then
            v_score := v_score + pts;
          elsif (q ? 'answer') and (q->>'answer') = ans_text then
            v_score := v_score + pts;
          end if;
        else
          corr := lower(btrim(coalesce(q->>'answer', '')));
          got := lower(btrim(coalesce(ans_text, '')));
          if corr <> '' and got <> '' and corr = got then
            v_score := v_score + pts;
          end if;
        end if;
      end loop;
    else
      -- matching_type
      v_pairs := coalesce(v_content->'pairs', '[]'::jsonb);
      for i in 0..coalesce(jsonb_array_length(v_pairs), 0) - 1 loop
        p := v_pairs->i;
        pts := coalesce((p->>'points')::int, 0);
        v_max := v_max + pts;
        ans_text := case
          when i < jsonb_array_length(v_answers) then v_answers->>i
          else ''
        end;
        corr := lower(btrim(coalesce(p->>'columnB', '')));
        got := lower(btrim(coalesce(ans_text, '')));
        if corr <> '' and got <> '' and corr = got then
          v_score := v_score + pts;
        end if;
      end loop;
    end if;
  else
    -- Non-objective types: keep score/max_score NULL; only status/submitted_at change
    v_score := null;
    v_max := null;
  end if;

  -- Update submission row (bypassing client-side RLS restrictions on grade fields)
  update public.assignment_submissions s
  set
    status = 'submitted',
    submitted_at = coalesce(s.submitted_at, v_now),
    score = v_score,
    max_score = v_max
  where s.id = v_submission.id
  returning s.assignment_id, s.student_id, s.score, s.max_score, s.status
  into assignment_id, student_id, score, max_score, status;

  return;
end;
$$;

-- 3) Grant execute to authenticated role
grant execute on function public.auto_grade_and_submit_assignment(bigint)
  to authenticated;