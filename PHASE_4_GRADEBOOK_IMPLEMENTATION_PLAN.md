# 📊 PHASE 4: TEACHER GRADEBOOK WORKSPACE INTEGRATION

## 🎯 OBJECTIVE
Integrate the old grading workspace into the new classroom UI with a **Gradebook tab** that displays a spreadsheet-like interface showing all students and their assignment scores in a grid format, similar to the provided mockup.

---

## 📸 UI MOCKUP ANALYSIS

Based on the provided image, the Gradebook UI should have:

### **Layout Structure:**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [← Back]  Gradebook                              [Compute Grades] Button   │
│           Grade 7 Jade Mathematics                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  LEFT SIDEBAR (Grade Level Tree)                                           │
│  ├─ High School                                                            │
│  │  ├─ Grade 7 ▼                                                           │
│  │  │  ├─ Grade 7 Jade ✓                                                   │
│  │  │  │  ├─ Mathematics (selected)                                        │
│  │  │  │  ├─ English                                                       │
│  │  │  │  ├─ Science                                                       │
│  │  │  │  └─ Filipino                                                      │
│  │  │  ├─ Grade 7 Diamond                                                  │
│  │  │  ├─ Grade 7 Sapphire                                                 │
│  │  │  └─ Grade 7 Emerald                                                  │
│  │  ├─ Grade 8 ▼                                                           │
│  │  ├─ Grade 9 ▼                                                           │
│  │  └─ ...                                                                 │
│  └─ Senior High School                                                     │
│                                                                             │
│  MAIN CONTENT (Gradebook Grid)                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │ Assignments                                                           │ │
│  │ ┌─────────────┬──────┬──────┬──────┬──────┬──────┬──────┬──────────┐ │ │
│  │ │ Category    │Quiz 1│Act 1 │Quiz 2│Quiz 3│Act 2 │      │ Overall  │ │ │
│  │ │             │ Quiz │Activ.│ Quiz │ Quiz │Activ.│      │          │ │ │
│  │ │ Due         │Sep 10│Sep 10│Sep 10│Sep 10│Sep 10│      │          │ │ │
│  │ │ Grade Rel.  │Inst. │Inst. │Inst. │Inst. │Inst. │      │          │ │ │
│  │ │ Overall     │  10  │  80  │  20  │  10  │ 100  │      │          │ │ │
│  │ ├─────────────┼──────┼──────┼──────┼──────┼──────┼──────┼──────────┤ │ │
│  │ │ 👤 Cruz,    │ 🔴 0 │ 🟡 0 │ 🔺 0 │ ⭐ 0 │ 0%   │ 5.00 │    0     │ │ │
│  │ │    Mathew   │      │      │      │      │      │      │          │ │ │
│  │ ├─────────────┼──────┼──────┼──────┼──────┼──────┼──────┼──────────┤ │ │
│  │ │ 👤 Cruz,    │ 🔴 0 │ 🟡 0 │ 🔺 0 │ ⭐ 0 │ 0%   │ 5.00 │    0     │ │ │
│  │ │    Mathew   │      │      │      │      │      │      │          │ │ │
│  │ └─────────────┴──────┴──────┴──────┴──────┴──────┴──────┴──────────┘ │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### **Key UI Elements:**
1. **Header Row (Assignment Info)**:
   - Assignment title (e.g., "Quiz 1", "Activity 1")
   - Category badge (Quiz/Activity)
   - Due date
   - Grade release status (Instant/Scheduled)
   - Total points (e.g., "10", "80")

2. **Student Rows**:
   - Student avatar + name (e.g., "👤 Cruz, Mathew")
   - Score cells with status indicators:
     - 🔴 Red circle = Missing
     - 🟡 Yellow square = Incomplete
     - 🔺 Red triangle = Absent
     - ⭐ Green star = Excused
     - Number = Actual score
   - Overall percentage (e.g., "0%")
   - Weighted score (e.g., "5.00")
   - Final score (e.g., "0")

3. **Status Badges (Top-right)**:
   - 🔴 Missing
   - 🟡 Incomplete
   - 🔺 Absent
   - ⭐ Excused

4. **Compute Grades Button**:
   - Top-right corner
   - Opens DepEd grade computation dialog

---

## 🏗️ ARCHITECTURE ANALYSIS

### **Current Old Implementation:**
- **File**: `lib/screens/teacher/grades/grade_entry_screen.dart` (2083 lines)
- **Layout**: 3-panel (Classrooms | Courses/Students | Grading Workspace)
- **Features**:
  - Classroom selection
  - Course/Subject selection
  - Quarter selection (Q1-Q4)
  - Student selection (one at a time)
  - 3 tabs: "completed", "to grade", "compute scores"
  - DepEd grade computation with WW/PT/QA breakdown
  - Manual QA score entry
  - Weight overrides (WW%, PT%, QA%)
  - Plus points / Extra points
  - Grade saving to `student_grades` table

### **Database Schema:**
```sql
-- student_grades table
CREATE TABLE public.student_grades (
  id uuid PRIMARY KEY,
  student_id uuid NOT NULL,
  classroom_id uuid NOT NULL,
  course_id bigint,
  quarter smallint NOT NULL CHECK (quarter >= 1 AND quarter <= 4),
  initial_grade numeric NOT NULL,
  transmuted_grade numeric NOT NULL,
  adjusted_grade numeric,
  plus_points numeric DEFAULT 0,
  extra_points numeric DEFAULT 0,
  remarks text,
  computed_at timestamp with time zone NOT NULL DEFAULT now(),
  computed_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  qa_score_override numeric,
  qa_max_override numeric,
  ww_weight_override numeric,  -- Fraction (0.0-1.0)
  pt_weight_override numeric,  -- Fraction (0.0-1.0)
  qa_weight_override numeric   -- Fraction (0.0-1.0)
);
```

### **DepEd Grade Computation Logic:**
```dart
// From DepEdGradeService
static const double WRITTEN_WORK_WEIGHT = 0.30;      // 30%
static const double PERFORMANCE_TASK_WEIGHT = 0.50;  // 50%
static const double QUARTERLY_ASSESSMENT_WEIGHT = 0.20; // 20%

// Formula:
Initial Grade = (WW_PS * WW_Weight) + (PT_PS * PT_Weight) + (QA_PS * QA_Weight)
Initial Grade = Initial Grade + Plus Points + Extra Points
Transmuted Grade = 60 + (40 * (Initial Grade / 100))  // Linear transmutation
```

### **Assignment Component Classification:**
- **Written Works (WW)**: quiz, multiple_choice, identification, matching_type
- **Performance Task (PT)**: essay, file_upload
- **Quarterly Assessment (QA)**: Manual entry (no assignments)

---

## 🎨 NEW UI DESIGN PLAN

### **Integration into Classroom UI:**
```
My Classroom > Select Classroom > Select Subject > [Gradebook Tab]
```

### **Tab Structure:**
```
┌─────────────────────────────────────────────────────────────────┐
│ Resources │ Assignments │ Gradebook │ Students │               │
└─────────────────────────────────────────────────────────────────┘
```

### **Gradebook Tab Layout:**
```
┌─────────────────────────────────────────────────────────────────┐
│ [Q1] [Q2] [Q3] [Q4]                    [Compute Grades] Button │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Spreadsheet Grid (Horizontal Scroll)                      │ │
│  │ ┌─────────────┬──────┬──────┬──────┬──────┬──────────────┐│ │
│  │ │ Student     │Asgn 1│Asgn 2│Asgn 3│Asgn 4│ Overall      ││ │
│  │ ├─────────────┼──────┼──────┼──────┼──────┼──────────────┤│ │
│  │ │ 👤 Student 1│  10  │  15  │  20  │  18  │ 85% (42.5)   ││ │
│  │ │ 👤 Student 2│  8   │  14  │  19  │  17  │ 82% (41.0)   ││ │
│  │ └─────────────┴──────┴──────┴──────┴──────┴──────────────┘│ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 IMPLEMENTATION TASKS

### **Task 1: Create Gradebook Tab Widget**
- **File**: `lib/widgets/classroom/subject_gradebook_tab.dart` (NEW)
- **Features**:
  - Quarter selection (Q1-Q4)
  - Fetch all students in classroom
  - Fetch all assignments for selected quarter + subject
  - Display spreadsheet grid
  - Click cell to edit score
  - Click student row to open grade computation dialog
  - "Compute Grades" button (top-right)

### **Task 2: Create Gradebook Grid Widget**
- **File**: `lib/widgets/classroom/gradebook_grid.dart` (NEW)
- **Features**:
  - Horizontal scrollable table
  - Fixed left column (student names)
  - Dynamic assignment columns
  - Editable score cells
  - Status indicators (Missing, Incomplete, Absent, Excused)
  - Overall column (percentage + weighted score)

### **Task 3: Create Grade Computation Dialog**
- **File**: `lib/widgets/classroom/grade_computation_dialog.dart` (NEW)
- **Features**:
  - Display WW/PT/QA breakdown
  - Show assignment scores
  - Manual QA entry
  - Weight overrides
  - Plus/Extra points
  - Remarks
  - Save to `student_grades` table

### **Task 4: Integrate into SubjectContentTabs**
- **File**: `lib/widgets/classroom/subject_content_tabs.dart` (MODIFY)
- **Changes**:
  - Add "Gradebook" tab (after Assignments)
  - Pass subject, classroom, userRole to GradebookTab

### **Task 5: Remove Old Grade Entry Navigation**
- **File**: `lib/screens/teacher/teacher_dashboard_screen.dart` (MODIFY)
- **Changes**:
  - Remove "Grades" navigation (index 3)
  - Update indices for Attendance, Reports, Profile, Help

### **Task 6: Preserve Backend Logic**
- **Files**: Keep existing services unchanged
  - `lib/services/deped_grade_service.dart` ✅
  - `lib/services/grade_service.dart` ✅
  - `lib/models/quarterly_grade.dart` ✅

---

## 🔄 DATA FLOW

### **Gradebook Tab Load:**
```
1. User selects classroom → subject → Gradebook tab
2. Fetch students: ClassroomService.getClassroomStudents(classroomId)
3. Fetch assignments: AssignmentService.getClassroomAssignments(classroomId, quarter)
4. Filter assignments by subject (course_id)
5. Fetch submissions: For each student, get all submissions for assignments
6. Build grid: Students (rows) × Assignments (columns)
7. Display scores in cells
```

### **Score Edit:**
```
1. User clicks score cell
2. Show dialog with score input
3. Update submission: SubmissionService.updateSubmission(submissionId, score)
4. Refresh grid
```

### **Compute Grades:**
```
1. User clicks "Compute Grades" button
2. Show dialog with student list
3. User selects student
4. Fetch breakdown: DepEdGradeService.computeQuarterlyBreakdown(...)
5. Display WW/PT/QA breakdown
6. Allow manual QA entry, weight overrides, plus/extra points
7. Save: DepEdGradeService.saveOrUpdateStudentQuarterGrade(...)
8. Close dialog
```

---

## ✅ SUCCESS CRITERIA

- ✅ Gradebook tab appears in subject content tabs
- ✅ Grid displays all students and assignments
- ✅ Scores are editable by clicking cells
- ✅ Status indicators show (Missing, Incomplete, etc.)
- ✅ Quarter filtering works (Q1-Q4)
- ✅ "Compute Grades" button opens computation dialog
- ✅ DepEd computation logic preserved
- ✅ Grades save to `student_grades` table
- ✅ Old "Grades" navigation removed from dashboard
- ✅ Clean build with 0 errors

---

## 🔧 TECHNICAL SPECIFICATIONS

### **Widget Hierarchy:**
```
SubjectContentTabs
├─ Resources Tab
├─ Assignments Tab
└─ Gradebook Tab (NEW)
   ├─ Quarter Selector (Q1-Q4)
   ├─ Compute Grades Button
   └─ GradebookGrid
      ├─ Header Row (Assignment Info)
      ├─ Student Rows
      │  ├─ Student Name Cell (Fixed)
      │  ├─ Score Cells (Editable)
      │  └─ Overall Cell (Computed)
      └─ Status Indicators
```

### **State Management:**
```dart
class _SubjectGradebookTabState extends State<SubjectGradebookTab> {
  int _selectedQuarter = 1;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _assignments = [];
  Map<String, Map<String, dynamic>> _submissions = {}; // studentId_assignmentId -> submission
  bool _isLoading = true;

  // Load data
  Future<void> _loadGradebookData() async {
    // 1. Fetch students
    // 2. Fetch assignments (filtered by quarter + subject)
    // 3. Fetch submissions (for all students × assignments)
    // 4. Build submission map
  }

  // Edit score
  Future<void> _editScore(String studentId, String assignmentId, double currentScore) async {
    // Show dialog
    // Update submission
    // Refresh grid
  }

  // Compute grades
  Future<void> _showComputeGradesDialog() async {
    // Show student list
    // User selects student
    // Open grade computation dialog
  }
}
```

### **Grid Data Structure:**
```dart
// Grid cell data
class GradebookCell {
  final String studentId;
  final String assignmentId;
  final double? score;
  final double? maxScore;
  final String status; // 'submitted', 'graded', 'missing', 'excused'
  final bool isLate;

  // Status indicator
  Widget getStatusIcon() {
    if (status == 'missing') return Icon(Icons.circle, color: Colors.red);
    if (status == 'incomplete') return Icon(Icons.square, color: Colors.orange);
    if (status == 'excused') return Icon(Icons.star, color: Colors.green);
    if (isLate) return Icon(Icons.warning, color: Colors.red);
    return SizedBox.shrink();
  }
}

// Grid row data
class GradebookRow {
  final String studentId;
  final String studentName;
  final List<GradebookCell> cells;
  final double overallPercentage;
  final double weightedScore;
  final double finalScore;
}
```

### **API Calls:**
```dart
// 1. Fetch students
final students = await ClassroomService().getClassroomStudents(classroomId);

// 2. Fetch assignments (filtered by quarter + subject)
final assignments = await AssignmentService().getClassroomAssignments(classroomId);
final filteredAssignments = assignments.where((a) =>
  a['quarter_no'] == selectedQuarter &&
  a['course_id'] == subject.id
).toList();

// 3. Fetch submissions (bulk query)
final submissionQuery = await Supabase.instance.client
  .from('assignment_submissions')
  .select('*')
  .eq('classroom_id', classroomId)
  .inFilter('assignment_id', assignmentIds)
  .inFilter('student_id', studentIds);

// 4. Build submission map
final submissionMap = <String, Map<String, dynamic>>{};
for (final sub in submissions) {
  final key = '${sub['student_id']}_${sub['assignment_id']}';
  submissionMap[key] = sub;
}
```

### **Score Editing:**
```dart
Future<void> _editScore(String studentId, String assignmentId, double currentScore) async {
  final newScore = await showDialog<double>(
    context: context,
    builder: (ctx) => ScoreEditDialog(
      currentScore: currentScore,
      maxScore: assignment['total_points'],
    ),
  );

  if (newScore != null) {
    // Update submission
    await SubmissionService().updateSubmissionScore(
      submissionId: submissionId,
      score: newScore,
      gradedBy: teacherId,
    );

    // Refresh grid
    _loadGradebookData();
  }
}
```

### **Grade Computation Dialog:**
```dart
Future<void> _showComputeGradesDialog() async {
  // Step 1: Show student list
  final selectedStudent = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StudentSelectionDialog(students: _students),
  );

  if (selectedStudent == null) return;

  // Step 2: Compute breakdown
  final breakdown = await DepEdGradeService().computeQuarterlyBreakdown(
    classroomId: widget.classroomId,
    courseId: widget.subject.id,
    studentId: selectedStudent['id'],
    quarter: _selectedQuarter,
  );

  // Step 3: Show computation dialog
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => GradeComputationDialog(
      student: selectedStudent,
      breakdown: breakdown,
      quarter: _selectedQuarter,
      classroomId: widget.classroomId,
      courseId: widget.subject.id,
    ),
  );

  if (saved == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Grade saved successfully')),
    );
  }
}
```

---

## 📊 PERFORMANCE CONSIDERATIONS

### **Optimization Strategies:**
1. **Lazy Loading**: Load only visible rows (virtualized scrolling)
2. **Caching**: Cache submissions map to avoid repeated queries
3. **Debouncing**: Debounce score edits to avoid excessive API calls
4. **Pagination**: If > 50 students, implement pagination
5. **Realtime Updates**: Subscribe to submission changes for live updates

### **Query Optimization:**
```dart
// Instead of N queries (one per student), use bulk query
// BAD:
for (final student in students) {
  final subs = await getSubmissions(student.id);
}

// GOOD:
final allSubs = await Supabase.instance.client
  .from('assignment_submissions')
  .select('*')
  .eq('classroom_id', classroomId)
  .inFilter('student_id', studentIds)
  .inFilter('assignment_id', assignmentIds);
```

---

## 🎯 PHASE 4 IMPLEMENTATION STEPS

### **Step 1: Create Gradebook Tab Widget** (30 min)
- Create `lib/widgets/classroom/subject_gradebook_tab.dart`
- Add quarter selector
- Add "Compute Grades" button
- Add loading state

### **Step 2: Create Gradebook Grid Widget** (60 min)
- Create `lib/widgets/classroom/gradebook_grid.dart`
- Implement horizontal scrollable table
- Add fixed left column (student names)
- Add dynamic assignment columns
- Add status indicators

### **Step 3: Implement Score Editing** (30 min)
- Create score edit dialog
- Implement submission update
- Add validation (score <= max_score)

### **Step 4: Implement Grade Computation** (45 min)
- Create student selection dialog
- Create grade computation dialog
- Integrate DepEdGradeService
- Add save functionality

### **Step 5: Integrate into SubjectContentTabs** (15 min)
- Add "Gradebook" tab
- Pass required props
- Test navigation

### **Step 6: Remove Old Navigation** (10 min)
- Remove "Grades" from teacher dashboard
- Update navigation indices

### **Step 7: Testing & Polish** (30 min)
- Test with real data
- Fix UI issues
- Add error handling
- Verify DepEd computation

**Total Estimated Time: ~3.5 hours**

---

## 🚨 CRITICAL REQUIREMENTS

### **Must Preserve:**
- ✅ DepEd grade computation formulas (WW 30%, PT 50%, QA 20%)
- ✅ Transmutation formula: `60 + (40 * (IG / 100))`
- ✅ Weight override functionality
- ✅ Plus points / Extra points
- ✅ Manual QA entry
- ✅ Grade saving to `student_grades` table
- ✅ All existing services and models

### **Must Remove:**
- ❌ Old "Grades" navigation from teacher dashboard
- ❌ Standalone `GradeEntryScreen` access

### **Must Add:**
- ✅ Gradebook tab in subject content tabs
- ✅ Spreadsheet-like grid UI
- ✅ Editable score cells
- ✅ Status indicators
- ✅ "Compute Grades" button

---

**READY FOR IMPLEMENTATION** 🚀

**Next Command**: `proceed with step 1` to start implementation

