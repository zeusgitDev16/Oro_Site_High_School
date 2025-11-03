-- ============================================
-- FIX AUTH GATE - ALLOW USERS TO READ OWN PROFILE
-- This fixes the "Unable to determine user role" error
-- ============================================

-- Drop existing SELECT policies on profiles
DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- Create simple policy: Users can ALWAYS read their own profile
CREATE POLICY "profiles_select_own"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Create policy: Admins can read all profiles
CREATE POLICY "profiles_select_admin"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = auth.uid() AND r.name = 'admin'
    )
  );

-- Ensure roles table is readable by all authenticated users
DROP POLICY IF EXISTS "roles_select_all" ON public.roles;
DROP POLICY IF EXISTS "Authenticated users can read roles" ON public.roles;

CREATE POLICY "roles_select_authenticated"
  ON public.roles FOR SELECT
  TO authenticated
  USING (true);

-- Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as command
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'roles')
ORDER BY tablename, policyname;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ AUTH GATE FIX APPLIED!';
  RAISE NOTICE '';
  RAISE NOTICE '🔐 Users can now:';
  RAISE NOTICE '  • Read their own profile';
  RAISE NOTICE '  • Read roles table';
  RAISE NOTICE '  • Login successfully';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Try logging in again!';
END $$;
