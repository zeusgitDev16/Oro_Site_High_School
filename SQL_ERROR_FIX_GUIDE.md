# 🔧 **SQL ERROR FIX GUIDE**
## **Resolving "column role_id does not exist" Error**

---

## ❌ **The Error You Encountered**

```
ERROR: 42703: column "role_id" does not exist
```

---

## 🎯 **What Caused It**

### **Problem 1: Duplicate SQL Marker**
The original file started with:
```sql
```sql
-- ============================================
```

This extra ````sql` at line 1 caused a syntax error that prevented proper table creation.

### **Problem 2: Execution Order**
The RLS policies tried to reference `role_id` before verifying the column existed, causing the error when the initial table creation failed.

---

## ✅ **THE FIX**

I've created a **corrected version**: `COMPLETE_SUPABASE_SCHEMA_FIXED.sql`

### **What Was Fixed:**

1. ✅ **Removed duplicate SQL marker** at the beginning
2. ✅ **Reordered sections** - Seed data now comes BEFORE functions
3. ✅ **Added DROP POLICY IF EXISTS** statements to prevent conflicts
4. ✅ **Better error handling** throughout the script

---

## 🚀 **HOW TO USE THE FIXED VERSION**

### **Step 1: Clean Up (If Needed)**

If you already ran the broken script, you may need to clean up first:

```sql
-- Option A: Drop all policies (if tables exist but policies failed)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "Users can view own profile" ON public.' || r.tablename;
        EXECUTE 'DROP POLICY IF EXISTS "Admins can view all profiles" ON public.' || r.tablename;
        -- Add more as needed
    END LOOP;
END $$;

-- Option B: Drop all tables and start fresh (DESTRUCTIVE!)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

**⚠️ WARNING:** Option B will delete ALL data. Only use if you have no important data.

### **Step 2: Run the Fixed Script**

1. **Open Supabase Dashboard**
   - Go to: https://fhqzohvtioosycaafnij.supabase.co

2. **Navigate to SQL Editor**
   - Click **SQL Editor** in left sidebar
   - Click **New Query**

3. **Copy the Fixed File**
   - Open: `COMPLETE_SUPABASE_SCHEMA_FIXED.sql`
   - Copy ALL contents (Ctrl+A, Ctrl+C)

4. **Paste and Execute**
   - Paste into SQL Editor
   - Click **Run** (or Ctrl+Enter)
   - Wait for completion (30-60 seconds)

5. **Verify Success**
   - Check for success message in output
   - Go to **Table Editor** → Should see 23 tables
   - Check **Database** → **Roles** → RLS should be enabled

---

## 🔍 **VERIFICATION CHECKLIST**

After running the fixed script, verify everything is correct:

### **1. Check Tables Exist**

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

**Expected:** 23 tables including:
- roles
- permissions
- profiles
- students
- courses
- enrollments
- grades
- attendance
- messages
- notifications
- etc.

### **2. Check role_id Column Exists**

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;
```

**Expected columns:**
- id (uuid)
- created_at (timestamp with time zone)
- full_name (text)
- avatar_url (text)
- **role_id (bigint)** ← This should exist!
- email (text)
- phone (text)
- is_active (boolean)

### **3. Check Roles Table Has Data**

```sql
SELECT * FROM public.roles;
```

**Expected output:**
```
id | name
---+------------------
1  | admin
2  | teacher
3  | student
4  | parent
5  | grade_coordinator
```

### **4. Check RLS is Enabled**

```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Expected:** All tables should have `rowsecurity = true`

### **5. Check Policies Exist**

```sql
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;
```

**Expected:** Each table should have 1-5 policies

### **6. Check Functions Exist**

```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

**Expected functions:**
- get_user_role
- handle_new_user
- is_admin
- is_course_teacher
- is_enrolled
- is_parent_of

---

## 🐛 **TROUBLESHOOTING COMMON ISSUES**

### **Issue 1: "relation already exists"**

**Cause:** Tables already exist from previous run

**Solution:**
```sql
-- Drop specific table
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Or drop all and start fresh
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

### **Issue 2: "policy already exists"**

**Cause:** Policies from previous run

**Solution:** The fixed script includes `DROP POLICY IF EXISTS` statements, so this shouldn't happen. If it does:

```sql
-- Drop all policies on a table
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
-- etc.
```

### **Issue 3: "function already exists"**

**Cause:** Functions from previous run

**Solution:** The fixed script uses `CREATE OR REPLACE FUNCTION`, so this shouldn't happen. If it does:

```sql
DROP FUNCTION IF EXISTS public.get_user_role(UUID);
DROP FUNCTION IF EXISTS public.is_admin(UUID);
-- etc.
```

### **Issue 4: "permission denied for schema public"**

**Cause:** Schema permissions issue

**Solution:**
```sql
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
```

### **Issue 5: Storage bucket errors**

**Cause:** Storage buckets already exist or storage not enabled

**Solution:**
```sql
-- Check if buckets exist
SELECT * FROM storage.buckets;

-- Delete and recreate if needed
DELETE FROM storage.buckets WHERE id IN ('avatars', 'assignments', 'submissions', 'resources');

-- Then re-run the storage section of the script
```

---

## 📊 **COMPARISON: OLD vs FIXED**

| Aspect | Old Script | Fixed Script |
|--------|-----------|--------------|
| **Syntax** | ❌ Extra ````sql` marker | ✅ Clean syntax |
| **Order** | ❌ Functions before seed data | ✅ Seed data before functions |
| **Policies** | ❌ No DROP IF EXISTS | ✅ Includes DROP IF EXISTS |
| **Error Handling** | ❌ Minimal | ✅ Comprehensive |
| **Idempotent** | ❌ Fails on re-run | ✅ Safe to re-run |

---

## ✅ **SUCCESS CRITERIA**

Your database is correctly set up when:

- ✅ All 23 tables exist
- ✅ `profiles.role_id` column exists
- ✅ 5 roles inserted (admin, teacher, student, parent, grade_coordinator)
- ✅ 18 permissions inserted
- ✅ RLS enabled on all tables
- ✅ 50+ policies created
- ✅ 5 functions created
- ✅ 4 storage buckets created
- ✅ No errors in SQL output

---

## 🎯 **NEXT STEPS AFTER FIX**

Once the fixed script runs successfully:

1. **Create Test Users**
   - Go to Authentication → Users
   - Create admin, teacher, student, parent users
   - See `SUPABASE_SETUP_GUIDE.md` for details

2. **Assign Roles**
   ```sql
   -- Get user IDs
   SELECT id, email FROM auth.users;
   
   -- Assign roles
   UPDATE profiles SET role_id = 1 WHERE email = 'admin@orosite.edu.ph';
   UPDATE profiles SET role_id = 2 WHERE email = 'teacher@orosite.edu.ph';
   UPDATE profiles SET role_id = 3 WHERE email = 'student@orosite.edu.ph';
   UPDATE profiles SET role_id = 4 WHERE email = 'parent@orosite.edu.ph';
   ```

3. **Test Flutter App**
   ```bash
   flutter run -d chrome
   ```

4. **Verify Each Role**
   - Login as each user type
   - Verify correct dashboard appears
   - Check console for errors

---

## 📞 **STILL HAVING ISSUES?**

If you're still encountering errors:

1. **Copy the exact error message**
2. **Check which line number failed**
3. **Run this diagnostic query:**

```sql
-- Check what exists
SELECT 
  'Tables' as type, 
  COUNT(*) as count 
FROM information_schema.tables 
WHERE table_schema = 'public'
UNION ALL
SELECT 
  'Functions', 
  COUNT(*) 
FROM information_schema.routines 
WHERE routine_schema = 'public'
UNION ALL
SELECT 
  'Policies', 
  COUNT(*) 
FROM pg_policies 
WHERE schemaname = 'public';
```

4. **Check for specific column:**

```sql
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name = 'role_id';
```

---

## 💡 **PRO TIPS**

1. **Always backup before running SQL scripts**
2. **Test in development environment first**
3. **Run scripts in sections if troubleshooting**
4. **Check Supabase logs** (Dashboard → Database → Logs)
5. **Use transactions for safety:**

```sql
BEGIN;
-- Run your script here
-- If everything looks good:
COMMIT;
-- If something went wrong:
-- ROLLBACK;
```

---

**Fixed Version:** `COMPLETE_SUPABASE_SCHEMA_FIXED.sql`  
**Status:** Ready to use ✅  
**Last Updated:** January 2025
