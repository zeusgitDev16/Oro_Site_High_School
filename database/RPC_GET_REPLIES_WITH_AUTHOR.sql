-- Idempotent RPC to fetch replies with author names server-side
-- Resolves text author_id to uuid profiles.id via try_uuid, bypassing client type issues
-- SECURITY DEFINER to avoid cross-table RLS mismatches when allowed. Limit result by announcement_id

create or replace function public.get_replies_with_author(
  p_announcement_id int
)
returns table (
  id bigint,
  announcement_id int,
  author_id text,
  content text,
  created_at timestamptz,
  is_deleted boolean,
  author_name text
)
language sql
security definer
set search_path = public
as $$
  select
    ar.id,
    ar.announcement_id,
    ar.author_id,
    ar.content,
    ar.created_at,
    ar.is_deleted,
    coalesce(p.full_name, 'User') as author_name
  from public.announcement_replies ar
  left join public.profiles p
    on p.id = public.try_uuid(ar.author_id)
  where ar.announcement_id = p_announcement_id
  order by ar.created_at asc;
$$;

-- Allow client roles to call this RPC
grant execute on function public.get_replies_with_author(int) to anon, authenticated;
