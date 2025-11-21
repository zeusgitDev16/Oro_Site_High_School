begin;

-- ============================================
-- 1) assignment_submissions: classroom_id consistency
--    (no RLS changes; just keep data aligned)
-- ============================================

create or replace function public.sync_assignment_submission_classroom()
returns trigger
language plpgsql
as $$
declare
  v_classroom_id uuid;
begin
  -- If assignment_id is missing, nothing to do
  if new.assignment_id is null then
    return new;
  end if;

  -- Look up the assignment's classroom_id
  select a.classroom_id
  into v_classroom_id
  from public.assignments a
  where a.id = new.assignment_id;

  -- If not found, leave classroom_id as provided (RLS will still enforce)
  if v_classroom_id is null then
    return new;
  end if;

  -- Always align classroom_id with the assignment's classroom
  new.classroom_id := v_classroom_id;
  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'sync_assignment_submission_classroom_trigger'
      and tgrelid = 'public.assignment_submissions'::regclass
  ) then
    create trigger sync_assignment_submission_classroom_trigger
    before insert or update of assignment_id, classroom_id
    on public.assignment_submissions
    for each row
    execute function public.sync_assignment_submission_classroom();
  end if;
end $$;

-- ============================================
-- 2) student_grades: complete RLS
-- ============================================

alter table if exists public.student_grades
  enable row level security;

-- Helper: who can manage a student_grades row?
-- Uses existing helpers public.is_admin() and public.is_course_teacher().
create or replace function public.can_manage_student_grade(
  p_classroom_id uuid,
  p_course_id    bigint
)
returns boolean
language plpgsql
as $$
begin
  -- Admin override
  if public.is_admin() then
    return true;
  end if;

  -- Classroom teacher or co-teacher
  if p_classroom_id is not null and exists (
    select 1
    from public.classrooms c
    where c.id = p_classroom_id
      and (
        c.teacher_id = auth.uid()
        or exists (
          select 1
          from public.classroom_teachers ct
          where ct.classroom_id = c.id
            and ct.teacher_id  = auth.uid()
        )
      )
  ) then
    return true;
  end if;

  -- Course teacher (primary or via course_teachers / course_assignments)
  if p_course_id is not null and public.is_course_teacher(p_course_id, auth.uid()) then
    return true;
  end if;

  -- Grade level coordinator:
  -- coordinator_assignments.grade_level matches classroom or course grade_level.
  if exists (
    select 1
    from public.coordinator_assignments ca
    where ca.teacher_id = auth.uid()
      and ca.is_active  = true
      and (
        (
          p_classroom_id is not null
          and exists (
            select 1
            from public.classrooms c2
            where c2.id = p_classroom_id
              and c2.grade_level = ca.grade_level
          )
        )
        or
        (
          p_classroom_id is null
          and p_course_id is not null
          and exists (
            select 1
            from public.courses co
            where co.id = p_course_id
              and co.grade_level = ca.grade_level
          )
        )
      )
  ) then
    return true;
  end if;

  return false;
end;
$$;

-- Drop only policies we (re)define
drop policy if exists "student_grades_select_own"          on public.student_grades;
drop policy if exists "student_grades_teacher_select"      on public.student_grades;
drop policy if exists "student_grades_teacher_insert"      on public.student_grades;
drop policy if exists "student_grades_teacher_update"      on public.student_grades;

-- 2.a Students: can view ONLY their own grades
create policy "student_grades_select_own"
  on public.student_grades
  for select
  to authenticated
  using (student_id = auth.uid());

-- 2.b Teachers / co-teachers / coordinators / admins: select rows they manage
create policy "student_grades_teacher_select"
  on public.student_grades
  for select
  to authenticated
  using (public.can_manage_student_grade(classroom_id, course_id));

-- 2.c Same set can INSERT grades for rows they manage
create policy "student_grades_teacher_insert"
  on public.student_grades
  for insert
  to authenticated
  with check (public.can_manage_student_grade(classroom_id, course_id));

-- 2.d Same set can UPDATE grades for rows they manage
create policy "student_grades_teacher_update"
  on public.student_grades
  for update
  to authenticated
  using      (public.can_manage_student_grade(classroom_id, course_id))
  with check (public.can_manage_student_grade(classroom_id, course_id));

-- ============================================
-- 3) assignment_files: complete teacher/admin manage policies
-- ============================================

alter table if exists public.assignment_files
  enable row level security;

-- Keep existing:
--   "Students can view assignment files in enrolled classrooms"
--   "Users can upload files"
--   "Users can delete their files"
-- and the PHASE2 "Teachers can view assignment files" policy.

drop policy if exists "Teachers can update assignment files" on public.assignment_files;
drop policy if exists "Teachers can delete assignment files" on public.assignment_files;

-- Reuse same teacher/co-teacher/admin condition as view policy:
-- Teachers/co-teachers/admin can UPDATE assignment_files for assignments they manage
create policy "Teachers can update assignment files"
  on public.assignment_files
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.assignments a
      where a.id = assignment_files.assignment_id
        and (
          a.teacher_id = auth.uid()
          or exists (
            select 1
            from public.classroom_teachers ct
            where ct.classroom_id = a.classroom_id
              and ct.teacher_id   = auth.uid()
          )
        )
    )
    or public.is_admin()
  )
  with check (
    exists (
      select 1
      from public.assignments a
      where a.id = assignment_files.assignment_id
        and (
          a.teacher_id = auth.uid()
          or exists (
            select 1
            from public.classroom_teachers ct
            where ct.classroom_id = a.classroom_id
              and ct.teacher_id   = auth.uid()
          )
        )
    )
    or public.is_admin()
  );

-- Teachers/co-teachers/admin can DELETE assignment_files for assignments they manage
create policy "Teachers can delete assignment files"
  on public.assignment_files
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.assignments a
      where a.id = assignment_files.assignment_id
        and (
          a.teacher_id = auth.uid()
          or exists (
            select 1
            from public.classroom_teachers ct
            where ct.classroom_id = a.classroom_id
              and ct.teacher_id   = auth.uid()
          )
        )
    )
    or public.is_admin()
  );

commit;