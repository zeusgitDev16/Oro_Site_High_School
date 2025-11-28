# 🗄️ PHASE 1 - TASK 1.2: DATABASE SCHEMA VERIFICATION

**Status:** ✅ COMPLETE
**Date:** 2025-11-27

---

## 🎯 **OBJECTIVE**

Verify database schema supports both old (course-based) and new (subject-based) systems.

---

## ✅ **SCHEMA VERIFICATION RESULTS**

### **1. `student_grades` Table**

**Total Columns:** 22

**Key Columns for Migration:**

| Column | Type | Nullable | System | Status |
|--------|------|----------|--------|--------|
| `id` | uuid | NO | Both | ✅ Primary key |
| `student_id` | uuid | NO | Both | ✅ Required |
| `classroom_id` | uuid | NO | Both | ✅ Required |
| `course_id` | bigint | YES | OLD | ✅ Nullable (backward compat) |
| `subject_id` | uuid | YES | NEW | ✅ Nullable (new system) |
| `quarter` | smallint | NO | Both | ✅ Required (1-4) |
| `initial_grade` | numeric | NO | Both | ✅ Required |
| `transmuted_grade` | numeric | NO | Both | ✅ Required |
| `adjusted_grade` | numeric | YES | Both | ✅ Optional |
| `plus_points` | numeric | YES | Both | ✅ Optional |
| `extra_points` | numeric | YES | Both | ✅ Optional |
| `ww_weight_override` | numeric | YES | Both | ✅ Optional (fraction 0-1) |
| `pt_weight_override` | numeric | YES | Both | ✅ Optional (fraction 0-1) |
| `qa_weight_override` | numeric | YES | Both | ✅ Optional (fraction 0-1) |
| `qa_score_override` | numeric | YES | Both | ✅ Optional |
| `qa_max_override` | numeric | YES | Both | ✅ Optional |
| `school_year` | text | NO | Both | ✅ Required |
| `computed_at` | timestamptz | NO | Both | ✅ Required |
| `computed_by` | uuid | YES | Both | ✅ Optional |

**Verdict:** ✅ **PERFECT!** Table supports both systems

**Key Findings:**
- ✅ Both `course_id` (bigint) and `subject_id` (uuid) exist
- ✅ Both are nullable (allows gradual migration)
- ✅ All weight override columns exist
- ✅ All DepEd computation fields exist

---

### **2. `classroom_subjects` Table**

**Total Columns:** 12

**Key Columns:**

| Column | Type | Nullable | Purpose | Status |
|--------|------|----------|---------|--------|
| `id` | uuid | NO | Primary key | ✅ |
| `classroom_id` | uuid | NO | Links to classroom | ✅ |
| `subject_name` | text | NO | Subject name | ✅ |
| `subject_code` | text | YES | Subject code | ✅ |
| `description` | text | YES | Description | ✅ |
| `teacher_id` | uuid | YES | Subject teacher | ✅ |
| `parent_subject_id` | uuid | YES | For sub-subjects | ✅ |
| `course_id` | bigint | YES | OLD system link | ✅ Backward compat |
| `is_active` | boolean | YES | Active flag | ✅ |
| `created_at` | timestamptz | YES | Timestamp | ✅ |
| `updated_at` | timestamptz | YES | Timestamp | ✅ |
| `created_by` | uuid | YES | Creator | ✅ |

**Verdict:** ✅ **EXCELLENT!** Table supports both systems

**Key Findings:**
- ✅ Has `course_id` for backward compatibility
- ✅ Has `teacher_id` for subject teacher assignment
- ✅ Has `parent_subject_id` for sub-subjects
- ✅ Has `is_active` for soft delete

---

## 🔄 **BACKWARD COMPATIBILITY STRATEGY**

### **Query Pattern for Grades:**

```sql
-- Fetch grades with backward compatibility
SELECT * FROM student_grades
WHERE student_id = $1
  AND classroom_id = $2
  AND (
    subject_id = $3  -- NEW system (UUID)
    OR 
    course_id = $4   -- OLD system (bigint) - fallback
  )
ORDER BY quarter;
```

### **Query Pattern for Subjects:**

```sql
-- Fetch subjects for a classroom
SELECT * FROM classroom_subjects
WHERE classroom_id = $1
  AND is_active = true
ORDER BY subject_name;

-- Fetch courses for a classroom (OLD - fallback)
SELECT c.* FROM courses c
INNER JOIN classroom_courses cc ON c.id = cc.course_id
WHERE cc.classroom_id = $1
  AND c.is_active = true
ORDER BY c.title;
```

---

## 🔍 **DATA INTEGRITY CHECKS**

### **Check 1: Grades with subject_id**
```sql
SELECT COUNT(*) as new_system_grades
FROM student_grades
WHERE subject_id IS NOT NULL;
```

### **Check 2: Grades with course_id only**
```sql
SELECT COUNT(*) as old_system_grades
FROM student_grades
WHERE course_id IS NOT NULL AND subject_id IS NULL;
```

### **Check 3: Subjects in classrooms**
```sql
SELECT COUNT(*) as total_subjects
FROM classroom_subjects
WHERE is_active = true;
```

### **Check 4: Courses in classrooms**
```sql
SELECT COUNT(*) as total_courses
FROM classroom_courses;
```

---

## 📊 **FOREIGN KEY RELATIONSHIPS**

### **student_grades Table:**
- `student_id` → `profiles.id` (student)
- `classroom_id` → `classrooms.id`
- `course_id` → `courses.id` (nullable, OLD)
- `subject_id` → `classroom_subjects.id` (nullable, NEW)
- `computed_by` → `profiles.id` (teacher)

### **classroom_subjects Table:**
- `classroom_id` → `classrooms.id`
- `teacher_id` → `profiles.id` (nullable)
- `parent_subject_id` → `classroom_subjects.id` (nullable)
- `course_id` → `courses.id` (nullable, backward compat)

**Verdict:** ✅ All relationships are properly defined

---

## 🎯 **MIGRATION PATH**

### **Phase 1: Dual Support (Current)**
- ✅ Both `course_id` and `subject_id` exist
- ✅ Queries check both fields
- ✅ Old data continues to work

### **Phase 2: Gradual Migration**
- Teachers create new subjects in classrooms
- Grades are saved with `subject_id`
- Old grades remain with `course_id`

### **Phase 3: Full Migration (Future)**
- Migrate old `course_id` grades to `subject_id`
- Update all references
- Deprecate `course_id` field

---

## ✅ **VERIFICATION CHECKLIST**

- [x] `student_grades` table has both `course_id` and `subject_id`
- [x] Both fields are nullable (allows gradual migration)
- [x] `classroom_subjects` table exists and is active
- [x] `classroom_subjects` has `teacher_id` for subject teachers
- [x] Weight override columns exist (`ww_weight_override`, `pt_weight_override`, `qa_weight_override`)
- [x] QA override columns exist (`qa_score_override`, `qa_max_override`)
- [x] Foreign key relationships are correct
- [x] Backward compatibility is preserved

---

## 🚀 **CONCLUSION**

**Status:** ✅ **SCHEMA IS READY!**

The database schema is **perfectly designed** for the migration:
- ✅ Supports both old and new systems
- ✅ Allows gradual migration
- ✅ Preserves all DepEd computation fields
- ✅ No schema changes needed

**Next Step:** Proceed to Task 1.3 (Widget Inventory)

---

**Verification Complete!** ✅


