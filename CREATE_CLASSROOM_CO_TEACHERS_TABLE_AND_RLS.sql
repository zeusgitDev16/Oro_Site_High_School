-- CREATE_CLASSROOM_CO_TEACHERS_TABLE_AND_RLS.sql
-- Purpose: Enable co-teacher membership via classroom_teachers mapping table
-- Idempotent: Safe to run multiple times

-- 1) Mapping table: classroom_teachers
-- Associates additional teachers to classrooms (co-teachers)
create table if not exists public.classroom_teachers (
  classroom_id uuid not null references public.classrooms(id) on delete cascade,
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (classroom_id, teacher_id)
);

-- Helpful indexes
create index if not exists idx_classroom_teachers_teacher on public.classroom_teachers(teacher_id);
create index if not exists idx_classroom_teachers_classroom on public.classroom_teachers(classroom_id);

-- 2) Enable RLS
alter table public.classroom_teachers enable row level security;

-- 3) RLS policies on classroom_teachers
-- 3a) Teacher can see their own co-teacher memberships
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE polname = 'ct_select_own_memberships'
      AND schemaname = 'public'
      AND tablename = 'classroom_teachers'
  ) THEN
    EXECUTE $$
      create policy ct_select_own_memberships
      on public.classroom_teachers
      for select
      using (teacher_id = auth.uid());
    $$;
  END IF;
END $$;

-- 3b) Teacher can join a classroom as co-teacher (self-insert)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE polname = 'ct_insert_self_join'
      AND schemaname = 'public'
      AND tablename = 'classroom_teachers'
  ) THEN
    EXECUTE $$
      create policy ct_insert_self_join
      on public.classroom_teachers
      for insert
      with check (
        teacher_id = auth.uid()
        and exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and c.is_active = true
        )
      );
    $$;
  END IF;
END $$;

-- 3c) Optional: Owner can view all co-teachers of their classrooms
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE polname = 'ct_owner_select_memberships'
      AND schemaname = 'public'
      AND tablename = 'classroom_teachers'
  ) THEN
    EXECUTE $$
      create policy ct_owner_select_memberships
      on public.classroom_teachers
      for select
      using (
        exists (
          select 1 from public.classrooms c
          where c.id = classroom_id
            and c.teacher_id = auth.uid()
        )
      );
    $$;
  END IF;
END $$;

-- 4) Ensure classrooms RLS allows co-teachers to view classrooms they joined
-- This supports embedding: from('classroom_teachers').select('classroom_id, classrooms(*)')
alter table public.classrooms enable row level security;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE polname = 'classrooms_select_co_teachers'
      AND schemaname = 'public'
      AND tablename = 'classrooms'
  ) THEN
    EXECUTE $$
      create policy classrooms_select_co_teachers
      on public.classrooms
      for select
      using (
        exists (
          select 1
          from public.classroom_teachers ct
          where ct.classroom_id = classrooms.id
            and ct.teacher_id = auth.uid()
        )
      );
    $$;
  END IF;
END $$;

-- End of script