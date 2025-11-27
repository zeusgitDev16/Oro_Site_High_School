# PHASE 3 - TASK 3.1: DATABASE VERIFICATION REPORT

## ✅ TASK STATUS: IN PROGRESS

**Date**: 2025-11-26  
**Task**: Verify Attendance Database Operations  
**Objective**: Test CRUD operations, RLS policies, and data integrity

---

## 🚨 CRITICAL ISSUE DISCOVERED

### **Problem: Type Mismatch Between `classroom_subjects` and `attendance` Table**

**Root Cause:**
- The `attendance` table expects `course_id` as **BIGINT** (references `courses.id`)
- The new implementation uses `classroom_subjects` with **UUID** ids
- `classroom_subjects` table does NOT have a `course_id` field

**Current Implementation (Phase 2):**
```dart
// lib/widgets/attendance/attendance_tab_widget.dart
await _supabase
    .from('attendance')
    .select('student_id, status')
    .eq('course_id', widget.subject.id)  // ❌ WRONG: subject.id is UUID string
    .eq('quarter', _selectedQuarter)
    .eq('date', dateStr);
```

**Database Schema:**
```sql
-- attendance table expects BIGINT
CREATE TABLE public.attendance (
  id BIGSERIAL PRIMARY KEY,
  student_id UUID NOT NULL REFERENCES public.profiles(id),
  course_id BIGINT NOT NULL REFERENCES public.courses(id),  -- ❌ BIGINT, not UUID
  date DATE NOT NULL,
  status TEXT NOT NULL,
  quarter SMALLINT CHECK (quarter >= 1 AND quarter <= 4)
);

-- classroom_subjects has UUID id, NO course_id field
CREATE TABLE public.classroom_subjects (
  id UUID PRIMARY KEY,  -- ❌ UUID, not BIGINT
  classroom_id UUID NOT NULL,
  subject_name TEXT NOT NULL,
  teacher_id UUID,
  -- NO course_id field!
);
```

**Impact:**
- ❌ Attendance queries will FAIL (type mismatch)
- ❌ Attendance save operations will FAIL (foreign key constraint violation)
- ❌ Cannot link attendance to classroom_subjects without course_id

---

## 🔧 SOLUTION OPTIONS

### **Option 1: Add `course_id` to `classroom_subjects` Table** ✅ RECOMMENDED

**Approach**: Add a nullable `course_id` BIGINT column to `classroom_subjects` that references `courses.id`

**Pros:**
- ✅ Maintains backward compatibility with existing attendance data
- ✅ No changes needed to attendance table or RLS policies
- ✅ Allows gradual migration (nullable field)
- ✅ Supports both old (courses) and new (classroom_subjects) systems

**Cons:**
- ⚠️ Requires database migration
- ⚠️ Need to populate course_id for existing classroom_subjects

**Migration SQL:**
```sql
-- Add course_id to classroom_subjects
ALTER TABLE public.classroom_subjects
ADD COLUMN IF NOT EXISTS course_id BIGINT REFERENCES public.courses(id) ON DELETE SET NULL;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_classroom_subjects_course_id 
ON public.classroom_subjects(course_id);
```

**Code Changes:**
```dart
// Update ClassroomSubject model
class ClassroomSubject {
  final String id;
  final String classroomId;
  final String subjectName;
  final int? courseId;  // NEW: Add course_id field
  // ...
}

// Update attendance queries
await _supabase
    .from('attendance')
    .select('student_id, status')
    .eq('course_id', widget.subject.courseId)  // ✅ Use courseId (BIGINT)
    .eq('quarter', _selectedQuarter)
    .eq('date', dateStr);
```

---

### **Option 2: Migrate Attendance to Use `subject_id` UUID** ❌ NOT RECOMMENDED

**Approach**: Change attendance table to use `subject_id` UUID instead of `course_id` BIGINT

**Pros:**
- ✅ Aligns with new classroom_subjects architecture

**Cons:**
- ❌ BREAKS backward compatibility with existing attendance data
- ❌ Requires migrating ALL existing attendance records
- ❌ Requires updating ALL RLS policies
- ❌ Requires updating old teacher attendance screen
- ❌ High risk of data loss
- ❌ Violates user requirement: "full accountability and backward compatibility"

**Verdict**: ❌ REJECTED - Too risky, breaks backward compatibility

---

## 📋 VERIFICATION CHECKLIST

### **Database Schema Verification**

- [x] ✅ Attendance table schema reviewed
- [x] ✅ Attendance table has `course_id` BIGINT field
- [x] ✅ Attendance table has `quarter` SMALLINT field
- [x] ✅ Attendance table has foreign key to `courses(id)`
- [x] ✅ Classroom_subjects table schema reviewed
- [x] ❌ Classroom_subjects does NOT have `course_id` field
- [ ] ⏳ Need to add `course_id` to classroom_subjects

### **RLS Policies Verification**

- [x] ✅ RLS enabled on attendance table
- [x] ✅ Students can view own attendance (SELECT policy)
- [x] ✅ Teachers can manage course attendance (ALL policy using `is_course_teacher()`)
- [x] ✅ Parents can view children attendance (SELECT policy)
- [x] ✅ Admins can view all attendance (SELECT policy)
- [x] ✅ `is_course_teacher()` function exists and checks both `courses.teacher_id` and `course_assignments`

### **Data Integrity Verification**

- [ ] ⏳ Foreign key constraints (pending migration)
- [ ] ⏳ Check constraints (quarter 1-4) (pending migration)
- [ ] ⏳ Unique constraints (pending migration)
- [ ] ⏳ NOT NULL constraints (pending migration)

---

## 🎯 NEXT STEPS

1. **Create Migration**: Add `course_id` to `classroom_subjects` table
2. **Update Model**: Add `courseId` field to `ClassroomSubject` Dart model
3. **Update Queries**: Fix attendance queries to use `courseId` instead of `id`
4. **Test Operations**: Verify CRUD operations work correctly
5. **Verify RLS**: Test RLS policies with real teacher/student accounts
6. **Document**: Update documentation with new field

---

## 📝 NOTES

- The old implementation (`teacher_attendance_screen.dart`) likely works because it uses the old `courses` table directly
- The new implementation needs to bridge between `classroom_subjects` (UUID) and `courses` (BIGINT)
- This is a critical blocker for Phase 3 completion
- Must be resolved before proceeding with Tasks 3.2, 3.3, 3.4

---

**Status**: ⏸️ BLOCKED - Requires database migration before proceeding

