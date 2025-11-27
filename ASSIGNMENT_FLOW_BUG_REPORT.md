# ASSIGNMENT FLOW BUG REPORT

**Date:** 2025-11-27  
**Focus:** Teacher Assignment Creation & Student Submission Flow  
**Classroom:** Amanpulo (Grade 7, School Year 2025-2026)

---

## 🎯 FLOW VERIFICATION SUMMARY

### ✅ **GOOD NEWS: New UI is Active**
- Feature flag defaults to `TRUE` (new classroom UI enabled)
- Teachers use `my_classroom_screen_v2.dart` (uses `classroom_subjects`)
- Students use `student_classroom_screen_v2.dart` (uses `classroom_subjects`)
- Amanpulo has 2 subjects in `classroom_subjects` table ✅

### ⚠️ **POTENTIAL ISSUE: Assignment System Compatibility**

The assignment system was designed for the **OLD** `courses` table but Amanpulo uses the **NEW** `classroom_subjects` table.

---

## 🔍 DEEP ANALYSIS

### **1. Database Schema**

**Assignments Table:**
```sql
CREATE TABLE assignments (
  id bigint PRIMARY KEY,
  classroom_id uuid,
  course_id bigint,  -- ⚠️ Links to OLD courses table
  teacher_id uuid,
  title text,
  assignment_type text,
  quarter_no integer,
  component text,
  ...
)
```

**Classroom Subjects Table (NEW):**
```sql
CREATE TABLE classroom_subjects (
  id uuid PRIMARY KEY,
  classroom_id uuid,
  subject_name text,
  teacher_id uuid,
  course_id bigint,  -- ⚠️ NULL for Amanpulo subjects
  ...
)
```

**Current State for Amanpulo:**
- Filipino: `course_id = NULL`
- TLE: `course_id = NULL`

---

## 🐛 **CRITICAL QUESTION: Does Assignment Creation Work?**

### **Scenario 1: Teacher Creates Assignment in New UI**

**File:** `lib/widgets/classroom/subject_content_tabs.dart`  
**Expected Flow:**
1. Teacher selects subject (Filipino or TLE)
2. Teacher clicks "Create Assignment"
3. Assignment created with `classroom_id` + `subject_id`?

**Question:** Does the new UI pass `course_id` or `subject_id` when creating assignments?

### **Scenario 2: Old Assignment Service**

**File:** `lib/services/assignment_service.dart`
```dart
Future<Map<String, dynamic>> createAssignment({
  required String classroomId,
  String? courseId,  // ⚠️ Optional but used for filtering
  ...
}) async {
  final assignmentData = {
    'classroom_id': classroomId,
    if (courseId != null) 'course_id': courseId,  // ⚠️ May be NULL
    ...
  };
}
```

**Question:** Can assignments be created without `course_id`?

---

## 🔬 **VERIFICATION NEEDED**

### **Test 1: Can Teacher See Subjects?**
- ✅ **VERIFIED:** Teacher can see 2 subjects (Filipino, TLE) in new UI
- ✅ **VERIFIED:** Subjects load via `getSubjectsByClassroomForTeacher()`

### **Test 2: Can Teacher Create Assignment?**
- ❓ **NEEDS TESTING:** Does assignment creation work without `course_id`?
- ❓ **NEEDS TESTING:** Does new UI pass `subject_id` or `course_id`?

### **Test 3: Can Students See Assignments?**
- ❓ **NEEDS TESTING:** Student query filters by `course_id`:
```dart
builder.eq('course_id', _selectedCourse!.id);  // ⚠️ May fail if NULL
```

### **Test 4: Assignment-Subject Linking**
- ❓ **NEEDS TESTING:** How are assignments linked to subjects in new UI?
- ❓ **NEEDS TESTING:** Is there a `classroom_subjects.course_id` → `assignments.course_id` relationship?

---

## 🚨 **CONFIRMED CRITICAL BUGS**

### **BUG #1: Type Mismatch in Assignment Filtering** 🔴 **CRITICAL - CONFIRMED**
**Location:** `lib/widgets/classroom/subject_assignments_tab.dart` (Line 115)
**Severity:** 🔴 CRITICAL

**Code:**
```dart
// Filter assignments for this subject
final subjectAssignments = assignments.where((a) {
  // TODO: Update when assignments table has subject_id column
  // For now, filter by course_id (temporary)
  return a['course_id']?.toString() == widget.subject.id;  // ❌ BUG!
}).toList();
```

**Issue:**
- `course_id` is a **bigint** (e.g., `123`)
- `subject.id` is a **UUID** (e.g., `057b6195-36c6-4eab-bc6f-f6d5625ebcc0`)
- Comparison will **NEVER match**!

**Impact:**
- ❌ **NO assignments will EVER appear in any subject**
- ❌ Teachers cannot see assignments they created
- ❌ Students cannot see any assignments
- ❌ Assignment system is completely broken in new UI

**Proof:**
- Amanpulo Filipino subject ID: `057b6195-36c6-4eab-bc6f-f6d5625ebcc0` (UUID)
- Amanpulo TLE subject ID: `df9ac7be-3757-48c3-9447-fafbeb761c83` (UUID)
- Assignment `course_id` would be bigint (e.g., `1`, `2`, `3`) or NULL
- UUID ≠ bigint → **NO MATCH EVER**

---

### **BUG #2: Missing subject_id Column in Assignments Table** 🔴 **CRITICAL**
**Location:** `database/supabase_schema.sql` - `assignments` table
**Severity:** 🔴 CRITICAL

**Issue:**
- Assignments table has `course_id` (bigint) but NO `subject_id` (uuid)
- New UI uses `classroom_subjects` (UUID-based)
- No way to link assignments to subjects in new system

**Impact:**
- Cannot create subject-specific assignments in new UI
- Cannot filter assignments by subject
- Assignment-subject relationship is broken

---

### **BUG #3: Amanpulo Subjects Have NULL course_id** 🟡 **MODERATE**
**Location:** `classroom_subjects` table
**Severity:** 🟡 MODERATE

**Current State:**
- Filipino: `course_id = NULL`
- TLE: `course_id = NULL`

**Issue:**
- Even if we use `course_id` for filtering, it's NULL
- No link between subjects and old courses system

**Impact:**
- Cannot use `course_id` as a workaround
- Must implement proper `subject_id` solution

---

## ✅ **RECOMMENDED FIX (IMMEDIATE)**

### **Fix: Add subject_id Column to Assignments Table**

**Step 1: Database Migration**
```sql
-- Add subject_id column to assignments table
ALTER TABLE public.assignments
ADD COLUMN IF NOT EXISTS subject_id UUID REFERENCES public.classroom_subjects(id) ON DELETE SET NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_assignments_subject_id ON public.assignments(subject_id);

-- Verify
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'assignments' AND column_name = 'subject_id';
```

**Step 2: Update Assignment Service**
```dart
// lib/services/assignment_service.dart
Future<Map<String, dynamic>> createAssignment({
  required String classroomId,
  String? courseId,  // Keep for backward compatibility
  String? subjectId, // NEW: For new classroom_subjects system
  ...
}) async {
  final assignmentData = {
    'classroom_id': classroomId,
    if (courseId != null) 'course_id': courseId,
    if (subjectId != null) 'subject_id': subjectId, // NEW
    ...
  };
}
```

**Step 3: Update Assignment Filtering**
```dart
// lib/widgets/classroom/subject_assignments_tab.dart (Line 115)
// BEFORE:
return a['course_id']?.toString() == widget.subject.id;  // ❌ BUG

// AFTER:
return a['subject_id']?.toString() == widget.subject.id;  // ✅ FIXED
```

**Step 4: Update Assignment Creation Screen**
```dart
// lib/screens/teacher/assignments/create_assignment_screen_new.dart
await assignmentService.createAssignment(
  classroomId: widget.classroom.id,
  subjectId: widget.subject.id,  // NEW: Pass subject ID
  ...
);
```

---

## 📊 **IMPACT ANALYSIS**

### **Before Fix:**
- ❌ NO assignments visible in any subject
- ❌ Teachers cannot see created assignments
- ❌ Students cannot access assignments
- ❌ Assignment system completely broken in new UI

### **After Fix:**
- ✅ Assignments properly linked to subjects
- ✅ Teachers can see subject-specific assignments
- ✅ Students can see assignments in their subjects
- ✅ Backward compatible with old `course_id` system

---

## 🎯 **NEXT STEPS**

1. ✅ **Apply database migration** - Add `subject_id` column
2. ✅ **Update assignment service** - Support `subjectId` parameter
3. ✅ **Fix assignment filtering** - Use `subject_id` instead of `course_id`
4. ✅ **Test assignment creation** - Verify assignments appear correctly
5. ✅ **Test student view** - Verify students can see assignments

**Status:** 🚨 **CRITICAL BUG CONFIRMED - FIX READY TO APPLY**

