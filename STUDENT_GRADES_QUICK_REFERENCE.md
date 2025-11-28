# 🎯 STUDENT GRADES REVAMP - QUICK REFERENCE

## 📊 **AT A GLANCE**

| Aspect | Current (OLD) | Target (NEW) |
|--------|---------------|--------------|
| **Data Model** | `classroom_id` + `course_id` (bigint) | `classroom_id` + `subject_id` (UUID) |
| **Subject Source** | `courses` table via `classroom_courses` | `classroom_subjects` table |
| **UI Layout** | Custom layout | Three-panel (Classroom \| Subject \| Grades) |
| **Widget Reuse** | Minimal | Extensive (matches gradebook) |
| **Teacher Sync** | Partial | Full (matches gradebook exactly) |
| **Backward Compat** | N/A | Full support for old courses |

---

## 🎯 **KEY OBJECTIVES**

1. **UI Redesign:** Match new classroom design patterns
2. **Backend Integration:** Use `classroom_subjects` table
3. **RLS Policies:** Support `subject_id` in permissions
4. **DepEd Logic:** Preserve computation accuracy
5. **Backward Compat:** Support both old and new systems

---

## 📦 **8 PHASES OVERVIEW**

| Phase | Focus | Duration | Key Deliverables |
|-------|-------|----------|------------------|
| **1** | Analysis & Preparation | 2-3 days | Analysis docs, schema verification |
| **2** | UI Redesign | 3-4 days | New screen, widgets |
| **3** | Backend Integration | 3-4 days | Service methods, queries |
| **4** | RLS & Permissions | 2-3 days | Updated policies, functions |
| **5** | DepEd Computation | 1-2 days | Verified logic |
| **6** | Backward Compatibility | 2-3 days | Dual query support |
| **7** | Testing & Validation | 3-4 days | All tests passing |
| **8** | Documentation & Deployment | 2-3 days | Docs, deployment plan |

**Total:** 18-26 days

---

## 🔑 **CRITICAL CHANGES**

### **1. Database Queries**

**OLD:**
```sql
SELECT * FROM student_grades
WHERE student_id = $1
  AND classroom_id = $2
  AND course_id = $3;  -- bigint
```

**NEW:**
```sql
SELECT * FROM student_grades
WHERE student_id = $1
  AND classroom_id = $2
  AND (
    subject_id = $3  -- UUID (NEW)
    OR 
    course_id = $4   -- bigint (OLD - fallback)
  );
```

---

### **2. Subject Fetching**

**OLD:**
```dart
// Get courses from classroom_courses
final courses = await _classroomService.getClassroomCourses(classroomId);
```

**NEW:**
```dart
// Get subjects from classroom_subjects
final subjects = await _studentGradesService.getClassroomSubjects(
  classroomId: classroomId,
  studentId: studentId,
);
```

---

### **3. RLS Function**

**OLD:**
```sql
can_manage_student_grade(classroom_id uuid, course_id bigint)
```

**NEW:**
```sql
can_manage_student_grade(
  p_classroom_id uuid,
  p_course_id bigint DEFAULT NULL,
  p_subject_id uuid DEFAULT NULL  -- NEW parameter
)
```

---

### **4. UI Layout**

**OLD:**
```
┌─────────────────────────────────────┐
│  My Grades                          │
├─────────────────────────────────────┤
│  [Classroom Dropdown]               │
│  [Course Dropdown]                  │
│  [Q1] [Q2] [Q3] [Q4]               │
│                                     │
│  Grade Display                      │
└─────────────────────────────────────┘
```

**NEW:**
```
┌──────────┬──────────┬──────────────┐
│ GRADE 7  │ SUBJECTS │  QUARTER 1   │
│ ▼ Amanp  │          │  [Q1][Q2]... │
│   Oro    │ Filipino │              │
│          │ English  │  Grade       │
│ GRADE 8  │ Math     │  Summary     │
│          │ Science  │              │
└──────────┴──────────┴──────────────┘
```

---

## 📁 **NEW FILES TO CREATE**

### **Screens:**
- `lib/screens/student/grades/student_grades_screen_v2.dart`

### **Widgets:**
- `lib/screens/student/grades/widgets/student_grades_subject_panel.dart`
- `lib/screens/student/grades/widgets/student_grades_content_panel.dart`
- `lib/screens/student/grades/widgets/student_quarter_selector.dart`
- `lib/screens/student/grades/widgets/student_grade_breakdown_card.dart`
- `lib/screens/student/grades/widgets/student_grade_summary_card.dart`

### **Services:**
- `lib/services/student_grades_service.dart`

### **Database:**
- `database/migrations/UPDATE_CAN_MANAGE_STUDENT_GRADE_FUNCTION.sql`
- `database/migrations/UPDATE_STUDENT_GRADES_RLS_POLICIES.sql`

---

## 🧪 **TESTING CHECKLIST**

### **Unit Tests:**
- [ ] `StudentGradesService.getStudentClassrooms()`
- [ ] `StudentGradesService.getClassroomSubjects()`
- [ ] `StudentGradesService.getSubjectGrades()`
- [ ] `StudentGradesService.getQuarterBreakdown()`

### **Integration Tests:**
- [ ] Student login → view grades flow
- [ ] Classroom selection → subject selection flow
- [ ] Quarter selection → grade display flow
- [ ] Realtime grade updates

### **RLS Tests:**
- [ ] Student can view own grades
- [ ] Student cannot view other grades
- [ ] Teacher can view student grades
- [ ] Teacher can save grades
- [ ] Unauthorized access blocked

### **Sync Tests:**
- [ ] Teacher computes grade → appears in student view
- [ ] Breakdown matches between teacher and student
- [ ] Weights match between teacher and student
- [ ] Transmutation matches

---

## 🚨 **CRITICAL SUCCESS FACTORS**

1. **Backward Compatibility:** Must support both old and new systems
2. **DepEd Accuracy:** Grade computation must match teacher gradebook
3. **RLS Security:** Students can only see their own grades
4. **UI Consistency:** Must match new classroom design
5. **Performance:** Queries must be optimized for 100+ students

---

## 📞 **QUICK CONTACTS**

| Area | Contact | Notes |
|------|---------|-------|
| UI Design | Design Team | For widget styling |
| Database | DBA Team | For RLS policy updates |
| Testing | QA Team | For test case review |
| Deployment | DevOps Team | For deployment plan |

---

## 🔗 **RELATED DOCUMENTS**

- **Full Plan:** `STUDENT_GRADES_REVAMP_PLAN.md` (308 lines)
- **Summary:** `STUDENT_GRADES_REVAMP_SUMMARY.md` (150 lines)
- **This Document:** `STUDENT_GRADES_QUICK_REFERENCE.md` (Quick lookup)

---

## 🎯 **NEXT IMMEDIATE STEPS**

1. ✅ Review this plan with team
2. ✅ Get approval for approach
3. ⏳ Start Phase 1: Analysis & Preparation
4. ⏳ Create `STUDENT_GRADES_CURRENT_STATE_ANALYSIS.md`
5. ⏳ Verify database schema

---

**Questions? See full plan for details!** 📚


