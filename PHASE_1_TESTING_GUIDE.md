# 🧪 PHASE 1 TESTING GUIDE - Left Sidebar Role-Based Filtering

**Phase:** 1 of 6  
**Feature:** Student-only view of enrolled classrooms in left sidebar  
**Estimated Time:** 15-20 minutes

---

## 🎯 **WHAT TO TEST**

Phase 1 implements role-based filtering in the left sidebar:
- **Students** see only enrolled grade levels and classrooms
- **Admin/Teacher** see all grade levels and classrooms (unchanged)

---

## 📋 **PRE-REQUISITES**

### **Required Test Data:**
1. ✅ At least one student account
2. ✅ At least one admin account
3. ✅ At least 2-3 classrooms in different grade levels
4. ✅ Student enrolled in 1-2 classrooms (not all)

### **Setup Steps:**
1. Login as **Admin**
2. Navigate to **Classrooms** screen
3. Create classrooms in different grades (e.g., Grade 7, Grade 8, Grade 10)
4. Enroll a student in **only some** classrooms (e.g., Grade 7 and Grade 8)
5. Leave some classrooms without the student (e.g., Grade 10)

---

## 🧪 **TEST SEQUENCE**

### **TEST 1: Student View - Enrolled Classrooms Only** ⭐

**Objective:** Verify students only see enrolled grade levels and classrooms

**Steps:**
1. Login as **Student** (the one you enrolled)
2. Navigate to **My Classroom** from dashboard
3. Observe the left sidebar

**Expected Results:**
- ✅ Only enrolled grade levels appear (e.g., Grade 7, Grade 8)
- ✅ Only enrolled classrooms appear under each grade
- ✅ Non-enrolled grades are hidden (e.g., Grade 10)
- ✅ Other classrooms in same grade are hidden
- ✅ Section headers only show if grades exist
- ✅ Sidebar title shows "MY CLASSROOMS"

**Example:**
```
✅ CORRECT VIEW:
┌─────────────────────────┐
│ MY CLASSROOMS           │
├─────────────────────────┤
│ JUNIOR HIGH SCHOOL      │
│ Grade 7 ▼               │
│   └─ Section A          │  ← Enrolled
│ Grade 8 ▼               │
│   └─ Section B          │  ← Enrolled
└─────────────────────────┘

❌ SHOULD NOT SEE:
- Grade 9, 10, 11, 12
- Other sections in Grade 7/8
```

**Pass Criteria:**
- [ ] Only enrolled grades visible
- [ ] Only enrolled classrooms visible
- [ ] No other grades or classrooms shown

---

### **TEST 2: Admin View - All Classrooms** ⭐

**Objective:** Verify admin sees all classrooms (backward compatibility)

**Steps:**
1. Logout from student account
2. Login as **Admin**
3. Navigate to **Classrooms** screen
4. Observe the left sidebar

**Expected Results:**
- ✅ All grade levels appear (7, 8, 9, 10, 11, 12)
- ✅ All classrooms appear under each grade
- ✅ No filtering is applied
- ✅ Sidebar title shows "CLASSROOM MANAGEMENT"
- ✅ Grade coordinator buttons visible
- ✅ School year selector visible

**Example:**
```
✅ CORRECT VIEW:
┌─────────────────────────┐
│ CLASSROOM MANAGEMENT    │
├─────────────────────────┤
│ JUNIOR HIGH SCHOOL      │
│ Grade 7 ▼               │
│   ├─ Section A          │
│   ├─ Section B          │
│   └─ Section C          │
│ Grade 8 ▼               │
│   ├─ Section A          │
│   └─ Section B          │
│ Grade 9 ▼               │
│ Grade 10 ▼              │
│ SENIOR HIGH SCHOOL      │
│ Grade 11 ▼              │
│ Grade 12 ▼              │
└─────────────────────────┘
```

**Pass Criteria:**
- [ ] All grades visible (7-12)
- [ ] All classrooms visible
- [ ] Grade coordinator buttons work
- [ ] School year selector works

---

### **TEST 3: Teacher View - All Assigned Classrooms** ⭐

**Objective:** Verify teacher sees all assigned classrooms (backward compatibility)

**Steps:**
1. Logout from admin account
2. Login as **Teacher**
3. Navigate to **My Classroom** from dashboard
4. Observe the left sidebar

**Expected Results:**
- ✅ All assigned classrooms appear
- ✅ No filtering is applied
- ✅ Sidebar title shows "MY CLASSROOMS"
- ✅ Can select and view any assigned classroom

**Pass Criteria:**
- [ ] All assigned classrooms visible
- [ ] No filtering applied
- [ ] Can access all classrooms

---

### **TEST 4: Empty State - Student Not Enrolled** ⭐

**Objective:** Verify behavior when student has no enrollments

**Steps:**
1. Create a new student account (or unenroll existing student)
2. Login as that student
3. Navigate to **My Classroom**
4. Observe the left sidebar

**Expected Results:**
- ✅ No grade levels appear
- ✅ No classrooms appear
- ✅ Empty state message shows
- ✅ No errors or crashes

**Pass Criteria:**
- [ ] Graceful empty state
- [ ] No errors in console
- [ ] App doesn't crash

---

### **TEST 5: Grade Expansion - Student View** ⭐

**Objective:** Verify grade expansion works for students

**Steps:**
1. Login as student with enrollments
2. Navigate to **My Classroom**
3. Click on a grade level to expand/collapse
4. Observe behavior

**Expected Results:**
- ✅ Grade expands to show enrolled classrooms
- ✅ Grade collapses to hide classrooms
- ✅ Expansion state persists during session
- ✅ Only enrolled classrooms appear when expanded

**Pass Criteria:**
- [ ] Expansion/collapse works
- [ ] Only enrolled classrooms shown
- [ ] No errors

---

### **TEST 6: Classroom Selection - Student View** ⭐

**Objective:** Verify classroom selection works for students

**Steps:**
1. Login as student with enrollments
2. Navigate to **My Classroom**
3. Expand a grade level
4. Click on a classroom
5. Observe behavior

**Expected Results:**
- ✅ Classroom is selected (highlighted)
- ✅ Subjects panel loads for that classroom
- ✅ Main content area updates
- ✅ No errors

**Pass Criteria:**
- [ ] Classroom selection works
- [ ] UI updates correctly
- [ ] No errors

---

## 🐛 **COMMON ISSUES & SOLUTIONS**

### **Issue 1: Student sees all classrooms**
**Cause:** `userRole` not passed or incorrect  
**Solution:** Check `StudentClassroomScreenV2` passes `userRole: 'student'`

### **Issue 2: Admin sees filtered classrooms**
**Cause:** `userRole` incorrectly set to 'student'  
**Solution:** Verify admin screen doesn't pass `userRole` (should be `null`)

### **Issue 3: No grades appear for student**
**Cause:** Student not enrolled in any classrooms  
**Solution:** Enroll student in at least one classroom via admin panel

### **Issue 4: Section headers show but no grades**
**Cause:** Logic error in conditional rendering  
**Solution:** Check `_visibleGrades.any((g) => g >= 7 && g <= 10)` condition

---

## ✅ **FINAL VERIFICATION**

After completing all tests, verify:

- [ ] ✅ Students see only enrolled classrooms
- [ ] ✅ Admin sees all classrooms
- [ ] ✅ Teacher sees all assigned classrooms
- [ ] ✅ No errors in console
- [ ] ✅ No crashes or freezes
- [ ] ✅ Backward compatibility maintained
- [ ] ✅ Build passes with 0 errors

---

## 📊 **TEST RESULTS TEMPLATE**

```
PHASE 1 TEST RESULTS
Date: ___________
Tester: ___________

TEST 1 - Student View: [ PASS / FAIL ]
TEST 2 - Admin View: [ PASS / FAIL ]
TEST 3 - Teacher View: [ PASS / FAIL ]
TEST 4 - Empty State: [ PASS / FAIL ]
TEST 5 - Grade Expansion: [ PASS / FAIL ]
TEST 6 - Classroom Selection: [ PASS / FAIL ]

Overall Status: [ PASS / FAIL ]

Notes:
_________________________________
_________________________________
_________________________________
```

---

## 🚀 **NEXT STEPS**

If all tests pass:
- ✅ Phase 1 is complete and verified
- ✅ Ready to proceed to Phase 2: Classroom Details View

If any tests fail:
- ❌ Review implementation
- ❌ Fix issues
- ❌ Re-run tests

---

**Happy Testing! 🧪**

