-- ============================================
-- FIX: Profile Creation on Azure Login
-- ============================================

-- 1. Check if profiles table allows inserts
-- Run this first to see current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 2. Drop existing restrictive policies that might block inserts
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- 3. Create new policies that allow profile creation
CREATE POLICY "Enable insert for authenticated users"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Enable read for authenticated users"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 4. Verify roles table has data
SELECT * FROM roles;

-- If empty, insert roles
INSERT INTO roles (id, name, created_at) VALUES
  (1, 'admin', NOW()),
  (2, 'teacher', NOW()),
  (3, 'student', NOW()),
  (4, 'parent', NOW()),
  (5, 'coordinator', NOW())
ON CONFLICT (id) DO NOTHING;

-- 5. Check if your auth user exists
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'admin@aezycreativegmail.onmicrosoft.com';

-- 6. Manually create your profile (use the ID from step 5)
-- REPLACE 'YOUR_USER_ID' with the actual ID from step 5
INSERT INTO profiles (id, email, full_name, role_id, is_active, created_at)
VALUES (
  '142c7f32-de38-4a9f-a978-2768fe67cdc9',  -- Replace with your actual user ID
  'admin@aezycreativegmail.onmicrosoft.com',
  'Admin User',
  1,
  true,
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  updated_at = NOW();

-- 7. Verify profile was created
SELECT * FROM profiles WHERE email = 'admin@aezycreativegmail.onmicrosoft.com';

-- ============================================
-- COMPLETION MESSAGE
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Profile creation policies updated!';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Check if your profile was created (step 7 above)';
  RAISE NOTICE '2. Logout and login again';
  RAISE NOTICE '3. Profile should auto-create on next login';
END $$;
