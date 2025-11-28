# 📊 PHASE 1 - TASK 1.1: CURRENT STATE ANALYSIS

**Status:** ✅ COMPLETE
**Date:** 2025-11-27

---

## 🎯 **OBJECTIVE**

Document current student grades implementation and identify gaps compared to teacher gradebook.

---

## 📁 **CURRENT IMPLEMENTATION**

### **File:** `lib/screens/student/grades/student_grade_viewer_screen.dart`

**Lines of Code:** 991 lines

**Architecture:**
- Single-screen implementation
- Uses OLD course-based system
- Custom UI layout (not matching new classroom design)
- Realtime subscription for grade updates

---

## 🔍 **DATA FLOW ANALYSIS**

### **Current Flow (OLD System):**

```
Student Login
  ↓
Get Enrolled Classrooms (classroom_students)
  ↓
Select Classroom
  ↓
Get Classroom Courses (classroom_courses) ← OLD
  ↓
courses table (course_id: bigint) ← OLD
  ↓
Select Course
  ↓
Get Student Grades (student_grades.course_id) ← OLD
  ↓
Display Grades by Quarter
```

---

## 📊 **KEY COMPONENTS**

### **1. State Management**

```dart
// Left panel
List<Classroom> _classrooms = [];
Classroom? _selectedClassroom;

// Middle panel (COURSES - OLD)
List<Course> _courses = [];  // ← OLD: Uses Course model
Course? _selectedCourse;     // ← OLD: Uses Course model

// Right panel
Map<int, Map<String, dynamic>> _quarterGrades = {};
int _selectedQuarter = 1;
Map<String, dynamic>? _explain;
```

**Issue:** Uses `Course` model instead of `ClassroomSubject` model

---

### **2. Data Fetching Methods**

#### **Load Classrooms (Lines 78-98)**
```dart
Future<void> _loadStudentClassrooms() async {
  final classes = await _classroomService.getStudentClassrooms(uid);
  // ✅ CORRECT: Uses student enrollment
}
```

#### **Load Courses (Lines 118-138)** ❌ OLD SYSTEM
```dart
Future<void> _loadClassroomCourses(String classroomId) async {
  final courses = await _classroomService.getClassroomCourses(classroomId);
  // ❌ PROBLEM: Uses OLD course system
  // ❌ Should use: getClassroomSubjects()
}
```

#### **Load Grades (Lines 140-174)** ❌ OLD SYSTEM
```dart
Future<void> _loadQuarterGrades() async {
  final rows = await supa
      .from('student_grades')
      .select()
      .eq('student_id', uid)
      .eq('classroom_id', c.id)
      .eq('course_id', course.id);  // ❌ PROBLEM: Uses course_id
  // ❌ Should use: subject_id
}
```

---

### **3. UI Layout**

**Current Layout:**
```
┌─────────────────────────────────────┐
│  AppBar: "My Grades"                │
├─────────────────────────────────────┤
│  Top Controls:                      │
│  [Classroom Dropdown]               │
│  [Course Dropdown]                  │
│  [Q1] [Q2] [Q3] [Q4]               │
├─────────────────────────────────────┤
│  Grade Area:                        │
│  - Summary Card                     │
│  - Breakdown Card                   │
└─────────────────────────────────────┘
```

**Issues:**
- ❌ Not three-panel layout
- ❌ Uses dropdowns instead of sidebar
- ❌ Doesn't match new classroom design

---

### **4. Grade Display**

**Summary Card (Lines 336-443):**
- ✅ Shows transmuted grade (large)
- ✅ Shows initial grade
- ✅ Shows plus/extra points
- ✅ Shows WW/PT/QA weights
- ✅ Shows computed date

**Breakdown Card (Lines 445-635):**
- ✅ Shows WW/PT/QA items
- ✅ Shows score/max for each item
- ✅ Shows missing assignments
- ✅ Shows computation formula
- ✅ Uses DepEd computation logic

**Verdict:** ✅ Grade display logic is GOOD - can be reused

---

### **5. DepEd Computation**

**Load Explanation (Lines 637-921):**
```dart
final computed = await _depEd.computeQuarterlyBreakdown(
  classroomId: c.id,
  courseId: course.id,  // ❌ Uses course_id
  studentId: uid,
  quarter: q,
  courseTitle: course.title,
  qaScoreOverride: qaScoreOv,
  qaMaxOverride: qaMaxOv,
  plusPoints: plus,
  extraPoints: extra,
  wwWeightOverride: wwW,
  ptWeightOverride: ptW,
  qaWeightOverride: qaW,
);
```

**Good News:** ✅ `DepEdGradeService.computeQuarterlyBreakdown()` already supports `subjectId` parameter!

---

## 🔴 **IDENTIFIED GAPS**

### **Gap 1: Data Model Mismatch**
- **Current:** Uses `Course` model with `course_id` (bigint)
- **Target:** Should use `ClassroomSubject` model with `subject_id` (UUID)
- **Impact:** Cannot fetch grades for new classroom subjects

### **Gap 2: UI Layout Mismatch**
- **Current:** Single-screen with dropdowns
- **Target:** Three-panel layout (Classroom | Subject | Grades)
- **Impact:** Doesn't match new classroom design

### **Gap 3: Service Method Missing**
- **Current:** Uses `_classroomService.getClassroomCourses()`
- **Target:** Need `StudentGradesService.getClassroomSubjects()`
- **Impact:** Cannot fetch subjects for student

### **Gap 4: Query Logic**
- **Current:** Queries `student_grades` with `course_id`
- **Target:** Should query with `subject_id` (with fallback to `course_id`)
- **Impact:** Cannot display grades for new subjects

### **Gap 5: Widget Reuse**
- **Current:** Custom widgets
- **Target:** Should reuse `ClassroomLeftSidebarStateful`, `GradebookSubjectList` pattern
- **Impact:** Inconsistent UI across app

---

## ✅ **WHAT'S WORKING WELL**

1. ✅ **Realtime Subscription:** Grade updates work correctly
2. ✅ **Grade Display:** Summary and breakdown cards are excellent
3. ✅ **DepEd Logic:** Computation is accurate and detailed
4. ✅ **Weight Overrides:** Custom weights are respected
5. ✅ **Component Mapping:** WW/PT/QA categorization works
6. ✅ **Missing Assignments:** Properly marked and displayed

---

## 📋 **MIGRATION REQUIREMENTS**

### **Must Preserve:**
- ✅ Realtime subscription logic
- ✅ Grade summary card design
- ✅ Grade breakdown card design
- ✅ DepEd computation accuracy
- ✅ Weight override support
- ✅ Missing assignment detection

### **Must Change:**
- ❌ Data model: `Course` → `ClassroomSubject`
- ❌ Query field: `course_id` → `subject_id`
- ❌ UI layout: Dropdowns → Three-panel
- ❌ Service method: `getClassroomCourses()` → `getClassroomSubjects()`

### **Must Add:**
- ➕ Backward compatibility for old `course_id` data
- ➕ Dual query support (subject_id OR course_id)
- ➕ Widget reuse from new classroom design

---

## 🎯 **NEXT STEPS**

1. ✅ **Task 1.2:** Verify database schema supports both systems
2. ✅ **Task 1.3:** Identify reusable widgets from new classroom design
3. ⏳ **Phase 2:** Begin UI redesign with three-panel layout

---

**Analysis Complete!** ✅


