-- ASSIGNMENTS_RLS_STUDENTS_PUBLISHED_VISIBILITY_FIX.sql
-- Purpose: Align student assignment visibility with app logic:
--          students see all *published + active* assignments in classrooms
--          where they are enrolled, regardless of due date or late settings.
-- Idempotent and safe to run multiple times.

begin;

-- Ensure RLS is enabled on assignments (defensive)
alter table if exists public.assignments
  enable row level security;

-- Drop legacy / conflicting student-view policies if present
-- (these may have stricter conditions on due_date / allow_late_submissions)
drop policy if exists "assignments_select_students_published" on public.assignments;
drop policy if exists "students_can_view_published_classroom_assignments" on public.assignments;

-- New unified student visibility policy
create policy "assignments_select_students_published"
  on public.assignments
  for select
  to authenticated
  using (
    -- Admins retain full visibility (also covered by other admin policies)
    public.is_admin()
    or (
      public.assignments.is_published = true
      and public.assignments.is_active = true
      and exists (
        select 1
        from public.classroom_students cs
        where cs.classroom_id = public.assignments.classroom_id
          and cs.student_id   = auth.uid()
      )
    )
  );

commit;

