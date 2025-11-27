# ✅ Inspection Checklist - Verify Changes

**Purpose:** Systematic checklist to verify all changes are correct  
**Use:** Check off each item as you verify it

---

## 📋 Pre-Inspection Setup

- [ ] Open project in IDE (VS Code / Android Studio)
- [ ] Open browser with DevTools (F12)
- [ ] Have 3 test accounts ready (Admin, Teacher, Student)
- [ ] Run `flutter analyze` - confirm 0 errors
- [ ] Run `flutter run` - app starts successfully

---

## 🔧 Error Fix Verification

### Fix #1: Const Constructor (classroom_subjects_panel.dart)

**File to Inspect:** `lib/widgets/classroom/classroom_subjects_panel.dart`

**Line 32-37:** Check field initialization removed
- [ ] Line 32-35: No `_permissionService` field initialization
- [ ] Line 37: `const ClassroomSubjectsPanel({...})` exists
- [ ] No compilation errors in this file

**Line 49-57:** Check local instantiation added
- [ ] Line 50: `final permissionService = ClassroomPermissionService();` exists
- [ ] Line 51: Uses `permissionService.canCreateSubjects(...)`
- [ ] Method works correctly (test by viewing subjects panel)

**Runtime Test:**
- [ ] Navigate to any classroom screen
- [ ] Subjects panel displays correctly
- [ ] No errors in console

**Verdict:** ✅ Fix is correct / ❌ Issue found: _______________

---

### Fix #2: Method Name (subject_assignments_tab.dart)

**File to Inspect:** `lib/widgets/classroom/subject_assignments_tab.dart`

**Line 85:** Check method name corrected
- [ ] Line 85: `getClassroomAssignments(` (NOT `getAssignmentsByClassroom`)
- [ ] Method signature matches `AssignmentService`
- [ ] No compilation errors in this file

**Runtime Test:**
- [ ] Login as Teacher
- [ ] Navigate to: My Classroom → Select classroom → Select subject
- [ ] Click "Assignments" tab
- [ ] Assignments load without errors

**Verdict:** ✅ Fix is correct / ❌ Issue found: _______________

---

### Fix #3: Feature Flag Service (feature_flag_service.dart)

**File to Inspect:** `lib/services/feature_flag_service.dart`

**File Existence:**
- [ ] File exists at `lib/services/feature_flag_service.dart`
- [ ] File is ~150 lines long
- [ ] No compilation errors in this file

**Line 1-2:** Check imports
- [ ] Line 1: `import 'package:shared_preferences/shared_preferences.dart';`
- [ ] No other imports needed

**Line 30-35:** Check storage keys
- [ ] Line 32: `_newClassroomUIKey` defined
- [ ] Line 33: `_emergencyRollbackKey` defined

**Line 45-65:** Check main method
- [ ] Line 45: `isNewClassroomUIEnabled()` method exists
- [ ] Line 52-56: Emergency rollback check exists
- [ ] Line 59: Default returns `false` (old UI)

**Line 70-80:** Check enable method
- [ ] Line 70: `enableNewClassroomUI()` method exists
- [ ] Line 74: Sets flag to `true`

**Line 85-95:** Check disable method
- [ ] Line 85: `disableNewClassroomUI()` method exists
- [ ] Line 89: Sets flag to `false`

**Line 100-110:** Check toggle method
- [ ] Line 100: `toggleNewClassroomUI()` method exists
- [ ] Toggles between true/false

**Line 120-130:** Check emergency rollback
- [ ] Line 120: `emergencyRollback()` method exists
- [ ] Sets emergency flag to `true`

**Line 135-145:** Check clear rollback
- [ ] Line 135: `clearEmergencyRollback()` method exists
- [ ] Removes emergency flag

**Runtime Test:**
- [ ] Open browser console (F12)
- [ ] Import service: `import 'package:oro_site_high_school/services/feature_flag_service.dart';`
- [ ] Run: `await FeatureFlagService.isNewClassroomUIEnabled();`
- [ ] Returns `false` (default)
- [ ] No errors

**Verdict:** ✅ Fix is correct / ❌ Issue found: _______________

---

## 📚 Feature Addition Verification

### Feature #1: Classroom Fetching (classroom_service.dart)

**File to Inspect:** `lib/services/classroom_service.dart`

**Line 98-201:** Check `getTeacherClassrooms()` method
- [ ] Line 98: Method signature: `Future<List<Classroom>> getTeacherClassrooms(String teacherId)`
- [ ] Line 105-115: Fetches owned classrooms (`teacher_id`)
- [ ] Line 120-135: Fetches advisory classrooms (`advisory_teacher_id`)
- [ ] Line 140-155: Fetches co-teacher classrooms (`classroom_teachers` table)
- [ ] Line 160-180: Fetches subject teacher classrooms (`classroom_subjects` table)
- [ ] Line 185-190: Merges and deduplicates by classroom ID
- [ ] Line 192-197: Sorts by grade level (7-12), then title

**Line 815-878:** Check `getStudentClassrooms()` method
- [ ] Line 815: Method signature: `Future<List<Classroom>> getStudentClassrooms(String studentId)`
- [ ] Line 820-830: Fetches from `classroom_students` table
- [ ] Line 850-860: Filters active classrooms only
- [ ] Line 865-870: Sorts by grade level (7-12), then title

**Runtime Test - Teacher:**
- [ ] Login as Admin, create classroom, assign Teacher A as advisory
- [ ] Login as Teacher A
- [ ] Navigate to: My Classroom
- [ ] Classroom appears in list
- [ ] No duplicates if teacher has multiple roles

**Runtime Test - Student:**
- [ ] Login as Admin, enroll Student A in classroom
- [ ] Login as Student A
- [ ] Navigate to: My Classroom
- [ ] Classroom appears in list
- [ ] Only enrolled classrooms visible

**Verdict:** ✅ Feature works correctly / ❌ Issue found: _______________

---

### Feature #2: Feature Flag Imports (Dashboard Screens)

**File to Inspect:** `lib/screens/student/dashboard/student_dashboard_screen.dart`

**Line 17:** Check import added
- [ ] Line 17: `import 'package:oro_site_high_school/services/feature_flag_service.dart';`
- [ ] No compilation errors

**Line 166:** Check feature flag usage
- [ ] Line 166: `final useNewUI = await FeatureFlagService.isNewClassroomUIEnabled();`
- [ ] Line 171: Routes to `StudentClassroomScreenV2` if true
- [ ] Line 173: Routes to `StudentClassroomScreen` if false

**File to Inspect:** `lib/screens/teacher/teacher_dashboard_screen.dart`

**Line 17:** Check import added
- [ ] Line 17: `import 'package:oro_site_high_school/services/feature_flag_service.dart';`
- [ ] No compilation errors

**Line 149:** Check feature flag usage
- [ ] Line 149: `final useNewUI = await FeatureFlagService.isNewClassroomUIEnabled();`
- [ ] Line 154: Routes to `MyClassroomScreenV2` if true
- [ ] Line 156: Routes to `MyClassroomScreen` if false

**Runtime Test:**
- [ ] Login as Teacher
- [ ] Navigate to: My Classroom
- [ ] Old UI appears (default)
- [ ] Enable new UI in console
- [ ] Navigate to: My Classroom again
- [ ] New UI appears (3-panel layout)

**Verdict:** ✅ Feature works correctly / ❌ Issue found: _______________

---

## 🔒 Protected Systems Verification

### Grading Workspace (CRITICAL)

**File to Inspect:** `lib/screens/teacher/grades/grade_entry_screen.dart`

**Git Diff Check:**
- [ ] Run: `git diff lib/screens/teacher/grades/grade_entry_screen.dart`
- [ ] Output is empty (no changes)

**File to Inspect:** `lib/services/deped_grade_service.dart`

**Git Diff Check:**
- [ ] Run: `git diff lib/services/deped_grade_service.dart`
- [ ] Output is empty (no changes)

**Runtime Test:**
- [ ] Login as Teacher
- [ ] Navigate to: Grades → Grade Entry
- [ ] Select student and quarter
- [ ] Enter scores: WW=80, PT=85, QA=90
- [ ] Click "Compute Grade"
- [ ] Verify: Grade = 84.5 (correct formula: 80×0.30 + 85×0.50 + 90×0.20)
- [ ] Click "Save Grade"
- [ ] Grade saves successfully

**Verdict:** ✅ UNTOUCHED and functional / ❌ CRITICAL ISSUE: _______________

---

### Attendance System (CRITICAL)

**File to Inspect:** `lib/screens/teacher/attendance/teacher_attendance_screen.dart`

**Git Diff Check:**
- [ ] Run: `git diff lib/screens/teacher/attendance/teacher_attendance_screen.dart`
- [ ] Output is empty (no changes)

**File to Inspect:** `lib/services/attendance_service.dart`

**Git Diff Check:**
- [ ] Run: `git diff lib/services/attendance_service.dart`
- [ ] Output is empty (no changes)

**Runtime Test:**
- [ ] Login as Teacher
- [ ] Navigate to: Attendance
- [ ] Select classroom and date
- [ ] Mark students: Present, Absent, Late
- [ ] Click "Save Attendance"
- [ ] Attendance saves successfully
- [ ] QR code generation works (if applicable)

**Verdict:** ✅ UNTOUCHED and functional / ❌ CRITICAL ISSUE: _______________

---

## 🔄 Backward Compatibility Verification

### Old UI Still Works
- [ ] Disable new UI: `await FeatureFlagService.disableNewClassroomUI();`
- [ ] Login as Teacher
- [ ] Navigate to: My Classroom
- [ ] Old UI loads successfully
- [ ] All features work (view classrooms, subjects, modules)

### New UI Works
- [ ] Enable new UI: `await FeatureFlagService.enableNewClassroomUI();`
- [ ] Login as Teacher
- [ ] Navigate to: My Classroom
- [ ] New UI loads successfully (3-panel layout)
- [ ] All features work (select classroom, subject, view content)

### Switching Works
- [ ] Toggle between old and new UI 3 times
- [ ] No errors during switches
- [ ] Both UIs remain functional

**Verdict:** ✅ Backward compatible / ❌ Issue found: _______________

---

## 📊 Final Inspection Summary

### Error Fixes
- [ ] ✅ Const constructor fix verified
- [ ] ✅ Method name fix verified
- [ ] ✅ Feature flag service created and works

### Feature Additions
- [ ] ✅ Classroom fetching works (teacher 4 patterns, student 1 pattern)
- [ ] ✅ Feature flag imports added to dashboards
- [ ] ✅ Feature flag routing works

### Protected Systems
- [ ] ✅ Grading workspace UNTOUCHED and functional
- [ ] ✅ Attendance system UNTOUCHED and functional

### Backward Compatibility
- [ ] ✅ Old UI still works
- [ ] ✅ New UI works
- [ ] ✅ Switching between UIs works

### Build Status
- [ ] ✅ `flutter analyze` shows 0 errors
- [ ] ✅ App runs without crashes
- [ ] ✅ No console errors during testing

---

## 🎯 Final Verdict

**Overall Status:** 
- [ ] ✅ ALL CHECKS PASSED - Changes are safe and correct
- [ ] ⚠️ MINOR ISSUES FOUND - See notes below
- [ ] ❌ CRITICAL ISSUES FOUND - STOP and report immediately

**Issues Found:**
```
1. [Issue description]
2. [Issue description]
3. [Issue description]
```

**Notes:**
```
[Any additional observations or comments]
```

**Recommendation:**
- [ ] ✅ Approve for production
- [ ] ⚠️ Approve with minor fixes
- [ ] ❌ Reject - critical issues must be fixed

---

**Inspection completed by:** _______________  
**Date:** _______________  
**Time spent:** _______________ minutes

---

**Thank you for the thorough inspection! 🔍✨**

