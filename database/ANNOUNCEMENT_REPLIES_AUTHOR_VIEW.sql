-- Idempotent helper to robustly join announcement_replies.author_id (text) to profiles.id (uuid)
-- 1) Safe cast function: returns NULL if the text is not a valid UUID
create or replace function public.try_uuid(t text)
returns uuid
language plpgsql
immutable
as $
declare
  out uuid;
begin
  begin
    -- Trim whitespace before attempting cast to handle text-vs-uuid mismatch
    out := btrim(t)::uuid;
    return out;
  exception when invalid_text_representation then
    return null;
  end;
end;
$;

-- 2) Optional: computed UUID column for author_id (improves join/indexing without changing original column)
alter table public.announcement_replies
  add column if not exists author_id_uuid uuid generated always as (public.try_uuid(author_id)) stored;

-- 3) Optional index for faster lookups on the generated column
create index if not exists idx_announcement_replies_author_id_uuid
  on public.announcement_replies (author_id_uuid);

-- 4) View that exposes author_name resolved from profiles using safe cast
create or replace view public.announcement_replies_with_author as
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
  on p.id = public.try_uuid(ar.author_id);

-- 5) Grant read access to the view (Supabase client reads via anon/authenticated roles)
grant select on public.announcement_replies_with_author to anon, authenticated;
