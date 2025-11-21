-- ============================================================
-- STUDENT CLASSROOM COURSE ACCESS RLS FIX (Idempotent)
-- ============================================================
-- Goal:
--  - Let enrolled students view:
--      * classroom_courses rows for their classrooms
--      * course_modules rows for courses in their classrooms
--  - Do NOT change existing teacher/co-teacher/admin behavior
--  - Avoid helper functions (is_admin, is_classroom_manager) in
--    new policies to reduce recursion risk.
-- ============================================================

BEGIN;

-- ============================================================
-- 1) classroom_courses: students can view courses in classrooms
--    they are enrolled in (via classroom_students)
-- ============================================================

ALTER TABLE public.classroom_courses ENABLE ROW LEVEL SECURITY;

-- Idempotent: drop if policy already exists
DROP POLICY IF EXISTS "Students can view classroom courses"
  ON public.classroom_courses;

CREATE POLICY "Students can view classroom courses"
ON public.classroom_courses
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.classroom_students cs
    WHERE cs.classroom_id = classroom_courses.classroom_id
      AND cs.student_id = auth.uid()
  )
);

-- Notes:
--  - This policy is PERMISSIVE and adds to existing teacher /
--    co-teacher policies (classroom_courses_*_memberships).
--  - Teachers/co-teachers continue to be governed by the existing
--    policies that check classrooms + classroom_teachers.
--  - No helper functions (is_admin, is_classroom_manager) are used.

-- ============================================================
-- 2) course_modules: students can view modules for courses
--    attached to classrooms they are enrolled in
-- ============================================================

ALTER TABLE public.course_modules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can view course modules in their classrooms"
  ON public.course_modules;

CREATE POLICY "Students can view course modules in their classrooms"
ON public.course_modules
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.classroom_courses cc
    JOIN public.classroom_students cs
      ON cs.classroom_id = cc.classroom_id
    WHERE course_modules.course_id = cc.course_id::bigint
      AND cs.student_id = auth.uid()
  )
);

-- Notes:
--  - We explicitly cast cc.course_id::bigint to match
--    course_modules.course_id (bigint) and avoid type ambiguity.
--  - Existing teacher/admin policies remain untouched:
--      * "course_modules_select_course_teachers"
--      * "modules_admin_full_access"
--  - Students only see modules if:
--      * The module's course_id is linked via classroom_courses
--        to a classroom, AND
--      * They are enrolled in that classroom via classroom_students.

COMMIT;

-- ============================================================
-- End of student classroom course access RLS fix
-- ============================================================