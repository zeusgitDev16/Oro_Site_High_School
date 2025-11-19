-- Announcement replies table + classroom-scoped RLS (Idempotent)
-- This script safely creates the table, indexes, foreign key, and RLS policies so it can be re-run.

begin;

-- 1) Create table if not exists
create table if not exists public.announcement_replies (
  id bigserial primary key,
  announcement_id bigint not null,
  author_id text not null,
  content text not null,
  created_at timestamptz not null default now()
);

-- 2) Add FK to announcements(id), on delete cascade (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'announcement_replies_announcement_id_fkey'
  ) THEN
    ALTER TABLE public.announcement_replies
      ADD CONSTRAINT announcement_replies_announcement_id_fkey
      FOREIGN KEY (announcement_id)
      REFERENCES public.announcements(id)
      ON DELETE CASCADE;
  END IF;
END$$;

-- 3) Helpful indexes
create index if not exists idx_announcement_replies_announcement on public.announcement_replies(announcement_id);
create index if not exists idx_announcement_replies_created_at on public.announcement_replies(created_at desc);
create index if not exists idx_announcement_replies_author on public.announcement_replies(author_id);

-- 4) Enable RLS
alter table if exists public.announcement_replies enable row level security;

-- 5) Drop existing policies (idempotent reset)
DROP POLICY IF EXISTS "Replies select visible to classroom members" ON public.announcement_replies;
DROP POLICY IF EXISTS "Replies insert by classroom members" ON public.announcement_replies;
DROP POLICY IF EXISTS "Replies update by author_or_teacher" ON public.announcement_replies;
DROP POLICY IF EXISTS "Replies delete by author_or_teacher" ON public.announcement_replies;

-- 6) Policies
-- Helper logic (duplicated inline) mirrors announcements classroom scoping
-- SELECT: classroom owner (teacher), co-teachers, classroom students, or admin
CREATE POLICY "Replies select visible to classroom members"
  ON public.announcement_replies
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.announcements a
      JOIN public.classrooms c ON c.id::text = a.classroom_id::text
      WHERE a.id = public.announcement_replies.announcement_id
        AND (
          c.teacher_id::text = auth.uid()::text
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id::text = a.classroom_id::text
              AND ct.teacher_id::text = auth.uid()::text
          )
          OR EXISTS (
            SELECT 1 FROM public.classroom_students cs
            WHERE cs.classroom_id::text = a.classroom_id::text
              AND cs.student_id::text = auth.uid()::text
          )
          OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
        )
    )
  );

-- INSERT: classroom members (teacher owner, co-teachers OR enrolled students), or admin
CREATE POLICY "Replies insert by classroom members"
  ON public.announcement_replies
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.announcements a
      JOIN public.classrooms c ON c.id::text = a.classroom_id::text
      WHERE a.id = public.announcement_replies.announcement_id
        AND (
          c.teacher_id::text = auth.uid()::text
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id::text = a.classroom_id::text
              AND ct.teacher_id::text = auth.uid()::text
          )
          OR EXISTS (
            SELECT 1 FROM public.classroom_students cs
            WHERE cs.classroom_id::text = a.classroom_id::text
              AND cs.student_id::text = auth.uid()::text
          )
          OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
        )
    )
  );

-- UPDATE: author can edit own reply; teachers/co-teachers can edit any; admin override
CREATE POLICY "Replies update by author_or_teacher"
  ON public.announcement_replies
  FOR UPDATE
  TO authenticated
  USING (
    -- Author
    public.announcement_replies.author_id::text = auth.uid()::text
    OR
    -- Classroom owner, co-teachers, or admin per linked announcement
    EXISTS (
      SELECT 1
      FROM public.announcements a
      JOIN public.classrooms c ON c.id::text = a.classroom_id::text
      WHERE a.id = public.announcement_replies.announcement_id
        AND (
          c.teacher_id::text = auth.uid()::text
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id::text = a.classroom_id::text
              AND ct.teacher_id::text = auth.uid()::text
          )
          OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
        )
    )
  )
  WITH CHECK (
    public.announcement_replies.author_id::text = auth.uid()::text
    OR EXISTS (
      SELECT 1
      FROM public.announcements a
      JOIN public.classrooms c ON c.id::text = a.classroom_id::text
      WHERE a.id = public.announcement_replies.announcement_id
        AND (
          c.teacher_id::text = auth.uid()::text
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id::text = a.classroom_id::text
              AND ct.teacher_id::text = auth.uid()::text
          )
          OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
        )
    )
  );

-- DELETE: author can delete own reply; teachers/co-teachers can delete any; admin override
CREATE POLICY "Replies delete by author_or_teacher"
  ON public.announcement_replies
  FOR DELETE
  TO authenticated
  USING (
    public.announcement_replies.author_id::text = auth.uid()::text
    OR EXISTS (
      SELECT 1
      FROM public.announcements a
      JOIN public.classrooms c ON c.id::text = a.classroom_id::text
      WHERE a.id = public.announcement_replies.announcement_id
        AND (
          c.teacher_id::text = auth.uid()::text
          OR EXISTS (
            SELECT 1 FROM public.classroom_teachers ct
            WHERE ct.classroom_id::text = a.classroom_id::text
              AND ct.teacher_id::text = auth.uid()::text
          )
          OR COALESCE((SELECT public.is_admin(auth.uid())), FALSE)
        )
    )
  );

commit;
