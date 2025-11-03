# 🎓 Teachers Not Showing in Course Creation - Diagnosis & Fix

## 📋 Issue

Teachers are not appearing in the "Teacher Assignment" section when creating a new course.

---

## 🔍 Root Cause Analysis

The issue is likely one of these:

### **Cause 1: No Teachers in Database** (MOST LIKELY)
- The `teachers` table is empty
- Users with role "teacher" exist in `profiles` table
- But no corresponding records in `teachers` table

### **Cause 2: RLS Policy Blocking**
- RLS on `teachers` table is blocking the query
- Already fixed with `true` policy

### **Cause 3: Data Mismatch**
- Teachers exist but `is_active = false`
- Or `first_name`/`last_name` fields are NULL

---

## ✅ Solution: Add Debug Logging

I've added comprehensive logging to `TeacherService.getActiveTeachers()` to help diagnose the issue.

### **What the Logs Will Show**

When you open the Create Course screen, check the console for:

```
🔍 TeacherService: Fetching active teachers...
✅ TeacherService: Received X teachers
📝 Teacher: John Doe
📝 Teacher: Jane Smith
```

**If you see**:
- `Received 0 teachers` → No teachers in database
- `❌ Error fetching active teachers` → RLS or query issue
- No logs at all → Service not being called

---

## 🧪 Step-by-Step Diagnosis

### **Step 1: Check Console Output**

1. Open your app
2. Open browser console (F12)
3. Navigate to "Create Course" screen
4. Look for the teacher service logs

### **Step 2: Verify Teachers Exist in Database**

Run this query in Supabase SQL Editor:

```sql
-- Check if teachers table has data
SELECT COUNT(*) as teacher_count FROM teachers;

-- Check if teachers are active
SELECT COUNT(*) as active_teachers FROM teachers WHERE is_active = true;

-- See actual teacher data
SELECT 
    t.id,
    t.employee_id,
    t.first_name,
    t.last_name,
    t.is_active,
    p.email,
    p.full_name
FROM teachers t
LEFT JOIN profiles p ON t.id = p.id
LIMIT 10;
```

**Expected Results**:
- `teacher_count` > 0
- `active_teachers` > 0
- Should see teacher names

**If `teacher_count = 0`**:
- You need to create teacher records!
- See "How to Add Teachers" section below

### **Step 3: Check RLS Policies**

Run this query:

```sql
-- Check teachers table RLS
SELECT 
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'teachers';
```

**Expected**: Should have a policy allowing SELECT

---

## 🔧 How to Add Teachers

If you have NO teachers in the database, you need to create them.

### **Option 1: Use Admin Panel (If Available)**

1. Go to Admin Dashboard
2. Click "Manage Users"
3. Click "Add User"
4. Select role: "Teacher"
5. Fill in details
6. Submit

This should create both:
- Profile record (in `profiles` table)
- Teacher record (in `teachers` table)

### **Option 2: Manual SQL Insert**

If you need to add teachers manually:

```sql
-- First, create a profile with teacher role
INSERT INTO profiles (id, email, full_name, role_id, is_active)
VALUES (
    gen_random_uuid(),
    'teacher1@orosite.edu.ph',
    'John Doe',
    2, -- Teacher role
    true
)
RETURNING id;

-- Then, create teacher record (use the UUID from above)
INSERT INTO teachers (
    id,
    employee_id,
    first_name,
    last_name,
    department,
    subjects,
    is_active
)
VALUES (
    'paste-uuid-here', -- UUID from profile insert
    'EMP001',
    'John',
    'Doe',
    'Mathematics',
    '["Mathematics", "Statistics"]'::jsonb,
    true
);
```

### **Option 3: Use ProfileService.createUser()**

The `ProfileService.createUser()` method should automatically create teacher records when `roleId = 2`.

Check if this is working:

```dart
await profileService.createUser(
  email: 'teacher@test.com',
  fullName: 'Test Teacher',
  roleId: 2, // Teacher
  employeeId: 'EMP001',
  department: 'Mathematics',
  subjects: ['Mathematics', 'Science'],
);
```

---

## 🎯 Quick Test

### **Test 1: Check if Teachers Exist**

```sql
SELECT COUNT(*) FROM teachers WHERE is_active = true;
```

**If 0**: You need to add teachers (see above)

### **Test 2: Check if Query Works**

```sql
SELECT 
    t.*,
    p.email,
    p.full_name
FROM teachers t
INNER JOIN profiles p ON t.id = p.id
WHERE t.is_active = true
ORDER BY t.last_name;
```

**If this returns data**: Query works, issue is in Dart code  
**If this returns empty**: No teachers in database

### **Test 3: Check RLS**

```sql
-- This should work (you're authenticated)
SELECT * FROM teachers LIMIT 5;
```

**If error**: RLS is blocking  
**If empty**: No data  
**If shows data**: RLS is fine

---

## 📊 Expected vs Current State

### **Expected State**

```
profiles table:
- id: uuid-1, email: teacher1@..., role_id: 2
- id: uuid-2, email: teacher2@..., role_id: 2

teachers table:
- id: uuid-1, first_name: John, last_name: Doe, is_active: true
- id: uuid-2, first_name: Jane, last_name: Smith, is_active: true
```

### **Current State (Likely)**

```
profiles table:
- id: uuid-1, email: teacher1@..., role_id: 2 ✅

teachers table:
- (empty) ❌
```

---

## 🚀 Action Plan

### **Step 1: Run Diagnosis**

1. Open Create Course screen
2. Check console logs
3. Note what you see

### **Step 2: Check Database**

1. Run SQL query: `SELECT COUNT(*) FROM teachers;`
2. If 0, proceed to Step 3
3. If > 0, check Step 4

### **Step 3: Add Teachers (If None Exist)**

Choose one method:
- Use Admin Panel to add users with teacher role
- Use SQL to manually insert
- Use ProfileService.createUser() in code

### **Step 4: Verify RLS (If Teachers Exist)**

1. Check RLS policies on `teachers` table
2. Should have policy allowing SELECT
3. Test query manually in SQL editor

### **Step 5: Test Again**

1. Refresh app
2. Go to Create Course
3. Check if teachers appear

---

## 🔍 Console Output Guide

### **Success Output**

```
🔍 TeacherService: Fetching active teachers...
✅ TeacherService: Received 3 teachers
📝 Teacher: John Doe
📝 Teacher: Jane Smith
📝 Teacher: Bob Johnson
```

### **No Teachers Output**

```
🔍 TeacherService: Fetching active teachers...
✅ TeacherService: Received 0 teachers
```

**Action**: Add teachers to database

### **Error Output**

```
🔍 TeacherService: Fetching active teachers...
❌ Error fetching active teachers: PostgrestException...
❌ Postgrest error: ...
```

**Action**: Check RLS policies or table structure

---

## 📝 Summary

### **The Issue**
Teachers not showing in course creation dropdown

### **Most Likely Cause**
No teacher records in `teachers` table

### **The Fix**
1. Check console logs (now added)
2. Verify teachers exist in database
3. Add teachers if missing
4. Verify RLS policies allow reading

### **Next Steps**
1. Open Create Course screen
2. Check console output
3. Share the logs with me
4. I'll help you fix the specific issue

---

**Status**: ✅ Debug logging added  
**Next**: Check console output and share results
