-- Idempotent RLS policies to allow teachers (including co-teachers) to manage course attendance
--
-- Goal:
-- - Keep existing student/admin behavior on public.attendance
--   * Students: can see only their own rows (attendance_select_own_or_admin)
--   * Admins: can insert/update (attendance_insert_admin / attendance_update_admin)
-- - Add teacher/co-teacher permissions so that the Teacher Attendance workspace
--   can read and write attendance for their courses.
-- - Safe to run multiple times: each policy is dropped/recreated by name;
--   existing student/admin policies are left untouched.

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Helper condition (inlined): current user is a teacher or co-teacher
-- for the course referenced by attendance.course_id.
--
-- 1) Direct course ownership: courses.teacher_id = auth.uid()
-- 2) Co-teacher via classroom_courses + classroom_teachers mapping:
--      attendance.course_id -> classroom_courses.course_id
--      classroom_courses.classroom_id -> classroom_teachers.classroom_id
--      classroom_teachers.teacher_id = auth.uid()

-- 1) SELECT: allow teachers/co-teachers to view attendance for their courses
DROP POLICY IF EXISTS "attendance_teachers_select_by_course" ON public.attendance;
CREATE POLICY "attendance_teachers_select_by_course"
ON public.attendance
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.courses c
    WHERE c.id = public.attendance.course_id
      AND c.teacher_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1
    FROM public.classroom_courses cc
    JOIN public.classroom_teachers ct
      ON ct.classroom_id = cc.classroom_id
    WHERE cc.course_id = public.attendance.course_id
      AND ct.teacher_id = auth.uid()
  )
);

-- 2) INSERT: allow teachers/co-teachers to insert attendance rows
DROP POLICY IF EXISTS "attendance_teachers_insert_by_course" ON public.attendance;
CREATE POLICY "attendance_teachers_insert_by_course"
ON public.attendance
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.courses c
    WHERE c.id = public.attendance.course_id
      AND c.teacher_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1
    FROM public.classroom_courses cc
    JOIN public.classroom_teachers ct
      ON ct.classroom_id = cc.classroom_id
    WHERE cc.course_id = public.attendance.course_id
      AND ct.teacher_id = auth.uid()
  )
);

-- 3) UPDATE: allow teachers/co-teachers to update rows they own by course
DROP POLICY IF EXISTS "attendance_teachers_update_by_course" ON public.attendance;
CREATE POLICY "attendance_teachers_update_by_course"
ON public.attendance
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.courses c
    WHERE c.id = public.attendance.course_id
      AND c.teacher_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1
    FROM public.classroom_courses cc
    JOIN public.classroom_teachers ct
      ON ct.classroom_id = cc.classroom_id
    WHERE cc.course_id = public.attendance.course_id
      AND ct.teacher_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.courses c
    WHERE c.id = public.attendance.course_id
      AND c.teacher_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1
    FROM public.classroom_courses cc
    JOIN public.classroom_teachers ct
      ON ct.classroom_id = cc.classroom_id
    WHERE cc.course_id = public.attendance.course_id
      AND ct.teacher_id = auth.uid()
  )
);

-- 4) DELETE: allow teachers/co-teachers to delete attendance rows for their courses
DROP POLICY IF EXISTS "attendance_teachers_delete_by_course" ON public.attendance;
CREATE POLICY "attendance_teachers_delete_by_course"
ON public.attendance
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.courses c
    WHERE c.id = public.attendance.course_id
      AND c.teacher_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1
    FROM public.classroom_courses cc
    JOIN public.classroom_teachers ct
      ON ct.classroom_id = cc.classroom_id
    WHERE cc.course_id = public.attendance.course_id
      AND ct.teacher_id = auth.uid()
  )
);

-- 5) Teachers who own classrooms linked to the course can manage attendance
--    (covers courses where courses.teacher_id is NULL but the course is
--     attached to a classroom taught by the current teacher).
DROP POLICY IF EXISTS "attendance_teachers_manage_by_classroom" ON public.attendance;
CREATE POLICY "attendance_teachers_manage_by_classroom"
ON public.attendance
AS PERMISSIVE
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.classroom_courses cc
    JOIN public.classrooms cl
      ON cl.id = cc.classroom_id
    WHERE cc.course_id = public.attendance.course_id
      AND cl.teacher_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.classroom_courses cc
    JOIN public.classrooms cl
      ON cl.id = cc.classroom_id
    WHERE cc.course_id = public.attendance.course_id
      AND cl.teacher_id = auth.uid()
  )
);

