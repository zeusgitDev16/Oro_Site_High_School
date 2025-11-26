# 🧪 Complete Testing Guide - Feature Walkthrough & Inspection

**Date:** 2025-11-26  
**Purpose:** Step-by-step guide to test all changes and verify nothing was broken  
**Time Required:** ~30-45 minutes for complete walkthrough

---

## 📋 Table of Contents

1. [Pre-Testing Setup](#pre-testing-setup)
2. [Phase 1: Error Fixes Verification](#phase-1-error-fixes-verification)
3. [Phase 2: Feature Flag System Testing](#phase-2-feature-flag-system-testing)
4. [Phase 3: Classroom Fetching Testing](#phase-3-classroom-fetching-testing)
5. [Phase 4: Admin Classroom Management Testing](#phase-4-admin-classroom-management-testing)
6. [Phase 5: Protected Systems Verification](#phase-5-protected-systems-verification)
7. [Phase 6: Backward Compatibility Testing](#phase-6-backward-compatibility-testing)

---

## 🔧 Pre-Testing Setup

### Step 1: Verify Build Status
```bash
# Run Flutter analyze to confirm 0 errors
flutter analyze

# Expected: 0 errors (warnings and info are OK)
```

### Step 2: Run the Application
```bash
# Clean build
flutter clean
flutter pub get
flutter run

# Or for web
flutter run -d chrome
```

### Step 3: Prepare Test Accounts
You'll need access to:
- ✅ **1 Admin account** (for classroom management)
- ✅ **2 Teacher accounts** (for classroom fetching tests)
- ✅ **2 Student accounts** (for classroom fetching tests)

---

## 🔍 Phase 1: Error Fixes Verification

### Test 1.1: Const Constructor Fix
**File:** `lib/widgets/classroom/classroom_subjects_panel.dart`

**What Changed:**
- Removed field initialization: `final ClassroomPermissionService _permissionService = const ClassroomPermissionService();`
- Added local instantiation in getter: `final permissionService = ClassroomPermissionService();`

**How to Test:**
1. ✅ **Build the app** - Should compile without errors
2. ✅ **Navigate to any classroom screen** (admin, teacher, or student)
3. ✅ **Verify subjects panel displays correctly**
4. ✅ **Check "Add Subject" button visibility** (should show for admin/teacher, hide for student)

**Expected Result:**
- ✅ No compilation errors
- ✅ Subjects panel renders correctly
- ✅ RBAC permissions work (admin/teacher can add, student cannot)

**What to Inspect:**
- Does the subjects panel load?
- Can you see the list of subjects?
- Does the "Add Subject" button appear for admin/teacher?

---

### Test 1.2: Method Name Fix
**File:** `lib/widgets/classroom/subject_assignments_tab.dart`

**What Changed:**
- Changed: `getAssignmentsByClassroom()` → `getClassroomAssignments()`

**How to Test:**
1. ✅ **Login as Teacher**
2. ✅ **Navigate to:** My Classroom → Select a classroom → Select a subject
3. ✅ **Click on "Assignments" tab**
4. ✅ **Verify assignments load without errors**

**Expected Result:**
- ✅ Assignments tab loads successfully
- ✅ Assignments are displayed (if any exist)
- ✅ No console errors about undefined methods

**What to Inspect:**
- Does the assignments tab load?
- Are assignments displayed correctly?
- Check browser console for errors (F12)

---

### Test 1.3: Feature Flag Service Creation
**File:** `lib/services/feature_flag_service.dart` (NEW FILE)

**What Changed:**
- Created complete feature flag service from scratch
- Enables toggling between old and new classroom UI

**How to Test:**
1. ✅ **Open Flutter DevTools Console**
2. ✅ **Run this code in console:**
```dart
import 'package:oro_site_high_school/services/feature_flag_service.dart';

// Check current state
final enabled = await FeatureFlagService.isNewClassroomUIEnabled();
print('New UI enabled: $enabled'); // Should print: false (default)
```

**Expected Result:**
- ✅ Service imports without errors
- ✅ Default state is `false` (old UI)
- ✅ No compilation errors

**What to Inspect:**
- Does the service import successfully?
- Is the default state `false`?

---

## 🎛️ Phase 2: Feature Flag System Testing

### Test 2.1: Enable New Classroom UI
**Purpose:** Test switching from old to new classroom UI

**Steps:**
1. ✅ **Login as Teacher**
2. ✅ **Open browser console** (F12)
3. ✅ **Enable new UI:**
```dart
import 'package:oro_site_high_school/services/feature_flag_service.dart';
await FeatureFlagService.enableNewClassroomUI();
```
4. ✅ **Navigate to:** Dashboard → My Classroom
5. ✅ **Verify:** Should see **NEW** three-panel layout (Classrooms | Subjects | Content)

**Expected Result:**
- ✅ Console prints: "✅ New classroom UI enabled"
- ✅ Navigation routes to `MyClassroomScreenV2`
- ✅ Three-panel layout appears

**What to Inspect:**
- Does the new UI load?
- Are there three panels (classrooms, subjects, content)?
- Does it look different from the old UI?

---

### Test 2.2: Disable New Classroom UI (Rollback)
**Purpose:** Test instant rollback to old UI

**Steps:**
1. ✅ **With new UI still enabled, open console**
2. ✅ **Disable new UI:**
```dart
import 'package:oro_site_high_school/services/feature_flag_service.dart';
await FeatureFlagService.disableNewClassroomUI();
```
3. ✅ **Navigate to:** Dashboard → My Classroom
4. ✅ **Verify:** Should see **OLD** classroom UI

**Expected Result:**
- ✅ Console prints: "✅ New classroom UI disabled - reverted to old UI"
- ✅ Navigation routes to `MyClassroomScreen` (old)
- ✅ Old UI appears (different layout)

**What to Inspect:**
- Does it switch back to old UI?
- Is the rollback instant (< 5 seconds)?
- Does old UI still work correctly?

---

### Test 2.3: Emergency Rollback
**Purpose:** Test emergency rollback that overrides feature flag

**Steps:**
1. ✅ **Enable new UI first:**
```dart
await FeatureFlagService.enableNewClassroomUI();
```
2. ✅ **Activate emergency rollback:**
```dart
await FeatureFlagService.emergencyRollback();
```
3. ✅ **Navigate to:** Dashboard → My Classroom
4. ✅ **Verify:** Should see **OLD** UI (even though flag is enabled)

**Expected Result:**
- ✅ Console prints: "🚨 EMERGENCY ROLLBACK ACTIVATED - All users forced to old UI"
- ✅ Old UI appears despite feature flag being enabled
- ✅ Emergency rollback overrides feature flag

**What to Inspect:**
- Does emergency rollback force old UI?
- Does it override the feature flag?

---

### Test 2.4: Clear Emergency Rollback
**Purpose:** Test clearing emergency rollback

**Steps:**
1. ✅ **Clear emergency rollback:**
```dart
await FeatureFlagService.clearEmergencyRollback();
```
2. ✅ **Navigate to:** Dashboard → My Classroom
3. ✅ **Verify:** Should see **NEW** UI (feature flag takes effect again)

**Expected Result:**
- ✅ Console prints: "✅ Emergency rollback cleared"
- ✅ Feature flag works normally again
- ✅ New UI appears (because flag is still enabled)

**What to Inspect:**
- Does clearing rollback restore feature flag behavior?
- Does new UI appear again?

---

## 📚 Phase 3: Classroom Fetching Testing

### Test 3.1: Teacher as Classroom Owner
**Purpose:** Verify teacher sees classrooms they created

**Setup:**
1. ✅ **Login as Admin**
2. ✅ **Create a classroom:**
   - Navigate to: Classrooms
   - Click: "Create Classroom"
   - Fill in: Title, Grade Level, School Level
   - **Important:** Leave "Advisory Teacher" empty (you are the owner)
   - Click: "Create"

**Test:**
1. ✅ **Login as Teacher** (the one who created the classroom)
2. ✅ **Navigate to:** My Classroom
3. ✅ **Verify:** Classroom appears in the list

**Expected Result:**
- ✅ Classroom appears in teacher's classroom list
- ✅ Sorted by grade level (7-12)

**What to Inspect:**
- Does the classroom appear?
- Is it sorted correctly by grade level?

---

### Test 3.2: Teacher as Advisory Teacher
**Purpose:** Verify teacher sees classrooms where they are advisory teacher

**Setup:**
1. ✅ **Login as Admin**
2. ✅ **Create a classroom:**
   - Navigate to: Classrooms
   - Click: "Create Classroom"
   - Fill in: Title, Grade Level, School Level
   - **Important:** Select Teacher A as "Advisory Teacher"
   - Click: "Create"

**Test:**
1. ✅ **Login as Teacher A**
2. ✅ **Navigate to:** My Classroom
3. ✅ **Verify:** Classroom appears in the list

**Expected Result:**
- ✅ Classroom appears in Teacher A's classroom list
- ✅ Teacher A can access classroom even though they didn't create it

**What to Inspect:**
- Does the classroom appear for the advisory teacher?
- Can they access it?

---

### Test 3.3: Teacher as Subject Teacher
**Purpose:** Verify teacher sees classrooms where they teach a subject

**Setup:**
1. ✅ **Login as Admin**
2. ✅ **Create a classroom** (or use existing)
3. ✅ **Add a subject:**
   - Select the classroom
   - Click: "Add Subject"
   - Fill in: Subject Name, Subject Code
   - **Important:** Assign Teacher B as subject teacher
   - Click: "Save"

**Test:**
1. ✅ **Login as Teacher B**
2. ✅ **Navigate to:** My Classroom
3. ✅ **Verify:** Classroom appears in the list

**Expected Result:**
- ✅ Classroom appears in Teacher B's classroom list
- ✅ Teacher B can access classroom because they teach a subject in it

**What to Inspect:**
- Does the classroom appear for the subject teacher?
- Can they access it?

---

### Test 3.4: Teacher with Multiple Roles (Deduplication)
**Purpose:** Verify teacher sees classroom only once even with multiple roles

**Setup:**
1. ✅ **Login as Admin**
2. ✅ **Create a classroom:**
   - Set Teacher C as "Advisory Teacher"
3. ✅ **Add a subject:**
   - Assign Teacher C as subject teacher

**Test:**
1. ✅ **Login as Teacher C**
2. ✅ **Navigate to:** My Classroom
3. ✅ **Verify:** Classroom appears **ONLY ONCE** (not duplicated)

**Expected Result:**
- ✅ Classroom appears only once in the list
- ✅ No duplicates despite multiple roles

**What to Inspect:**
- Does the classroom appear only once?
- Are there any duplicates?

---

### Test 3.5: Student Classroom Fetching
**Purpose:** Verify student sees only enrolled classrooms

**Setup:**
1. ✅ **Login as Admin**
2. ✅ **Create a classroom** (or use existing)
3. ✅ **Enroll Student A:**
   - Select the classroom
   - Click: "Manage Students"
   - Search for Student A
   - Click: "Add Student"

**Test:**
1. ✅ **Login as Student A**
2. ✅ **Navigate to:** My Classroom
3. ✅ **Verify:** Classroom appears in the list

**Expected Result:**
- ✅ Classroom appears in Student A's classroom list
- ✅ Sorted by grade level

**What to Inspect:**
- Does the classroom appear for enrolled student?
- Is it sorted by grade level?

---

### Test 3.6: Student NOT Enrolled
**Purpose:** Verify student doesn't see classrooms they're not enrolled in

**Setup:**
1. ✅ **Login as Admin**
2. ✅ **Create a classroom**
3. ✅ **Do NOT enroll Student B**

**Test:**
1. ✅ **Login as Student B**
2. ✅ **Navigate to:** My Classroom
3. ✅ **Verify:** Classroom does NOT appear in the list

**Expected Result:**
- ✅ Classroom does NOT appear
- ✅ Student only sees enrolled classrooms

**What to Inspect:**
- Is the classroom hidden from non-enrolled student?
- Does student only see their enrolled classrooms?

---

## 🎓 Phase 4: Admin Classroom Management Testing

### Test 4.1: Create Classroom Flow
**Purpose:** Test complete classroom creation flow

**Steps:**
1. ✅ **Login as Admin**
2. ✅ **Navigate to:** Classrooms
3. ✅ **Click:** "Create Classroom" button
4. ✅ **Fill in Classroom Settings:**
   - Title: "Grade 7 - Section A"
   - School Level: "Junior High School"
   - Grade Level: 7
   - Max Students: 40
   - Advisory Teacher: Select a teacher
5. ✅ **Add Subjects:**
   - Click: "Add Subject"
   - Subject Name: "Mathematics"
   - Subject Code: "MATH7"
   - Assign Teacher: Select a teacher
   - Click: "Save"
6. ✅ **Upload Module/File:**
   - Click on the subject
   - Click: "Upload File"
   - Select a file
   - Verify: File appears in preview with "PREVIEW" badge
7. ✅ **Verify Preview Mode:**
   - Check: "PREVIEW" badges appear on subjects
   - Check: Main content shows preview
8. ✅ **Click:** "Create" button
9. ✅ **Verify:**
   - Classroom appears in left sidebar
   - Sorted by grade level
   - Mode switches to "Edit"

**Expected Result:**
- ✅ Classroom created successfully
- ✅ Appears in grade level tree (left sidebar)
- ✅ Preview mode works correctly
- ✅ Files uploaded to temporary storage
- ✅ Mode switches to edit after creation

**What to Inspect:**
- Does the create flow work smoothly?
- Are preview badges visible?
- Does the classroom appear in the sidebar?
- Is it sorted correctly?

---

### Test 4.2: Edit Classroom Flow
**Purpose:** Test editing existing classroom

**Steps:**
1. ✅ **Login as Admin**
2. ✅ **Navigate to:** Classrooms
3. ✅ **Click on existing classroom** in left sidebar
4. ✅ **Verify:** Main content shows classroom details (VIEW mode)
5. ✅ **Click:** "Edit" button
6. ✅ **Verify:** Mode switches to EDIT
7. ✅ **Modify:**
   - Change title
   - Add new subject
   - Upload new file
8. ✅ **Click:** "Save Changes"
9. ✅ **Verify:** Changes saved successfully

**Expected Result:**
- ✅ Edit mode detected correctly
- ✅ Changes saved to database
- ✅ No "PREVIEW" badges (already created)
- ✅ Classroom remains in correct position

**What to Inspect:**
- Does edit mode work?
- Are changes saved?
- Are there no preview badges in edit mode?

---

### Test 4.3: Student Enrollment
**Purpose:** Test adding students to classroom

**Steps:**
1. ✅ **Login as Admin**
2. ✅ **Navigate to:** Classrooms
3. ✅ **Select a classroom**
4. ✅ **Click:** "Manage Students" button
5. ✅ **Verify:** Dialog opens with two tabs (Enrolled Students / Add Students)
6. ✅ **Click:** "Add Students" tab
7. ✅ **Search for student:**
   - Type student name in search bar
   - Verify: Search works (by name, LRN, or email)
8. ✅ **Click:** "Add Student" button
9. ✅ **Verify:**
   - Student appears in "Enrolled Students" tab
   - Student count updates
10. ✅ **Test Student Limiter:**
    - Try adding more students than max_students
    - Verify: Error message appears

**Expected Result:**
- ✅ Student enrollment dialog works
- ✅ Search functionality works (name, LRN, email)
- ✅ Students added successfully
- ✅ Student count updates
- ✅ Student limiter enforced

**What to Inspect:**
- Does the enrollment dialog open?
- Does search work correctly?
- Are students added successfully?
- Is the student limiter enforced?

---

### Test 4.4: Grade Level Sorting
**Purpose:** Verify classrooms sorted by grade level in sidebar

**Steps:**
1. ✅ **Login as Admin**
2. ✅ **Create multiple classrooms:**
   - Grade 12 classroom
   - Grade 7 classroom
   - Grade 10 classroom
3. ✅ **Verify:** Classrooms appear in order: 7, 10, 12

**Expected Result:**
- ✅ Classrooms sorted by grade level (7-12)
- ✅ Within same grade, sorted alphabetically

**What to Inspect:**
- Are classrooms sorted correctly?
- Is the order: 7, 8, 9, 10, 11, 12?

---

## 🔒 Phase 5: Protected Systems Verification

### Test 5.1: Grading Workspace - MUST BE UNTOUCHED
**Purpose:** Verify grading system was not modified

**Steps:**
1. ✅ **Login as Teacher**
2. ✅ **Navigate to:** Grades → Grade Entry
3. ✅ **Select a student and quarter**
4. ✅ **Test DepEd Grade Computation:**
   - Enter Written Work scores
   - Enter Performance Task scores
   - Enter Quarterly Assessment score
   - Click: "Compute Grade"
   - Verify: Grade computed correctly (WW 30%, PT 50%, QA 20%)
5. ✅ **Test Grade Entry UI:**
   - Verify: Quarter chips (Q1, Q2, Q3, Q4) work
   - Verify: Three tabs (Written Work, Performance Task, Quarterly Assessment)
   - Verify: "Compute" button works
6. ✅ **Test Grade Saving:**
   - Click: "Save Grade"
   - Verify: Grade saved successfully
7. ✅ **Test Transmutation:**
   - Verify: Raw score transmuted to 100-point scale
8. ✅ **Test Plus/Extra Points:**
   - Add bonus points
   - Verify: Bonus points applied correctly

**Expected Result:**
- ✅ **ALL FEATURES WORK EXACTLY AS BEFORE**
- ✅ DepEd formula intact (WW 30%, PT 50%, QA 20%)
- ✅ Grade entry UI unchanged
- ✅ Transmutation works
- ✅ Bonus points work

**What to Inspect:**
- Does grade computation work correctly?
- Are the percentages correct (30%, 50%, 20%)?
- Does the UI look the same as before?
- Can you save grades?

**⚠️ CRITICAL:** If ANYTHING is broken here, report immediately!

---

### Test 5.2: Attendance System - MUST BE UNTOUCHED
**Purpose:** Verify attendance system was not modified

**Steps:**
1. ✅ **Login as Teacher**
2. ✅ **Navigate to:** Attendance
3. ✅ **Test Attendance Marking:**
   - Select a classroom
   - Select a date
   - Mark students as Present/Absent/Late/Excused
   - Click: "Save Attendance"
   - Verify: Attendance saved successfully
4. ✅ **Test QR Code Scanning:**
   - Click: "Generate QR Code"
   - Verify: QR code appears
   - Test: Scan with student device (if available)
5. ✅ **Test Attendance Reports:**
   - View attendance summary
   - Verify: Statistics correct
6. ✅ **Test Quarter Selection:**
   - Switch between quarters
   - Verify: Attendance data loads correctly

**Expected Result:**
- ✅ **ALL FEATURES WORK EXACTLY AS BEFORE**
- ✅ Attendance marking works
- ✅ QR code generation works
- ✅ Reports work
- ✅ Quarter selection works

**What to Inspect:**
- Does attendance marking work?
- Can you save attendance?
- Does QR code generation work?
- Are reports accurate?

**⚠️ CRITICAL:** If ANYTHING is broken here, report immediately!

---

## 🔄 Phase 6: Backward Compatibility Testing

### Test 6.1: Old Classroom UI Still Works
**Purpose:** Verify old classroom UI is functional

**Steps:**
1. ✅ **Disable new UI:**
```dart
await FeatureFlagService.disableNewClassroomUI();
```
2. ✅ **Login as Teacher**
3. ✅ **Navigate to:** My Classroom
4. ✅ **Verify:** Old UI loads and works correctly
5. ✅ **Test all features:**
   - View classrooms
   - View subjects
   - View modules
   - View assignments

**Expected Result:**
- ✅ Old UI loads successfully
- ✅ All features work as before
- ✅ No errors or broken functionality

**What to Inspect:**
- Does old UI still work?
- Are all features functional?
- Any errors in console?

---

### Test 6.2: New Classroom UI Works
**Purpose:** Verify new classroom UI is functional

**Steps:**
1. ✅ **Enable new UI:**
```dart
await FeatureFlagService.enableNewClassroomUI();
```
2. ✅ **Login as Teacher**
3. ✅ **Navigate to:** My Classroom
4. ✅ **Verify:** New UI loads (three-panel layout)
5. ✅ **Test all features:**
   - Select classroom (left panel)
   - Select subject (middle panel)
   - View content (right panel)
   - Switch between tabs (Modules, Assignments)

**Expected Result:**
- ✅ New UI loads successfully
- ✅ Three-panel layout appears
- ✅ All features work correctly

**What to Inspect:**
- Does new UI load?
- Are there three panels?
- Do all features work?

---

### Test 6.3: Switch Between Old and New UI
**Purpose:** Verify seamless switching between UIs

**Steps:**
1. ✅ **Enable new UI** → Navigate to My Classroom → Verify new UI
2. ✅ **Disable new UI** → Navigate to My Classroom → Verify old UI
3. ✅ **Enable new UI** → Navigate to My Classroom → Verify new UI
4. ✅ **Repeat 3-5 times**

**Expected Result:**
- ✅ Switching works seamlessly
- ✅ No errors during switches
- ✅ Both UIs remain functional

**What to Inspect:**
- Does switching work smoothly?
- Any errors during switches?
- Do both UIs work after multiple switches?

---

## ✅ Testing Checklist

### Error Fixes
- [ ] Const constructor fix verified (subjects panel works)
- [ ] Method name fix verified (assignments load)
- [ ] Feature flag service works (imports without errors)

### Feature Flag System
- [ ] Enable new UI works
- [ ] Disable new UI works (rollback)
- [ ] Emergency rollback works
- [ ] Clear emergency rollback works
- [ ] Default state is old UI (backward compatible)

### Classroom Fetching
- [ ] Teacher sees owned classrooms
- [ ] Teacher sees advisory classrooms
- [ ] Teacher sees subject teacher classrooms
- [ ] Teacher sees co-teacher classrooms
- [ ] Deduplication works (no duplicates)
- [ ] Student sees enrolled classrooms only
- [ ] Student doesn't see non-enrolled classrooms
- [ ] Grade level sorting works

### Admin Classroom Management
- [ ] Create classroom flow works
- [ ] Edit classroom flow works
- [ ] Preview mode works (PREVIEW badges)
- [ ] Student enrollment works
- [ ] Search functionality works
- [ ] Student limiter enforced
- [ ] Grade level sorting in sidebar works

### Protected Systems (CRITICAL)
- [ ] ✅ Grading workspace UNTOUCHED and functional
- [ ] ✅ Attendance system UNTOUCHED and functional
- [ ] ✅ DepEd grade computation works (30%, 50%, 20%)
- [ ] ✅ Grade entry UI unchanged
- [ ] ✅ Attendance marking works
- [ ] ✅ QR code generation works

### Backward Compatibility
- [ ] Old classroom UI still works
- [ ] New classroom UI works
- [ ] Switching between UIs works seamlessly
- [ ] No breaking changes detected

---

## 🚨 What to Report

### If You Find Issues:

**Report Format:**
```
Issue: [Brief description]
File: [File path]
Steps to Reproduce:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Expected: [What should happen]
Actual: [What actually happened]

Screenshots: [If applicable]
Console Errors: [Copy from browser console]
```

### Critical Issues (Report Immediately):
- ❌ Grading workspace broken
- ❌ Attendance system broken
- ❌ Cannot save grades
- ❌ Cannot mark attendance
- ❌ DepEd formula incorrect

### Non-Critical Issues (Report After Testing):
- ⚠️ UI layout issues
- ⚠️ Minor bugs
- ⚠️ Performance issues
- ⚠️ Console warnings

---

## ✅ Expected Test Results

**If all tests pass:**
- ✅ 0 critical errors
- ✅ All features work as expected
- ✅ Protected systems untouched
- ✅ Backward compatibility maintained
- ✅ Feature flag system functional

**Time to complete:** ~30-45 minutes

**Good luck with testing! 🧪✨**

