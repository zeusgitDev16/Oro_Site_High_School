-- RPC_GET_REPLIES_WITH_AUTHOR.sql
-- Purpose: Provide a secure (SECURITY DEFINER) RPC that returns announcement replies
--          with author names for a specific announcement, limited to users who are
--          members/owners (teacher, co_teacher) of the announcement's classroom.
-- Notes:
--  - This function bypasses RLS safely by re-applying the visibility checks inside
--    the function itself using auth.uid().
--  - It returns only the minimal fields the UI needs.
--  - It is idempotent (CREATE OR REPLACE on function, IF NOT EXISTS on index).

-- Supporting index for better performance when ordering and filtering by announcement_id
create index if not exists idx_announcement_replies_announcement_id_created_at
  on public.announcement_replies (announcement_id, created_at);

-- RPC: get_replies_with_author
-- Parameter type matches typical integer announcement_id usage in your app
-- Adjust to bigint if your schema uses bigint (then also update the Dart code argument type if needed)
create or replace function public.get_replies_with_author(
  p_announcement_id integer
)
returns table (
  id            bigint,
  author_id     uuid,
  author_name   text,
  content       text,
  is_deleted    boolean,
  created_at    timestamptz
)
language sql
security definer
set search_path = public
as $$
  with allowed as (
    select 1
    from public.announcements a
    join public.classrooms c on c.id = a.classroom_id
    where a.id = p_announcement_id
      and (
        -- Owner (primary teacher)
        c.teacher_id = auth.uid()
        or
        -- Unified classroom membership (preferred)
        exists (
          select 1
          from public.classroom_members cm
          where cm.classroom_id = c.id
            and cm.member_id = auth.uid()
            and cm.role in ('teacher','co_teacher')
        )
        or
        -- Legacy mapping (fallback)
        exists (
          select 1
          from public.classroom_teachers ct
          where ct.classroom_id = c.id
            and ct.teacher_id = auth.uid()
        )
      )
  )
  select
    r.id,
    r.author_id,
    coalesce(p.full_name,
             case when r.author_id = auth.uid() then 'You' else 'User' end) as author_name,
    r.content,
    coalesce(r.is_deleted, false) as is_deleted,
    r.created_at
  from public.announcement_replies r
  -- Only proceed if the caller is allowed to view this announcement/classroom
  join allowed on true
  left join public.profiles p on p.id = r.author_id
  where r.announcement_id = p_announcement_id
  order by r.created_at asc;
$$;

-- Ensure authenticated users can call the function
grant execute on function public.get_replies_with_author(integer) to authenticated;

-- Optional: tighten public access (uncomment if needed)
-- revoke all on function public.get_replies_with_author(integer) from public;

-- END OF FILE
