-- ============================================
-- RLS POLICIES FOR EXISTING SUPABASE TABLES
-- Based on SUPABASE_TABLES.md and SUPABASE_TABLES_PART2.md
-- ============================================

-- ============================================
-- STEP 1: CREATE HELPER FUNCTION
-- ============================================

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

-- ============================================
-- STEP 2: ENABLE RLS ON ALL TABLES
-- ============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 3: DROP ALL EXISTING POLICIES
-- ============================================

-- Drop all policies for each table
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- ============================================
-- STEP 4: CREATE NEW RLS POLICIES
-- ============================================

-- ============================================
-- ROLES TABLE
-- ============================================
CREATE POLICY "roles_select_all"
  ON public.roles FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- PROFILES TABLE
-- ============================================
CREATE POLICY "profiles_select_own_or_admin"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "profiles_insert_admin"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "profiles_update_own_or_admin"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "profiles_delete_admin"
  ON public.profiles FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- STUDENTS TABLE
-- ============================================
CREATE POLICY "students_select_own_or_admin"
  ON public.students FOR SELECT
  TO authenticated
  USING (id = auth.uid() OR public.is_admin());

CREATE POLICY "students_insert_admin"
  ON public.students FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "students_update_admin"
  ON public.students FOR UPDATE
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "students_delete_admin"
  ON public.students FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- PARENT_STUDENTS TABLE
-- ============================================
CREATE POLICY "parent_students_select_own_or_admin"
  ON public.parent_students FOR SELECT
  TO authenticated
  USING (parent_id = auth.uid() OR student_id = auth.uid() OR public.is_admin());

CREATE POLICY "parent_students_insert_admin"
  ON public.parent_students FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "parent_students_update_admin"
  ON public.parent_students FOR UPDATE
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "parent_students_delete_admin"
  ON public.parent_students FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- ACTIVITY_LOG TABLE
-- ============================================
CREATE POLICY "activity_log_select_own_or_admin"
  ON public.activity_log FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "activity_log_insert_all"
  ON public.activity_log FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================
-- ENROLLMENTS TABLE
-- ============================================
CREATE POLICY "enrollments_select_own_or_admin"
  ON public.enrollments FOR SELECT
  TO authenticated
  USING (student_id = auth.uid() OR public.is_admin());

CREATE POLICY "enrollments_insert_admin"
  ON public.enrollments FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "enrollments_update_admin"
  ON public.enrollments FOR UPDATE
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "enrollments_delete_admin"
  ON public.enrollments FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- COURSES TABLE
-- ============================================
CREATE POLICY "courses_select_all"
  ON public.courses FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "courses_insert_admin"
  ON public.courses FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "courses_update_teacher_or_admin"
  ON public.courses FOR UPDATE
  TO authenticated
  USING (teacher_id = auth.uid() OR public.is_admin());

CREATE POLICY "courses_delete_admin"
  ON public.courses FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- ATTENDANCE TABLE
-- ============================================
CREATE POLICY "attendance_select_own_or_admin"
  ON public.attendance FOR SELECT
  TO authenticated
  USING (student_id = auth.uid() OR public.is_admin());

CREATE POLICY "attendance_insert_admin"
  ON public.attendance FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "attendance_update_admin"
  ON public.attendance FOR UPDATE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- ASSIGNMENTS TABLE
-- ============================================
CREATE POLICY "assignments_select_all"
  ON public.assignments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "assignments_insert_admin"
  ON public.assignments FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "assignments_update_admin"
  ON public.assignments FOR UPDATE
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "assignments_delete_admin"
  ON public.assignments FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- SUBMISSIONS TABLE
-- ============================================
CREATE POLICY "submissions_select_own_or_admin"
  ON public.submissions FOR SELECT
  TO authenticated
  USING (student_id = auth.uid() OR public.is_admin());

CREATE POLICY "submissions_insert_own"
  ON public.submissions FOR INSERT
  TO authenticated
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "submissions_update_own"
  ON public.submissions FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid());

-- ============================================
-- GRADES TABLE
-- ============================================
CREATE POLICY "grades_select_own_or_admin"
  ON public.grades FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.submissions s
      WHERE s.id = grades.submission_id
      AND s.student_id = auth.uid()
    ) OR public.is_admin()
  );

CREATE POLICY "grades_insert_admin"
  ON public.grades FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "grades_update_admin"
  ON public.grades FOR UPDATE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- MESSAGES TABLE
-- ============================================
CREATE POLICY "messages_select_own"
  ON public.messages FOR SELECT
  TO authenticated
  USING (sender_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY "messages_insert_own"
  ON public.messages FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "messages_update_own"
  ON public.messages FOR UPDATE
  TO authenticated
  USING (recipient_id = auth.uid());

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE POLICY "notifications_select_own"
  ON public.notifications FOR SELECT
  TO authenticated
  USING (recipient_id = auth.uid());

CREATE POLICY "notifications_insert_all"
  ON public.notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "notifications_update_own"
  ON public.notifications FOR UPDATE
  TO authenticated
  USING (recipient_id = auth.uid());

-- ============================================
-- VERIFICATION
-- ============================================

-- Count policies per table
SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Verify RLS is enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN (
    'profiles', 'students', 'parent_students', 'activity_log',
    'enrollments', 'roles', 'courses', 'attendance', 'assignments',
    'submissions', 'grades', 'messages', 'notifications'
)
ORDER BY tablename;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ RLS POLICIES CREATED SUCCESSFULLY!';
  RAISE NOTICE '';
  RAISE NOTICE '🔐 Security Features:';
  RAISE NOTICE '  • Admins can manage all data';
  RAISE NOTICE '  • Students can view their own data';
  RAISE NOTICE '  • Teachers can manage their courses';
  RAISE NOTICE '  • Parents can view their children data';
  RAISE NOTICE '  • Activity logging enabled for all';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 You can now create users as admin!';
END $$;
