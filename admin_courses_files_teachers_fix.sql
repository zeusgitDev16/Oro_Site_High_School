-- ============================================================
-- ADMIN FIX: Courses + Course Files + Teachers (Idempotent)
-- ============================================================

-- 0) Helper: ensure public.is_admin() exists and matches roles/role_id
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles p
    JOIN public.roles r ON p.role_id = r.id
    WHERE p.id = auth.uid()
      AND r.name = 'admin'
  );
END;
$$;

-- ============================================================
-- 1) COURSES: backfill title/name and give admins full access
-- ============================================================

ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

-- Backfill title from name and vice versa (safe to run repeatedly)
UPDATE public.courses
SET title = name
WHERE title IS NULL AND name IS NOT NULL;

UPDATE public.courses
SET name = title
WHERE name IS NULL AND title IS NOT NULL;

-- Admin full CRUD on courses (using is_admin)
DROP POLICY IF EXISTS "courses_admin_full_access" ON public.courses;

CREATE POLICY "courses_admin_full_access"
ON public.courses
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Note: existing student/teacher view policies (e.g.
-- "Students can view courses in their classrooms") are left as-is.

-- ============================================================
-- 2) COURSE MODULES: admin full CRUD for file records
-- ============================================================

ALTER TABLE public.course_modules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "modules_admin_full_access" ON public.course_modules;

CREATE POLICY "modules_admin_full_access"
ON public.course_modules
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Existing read-only policies (like authenticated_can_view_modules)
-- are not touched; they continue to control non-admin access.

-- ============================================================
-- 3) COURSE ASSIGNMENTS: admin full CRUD for file records
-- ============================================================

ALTER TABLE public.course_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "assignments_admin_full_access" ON public.course_assignments;

CREATE POLICY "assignments_admin_full_access"
ON public.course_assignments
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Existing read-only policies (like authenticated_can_view_assignments)
-- are left intact for non-admin users.

-- ============================================================
-- 4) TEACHERS: allow authenticated read + admin manage
-- ============================================================

ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read teacher data (names, departments, etc.)
-- This keeps admin teacher lists and name lookups working.
DROP POLICY IF EXISTS "teachers_read_all_authenticated" ON public.teachers;

CREATE POLICY "teachers_read_all_authenticated"
ON public.teachers
FOR SELECT
TO authenticated
USING (true);

-- Admins can fully manage teachers (insert/update/delete)
DROP POLICY IF EXISTS "teachers_admin_full_access" ON public.teachers;

CREATE POLICY "teachers_admin_full_access"
ON public.teachers
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ============================================================
-- 5) COURSE_TEACHERS: ensure mapping table + permissive RLS
-- ============================================================

-- Create link table if it doesn't exist (matches CREATE_COURSE_TEACHERS_TABLE.sql)
CREATE TABLE IF NOT EXISTS public.course_teachers (
  id SERIAL PRIMARY KEY,
  course_id INTEGER NOT NULL,
  teacher_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(course_id, teacher_id)
);

-- Helpful indexes (idempotent)
CREATE INDEX IF NOT EXISTS idx_course_teachers_course_id
  ON public.course_teachers(course_id);

CREATE INDEX IF NOT EXISTS idx_course_teachers_teacher_id
  ON public.course_teachers(teacher_id);

ALTER TABLE public.course_teachers ENABLE ROW LEVEL SECURITY;

-- Reset to simple, permissive policies for now (admin + services)
DROP POLICY IF EXISTS "course_teachers_select_all" ON public.course_teachers;
DROP POLICY IF EXISTS "course_teachers_insert_authenticated" ON public.course_teachers;
DROP POLICY IF EXISTS "course_teachers_delete_authenticated" ON public.course_teachers;

CREATE POLICY "course_teachers_select_all"
ON public.course_teachers
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "course_teachers_insert_authenticated"
ON public.course_teachers
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "course_teachers_delete_authenticated"
ON public.course_teachers
FOR DELETE
TO authenticated
USING (true);

-- ============================================================
-- End of admin courses/files/teachers fix
-- ============================================================