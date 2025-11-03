# 🚀 Course Backend Setup - Quick Reference

## 📋 TL;DR

**What**: Complete database setup for Course Creation feature  
**Where**: Supabase SQL Editor  
**Time**: 5-10 minutes  
**Files**: `COURSE_BACKEND_SETUP.sql`

---

## ⚡ Quick Start (3 Steps)

### **Step 1: Open Supabase SQL Editor**
```
Supabase Dashboard → SQL Editor → New Query
```

### **Step 2: Copy & Paste**
```
Copy entire contents of COURSE_BACKEND_SETUP.sql → Paste → Run
```

### **Step 3: Verify Success**
```sql
-- Run this query to verify
SELECT 
    'courses' AS table_name, 
    COUNT(*) AS columns 
FROM information_schema.columns 
WHERE table_name = 'courses';
-- Should return 14+ columns
```

---

## 📊 What Gets Created

| Component | Count | Purpose |
|-----------|-------|---------|
| **Tables Modified** | 2 | `courses`, `enrollments` |
| **Tables Created** | 1 | `course_schedules` |
| **Tables Verified** | 2 | `teachers`, `course_assignments` |
| **Columns Added** | 12 | New fields for course management |
| **Indexes Created** | 15+ | Query performance optimization |
| **Constraints Added** | 5 | Data integrity enforcement |
| **Functions Created** | 4 | Helper functions for operations |
| **Triggers Created** | 3 | Auto-update timestamps |
| **RLS Policies** | 10+ | Secure data access by role |

---

## 🗄️ Database Schema Changes

### **courses Table** (9 new columns)
```
✅ course_code      TEXT UNIQUE      - e.g., "MATH7"
✅ grade_level      INT4             - 7-12 only
✅ section          TEXT             - e.g., "Diamond"
✅ subject          TEXT             - e.g., "Mathematics"
✅ school_year      TEXT             - e.g., "2024-2025"
✅ status           TEXT             - active/inactive/archived
✅ room_number      TEXT             - e.g., "101"
✅ is_active        BOOLEAN          - true/false
✅ updated_at       TIMESTAMPTZ      - auto-updated
```

### **enrollments Table** (3 new columns)
```
✅ status           TEXT             - active/dropped/completed
✅ enrolled_at      TIMESTAMPTZ      - enrollment timestamp
✅ enrollment_type  TEXT             - manual/auto/section_based
```

### **course_schedules Table** (NEW)
```
✅ id               BIGSERIAL        - Primary key
✅ course_id        BIGINT           - FK to courses
✅ day_of_week      TEXT             - Monday-Sunday
✅ start_time       TIME             - e.g., 08:00:00
✅ end_time         TIME             - e.g., 09:00:00
✅ room_number      TEXT             - Optional room
✅ is_active        BOOLEAN          - Schedule status
```

---

## 🔧 Helper Functions

### **1. Get Students by Section**
```sql
SELECT * FROM get_students_by_section(7, 'Diamond');
-- Returns all active students in Grade 7, Section Diamond
```

### **2. Auto-Enroll Students**
```sql
SELECT auto_enroll_students(course_id, 7, 'Diamond');
-- Enrolls all students in Grade 7, Section Diamond into the course
-- Returns count of enrolled students
```

### **3. Get Enrollment Count**
```sql
SELECT get_course_enrollment_count(course_id);
-- Returns number of active enrollments for a course
```

### **4. Check Course Code Uniqueness**
```sql
SELECT is_course_code_unique('MATH7');
-- Returns TRUE if code is available, FALSE if taken
```

---

## 🔒 Security (RLS Policies)

### **Who Can Do What**

| Role | View Courses | Create Course | Edit Course | Delete Course |
|------|--------------|---------------|-------------|---------------|
| **Admin** | ✅ All | ✅ Yes | ✅ Yes | ✅ Yes |
| **Teacher** | ✅ Assigned only | ❌ No | ❌ No | ❌ No |
| **Student** | ✅ Enrolled only | �� No | ❌ No | ❌ No |
| **Parent** | ✅ Child's courses | ❌ No | ❌ No | ❌ No |
| **Public** | ✅ Active only | ❌ No | ❌ No | ❌ No |

---

## ✅ Verification Checklist

Run these quick checks:

```sql
-- 1. Check courses table has new columns
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'courses' AND column_name IN (
    'course_code', 'grade_level', 'subject', 'school_year'
);
-- Should return 4 rows

-- 2. Check course_schedules table exists
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_name = 'course_schedules';
-- Should return 1

-- 3. Check helper functions exist
SELECT COUNT(*) FROM information_schema.routines 
WHERE routine_name LIKE '%course%' OR routine_name LIKE '%enroll%';
-- Should return 4+

-- 4. Check triggers exist
SELECT COUNT(*) FROM information_schema.triggers 
WHERE event_object_table IN ('courses', 'course_schedules');
-- Should return 2+

-- 5. Test course code uniqueness constraint
INSERT INTO courses (name, course_code, grade_level, subject) 
VALUES ('Test', 'TEST123', 7, 'Math');
INSERT INTO courses (name, course_code, grade_level, subject) 
VALUES ('Test2', 'TEST123', 7, 'Math');
-- Second insert should FAIL with unique constraint error
DELETE FROM courses WHERE course_code = 'TEST123';
```

---

## 🎯 Key Constraints

### **Grade Level Validation**
```sql
-- Only grades 7-12 allowed
CHECK (grade_level >= 7 AND grade_level <= 12)
```

### **Status Validation**
```sql
-- Only specific statuses allowed
CHECK (status IN ('active', 'inactive', 'archived'))
```

### **Course Code Uniqueness**
```sql
-- Each course code must be unique
UNIQUE (course_code)
```

### **No Duplicate Enrollments**
```sql
-- Student can't enroll in same course twice (while active)
UNIQUE (student_id, course_id) WHERE status = 'active'
```

### **Schedule Time Logic**
```sql
-- End time must be after start time
CHECK (end_time > start_time)
```

---

## 🧪 Quick Test Script

```sql
-- Complete test in 30 seconds
BEGIN;

-- 1. Insert test course
INSERT INTO courses (name, course_code, grade_level, subject, school_year, status, is_active)
VALUES ('Test Math 7', 'TESTMATH7', 7, 'Mathematics', '2024-2025', 'active', TRUE)
RETURNING id;
-- Note the returned ID

-- 2. Insert schedule (replace <id> with actual ID from step 1)
INSERT INTO course_schedules (course_id, day_of_week, start_time, end_time, room_number)
VALUES (<id>, 'Monday', '08:00', '09:00', '101');

-- 3. Test uniqueness function
SELECT is_course_code_unique('TESTMATH7') AS should_be_false;
SELECT is_course_code_unique('NONEXISTENT') AS should_be_true;

-- 4. Clean up
ROLLBACK;
-- All test data removed
```

---

## 🐛 Common Issues & Fixes

### **Issue: "column already exists"**
```
✅ SAFE TO IGNORE - Script is idempotent
```

### **Issue: "relation does not exist"**
```
❌ Check if profiles/students tables exist
❌ Verify you're in correct Supabase project
```

### **Issue: "permission denied"**
```
❌ Ensure you're project owner/admin
❌ Use Supabase Dashboard SQL Editor (not external client)
```

### **Issue: RLS blocking queries**
```sql
-- Temporarily disable for testing
ALTER TABLE courses DISABLE ROW LEVEL SECURITY;
-- Re-enable after testing
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
```

---

## 📈 Performance Tips

### **Indexes Created**
```
✅ idx_courses_grade_level     - Fast filtering by grade
✅ idx_courses_subject          - Fast filtering by subject
✅ idx_courses_status           - Fast filtering by status
✅ idx_courses_code             - Fast lookup by code
✅ idx_enrollments_student      - Fast student queries
✅ idx_enrollments_course       - Fast course queries
✅ idx_course_schedules_course  - Fast schedule lookup
```

### **Query Optimization**
```sql
-- ✅ GOOD: Uses index
SELECT * FROM courses WHERE grade_level = 7;

-- ❌ BAD: Full table scan
SELECT * FROM courses WHERE LOWER(name) LIKE '%math%';

-- ✅ GOOD: Uses index
SELECT * FROM courses WHERE course_code = 'MATH7';
```

---

## 🔄 Rollback Plan

If something goes wrong:

```sql
-- Rollback courses table changes
ALTER TABLE courses 
DROP COLUMN IF EXISTS course_code,
DROP COLUMN IF EXISTS grade_level,
DROP COLUMN IF EXISTS section,
DROP COLUMN IF EXISTS subject,
DROP COLUMN IF EXISTS school_year,
DROP COLUMN IF EXISTS status,
DROP COLUMN IF EXISTS room_number,
DROP COLUMN IF EXISTS is_active,
DROP COLUMN IF EXISTS updated_at;

-- Drop course_schedules table
DROP TABLE IF EXISTS course_schedules CASCADE;

-- Drop helper functions
DROP FUNCTION IF EXISTS get_students_by_section;
DROP FUNCTION IF EXISTS auto_enroll_students;
DROP FUNCTION IF EXISTS get_course_enrollment_count;
DROP FUNCTION IF EXISTS is_course_code_unique;

-- Drop triggers
DROP TRIGGER IF EXISTS update_courses_updated_at ON courses;
DROP TRIGGER IF EXISTS update_course_schedules_updated_at ON course_schedules;
```

---

## 📝 Next Steps

After successful backend setup:

1. ✅ **Verify** all tables and functions (use verification guide)
2. ✅ **Test** helper functions with sample data
3. ✅ **Proceed to Phase 2**: Update Dart models
4. ✅ **Proceed to Phase 3**: Implement CourseService
5. ✅ **Proceed to Phase 4**: Wire up UI

---

## 📚 Related Documents

- **Full Setup Script**: `COURSE_BACKEND_SETUP.sql`
- **Verification Guide**: `COURSE_BACKEND_VERIFICATION.md`
- **Implementation Plan**: `COURSE_CREATION_IMPLEMENTATION_PLAN.md`

---

## 🎓 DepEd Compliance

The backend supports:
- ✅ Grades 7-12 (Junior & Senior High)
- ✅ Core subjects (Math, Science, English, Filipino, etc.)
- ✅ SHS tracks (STEM, ABM, HUMSS, etc.)
- ✅ Section-based enrollment
- ✅ School year tracking
- ✅ Course scheduling

---

**Status**: ✅ Ready for execution  
**Estimated Time**: 5-10 minutes  
**Risk Level**: Low (idempotent, safe to re-run)  
**Next**: Run COURSE_BACKEND_SETUP.sql in Supabase

---

## 🚀 Execute Now

```bash
# 1. Open Supabase Dashboard
# 2. Go to SQL Editor
# 3. Copy COURSE_BACKEND_SETUP.sql
# 4. Paste and Run
# 5. Verify success with quick test
# 6. Proceed to Dart implementation
```

**Ready? Let's go! 💪**
