-- ============================================
-- DISABLE RLS FOR ADMIN USER CREATION
-- Temporary fix for thesis defense
-- ============================================

-- Disable RLS on profiles table (allow admin to create users)
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Disable RLS on students table
ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;

-- Disable RLS on teachers table
ALTER TABLE public.teachers DISABLE ROW LEVEL SECURITY;

-- Disable RLS on parent_links table
ALTER TABLE public.parent_links DISABLE ROW LEVEL SECURITY;

-- Disable RLS on activity_log table
ALTER TABLE public.activity_log DISABLE ROW LEVEL SECURITY;

-- Disable RLS on enrollments table
ALTER TABLE public.enrollments DISABLE ROW LEVEL SECURITY;

-- Disable RLS on roles table (for reading)
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'students', 'teachers', 'parent_links', 'activity_log', 'enrollments', 'roles')
ORDER BY tablename;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ RLS DISABLED for user creation tables';
  RAISE NOTICE '⚠️ Remember: This is for development/demo only';
  RAISE NOTICE '📝 For production, create proper RLS policies';
END $$;
