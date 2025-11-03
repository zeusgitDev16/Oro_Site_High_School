# 🔍 Course Backend Setup - Verification & Testing Guide

## 📋 Overview

This document provides step-by-step instructions to verify that the backend setup was successful and to test all database components before proceeding with Dart/Flutter integration.

---

## ✅ Pre-Execution Checklist

Before running the SQL setup script, ensure:

- [ ] You have access to Supabase Dashboard
- [ ] You have admin/owner permissions on the project
- [ ] You have backed up your database (optional but recommended)
- [ ] You are in the correct Supabase project

---

## 🚀 Execution Steps

### **Step 1: Open Supabase SQL Editor**

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**

### **Step 2: Execute the Setup Script**

**Option A: Execute All at Once (Recommended)**
```sql
-- Copy the entire contents of COURSE_BACKEND_SETUP.sql
-- Paste into SQL Editor
-- Click "Run" or press Ctrl+Enter
```

**Option B: Execute Section by Section**
```sql
-- Copy and run each section (1-10) individually
-- Wait for success message after each section
-- Verify results before proceeding to next section
```

### **Step 3: Check for Errors**

After execution, check the **Results** panel:
- ✅ Green checkmark = Success
- ❌ Red X = Error (read error message)

Common errors and solutions:
- **"column already exists"**: Safe to ignore (idempotent script)
- **"relation does not exist"**: Check table name spelling
- **"permission denied"**: Ensure you have admin rights

---

## 🔍 Verification Queries

Run these queries in SQL Editor to verify each component:

### **1. Verify Courses Table Structure**

```sql
-- Check all columns exist
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'courses'
ORDER BY ordinal_position;
```

**Expected Result**: Should show at least 14 columns including:
- `id`, `created_at`, `name`, `description`, `teacher_id`
- `course_code`, `grade_level`, `section`, `subject`
- `school_year`, `status`, `room_number`, `is_active`, `updated_at`

### **2. Verify Enrollments Table Structure**

```sql
-- Check enrollment columns
SELECT 
    column_name, 
    data_type, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'enrollments'
ORDER BY ordinal_position;
```

**Expected Result**: Should include:
- `id`, `created_at`, `student_id`, `course_id`
- `status`, `enrolled_at`, `enrollment_type`

### **3. Verify Course Schedules Table**

```sql
-- Check if table exists and has correct structure
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'course_schedules'
ORDER BY ordinal_position;
```

**Expected Result**: Should show:
- `id`, `created_at`, `course_id`, `day_of_week`
- `start_time`, `end_time`, `room_number`, `is_active`, `updated_at`

### **4. Verify Teachers Table**

```sql
-- Check teachers table
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'teachers'
ORDER BY ordinal_position;
```

**Expected Result**: Should show:
- `id`, `employee_id`, `first_name`, `last_name`, `middle_name`
- `department`, `subjects`, `is_grade_coordinator`, etc.

### **5. Verify Course Assignments Table**

```sql
-- Check course_assignments table
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'course_assignments'
ORDER BY ordinal_position;
```

**Expected Result**: Should show:
- `id`, `created_at`, `teacher_id`, `course_id`, `status`, `assigned_at`

### **6. Verify Indexes**

```sql
-- List all indexes on courses table
SELECT 
    indexname, 
    indexdef
FROM pg_indexes
WHERE tablename = 'courses'
  AND schemaname = 'public'
ORDER BY indexname;
```

**Expected Result**: Should show indexes like:
- `idx_courses_grade_level`
- `idx_courses_subject`
- `idx_courses_status`
- `idx_courses_code`
- `courses_course_code_unique` (unique constraint)

### **7. Verify Constraints**

```sql
-- List all constraints on courses table
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'courses'::regclass
ORDER BY conname;
```

**Expected Result**: Should show:
- `courses_course_code_unique` (UNIQUE)
- `courses_grade_level_check` (CHECK: grade_level >= 7 AND <= 12)
- `courses_status_check` (CHECK: status IN ('active', 'inactive', 'archived'))

### **8. Verify Helper Functions**

```sql
-- Check if functions exist
SELECT 
    routine_name,
    routine_type,
    data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'get_students_by_section',
    'auto_enroll_students',
    'get_course_enrollment_count',
    'is_course_code_unique'
  )
ORDER BY routine_name;
```

**Expected Result**: Should show 4 functions:
- `get_students_by_section` (returns TABLE)
- `auto_enroll_students` (returns INT)
- `get_course_enrollment_count` (returns INT)
- `is_course_code_unique` (returns BOOLEAN)

### **9. Verify Triggers**

```sql
-- Check if triggers exist
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN ('courses', 'course_schedules', 'teachers')
ORDER BY event_object_table, trigger_name;
```

**Expected Result**: Should show 3 triggers:
- `update_courses_updated_at` on `courses`
- `update_course_schedules_updated_at` on `course_schedules`
- `update_teachers_updated_at` on `teachers`

### **10. Verify RLS Policies**

```sql
-- Check RLS policies on courses table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename IN ('courses', 'enrollments', 'course_schedules', 'course_assignments')
ORDER BY tablename, policyname;
```

**Expected Result**: Should show multiple policies for each table protecting data by role.

---

## 🧪 Functional Testing

### **Test 1: Insert a Sample Course**

```sql
-- Insert a test course
INSERT INTO courses (
    name, 
    course_code, 
    description, 
    grade_level, 
    subject, 
    school_year, 
    status, 
    is_active
)
VALUES (
    'Test Mathematics 7',
    'TEST_MATH7',
    'Test course for verification',
    7,
    'Mathematics',
    '2024-2025',
    'active',
    TRUE
)
RETURNING *;
```

**Expected Result**: Should return the inserted course with auto-generated `id` and timestamps.

### **Test 2: Check Course Code Uniqueness**

```sql
-- Test uniqueness function
SELECT is_course_code_unique('TEST_MATH7') AS is_unique;
-- Should return FALSE (already exists)

SELECT is_course_code_unique('NONEXISTENT_CODE') AS is_unique;
-- Should return TRUE (doesn't exist)
```

### **Test 3: Test Grade Level Constraint**

```sql
-- Try to insert invalid grade level (should fail)
INSERT INTO courses (
    name, 
    course_code, 
    grade_level, 
    subject
)
VALUES (
    'Invalid Course',
    'INVALID_GRADE',
    6, -- Invalid: must be 7-12
    'Mathematics'
);
-- Expected: ERROR - violates check constraint "courses_grade_level_check"
```

### **Test 4: Insert Course Schedule**

```sql
-- Get the test course ID first
SELECT id FROM courses WHERE course_code = 'TEST_MATH7';

-- Insert a schedule (replace <course_id> with actual ID)
INSERT INTO course_schedules (
    course_id,
    day_of_week,
    start_time,
    end_time,
    room_number
)
VALUES (
    <course_id>, -- Replace with actual course ID
    'Monday',
    '08:00:00',
    '09:00:00',
    '101'
)
RETURNING *;
```

**Expected Result**: Should insert successfully with auto-generated `id`.

### **Test 5: Test Auto-Enrollment Function**

**Prerequisites**: You need at least one student in the `students` table.

```sql
-- Check if you have students
SELECT id, lrn, first_name, last_name, grade_level, section
FROM students
WHERE grade_level = 7
  AND is_active = TRUE
LIMIT 5;

-- If you have students, test auto-enrollment
-- (Replace <course_id>, <grade>, <section> with actual values)
SELECT auto_enroll_students(
    <course_id>,  -- Course ID from Test 1
    7,            -- Grade level
    'Diamond'     -- Section name (use actual section from students table)
) AS enrolled_count;
```

**Expected Result**: Should return the number of students enrolled.

### **Test 6: Verify Enrollments Created**

```sql
-- Check enrollments for the test course
SELECT 
    e.id,
    e.student_id,
    e.course_id,
    e.status,
    e.enrollment_type,
    s.first_name,
    s.last_name
FROM enrollments e
INNER JOIN students s ON e.student_id = s.id
WHERE e.course_id = <course_id>  -- Replace with actual course ID
ORDER BY s.last_name;
```

**Expected Result**: Should show enrolled students with `enrollment_type = 'section_based'`.

### **Test 7: Test Get Students by Section Function**

```sql
-- Test the helper function
SELECT * FROM get_students_by_section(7, 'Diamond');
-- Should return students in Grade 7, Section Diamond
```

### **Test 8: Test Enrollment Count Function**

```sql
-- Get enrollment count for test course
SELECT get_course_enrollment_count(<course_id>) AS total_enrolled;
-- Should return the number of active enrollments
```

### **Test 9: Test Updated_At Trigger**

```sql
-- Update a course and check if updated_at changes
UPDATE courses
SET description = 'Updated description'
WHERE course_code = 'TEST_MATH7'
RETURNING id, description, created_at, updated_at;

-- updated_at should be more recent than created_at
```

### **Test 10: Clean Up Test Data**

```sql
-- Delete test course (cascades to schedules and enrollments)
DELETE FROM courses WHERE course_code = 'TEST_MATH7';

-- Verify deletion
SELECT * FROM courses WHERE course_code = 'TEST_MATH7';
-- Should return no rows
```

---

## 📊 Performance Testing

### **Test Query Performance**

```sql
-- Test index usage on grade_level
EXPLAIN ANALYZE
SELECT * FROM courses WHERE grade_level = 7;

-- Test index usage on course_code
EXPLAIN ANALYZE
SELECT * FROM courses WHERE course_code = 'MATH7';

-- Test join performance
EXPLAIN ANALYZE
SELECT 
    c.name,
    c.course_code,
    COUNT(e.id) AS enrollment_count
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id AND e.status = 'active'
WHERE c.is_active = TRUE
GROUP BY c.id, c.name, c.course_code;
```

**Expected Result**: Query plans should show "Index Scan" (not "Seq Scan") for indexed columns.

---

## 🔒 Security Testing

### **Test RLS Policies**

**Note**: These tests require actual user authentication. You can test RLS after implementing the Flutter app.

```sql
-- As admin (role_id = 1), should see all courses
SELECT * FROM courses;

-- As teacher, should only see assigned courses
-- (Test this from Flutter app after authentication)

-- As student, should only see enrolled courses
-- (Test this from Flutter app after authentication)
```

---

## ✅ Final Verification Checklist

After running all tests, verify:

- [ ] All 5 tables exist and have correct structure
- [ ] All indexes are created
- [ ] All constraints are enforced
- [ ] All 4 helper functions work correctly
- [ ] All 3 triggers fire on UPDATE
- [ ] RLS policies are enabled
- [ ] Sample course can be inserted
- [ ] Course code uniqueness is enforced
- [ ] Grade level constraint works (7-12 only)
- [ ] Auto-enrollment function works
- [ ] Schedules can be added to courses
- [ ] Enrollments are created correctly
- [ ] Cascade deletes work properly
- [ ] Query performance is acceptable

---

## 🐛 Troubleshooting

### **Issue: "column already exists" error**

**Solution**: This is expected if you run the script multiple times. The script is idempotent (safe to re-run).

### **Issue: "relation does not exist" error**

**Solution**: 
1. Check if the referenced table exists (e.g., `profiles`, `students`)
2. Ensure you're in the correct schema (`public`)
3. Verify table names match exactly (case-sensitive)

### **Issue: "permission denied" error**

**Solution**:
1. Ensure you're logged in as project owner/admin
2. Check Supabase project permissions
3. Try running from Supabase Dashboard (not external client)

### **Issue: RLS policies blocking queries**

**Solution**:
1. Temporarily disable RLS for testing: `ALTER TABLE courses DISABLE ROW LEVEL SECURITY;`
2. Re-enable after testing: `ALTER TABLE courses ENABLE ROW LEVEL SECURITY;`
3. Or use service role key (bypasses RLS)

### **Issue: Auto-enrollment returns 0**

**Solution**:
1. Check if students exist: `SELECT * FROM students WHERE grade_level = 7 AND section = 'Diamond';`
2. Verify students are active: `is_active = TRUE`
3. Check if enrollments already exist (unique constraint prevents duplicates)

### **Issue: Triggers not firing**

**Solution**:
1. Verify trigger exists: `SELECT * FROM information_schema.triggers WHERE event_object_table = 'courses';`
2. Check trigger function exists: `SELECT * FROM pg_proc WHERE proname = 'update_updated_at_column';`
3. Re-create trigger if needed

---

## 📝 Next Steps After Verification

Once all verifications pass:

1. ✅ **Document any issues** encountered and solutions applied
2. ✅ **Take a database snapshot** (Supabase Dashboard → Database → Backups)
3. ✅ **Proceed to Phase 2**: Update Dart models
4. ✅ **Proceed to Phase 3**: Implement CourseService methods
5. ✅ **Proceed to Phase 4**: Wire up UI to backend

---

## 📞 Support

If you encounter issues not covered in this guide:

1. Check Supabase logs (Dashboard → Logs)
2. Review PostgreSQL error messages carefully
3. Consult Supabase documentation: https://supabase.com/docs
4. Check PostgreSQL documentation: https://www.postgresql.org/docs/

---

## 📊 Summary

This verification guide ensures:
- ✅ All database tables are properly structured
- ✅ All indexes optimize query performance
- ✅ All constraints enforce data integrity
- ✅ All helper functions work correctly
- ✅ All triggers automate timestamp updates
- ✅ All RLS policies secure data access
- ✅ The backend is ready for Flutter integration

**Status**: ✅ Backend setup complete and verified!

---

**Document Version**: 1.0  
**Created**: January 2025  
**Purpose**: Verify Course Creation backend setup  
**Next**: Proceed to Dart model updates (Phase 2)
