# ⚡ Quick Test Reference - Essential Tests Only

**Time Required:** ~10-15 minutes  
**Purpose:** Fast verification that nothing critical is broken

---

## 🚨 CRITICAL TESTS (Must Pass)

### 1. Build Verification (30 seconds)
```bash
flutter analyze
# Expected: 0 errors
```
✅ **PASS:** 0 errors  
❌ **FAIL:** Any errors appear

---

### 2. Grading Workspace (3 minutes)
**Login as Teacher → Grades → Grade Entry**

**Test:**
1. Select student and quarter
2. Enter scores: WW=80, PT=85, QA=90
3. Click "Compute Grade"
4. Verify: Grade = (80×0.30) + (85×0.50) + (90×0.20) = 84.5

✅ **PASS:** Grade computed correctly  
❌ **FAIL:** Wrong computation or errors

**⚠️ CRITICAL:** If this fails, STOP and report immediately!

---

### 3. Attendance System (2 minutes)
**Login as Teacher → Attendance**

**Test:**
1. Select classroom and date
2. Mark 3 students: Present, Absent, Late
3. Click "Save Attendance"
4. Verify: Saved successfully

✅ **PASS:** Attendance saved  
❌ **FAIL:** Errors or cannot save

**⚠️ CRITICAL:** If this fails, STOP and report immediately!

---

### 4. Feature Flag Service (2 minutes)
**Open Browser Console (F12)**

**Test:**
```dart
import 'package:oro_site_high_school/services/feature_flag_service.dart';

// Test 1: Check default state
final enabled = await FeatureFlagService.isNewClassroomUIEnabled();
print('Enabled: $enabled'); // Should be: false

// Test 2: Enable new UI
await FeatureFlagService.enableNewClassroomUI();
print('New UI enabled');

// Test 3: Disable new UI
await FeatureFlagService.disableNewClassroomUI();
print('New UI disabled');
```

✅ **PASS:** All commands work, no errors  
❌ **FAIL:** Import errors or exceptions

---

### 5. Classroom Fetching - Teacher (3 minutes)
**Setup (as Admin):**
1. Create classroom "Test Grade 7"
2. Assign Teacher A as advisory teacher
3. Add subject "Math" with Teacher A as subject teacher

**Test (as Teacher A):**
1. Login as Teacher A
2. Navigate to: My Classroom
3. Verify: "Test Grade 7" appears in list

✅ **PASS:** Classroom appears  
❌ **FAIL:** Classroom missing

---

### 6. Classroom Fetching - Student (2 minutes)
**Setup (as Admin):**
1. Use existing classroom
2. Enroll Student A

**Test (as Student A):**
1. Login as Student A
2. Navigate to: My Classroom
3. Verify: Enrolled classroom appears

✅ **PASS:** Classroom appears  
❌ **FAIL:** Classroom missing

---

### 7. Admin Classroom Creation (5 minutes)
**Login as Admin → Classrooms**

**Test:**
1. Click "Create Classroom"
2. Fill: Title="Test Class", Grade=7, Max Students=40
3. Add subject: "English"
4. Assign teacher to subject
5. Click "Create"
6. Verify: Classroom appears in left sidebar under Grade 7

✅ **PASS:** Classroom created and appears in sidebar  
❌ **FAIL:** Errors or classroom missing

---

## 📊 Quick Results Summary

| Test | Status | Time |
|------|--------|------|
| Build Verification | ⬜ | 30s |
| Grading Workspace | ⬜ | 3m |
| Attendance System | ⬜ | 2m |
| Feature Flag Service | ⬜ | 2m |
| Teacher Classroom Fetching | ⬜ | 3m |
| Student Classroom Fetching | ⬜ | 2m |
| Admin Classroom Creation | ⬜ | 5m |

**Total Time:** ~15 minutes

---

## 🎯 Pass/Fail Criteria

### ✅ ALL TESTS PASS
**Verdict:** Changes are safe, nothing broken  
**Action:** Proceed with full testing (optional)

### ❌ ANY CRITICAL TEST FAILS (Grading or Attendance)
**Verdict:** CRITICAL ISSUE - Protected systems affected  
**Action:** STOP immediately and report

### ⚠️ NON-CRITICAL TEST FAILS
**Verdict:** Minor issue in new features  
**Action:** Report issue, continue testing

---

## 🔍 What to Look For

### Good Signs ✅
- ✅ No console errors (F12)
- ✅ All features load smoothly
- ✅ Data saves successfully
- ✅ UI renders correctly
- ✅ No error dialogs

### Bad Signs ❌
- ❌ Red errors in console
- ❌ "Undefined method" errors
- ❌ "Cannot read property of null" errors
- ❌ Blank screens
- ❌ Infinite loading spinners
- ❌ Data not saving

---

## 🚨 Emergency Rollback

**If critical tests fail:**

```dart
// Open browser console (F12)
import 'package:oro_site_high_school/services/feature_flag_service.dart';

// Force all users to old UI
await FeatureFlagService.emergencyRollback();
print('Emergency rollback activated');
```

**Then report the issue immediately.**

---

## 📝 Quick Report Template

```
QUICK TEST RESULTS
==================

Build Verification: [PASS/FAIL]
Grading Workspace: [PASS/FAIL]
Attendance System: [PASS/FAIL]
Feature Flag Service: [PASS/FAIL]
Teacher Classroom Fetching: [PASS/FAIL]
Student Classroom Fetching: [PASS/FAIL]
Admin Classroom Creation: [PASS/FAIL]

Overall Status: [ALL PASS / ISSUES FOUND]

Issues Found:
1. [Issue description]
2. [Issue description]

Console Errors:
[Copy any errors from browser console]

Notes:
[Any additional observations]
```

---

## 🎯 Next Steps

### If All Tests Pass ✅
1. ✅ Mark as production-ready
2. ✅ Optional: Run full testing guide (30-45 min)
3. ✅ Optional: Enable new UI for testing

### If Tests Fail ❌
1. ❌ Document the failure
2. ❌ Copy console errors
3. ❌ Report immediately
4. ❌ Do NOT proceed to production

---

**Good luck! This should take ~15 minutes. 🚀**

