# 🧩 PHASE 1 - TASK 1.3: WIDGET INVENTORY

**Status:** ✅ COMPLETE
**Date:** 2025-11-27

---

## 🎯 **OBJECTIVE**

Identify reusable widgets from new classroom design that can be used in student grades screen.

---

## 📦 **AVAILABLE WIDGETS**

### **1. ClassroomLeftSidebarStateful** ⭐ REUSABLE

**File:** `lib/widgets/classroom/classroom_left_sidebar_stateful.dart`
**Lines:** 983 lines
**Purpose:** Grade level tree sidebar with classroom selection

**Features:**
- ✅ Grade level tree (7, 8, 9, 10, 11, 12)
- ✅ Expandable/collapsible sections
- ✅ Classroom cards with enrollment counts
- ✅ School year dropdown
- ✅ Role-based filtering (student, teacher, admin)
- ✅ Grade coordinator support
- ✅ Selection state management

**Usage in Gradebook:**
```dart
ClassroomLeftSidebarStateful(
  title: 'GRADEBOOK',
  expandedGrades: _expandedGrades,
  onGradeToggle: _handleGradeToggle,
  allClassrooms: _allClassrooms,
  selectedClassroom: _selectedClassroom,
  onClassroomSelected: _handleClassroomSelected,
  gradeCoordinators: const {},
  schoolYears: const [],
  userRole: 'teacher',
  isCoordinator: _isCoordinator,
  coordinatorGradeLevel: _coordinatorGradeLevel,
)
```

**Adaptation for Student Grades:**
```dart
ClassroomLeftSidebarStateful(
  title: 'MY GRADES',  // ← Change title
  expandedGrades: _expandedGrades,
  onGradeToggle: _handleGradeToggle,
  allClassrooms: _enrolledClassrooms,  // ← Student's enrolled classrooms
  selectedClassroom: _selectedClassroom,
  onClassroomSelected: _handleClassroomSelected,
  gradeCoordinators: const {},
  schoolYears: const [],
  userRole: 'student',  // ← Set to 'student'
  isCoordinator: false,
  coordinatorGradeLevel: null,
)
```

**Verdict:** ✅ **PERFECT FIT!** Can be reused with minimal changes

---

### **2. GradebookSubjectList** ⭐ ADAPTABLE

**File:** `lib/widgets/gradebook/gradebook_subject_list.dart`
**Lines:** 184 lines
**Purpose:** Subject list panel (middle panel)

**Features:**
- ✅ Subject cards with selection state
- ✅ Teacher name display
- ✅ Loading state
- ✅ Empty state
- ✅ Clean, modern design

**Current Signature:**
```dart
class GradebookSubjectList extends StatelessWidget {
  final List<ClassroomSubject> subjects;
  final ClassroomSubject? selectedSubject;
  final Function(ClassroomSubject) onSubjectSelected;
  final bool isLoading;
}
```

**Adaptation for Student Grades:**
- ✅ Can be reused AS-IS!
- ✅ Just pass student's subjects instead of teacher's subjects
- ✅ Maybe rename to `StudentGradesSubjectPanel` for clarity

**Verdict:** ✅ **EXCELLENT!** Can be reused with optional rename

---

### **3. SubjectContentTabs** ⚠️ NOT NEEDED

**File:** `lib/widgets/classroom/subject_content_tabs.dart`
**Purpose:** Tabbed interface for subject content (Overview, Assignments, etc.)

**Verdict:** ❌ Not needed for student grades (we only show grades, not tabs)

---

### **4. ClassroomViewerWidget** ❌ NOT NEEDED

**File:** `lib/widgets/classroom/classroom_viewer_widget.dart`
**Purpose:** Display classroom details

**Verdict:** ❌ Not needed for student grades

---

### **5. ClassroomEditorWidget** ❌ NOT NEEDED

**File:** `lib/widgets/classroom/classroom_editor_widget.dart`
**Purpose:** Edit classroom details

**Verdict:** ❌ Not needed for student grades (students can't edit)

---

## 🆕 **WIDGETS TO CREATE**

### **1. StudentGradesContentPanel** ⭐ NEW

**Purpose:** Right panel showing grade display

**Features:**
- Quarter selector (Q1, Q2, Q3, Q4)
- Grade summary card
- Grade breakdown card
- Loading/empty states

**Signature:**
```dart
class StudentGradesContentPanel extends StatelessWidget {
  final ClassroomSubject subject;
  final int selectedQuarter;
  final Function(int) onQuarterSelected;
  final Map<int, Map<String, dynamic>> quarterGrades;
  final Map<String, dynamic>? explanation;
  final bool isLoading;
}
```

---

### **2. StudentQuarterSelector** ⭐ NEW

**Purpose:** Quarter selection chips (Q1, Q2, Q3, Q4)

**Features:**
- Chip-based selection
- Visual feedback for selected quarter
- Compact design

**Signature:**
```dart
class StudentQuarterSelector extends StatelessWidget {
  final int selectedQuarter;
  final Function(int) onQuarterSelected;
}
```

---

### **3. StudentGradeSummaryCard** ⭐ NEW

**Purpose:** Display grade summary (transmuted grade, initial grade, weights)

**Features:**
- Large transmuted grade display
- Initial grade, plus/extra points
- WW/PT/QA weight chips
- Computed date

**Signature:**
```dart
class StudentGradeSummaryCard extends StatelessWidget {
  final Map<String, dynamic> gradeData;
  final int quarter;
  final List<double> weights;
}
```

**Note:** Can extract from current `_buildSummaryCard()` method

---

### **4. StudentGradeBreakdownCard** ⭐ NEW

**Purpose:** Display grade breakdown (WW/PT/QA items)

**Features:**
- Expandable WW/PT/QA sections
- Assignment list with scores
- Missing assignment indicators
- Computation formula

**Signature:**
```dart
class StudentGradeBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> explanation;
  final int quarter;
}
```

**Note:** Can extract from current `_buildExplanationCard()` method

---

## 📊 **WIDGET REUSE SUMMARY**

| Widget | Source | Status | Action |
|--------|--------|--------|--------|
| `ClassroomLeftSidebarStateful` | Classroom | ✅ Reuse | Use with `userRole: 'student'` |
| `GradebookSubjectList` | Gradebook | ✅ Reuse | Use as-is or rename |
| `StudentGradesContentPanel` | - | 🆕 Create | New widget for right panel |
| `StudentQuarterSelector` | - | 🆕 Create | Extract from current code |
| `StudentGradeSummaryCard` | - | 🆕 Create | Extract from current code |
| `StudentGradeBreakdownCard` | - | 🆕 Create | Extract from current code |

---

## 🎨 **DESIGN CONSISTENCY**

### **Color Scheme (from Gradebook):**
- Primary: `Colors.blue`
- Background: `Colors.grey.shade50`
- Border: `Colors.grey.shade300`
- Selected: `Colors.blue.shade50`
- Text: `Colors.black87`, `Colors.grey.shade600`

### **Spacing:**
- Panel width: 280px (left sidebar), 280px (subject list)
- Padding: 8-16px
- Card margin: 8px
- Border radius: 8px

### **Typography:**
- Header: 12px, bold, uppercase, letter-spacing: 0.5
- Title: 13-14px, fontWeight: w600
- Body: 12-13px
- Caption: 11px, grey

---

## 🔄 **MIGRATION STRATEGY**

### **Step 1: Create New Screen**
- Create `student_grades_screen_v2.dart`
- Keep old screen for backward compatibility

### **Step 2: Reuse Existing Widgets**
- Import `ClassroomLeftSidebarStateful`
- Import `GradebookSubjectList` (or create adapted version)

### **Step 3: Create New Widgets**
- Extract summary card logic → `StudentGradeSummaryCard`
- Extract breakdown card logic → `StudentGradeBreakdownCard`
- Create `StudentGradesContentPanel` to compose them

### **Step 4: Compose Layout**
```dart
Row(
  children: [
    ClassroomLeftSidebarStateful(...),  // ← Reused
    GradebookSubjectList(...),          // ← Reused
    Expanded(
      child: StudentGradesContentPanel(...),  // ← New
    ),
  ],
)
```

---

## ✅ **WIDGET INVENTORY CHECKLIST**

- [x] Identified reusable widgets from classroom design
- [x] Identified reusable widgets from gradebook design
- [x] Documented widget signatures and features
- [x] Planned new widgets to create
- [x] Documented design consistency guidelines
- [x] Planned migration strategy

---

## 🚀 **CONCLUSION**

**Status:** ✅ **INVENTORY COMPLETE!**

**Key Findings:**
- ✅ 2 major widgets can be reused (sidebar, subject list)
- ✅ 4 new widgets need to be created (content panel, cards)
- ✅ Design patterns are consistent and well-documented
- ✅ Migration path is clear

**Next Step:** Proceed to Phase 2 (UI Redesign)

---

**Inventory Complete!** ✅


