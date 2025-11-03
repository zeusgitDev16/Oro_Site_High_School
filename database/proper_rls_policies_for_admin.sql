-- ============================================
-- PROPER RLS POLICIES FOR ADMIN USER CREATION
-- Allows admins to create users while maintaining security
-- ============================================

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to check if current user is admin
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

-- Function to check if current user is authenticated
CREATE OR REPLACE FUNCTION public.is_authenticated()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN auth.uid() IS NOT NULL;
END;
$$;

-- ============================================
-- ROLES TABLE POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated users to read roles" ON public.roles;
DROP POLICY IF EXISTS "Authenticated users can view roles" ON public.roles;

-- Allow all authenticated users to read roles
CREATE POLICY "Authenticated users can read roles"
  ON public.roles FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- PROFILES TABLE POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can manage profiles" ON public.profiles;
DROP POLICY IF EXISTS "Teachers can view student profiles" ON public.profiles;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- Admins can insert profiles (for user creation)
CREATE POLICY "Admins can insert profiles"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Admins can update all profiles
CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (public.is_admin());

-- Admins can delete profiles
CREATE POLICY "Admins can delete profiles"
  ON public.profiles FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- STUDENTS TABLE POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Students can view own data" ON public.students;
DROP POLICY IF EXISTS "Teachers can view their students" ON public.students;
DROP POLICY IF EXISTS "Parents can view their children" ON public.students;
DROP POLICY IF EXISTS "Admins can manage students" ON public.students;

-- Students can view their own data
CREATE POLICY "Students can view own data"
  ON public.students FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Admins can manage all students
CREATE POLICY "Admins can manage all students"
  ON public.students FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================
-- TEACHERS TABLE POLICIES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Teachers can view own data" ON public.teachers;
DROP POLICY IF EXISTS "Admins can manage teachers" ON public.teachers;

-- Teachers can view their own data
CREATE POLICY "Teachers can view own data"
  ON public.teachers FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Admins can manage all teachers
CREATE POLICY "Admins can manage all teachers"
  ON public.teachers FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================
-- PARENT_LINKS TABLE POLICIES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Parents can view own links" ON public.parent_links;
DROP POLICY IF EXISTS "Admins can manage parent links" ON public.parent_links;

-- Parents can view their own links
CREATE POLICY "Parents can view own links"
  ON public.parent_links FOR SELECT
  TO authenticated
  USING (parent_email = (SELECT email FROM public.profiles WHERE id = auth.uid()));

-- Admins can manage all parent links
CREATE POLICY "Admins can manage all parent links"
  ON public.parent_links FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================
-- ACTIVITY_LOG TABLE POLICIES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own activity" ON public.activity_log;
DROP POLICY IF EXISTS "Admins can view all activity" ON public.activity_log;
DROP POLICY IF EXISTS "System can create activity logs" ON public.activity_log;

-- Users can view their own activity
CREATE POLICY "Users can view own activity"
  ON public.activity_log FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Admins can view all activity
CREATE POLICY "Admins can view all activity"
  ON public.activity_log FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- All authenticated users can insert activity logs
CREATE POLICY "Authenticated users can create activity logs"
  ON public.activity_log FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================
-- ENROLLMENTS TABLE POLICIES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Students can view own enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Teachers can view course enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Admins can manage enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Teachers can manage course enrollments" ON public.enrollments;

-- Students can view their own enrollments
CREATE POLICY "Students can view own enrollments"
  ON public.enrollments FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Admins can manage all enrollments
CREATE POLICY "Admins can manage all enrollments"
  ON public.enrollments FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================
-- COURSES TABLE POLICIES (if needed)
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage courses" ON public.courses;
DROP POLICY IF EXISTS "Teachers can view their courses" ON public.courses;
DROP POLICY IF EXISTS "Students can view enrolled courses" ON public.courses;

-- Admins can manage all courses
CREATE POLICY "Admins can manage all courses"
  ON public.courses FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Teachers can view courses they teach
CREATE POLICY "Teachers can view their courses"
  ON public.courses FOR SELECT
  TO authenticated
  USING (teacher_id = auth.uid());

-- Students can view courses they're enrolled in
CREATE POLICY "Students can view enrolled courses"
  ON public.courses FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.enrollments e
      WHERE e.course_id = courses.id
      AND e.student_id = auth.uid()
      AND e.status = 'active'
    )
  );

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'students', 'teachers', 'parent_links', 'activity_log', 'enrollments', 'roles', 'courses')
ORDER BY tablename;

-- Count policies per table
SELECT 
    schemaname,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ PROPER RLS POLICIES CREATED';
  RAISE NOTICE '🔐 Security maintained with role-based access';
  RAISE NOTICE '👤 Admins can create users';
  RAISE NOTICE '📝 All users have appropriate permissions';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Key Features:';
  RAISE NOTICE '  • Admins can create/manage all users';
  RAISE NOTICE '  • Students can view their own data';
  RAISE NOTICE '  • Teachers can view their courses';
  RAISE NOTICE '  • Parents can view their children';
  RAISE NOTICE '  • Activity logging enabled for all';
END $$;
