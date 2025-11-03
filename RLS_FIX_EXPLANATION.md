# 🔒 RLS and User Visibility Fix - Complete Explanation

## 📋 Issues Identified

### **Issue 1: Teachers Table "Unrestricted"** ⚠️

**What it means**:
- The `teachers` table shows as "Unrestricted" in Supabase
- This means **Row Level Security (RLS) is NOT enabled**
- Without RLS, the table is accessible to EVERYONE (major security risk)

**Why it's a problem**:
- Anyone can read/write teacher data
- No access control
- Security vulnerability

---

### **Issue 2: Only Admin Visible in Manage Users** 👤

**What's happening**:
- When you go to "Manage Users", only the current admin appears
- Teachers, students, and other users don't show up
- The list is empty except for your own account

**Root cause**:
- **RLS policies on `profiles` table are too restrictive**
- The policy only allows users to see their OWN profile
- Admins need a special policy to see ALL profiles

**Current problematic policy**:
```sql
-- This only lets you see YOUR OWN profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (id = auth.uid());
```

**What's missing**:
```sql
-- Admins need THIS policy to see ALL profiles
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role_id = 1 -- Admin role
    )
);
```

---

### **Issue 3: No Teachers in Course Creation** 🎓

**What's happening**:
- When creating a course, the teacher dropdown is empty
- No teachers appear for selection
- This is a **cascading effect** of Issues 1 and 2

**Why it happens**:
1. `TeacherService.getActiveTeachers()` tries to fetch teachers
2. It queries the `teachers` table
3. RLS blocks the query (or returns empty)
4. No teachers returned to UI
5. Dropdown is empty

**The query that's failing**:
```dart
final response = await _supabase
    .from('teachers')
    .select('*, profiles!inner(email, full_name, phone)')
    .eq('is_active', true)
    .order('last_name');
```

---

## 🔍 Understanding Your Database Structure

### **How Users Work in Your System**

```
┌─────────────────────────────────────────────────────────┐
│                    auth.users                           │
│  (Firebase/Supabase Auth - managed by Supabase)        │
│  - id (UUID)                                            │
│  - email                                                │
│  - encrypted_password                                   │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ (Foreign Key)
                 │
┌────────────────▼────────────────────────────────────────┐
│                    profiles                             │
│  (Your main user table - ALL users here)               │
│  - id (UUID, FK to auth.users)                         │
│  - email                                                │
│  - full_name                                            │
│  - role_id (1=Admin, 2=Teacher, 3=Student, etc.)       │
│  - is_active                                            │
└────────────────┬────────────────────────────────────────┘
                 │
                 ├────────────────���┬─────────────────┐
                 │                 │                 │
┌────────────────▼──┐  ┌───────────▼──┐  ┌──────────▼──────┐
│    teachers       │  │   students   │  │   (other roles) │
│  (role_id = 2)    │  │ (role_id = 3)│  │                 │
│  - id (FK)        │  │ - id (FK)    │  │                 │
│  - employee_id    │  │ - lrn        │  │                 │
│  - department     │  │ - grade      │  │                 │
│  - subjects       │  │ - section    │  │                 │
└───────────────────┘  └──────────────┘  └─────────────────┘
```

### **Key Points**

1. **`profiles` table = ALL users**
   - Every user (admin, teacher, student, parent) has a record here
   - This is your main user table
   - Role is determined by `role_id`

2. **`teachers` table = Teacher-specific data**
   - Only teachers have records here
   - Links to `profiles` via `id` (foreign key)
   - Contains teacher-specific fields (employee_id, subjects, etc.)

3. **`students` table = Student-specific data**
   - Only students have records here
   - Links to `profiles` via `id` (foreign key)
   - Contains student-specific fields (LRN, grade, section, etc.)

---

## 🔧 The Fix

### **What the SQL Script Does**

#### **1. Enables RLS on Teachers Table**
```sql
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
```
- Turns on Row Level Security
- Now policies control who can access teacher data

#### **2. Creates 3 Policies for Teachers Table**

**Policy A: Admins can manage teachers**
```sql
CREATE POLICY "Admins can manage teachers"
ON teachers FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1 -- Admin role
    )
);
```
- Admins (role_id = 1) can do EVERYTHING with teachers
- SELECT, INSERT, UPDATE, DELETE all allowed

**Policy B: Teachers can view their own record**
```sql
CREATE POLICY "Teachers can view own record"
ON teachers FOR SELECT
USING (id = auth.uid());
```
- Teachers can see their own teacher record
- Can't see other teachers

**Policy C: Anyone can view active teachers**
```sql
CREATE POLICY "Anyone can view active teachers"
ON teachers FOR SELECT
USING (is_active = TRUE);
```
- **This is the key for course creation!**
- Any authenticated user can see active teachers
- Needed for dropdowns, lists, etc.

#### **3. Fixes Profiles Table Policies**

**The Critical Fix**:
```sql
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role_id = 1 -- Admin role
    )
);
```

**What this does**:
- Checks if the current user (`auth.uid()`) is an admin
- If yes, they can see ALL profiles
- This fixes the "Manage Users" screen

#### **4. Updates Students Table Policies**

Similar policies for students:
- Students can view own record
- Admins can manage all students
- Teachers can view students (for their courses)

---

## ✅ How to Apply the Fix

### **Step 1: Open Supabase SQL Editor**
```
1. Go to your Supabase Dashboard
2. Click "SQL Editor" in the left sidebar
3. Click "New Query"
```

### **Step 2: Run the Fix Script**
```
1. Open the file: FIX_RLS_AND_USER_VISIBILITY.sql
2. Copy the ENTIRE contents
3. Paste into Supabase SQL Editor
4. Click "Run" (or press Ctrl+Enter)
```

### **Step 3: Verify Success**
```
1. Check for success messages in the output
2. Look for: "✅ RLS AND USER VISIBILITY FIX COMPLETE!"
3. No errors should appear
```

### **Step 4: Refresh and Test**

**Test 1: Check Teachers Table**
```
1. Go to Supabase → Table Editor
2. Find "teachers" table
3. Should NO LONGER show "Unrestricted"
4. Should show "RLS enabled" or similar
```

**Test 2: Check Manage Users**
```
1. Go to your app → Admin Dashboard
2. Click "Manage Users" or "Users"
3. Should now see ALL users (not just admin)
4. Should see teachers, students, etc.
```

**Test 3: Check Course Creation**
```
1. Go to Admin → Courses → Create Course
2. Scroll to "Teacher Assignment" section
3. Should now see teacher names
4. Should be able to select teachers
```

---

## 🧪 Verification Queries

After running the fix, you can verify with these queries:

### **Query 1: Check RLS Status**
```sql
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'teachers', 'students')
ORDER BY tablename;
```

**Expected Result**:
```
tablename  | rls_enabled
-----------+-------------
profiles   | true
students   | true
teachers   | true
```

### **Query 2: Check Policies on Teachers**
```sql
SELECT 
    policyname,
    cmd
FROM pg_policies
WHERE tablename = 'teachers'
ORDER BY policyname;
```

**Expected Result**:
```
policyname                      | cmd
--------------------------------+--------
Admins can manage teachers      | ALL
Anyone can view active teachers | SELECT
Teachers can view own record    | SELECT
```

### **Query 3: Test Fetching All Users**
```sql
SELECT 
    p.id,
    p.email,
    p.full_name,
    r.name AS role,
    p.is_active
FROM profiles p
LEFT JOIN roles r ON p.role_id = r.id
WHERE p.is_active = TRUE
ORDER BY r.name, p.full_name;
```

**Expected Result**: Should show ALL users (admins, teachers, students, etc.)

### **Query 4: Test Fetching Teachers**
```sql
SELECT 
    t.id,
    t.employee_id,
    t.first_name,
    t.last_name,
    p.email,
    p.full_name
FROM teachers t
INNER JOIN profiles p ON t.id = p.id
WHERE t.is_active = TRUE
ORDER BY t.last_name;
```

**Expected Result**: Should show all active teachers

---

## 🎯 Why This Happens

### **Understanding RLS (Row Level Security)**

**What is RLS?**
- A security feature in PostgreSQL/Supabase
- Controls who can see/modify which rows
- Works at the database level (not app level)

**How RLS Works**:
```
User makes query → RLS checks policies → Returns only allowed rows
```

**Example**:
```sql
-- User queries: SELECT * FROM profiles;

-- RLS applies policies:
-- Policy 1: Can see own profile (id = auth.uid())
-- Policy 2: If admin, can see all profiles

-- Result: Returns rows based on policies
```

### **Why Your Issues Occurred**

**Issue 1: Teachers "Unrestricted"**
- RLS was never enabled on `teachers` table
- Table was created without RLS
- Anyone could access it (security risk)

**Issue 2: Only Admin Visible**
- `profiles` table had RLS enabled
- But only had "view own profile" policy
- Missing "admins can view all" policy
- So admins could only see themselves

**Issue 3: No Teachers in Dropdown**
- `TeacherService` queries `teachers` table
- RLS blocks the query (no policy allows it)
- Or returns empty (no matching rows)
- UI gets empty array
- Dropdown shows nothing

---

## 🔐 Security Best Practices

### **What We Implemented**

✅ **Principle of Least Privilege**
- Users can only see their own data by default
- Admins get elevated permissions
- Teachers can see relevant student data

✅ **Role-Based Access Control (RBAC)**
- Permissions based on `role_id`
- Admin (1), Teacher (2), Student (3), etc.
- Policies check role before allowing access

✅ **Defense in Depth**
- RLS at database level
- Service layer validation
- UI-level checks

### **Policy Design Pattern**

```sql
-- Pattern: Check if user has required role
CREATE POLICY "policy_name"
ON table_name FOR operation
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = required_role_id
    )
);
```

---

## 📊 Before vs After

### **Before Fix**

| Issue | Status | Impact |
|-------|--------|--------|
| Teachers table RLS | ❌ Disabled | Security risk |
| Manage Users | ❌ Only shows admin | Can't manage users |
| Course creation | ❌ No teachers | Can't assign teachers |
| Teacher visibility | ❌ Blocked by RLS | Services fail |

### **After Fix**

| Issue | Status | Impact |
|-------|--------|--------|
| Teachers table RLS | ✅ Enabled | Secure |
| Manage Users | ✅ Shows all users | Full user management |
| Course creation | ✅ Shows teachers | Can assign teachers |
| Teacher visibility | ✅ Allowed by policy | Services work |

---

## 🚨 Common Errors and Solutions

### **Error 1: "new row violates row-level security policy"**

**Cause**: Trying to insert/update without proper policy

**Solution**: 
```sql
-- Add policy for INSERT
CREATE POLICY "Admins can insert"
ON table_name FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role_id = 1
    )
);
```

### **Error 2: "permission denied for table"**

**Cause**: RLS is enabled but no policies exist

**Solution**: Create at least one policy that matches your use case

### **Error 3: Query returns empty but data exists**

**Cause**: RLS policies are filtering out all rows

**Solution**: Check policies with:
```sql
SELECT * FROM pg_policies WHERE tablename = 'your_table';
```

---

## 🎓 For Your Thesis Defense

### **What to Explain**

1. **Security Implementation**
   - "We use Row Level Security for data protection"
   - "Users can only access data they're authorized to see"
   - "Admins have elevated permissions for management"

2. **Role-Based Access**
   - "System has 5 roles: Admin, Teacher, Student, Parent, Coordinator"
   - "Each role has specific permissions"
   - "Enforced at database level, not just UI"

3. **Data Isolation**
   - "Students can only see their own data"
   - "Teachers can see their students and courses"
   - "Admins can manage everything"

### **Demo Points**

1. Show Supabase dashboard with RLS enabled
2. Show policies in SQL Editor
3. Demonstrate Manage Users showing all users
4. Show course creation with teacher selection
5. Explain how RLS protects data

---

## ✅ Success Checklist

After applying the fix, verify:

- [ ] Teachers table no longer shows "Unrestricted"
- [ ] Manage Users shows all users (not just admin)
- [ ] Teachers appear in course creation dropdown
- [ ] Can select and assign teachers to courses
- [ ] RLS policies visible in Supabase dashboard
- [ ] No console errors when fetching users
- [ ] No console errors when fetching teachers
- [ ] Course creation works end-to-end

---

## 📝 Summary

### **What Was Wrong**
1. Teachers table had no RLS (security risk)
2. Profiles table policies too restrictive (admins couldn't see all users)
3. No policy allowing teacher visibility (dropdowns empty)

### **What We Fixed**
1. Enabled RLS on teachers table
2. Created 3 policies for teachers (admin, self, public view)
3. Added "admins can view all" policy for profiles
4. Updated students table policies for consistency

### **Result**
- ✅ Secure database with proper RLS
- ✅ Admins can see and manage all users
- ✅ Teachers visible in course creation
- ✅ System works as intended

---

**Status**: ✅ Fix Ready to Apply  
**Risk**: Low (only adds/updates policies, doesn't modify data)  
**Time**: 2-3 minutes to execute  
**Impact**: Immediate - fixes all 3 issues

---

## 🚀 Next Steps

1. **Apply the fix** - Run `FIX_RLS_AND_USER_VISIBILITY.sql`
2. **Verify** - Check all 3 issues are resolved
3. **Test** - Create a course and assign teachers
4. **Document** - Note the fix in your thesis documentation

Your system will be fully functional after this fix! 🎉
