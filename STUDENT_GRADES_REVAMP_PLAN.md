# 🎯 STUDENT GRADES REVAMP - COMPREHENSIVE MODULARIZED PLAN

## 📋 **EXECUTIVE SUMMARY**

**Goal:** Revamp student grades UI and backend to align with new classroom system while maintaining backward compatibility with old course system.

**Current State:**
- ✅ Student grades screen exists (`student_grade_viewer_screen.dart`)
- ✅ Uses OLD system: `classroom_id` + `course_id` (bigint)
- ✅ Teacher gradebook exists (`gradebook_screen.dart`)
- ✅ Uses NEW system: `classroom_id` + `subject_id` (UUID)
- ❌ **MISMATCH:** Student grades and teacher gradebook use different data models

**Target State:**
- ✅ Student grades aligned with new classroom system
- ✅ Uses `classroom_id` + `subject_id` (UUID) like gradebook
- ✅ Full backward compatibility with old course system
- ✅ UI matches new classroom design patterns
- ✅ Accurate grade computation and display

---

## 🎯 **THREE MAIN GOALS**

### **GOAL 1: UI REDESIGN** 🎨
Redesign student grades screen to match new classroom design patterns

### **GOAL 2: BACKEND INTEGRATION** 🔧
Wire student grades to gradebook with accurate subject fetching

### **GOAL 3: RLS & PERMISSIONS** 🔒
Ensure proper permissions for students and teachers

---

## 📦 **MODULARIZED TASKS**

---

## **PHASE 1: ANALYSIS & PREPARATION** 🔍

### **Task 1.1: Current State Analysis**
**Objective:** Document current implementation and identify gaps

**Subtasks:**
- [ ] 1.1.1 Analyze `student_grade_viewer_screen.dart` structure
- [ ] 1.1.2 Analyze `gradebook_screen.dart` structure
- [ ] 1.1.3 Document data flow differences
- [ ] 1.1.4 Identify reusable widgets from new classroom design
- [ ] 1.1.5 Document DepEd computation logic preservation requirements

**Deliverables:**
- `STUDENT_GRADES_CURRENT_STATE_ANALYSIS.md`
- `GRADEBOOK_TEACHER_FLOW_ANALYSIS.md`
- `DATA_FLOW_COMPARISON.md`

---

### **Task 1.2: Database Schema Verification**
**Objective:** Verify database schema supports both old and new systems

**Subtasks:**
- [ ] 1.2.1 Verify `student_grades` table has both `course_id` and `subject_id`
- [ ] 1.2.2 Verify `classroom_subjects` table structure
- [ ] 1.2.3 Verify `assignments` table has both `course_id` and `subject_id`
- [ ] 1.2.4 Verify foreign key relationships
- [ ] 1.2.5 Document backward compatibility strategy

**Deliverables:**
- `STUDENT_GRADES_SCHEMA_VERIFICATION.md`

**SQL Queries:**
```sql
-- Verify student_grades columns
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'student_grades' 
  AND column_name IN ('course_id', 'subject_id', 'classroom_id');

-- Verify classroom_subjects structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'classroom_subjects';
```

---

### **Task 1.3: Widget Inventory**
**Objective:** Identify reusable widgets from new classroom design

**Subtasks:**
- [ ] 1.3.1 Document `ClassroomLeftSidebarStateful` usage
- [ ] 1.3.2 Document `ClassroomSubjectsPanel` usage
- [ ] 1.3.3 Document `SubjectContentTabs` usage
- [ ] 1.3.4 Identify grade-specific widgets needed
- [ ] 1.3.5 Plan widget reuse strategy

**Deliverables:**
- `REUSABLE_WIDGETS_INVENTORY.md`

---

## **PHASE 2: UI REDESIGN** 🎨

### **Task 2.1: Create New Student Grades Screen Structure**
**Objective:** Build new screen layout matching classroom design

**Subtasks:**
- [ ] 2.1.1 Create `student_grades_screen_v2.dart`
- [ ] 2.1.2 Implement three-panel layout (Classroom | Subject | Grades)
- [ ] 2.1.3 Reuse `ClassroomLeftSidebarStateful` for classroom selection
- [ ] 2.1.4 Create `StudentGradesSubjectPanel` for subject list
- [ ] 2.1.5 Create `StudentGradesContentPanel` for grade display

**File Structure:**
```
lib/screens/student/grades/
├── student_grades_screen.dart (OLD - keep for backward compatibility)
├── student_grades_screen_v2.dart (NEW - main screen)
├── student_grade_viewer_screen.dart (OLD - keep for backward compatibility)
├── widgets/
│   ├── student_grades_subject_panel.dart
│   ├── student_grades_content_panel.dart
│   ├── student_quarter_selector.dart
│   ├── student_grade_breakdown_card.dart
│   └── student_grade_summary_card.dart
```

**Design Pattern:**
```
┌─────────────────────────────────────────────────────────────┐
│  My Grades                          [View Report Card]      │
├──────────┬──────────┬───────────────────────────────────────┤
│ GRADE 7  │ SUBJECTS │  QUARTER 1  [Q1] [Q2] [Q3] [Q4]      │
│ ▼ Amanp  │          │                                       │
│   Oro    │ Filipino │  ┌─────────────────────────────────┐ │
│          │ English  │  │ GRADE SUMMARY                   │ │
│ GRADE 8  │ Math     │  │ Initial: 88.5 → Final: 89      │ │
│          │ Science  │  │ Written Works: 85%              │ │
│          │          │  │ Performance Tasks: 90%          │ │
│          │          │  │ Quarterly Assessment: 92%       │ │
│          │          │  └─────────────────────────────────┘ │
│          │          │                                       │
│          │          │  ┌─────────────────────────────────┐ │
│          │          │  │ BREAKDOWN                       │ │
│          │          │  │ Written Works (30%)             │ │
│          │          │  │ • Quiz 1: 8/10 (80%)           │ │
│          │          │  │ • Quiz 2: 9/10 (90%)           │ │
│          │          │  └─────────────────────────────────┘ │
└──────────┴──────────┴───────────────────────────────────────┘
```

---

### **Task 2.2: Implement Subject Panel Widget**
**Objective:** Create subject list panel matching classroom design

**Subtasks:**
- [ ] 2.2.1 Create `StudentGradesSubjectPanel` widget
- [ ] 2.2.2 Implement subject list with selection state
- [ ] 2.2.3 Add loading state
- [ ] 2.2.4 Add empty state
- [ ] 2.2.5 Match styling with `GradebookSubjectList`

**Widget Signature:**
```dart
class StudentGradesSubjectPanel extends StatelessWidget {
  final List<ClassroomSubject> subjects;
  final ClassroomSubject? selectedSubject;
  final Function(ClassroomSubject) onSubjectSelected;
  final bool isLoading;
}
```

---

### **Task 2.3: Implement Grades Content Panel**
**Objective:** Create grade display panel with quarter selector

**Subtasks:**
- [ ] 2.3.1 Create `StudentGradesContentPanel` widget
- [ ] 2.3.2 Implement quarter selector (Q1, Q2, Q3, Q4)
- [ ] 2.3.3 Create grade summary card
- [ ] 2.3.4 Create grade breakdown card
- [ ] 2.3.5 Add loading and empty states

---

### **Task 2.4: Create Supporting Widgets**
**Objective:** Build reusable grade display components

**Subtasks:**
- [ ] 2.4.1 Create `StudentQuarterSelector` widget
- [ ] 2.4.2 Create `StudentGradeSummaryCard` widget
- [ ] 2.4.3 Create `StudentGradeBreakdownCard` widget
- [ ] 2.4.4 Create `StudentGradeItemTile` widget
- [ ] 2.4.5 Add proper styling and animations

---

## **PHASE 3: BACKEND INTEGRATION** 🔧

### **Task 3.1: Update Student Grades Service**
**Objective:** Create service methods for new classroom system

**Subtasks:**
- [ ] 3.1.1 Create `StudentGradesService` class
- [ ] 3.1.2 Implement `getStudentClassrooms()` method
- [ ] 3.1.3 Implement `getClassroomSubjects()` method (NEW)
- [ ] 3.1.4 Implement `getSubjectGrades()` method (NEW)
- [ ] 3.1.5 Implement `getQuarterBreakdown()` method (NEW)

**File:** `lib/services/student_grades_service.dart`

**Key Methods:**
```dart
class StudentGradesService {
  // Get classrooms student is enrolled in
  Future<List<Classroom>> getStudentClassrooms(String studentId);
  
  // Get subjects in a classroom (NEW - uses classroom_subjects)
  Future<List<ClassroomSubject>> getClassroomSubjects({
    required String classroomId,
    required String studentId,
  });
  
  // Get grades for a subject (NEW - uses subject_id)
  Future<Map<int, Map<String, dynamic>>> getSubjectGrades({
    required String studentId,
    required String classroomId,
    required String subjectId,
  });
  
  // Get quarter breakdown (NEW - uses subject_id)
  Future<Map<String, dynamic>> getQuarterBreakdown({
    required String studentId,
    required String classroomId,
    required String subjectId,
    required int quarter,
  });
}
```

---

### **Task 3.2: Implement Subject Fetching Logic**
**Objective:** Fetch subjects accurately from classroom_subjects table

**Subtasks:**
- [ ] 3.2.1 Query `classroom_subjects` table for classroom
- [ ] 3.2.2 Filter by student enrollment (via `classroom_students`)
- [ ] 3.2.3 Handle backward compatibility with old courses
- [ ] 3.2.4 Add error handling
- [ ] 3.2.5 Add logging for debugging

**Query Logic:**
```sql
-- NEW SYSTEM: Get subjects from classroom_subjects
SELECT cs.* 
FROM classroom_subjects cs
WHERE cs.classroom_id = $1
  AND cs.is_active = true
  AND EXISTS (
    SELECT 1 FROM classroom_students cst
    WHERE cst.classroom_id = cs.classroom_id
      AND cst.student_id = $2
  )
ORDER BY cs.subject_name;

-- OLD SYSTEM: Get courses from classroom_courses (backward compatibility)
SELECT c.* 
FROM courses c
INNER JOIN classroom_courses cc ON c.id = cc.course_id
WHERE cc.classroom_id = $1
  AND c.is_active = true
ORDER BY c.title;
```

---

### **Task 3.3: Implement Grade Fetching Logic**
**Objective:** Fetch grades using subject_id with backward compatibility

**Subtasks:**
- [ ] 3.3.1 Query `student_grades` table with `subject_id`
- [ ] 3.3.2 Fallback to `course_id` for old data
- [ ] 3.3.3 Handle missing grades gracefully
- [ ] 3.3.4 Add realtime subscription for grade updates
- [ ] 3.3.5 Add caching for performance

**Query Logic:**
```sql
-- Fetch grades with backward compatibility
SELECT * FROM student_grades
WHERE student_id = $1
  AND classroom_id = $2
  AND (
    subject_id = $3  -- NEW system
    OR 
    course_id = $4   -- OLD system (fallback)
  )
ORDER BY quarter;
```

---


