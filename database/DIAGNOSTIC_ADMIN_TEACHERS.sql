-- ============================================
-- DIAGNOSTIC: Admin Teachers Access
-- Run this in Supabase SQL Editor (logged in as admin)
-- ============================================

-- STEP 1: Who am I?
SELECT 
    '=== STEP 1: MY USER INFO ===' as section,
    auth.uid() as my_user_id,
    auth.email() as my_email;

-- STEP 2: My profile and role
SELECT 
    '=== STEP 2: MY PROFILE ===' as section,
    id,
    email,
    role,
    full_name
FROM profiles
WHERE id = auth.uid();

-- STEP 3: Check if I'm an admin
SELECT 
    '=== STEP 3: AM I ADMIN? ===' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM admins WHERE id = auth.uid()) THEN '✅ YES - Admin record exists'
        ELSE '❌ NO - No admin record'
    END as admin_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN '✅ YES - Profile role is admin'
        ELSE '❌ NO - Profile role is not admin'
    END as profile_role_status;

-- STEP 4: Count teachers in database
SELECT 
    '=== STEP 4: TEACHERS IN DATABASE ===' as section,
    COUNT(*) as total_teachers,
    COUNT(*) FILTER (WHERE is_active = true) as active_teachers,
    COUNT(*) FILTER (WHERE is_active = false) as inactive_teachers
FROM teachers;

-- STEP 5: Sample teachers (first 5)
SELECT 
    '=== STEP 5: SAMPLE TEACHERS ===' as section,
    id,
    employee_id,
    first_name,
    last_name,
    is_active
FROM teachers
ORDER BY last_name
LIMIT 5;

-- STEP 6: Check if I can access teachers table
SELECT 
    '=== STEP 6: CAN I ACCESS TEACHERS? ===' as section,
    COUNT(*) as accessible_teachers
FROM teachers;

-- STEP 7: Check teachers with profiles join (what the app does)
SELECT 
    '=== STEP 7: TEACHERS WITH PROFILES JOIN ===' as section,
    t.id,
    t.first_name,
    t.last_name,
    p.email,
    p.full_name,
    t.is_active
FROM teachers t
INNER JOIN profiles p ON p.id = t.id
WHERE t.is_active = true
ORDER BY t.last_name
LIMIT 5;

-- STEP 8: Check RLS policies on teachers table
SELECT 
    '=== STEP 8: TEACHERS TABLE RLS POLICIES ===' as section,
    policyname,
    cmd as command,
    qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'teachers'
ORDER BY policyname;

-- STEP 9: Check if RLS is enabled on teachers table
SELECT 
    '=== STEP 9: RLS STATUS ===' as section,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ENABLED'
        ELSE '❌ RLS DISABLED'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'teachers';

-- STEP 10: Final diagnosis
SELECT 
    '=== STEP 10: DIAGNOSIS ===' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM teachers WHERE is_active = true) = 0 THEN 
            '❌ NO ACTIVE TEACHERS IN DATABASE'
        WHEN NOT EXISTS (SELECT 1 FROM admins WHERE id = auth.uid()) AND 
             NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN 
            '❌ YOU ARE NOT AN ADMIN'
        WHEN (SELECT COUNT(*) FROM teachers) > 0 AND 
             (SELECT COUNT(*) FROM teachers) != (SELECT COUNT(*) FROM teachers WHERE true) THEN 
            '❌ RLS IS BLOCKING ACCESS TO TEACHERS'
        ELSE 
            '✅ SHOULD BE ABLE TO SEE TEACHERS'
    END as diagnosis;

-- ============================================
-- DIAGNOSTIC COMPLETE
-- ============================================
SELECT '=== DIAGNOSTIC COMPLETE ===' as section,
       'Review all steps above' as message;

