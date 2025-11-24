-- ============================================
-- FIX RLS POLICIES FOR SELF-REGISTRATION
-- ============================================
-- This migration fixes RLS policies to allow users to create their own
-- profile and role-specific records during first-time Azure AD login.
--
-- PROBLEM: When a new user logs in via Azure AD with an assigned role,
-- they need to create their own profile and role-specific record
-- (student, teacher, admin, parent). The previous policies only allowed
-- admins to insert records, blocking new users from self-registration.
--
-- SOLUTION: Update INSERT policies to allow users to insert their own
-- records (where auth.uid() = id) OR admins can insert any record.
-- ============================================

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
-- Allow users to create their own profile during first login
DROP POLICY IF EXISTS "profiles_insert_admin" ON profiles;

CREATE POLICY "profiles_insert_self_or_admin" 
ON profiles 
FOR INSERT 
TO authenticated 
WITH CHECK (
  auth.uid() = id OR is_admin()
);

COMMENT ON POLICY "profiles_insert_self_or_admin" ON profiles IS 
'Allows users to create their own profile during first login, or admins to create any profile';


-- ============================================
-- 2. STUDENTS TABLE
-- ============================================
-- Allow students to create their own student record during first login
DROP POLICY IF EXISTS "students_insert_admin" ON students;

CREATE POLICY "students_insert_self_or_admin" 
ON students 
FOR INSERT 
TO authenticated 
WITH CHECK (
  auth.uid() = id OR is_admin()
);

COMMENT ON POLICY "students_insert_self_or_admin" ON students IS 
'Allows students to create their own student record during first login, or admins to create any student record';


-- ============================================
-- 3. TEACHERS TABLE
-- ============================================
-- Allow teachers to create their own teacher record during first login
CREATE POLICY "teachers_insert_self_or_admin" 
ON teachers 
FOR INSERT 
TO authenticated 
WITH CHECK (
  auth.uid() = id OR is_admin()
);

COMMENT ON POLICY "teachers_insert_self_or_admin" ON teachers IS 
'Allows teachers to create their own teacher record during first login, or admins to create any teacher record';


-- ============================================
-- 4. ADMINS TABLE
-- ============================================
-- Allow admins to create their own admin record during first login
CREATE POLICY "admins_insert_self" 
ON admins 
FOR INSERT 
TO authenticated 
WITH CHECK (
  auth.uid() = id
);

CREATE POLICY "admins_select_self_or_admin" 
ON admins 
FOR SELECT 
TO authenticated 
USING (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "admins_update_admin" 
ON admins 
FOR UPDATE 
TO authenticated 
USING (is_admin()) 
WITH CHECK (is_admin());

CREATE POLICY "admins_delete_admin" 
ON admins 
FOR DELETE 
TO authenticated 
USING (is_admin());

COMMENT ON POLICY "admins_insert_self" ON admins IS 
'Allows admins to create their own admin record during first login';


-- ============================================
-- 5. PARENTS TABLE
-- ============================================
-- Allow parents to create their own parent record during first login
CREATE POLICY "parents_insert_self_or_admin" 
ON parents 
FOR INSERT 
TO authenticated 
WITH CHECK (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "parents_select_self_or_admin" 
ON parents 
FOR SELECT 
TO authenticated 
USING (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "parents_update_self_or_admin" 
ON parents 
FOR UPDATE 
TO authenticated 
USING (auth.uid() = id OR is_admin()) 
WITH CHECK (auth.uid() = id OR is_admin());

CREATE POLICY "parents_delete_admin" 
ON parents 
FOR DELETE 
TO authenticated 
USING (is_admin());

COMMENT ON POLICY "parents_insert_self_or_admin" ON parents IS
'Allows parents to create their own parent record during first login, or admins to create any parent record';


-- ============================================
-- 6. ICT_COORDINATORS TABLE
-- ============================================
-- Allow ICT coordinators to create their own record during first login
DROP POLICY IF EXISTS "ict_coordinators_insert_admin" ON ict_coordinators;

CREATE POLICY "ict_coordinators_insert_self_or_admin"
ON ict_coordinators
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "ict_coordinators_select_self_or_admin"
ON ict_coordinators
FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "ict_coordinators_update_self_or_admin"
ON ict_coordinators
FOR UPDATE
TO authenticated
USING (auth.uid() = id OR is_admin())
WITH CHECK (auth.uid() = id OR is_admin());

COMMENT ON POLICY "ict_coordinators_insert_self_or_admin" ON ict_coordinators IS
'Allows ICT coordinators to create their own record during first login, or admins to create any ICT coordinator record';


-- ============================================
-- 7. GRADE_COORDINATORS TABLE
-- ============================================
-- Allow grade coordinators to create their own record during first login
DROP POLICY IF EXISTS "grade_coordinators_insert_admin" ON grade_coordinators;

CREATE POLICY "grade_coordinators_insert_self_or_admin"
ON grade_coordinators
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "grade_coordinators_select_self_or_admin"
ON grade_coordinators
FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "grade_coordinators_update_self_or_admin"
ON grade_coordinators
FOR UPDATE
TO authenticated
USING (auth.uid() = id OR is_admin())
WITH CHECK (auth.uid() = id OR is_admin());

COMMENT ON POLICY "grade_coordinators_insert_self_or_admin" ON grade_coordinators IS
'Allows grade coordinators to create their own record during first login, or admins to create any grade coordinator record';


-- ============================================
-- 8. HYBRID_USERS TABLE
-- ============================================
-- Allow hybrid users to create their own record during first login
DROP POLICY IF EXISTS "hybrid_users_insert_admin" ON hybrid_users;

CREATE POLICY "hybrid_users_insert_self_or_admin"
ON hybrid_users
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "hybrid_users_select_self_or_admin"
ON hybrid_users
FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR is_admin()
);

CREATE POLICY "hybrid_users_update_self_or_admin"
ON hybrid_users
FOR UPDATE
TO authenticated
USING (auth.uid() = id OR is_admin())
WITH CHECK (auth.uid() = id OR is_admin());

COMMENT ON POLICY "hybrid_users_insert_self_or_admin" ON hybrid_users IS
'Allows hybrid users to create their own record during first login, or admins to create any hybrid user record';


-- ============================================
-- VERIFICATION
-- ============================================
-- Verify all policies are in place
SELECT
  tablename,
  policyname,
  cmd,
  CASE
    WHEN with_check IS NOT NULL THEN 'WITH CHECK: ' || with_check
    WHEN qual IS NOT NULL THEN 'USING: ' || qual
    ELSE 'N/A'
  END as policy_condition
FROM pg_policies
WHERE tablename IN ('profiles', 'students', 'teachers', 'admins', 'parents',
                    'ict_coordinators', 'grade_coordinators', 'hybrid_users')
  AND cmd = 'INSERT'
ORDER BY tablename, policyname;

