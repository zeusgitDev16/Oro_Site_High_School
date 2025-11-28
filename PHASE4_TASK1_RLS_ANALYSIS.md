# 🔒 PHASE 4 - TASK 4.1: RLS POLICY ANALYSIS

**Status:** ✅ COMPLETE
**Date:** 2025-11-27

---

## 🎯 **OBJECTIVE**

Analyze existing RLS policies and plan backward-compatible enhancements for subject_id support.

---

## ✅ **EXISTING RLS POLICIES VERIFIED**

### **1. student_grades Table** ✅ RLS ENABLED

**Policies Found:**
1. ✅ `student_grades_select_own` - Students can view own grades
2. ✅ `student_grades_teacher_select` - Teachers can view grades they manage
3. ✅ `student_grades_teacher_insert` - Teachers can insert grades they manage
4. ✅ `student_grades_teacher_update` - Teachers can update grades they manage

**Helper Function:**
- ✅ `can_manage_student_grade(p_classroom_id uuid, p_course_id bigint)`

**Current Logic:**
```sql
-- Students: view own grades
USING (student_id = auth.uid())

-- Teachers: view/insert/update grades they manage
USING (can_manage_student_grade(classroom_id, course_id))
```

**Verdict:** ✅ **WORKING** but only supports `course_id` (OLD system)

---

### **2. classroom_subjects Table** ✅ RLS ENABLED

**Policies Found:**
1. ✅ `Admins can do everything with classroom_subjects` - Admin full access
2. ✅ `Students can view subjects in their classrooms` - Students view enrolled subjects
3. ✅ `Teachers can update their assigned subjects` - Teachers update own subjects
4. ✅ `Teachers can view all classroom_subjects` - Teachers view all subjects

**Current Logic:**
```sql
-- Students: view subjects in enrolled classrooms
USING (EXISTS (
  SELECT 1 FROM classroom_students
  WHERE classroom_id = classroom_subjects.classroom_id
    AND student_id = auth.uid()
))

-- Teachers: view all subjects
USING (EXISTS (
  SELECT 1 FROM teachers WHERE id = auth.uid()
))

-- Teachers: update own subjects
USING (teacher_id = auth.uid() AND EXISTS (
  SELECT 1 FROM teachers WHERE id = auth.uid()
))
```

**Verdict:** ✅ **PERFECT!** Already supports student access

---

### **3. classroom_students Table** ✅ RLS ENABLED

**Policies Found:**
1. ✅ `Students can view own enrollments` - Students view own enrollments
2. ✅ `Students can enroll themselves` - Students self-enroll
3. ✅ `Teachers can view enrollments` - Teachers view enrollments
4. ✅ `Teachers can add students to own classrooms` - Teachers enroll students
5. ✅ `Teachers can remove students from own classrooms` - Teachers remove students
6. ✅ `Admins can view all enrollments` - Admin view all
7. ✅ `Admins can enroll students` - Admin enroll
8. ✅ `Admins can remove students` - Admin remove
9. ✅ `Admins can update enrollments` - Admin update

**Helper Function:**
- ✅ `is_classroom_manager(p_classroom_id uuid, p_user_id uuid)`

**Current Logic:**
```sql
-- Students: view own enrollments
USING (student_id = auth.uid())

-- Teachers: view/manage enrollments in their classrooms
USING (is_classroom_manager(classroom_id, auth.uid()))

-- Admins: full access
USING (is_admin())
```

**Verdict:** ✅ **PERFECT!** Comprehensive access control

---

## 🔍 **HELPER FUNCTIONS ANALYSIS**

### **Function 1: can_manage_student_grade()** ⚠️ NEEDS ENHANCEMENT

**Current Signature:**
```sql
can_manage_student_grade(p_classroom_id uuid, p_course_id bigint)
```

**Current Logic:**
1. ✅ Admin override
2. ✅ Classroom teacher or co-teacher
3. ✅ Course teacher (via `is_course_teacher()`)
4. ✅ Grade level coordinator

**Missing:**
- ❌ Subject teacher check (NEW system)

**Enhancement Needed:**
```sql
-- NEW signature (backward compatible)
can_manage_student_grade(
  p_classroom_id uuid,
  p_course_id bigint DEFAULT NULL,
  p_subject_id uuid DEFAULT NULL
)
```

**New Logic to Add:**
```sql
-- Check if user is subject teacher
IF p_subject_id IS NOT NULL THEN
  IF EXISTS (
    SELECT 1 FROM classroom_subjects
    WHERE id = p_subject_id
      AND classroom_id = p_classroom_id
      AND teacher_id = auth.uid()
  ) THEN
    RETURN true;
  END IF;
END IF;
```

**Verdict:** ⚠️ **NEEDS ENHANCEMENT** for subject_id support

---

### **Function 2: is_classroom_manager()** ✅ PERFECT

**Signature:**
```sql
is_classroom_manager(p_classroom_id uuid, p_user_id uuid)
```

**Logic:**
1. ✅ Classroom owner (teacher_id)
2. ✅ Co-teacher (classroom_teachers)

**Verdict:** ✅ **NO CHANGES NEEDED**

---

### **Function 3: is_admin()** ✅ PERFECT

**Signature:**
```sql
is_admin()  -- No parameters, uses auth.uid() internally
```

**Logic:**
1. ✅ Checks profiles.role_id against roles.name = 'admin'

**Verdict:** ✅ **NO CHANGES NEEDED**

---

## 📊 **BACKWARD COMPATIBILITY STRATEGY**

### **Key Principle:**
**ADD, DON'T REPLACE** - Enhance existing function without breaking old code

### **Strategy:**
1. ✅ Add `p_subject_id` parameter with `DEFAULT NULL`
2. ✅ Keep all existing logic intact
3. ✅ Add new subject teacher check
4. ✅ Maintain OR logic (course_id OR subject_id)
5. ✅ No policy changes needed (function signature compatible)

### **Why This Works:**
- ✅ Existing calls with 2 parameters still work
- ✅ New calls with 3 parameters work
- ✅ NULL handling preserves old behavior
- ✅ No breaking changes to existing code

---

## 🔐 **SECURITY MODEL**

### **Students:**
- ✅ Can view OWN grades (`student_id = auth.uid()`)
- ✅ Can view subjects in ENROLLED classrooms
- ✅ Can view OWN enrollments
- ❌ Cannot view OTHER students' grades
- ❌ Cannot modify any data

### **Teachers:**
- ✅ Can view/insert/update grades for THEIR subjects (NEW)
- ✅ Can view/insert/update grades for THEIR courses (OLD)
- ✅ Can view/insert/update grades for THEIR classrooms
- ✅ Can view/insert/update grades for THEIR grade level (coordinator)
- ❌ Cannot view/modify grades for OTHER teachers' subjects

### **Admins:**
- ✅ Can do EVERYTHING (full override)

---

## ✅ **VERIFICATION CHECKLIST**

- [x] All existing RLS policies verified
- [x] All helper functions analyzed
- [x] Backward compatibility strategy defined
- [x] Security model documented
- [x] Enhancement plan created
- [x] No breaking changes identified

---

## 🚀 **NEXT STEPS**

**Task 4.2:** Enhance `can_manage_student_grade()` function
- Add `p_subject_id` parameter with DEFAULT NULL
- Add subject teacher check
- Test backward compatibility
- Verify no breaking changes

---

**RLS Analysis Complete!** ✅


