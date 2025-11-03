-- RLS_FIX_ANNOUNCEMENTS_CO_TEACHERS.sql
-- Purpose: Ensure co-teachers (via classroom_members or legacy classroom_teachers) can SELECT
--          announcements and announcement_replies for classrooms they belong to.
--          Idempotent: guarded by pg_policies checks.

-- Enable RLS (safe if already enabled)
alter table if exists public.announcements enable row level security;
alter table if exists public.announcement_replies enable row level security;

-- Announcements SELECT policy: owner or member (teacher/co_teacher) of the classroom
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'announcements'
      and policyname = 'ann_select_owner_or_co_teacher'
  ) then
    create policy ann_select_owner_or_co_teacher
      on public.announcements
      for select
      using (
        exists (
          select 1
          from public.classrooms c
          where c.id = announcements.classroom_id
            and (
              -- owner (primary teacher)
              c.teacher_id = auth.uid()
              or
              -- unified membership table (preferred)
              exists (
                select 1
                from public.classroom_members cm
                where cm.classroom_id = c.id
                  and cm.member_id = auth.uid()
                  and cm.role in ('teacher','co_teacher')
              )
              or
              -- legacy mapping (fallback)
              exists (
                select 1
                from public.classroom_teachers ct
                where ct.classroom_id = c.id
                  and ct.teacher_id = auth.uid()
              )
            )
        )
      );
  end if;
end$$;

-- Announcement replies SELECT policy: owner or member of the parent announcement's classroom
-- (follows same membership logic; join through announcements->classrooms)

-- Helper note: policies may reference other tables; joins are allowed in USING clauses.

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'announcement_replies'
      and policyname = 'annrep_select_owner_or_co_teacher'
  ) then
    create policy annrep_select_owner_or_co_teacher
      on public.announcement_replies
      for select
      using (
        exists (
          select 1
          from public.announcements a
          join public.classrooms c on c.id = a.classroom_id
          where a.id = announcement_replies.announcement_id
            and (
              -- owner (primary teacher)
              c.teacher_id = auth.uid()
              or
              -- unified classroom membership
              exists (
                select 1
                from public.classroom_members cm
                where cm.classroom_id = c.id
                  and cm.member_id = auth.uid()
                  and cm.role in ('teacher','co_teacher')
              )
              or
              -- legacy mapping
              exists (
                select 1
                from public.classroom_teachers ct
                where ct.classroom_id = c.id
                  and ct.teacher_id = auth.uid()
              )
            )
        )
      );
  end if;
end$$;

-- Optional: ensure basic grant (Supabase typically manages this, but harmless if repeated)
-- grant select on public.announcements to authenticated;
-- grant select on public.announcement_replies to authenticated;

-- After applying this file, co-teachers should be able to see announcements and replies
-- for classrooms where they are members (either via classroom_members or legacy mapping).
