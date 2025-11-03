-- ============================================
-- CREATE MISSING TABLES AND APPLY RLS POLICIES
-- Complete setup for user creation system
-- ============================================

-- ============================================
-- CREATE MISSING TABLES
-- ============================================

-- Teachers table
CREATE TABLE IF NOT EXISTS public.teachers (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    employee_id TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    department TEXT,
    subjects TEXT[] DEFAULT '{}',
    is_grade_coordinator BOOLEAN DEFAULT false,
    coordinator_grade_level TEXT,
    is_shs_teacher BOOLEAN DEFAULT false,
    shs_track TEXT,
    shs_strands TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Parent links table
CREATE TABLE IF NOT EXISTS public.parent_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    parent_email TEXT NOT NULL,
    guardian_name TEXT NOT NULL,
    relationship TEXT DEFAULT 'parent',
    contact_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity log table
CREATE TABLE IF NOT EXISTS public.activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enrollments table
CREATE TABLE IF NOT EXISTS public.enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active',
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, course_id)
);

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- DROP EXISTING POLICIES (to avoid conflicts)
-- ============================================

-- Roles table
DROP POLICY IF EXISTS "Authenticated users can read roles" ON public.roles;
DROP POLICY IF EXISTS "Allow authenticated users to read roles" ON public.roles;
DROP POLICY IF EXISTS "Authenticated users can view roles" ON public.roles;

-- Profiles table
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can manage profiles" ON public.profiles;

-- Students table
DROP POLICY IF EXISTS "Students can view own data" ON public.students;
DROP POLICY IF EXISTS "Admins can manage all students" ON public.students;
DROP POLICY IF EXISTS "Admins can manage students" ON public.students;

-- Teachers table
DROP POLICY IF EXISTS "Teachers can view own data" ON public.teachers;
DROP POLICY IF EXISTS "Admins can manage all teachers" ON public.teachers;
DROP POLICY IF EXISTS "Admins can manage teachers" ON public.teachers;

-- Parent links table
DROP POLICY IF EXISTS "Parents can view own links" ON public.parent_links;
DROP POLICY IF EXISTS "Admins can manage all parent links" ON public.parent_links;

-- Activity log table
DROP POLICY IF EXISTS "Users can view own activity" ON public.activity_log;
DROP POLICY IF EXISTS "Admins can view all activity" ON public.activity_log;
DROP POLICY IF EXISTS "Authenticated users can create activity logs" ON public.activity_log;
DROP POLICY IF EXISTS "System can create activity logs" ON public.activity_log;

-- Enrollments table
DROP POLICY IF EXISTS "Students can view own enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Admins can manage all enrollments" ON public.enrollments;

-- Courses table
DROP POLICY IF EXISTS "Admins can manage all courses" ON public.courses;
DROP POLICY IF EXISTS "Teachers can view their courses" ON public.courses;
DROP POLICY IF EXISTS "Students can view enrolled courses" ON public.courses;

-- ============================================
-- CREATE NEW RLS POLICIES
-- ============================================

-- ROLES TABLE
CREATE POLICY "Authenticated users can read roles"
  ON public.roles FOR SELECT
  TO authenticated
  USING (true);

-- PROFILES TABLE
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Admins can insert profiles"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Admins can delete profiles"
  ON public.profiles FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- STUDENTS TABLE
CREATE POLICY "Students can view own data"
  ON public.students FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Admins can manage all students"
  ON public.students FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- TEACHERS TABLE
CREATE POLICY "Teachers can view own data"
  ON public.teachers FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Admins can manage all teachers"
  ON public.teachers FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- PARENT_LINKS TABLE
CREATE POLICY "Parents can view own links"
  ON public.parent_links FOR SELECT
  TO authenticated
  USING (parent_email = (SELECT email FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Admins can manage all parent links"
  ON public.parent_links FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ACTIVITY_LOG TABLE
CREATE POLICY "Users can view own activity"
  ON public.activity_log FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all activity"
  ON public.activity_log FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Authenticated users can create activity logs"
  ON public.activity_log FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ENROLLMENTS TABLE
CREATE POLICY "Students can view own enrollments"
  ON public.enrollments FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY "Admins can manage all enrollments"
  ON public.enrollments FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- COURSES TABLE
CREATE POLICY "Admins can manage all courses"
  ON public.courses FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Teachers can view their courses"
  ON public.courses FOR SELECT
  TO authenticated
  USING (teacher_id = auth.uid());

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
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_teachers_employee_id ON public.teachers(employee_id);
CREATE INDEX IF NOT EXISTS idx_teachers_department ON public.teachers(department);
CREATE INDEX IF NOT EXISTS idx_parent_links_student_id ON public.parent_links(student_id);
CREATE INDEX IF NOT EXISTS idx_parent_links_parent_email ON public.parent_links(parent_email);
CREATE INDEX IF NOT EXISTS idx_activity_log_user_id ON public.activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON public.activity_log(created_at);
CREATE INDEX IF NOT EXISTS idx_enrollments_student_id ON public.enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course_id ON public.enrollments(course_id);

-- ============================================
-- VERIFICATION
-- ============================================

-- Check tables exist
SELECT 
    table_name,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = t.table_name) as policy_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_name IN ('profiles', 'students', 'teachers', 'parent_links', 'activity_log', 'enrollments', 'roles', 'courses')
ORDER BY table_name;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ ALL TABLES CREATED';
  RAISE NOTICE '✅ RLS POLICIES APPLIED';
  RAISE NOTICE '🔐 Security configured with role-based access';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Tables created/verified:';
  RAISE NOTICE '  • profiles';
  RAISE NOTICE '  • students';
  RAISE NOTICE '  • teachers';
  RAISE NOTICE '  • parent_links';
  RAISE NOTICE '  • activity_log';
  RAISE NOTICE '  • enrollments';
  RAISE NOTICE '  • roles';
  RAISE NOTICE '  • courses';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 You can now create users as admin!';
END $$;
