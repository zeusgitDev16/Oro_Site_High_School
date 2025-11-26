# ⚡ Student Enrollment - Quick Test Script

**Purpose:** 5-minute verification that student enrollment system is working  
**Time Required:** 5 minutes  
**Prerequisites:** Admin account, 1 classroom, 2 student accounts

---

## 🎯 Quick Test (5 Minutes)

### Test 1: Admin Can Enroll Students (2 minutes)

**Steps:**
1. ✅ Login as Admin
2. ✅ Navigate to: Classrooms
3. ✅ Click: Any classroom in left sidebar
4. ✅ Verify: "Manage Students" button appears in Capacity section
5. ✅ Click: "Manage Students" button
6. ✅ Verify: Dialog opens with two tabs
7. ✅ Click: "Add Students" tab
8. ✅ Type: Student name in search bar
9. ✅ Click: Green "Add" button
10. ✅ Verify: Success message appears
11. ✅ Click: "Enrolled Students" tab
12. ✅ Verify: Student appears in list

**Expected Result:**
- ✅ Dialog opens correctly
- ✅ Search works
- ✅ Student added successfully
- ✅ Student count updated

**If Failed:**
- ❌ Check console for errors
- ❌ Verify `classroom_students` table exists
- ❌ Verify student account is active

---

### Test 2: Student Can Access Enrolled Classroom (2 minutes)

**Steps:**
1. ✅ Logout from Admin
2. ✅ Login as Student (enrolled in Test 1)
3. ✅ Navigate to: My Classroom
4. ✅ Verify: Left sidebar shows enrolled classroom
5. ✅ Click: The enrolled classroom
6. ✅ Verify: Middle panel loads subjects
7. ✅ Click: Any subject
8. ✅ Verify: Right panel shows 4 tabs (Modules, Assignments, Announcements, Members)

**Expected Result:**
- ✅ Student sees enrolled classroom
- ✅ Subjects load correctly
- ✅ Content tabs appear

**If Failed:**
- ❌ Check console for errors
- ❌ Verify `getStudentClassrooms()` is called
- ❌ Verify student_id matches enrolled record

---

### Test 3: Student Can View Modules and Assignments (1 minute)

**Steps:**
1. ✅ (Continue from Test 2)
2. ✅ Click: "Modules" tab
3. ✅ Verify: Modules list appears (or empty state)
4. ✅ Click: "Assignments" tab
5. ✅ Verify: Assignments list appears (or empty state)

**Expected Result:**
- ✅ Modules tab works
- ✅ Assignments tab works
- ✅ No errors in console

**If Failed:**
- ❌ Check if subject has modules/assignments
- ❌ Verify `SubjectContentTabs` widget is rendering
- ❌ Check console for API errors

---

## ✅ Pass/Fail Criteria

### ✅ PASS if:
- [x] Admin can open "Manage Students" dialog
- [x] Admin can search and add students
- [x] Student appears in "Enrolled Students" tab
- [x] Student can see enrolled classroom in "My Classroom"
- [x] Student can view subjects
- [x] Student can access modules and assignments tabs
- [x] No errors in console

### ❌ FAIL if:
- [ ] "Manage Students" button doesn't appear
- [ ] Dialog doesn't open
- [ ] Search doesn't work
- [ ] Student can't be added
- [ ] Student doesn't see enrolled classroom
- [ ] Subjects don't load
- [ ] Tabs don't appear
- [ ] Console shows errors

---

## 🔍 Verification Commands

### Check Database Records

**Verify student enrollment:**
```sql
SELECT 
  cs.id,
  cs.classroom_id,
  cs.student_id,
  cs.enrolled_at,
  c.title as classroom_title,
  s.first_name || ' ' || s.last_name as student_name
FROM classroom_students cs
JOIN classrooms c ON c.id = cs.classroom_id
JOIN students s ON s.id = cs.student_id
WHERE cs.classroom_id = 'YOUR_CLASSROOM_ID';
```

**Verify student count:**
```sql
SELECT 
  id,
  title,
  current_students,
  max_students,
  (SELECT COUNT(*) FROM classroom_students WHERE classroom_id = classrooms.id) as actual_count
FROM classrooms
WHERE id = 'YOUR_CLASSROOM_ID';
```

### Check Flutter Console

**Look for these log messages:**

**Admin Side:**
```
✅ Student added successfully
✅ Student count updated
```

**Student Side:**
```
📚 Fetching classrooms for student: [student_id]
✅ Found [N] classrooms for student
📖 Fetching subjects for classroom: [classroom_id]
✅ Found [N] subjects
```

---

## 🐛 Common Issues and Solutions

### Issue 1: "Manage Students" button doesn't appear

**Cause:** Classroom not in VIEW mode or `canEdit = false`

**Solution:**
1. Make sure classroom is selected (not in CREATE mode)
2. Verify `canEdit` prop is true in `ClassroomViewerWidget`

---

### Issue 2: Dialog opens but no students appear

**Cause:** No active students in database

**Solution:**
1. Create student accounts via Admin → Students
2. Ensure `is_active = true` for students
3. Verify students table has records

---

### Issue 3: Student added but doesn't appear in "Enrolled Students"

**Cause:** Dialog not refreshing after add

**Solution:**
1. Check console for errors
2. Verify `_loadEnrolledStudents()` is called after add
3. Check if `classroom_students` record was created

---

### Issue 4: Student can't see enrolled classroom

**Cause:** Feature flag disabled or wrong student_id

**Solution:**
1. Check if feature flag is enabled (optional)
2. Verify student_id matches auth.currentUser.id
3. Check if `classroom_students` record exists
4. Verify classroom `is_active = true`

---

### Issue 5: Subjects don't load

**Cause:** No subjects in classroom or API error

**Solution:**
1. Add subjects to classroom via Admin
2. Check console for API errors
3. Verify `classroom_subjects` table has records

---

## 📊 Test Report Template

```
STUDENT ENROLLMENT QUICK TEST REPORT
Date: _______________
Tester: _______________

Test 1: Admin Can Enroll Students
[ ] PASS  [ ] FAIL
Notes: _________________________________

Test 2: Student Can Access Enrolled Classroom
[ ] PASS  [ ] FAIL
Notes: _________________________________

Test 3: Student Can View Modules and Assignments
[ ] PASS  [ ] FAIL
Notes: _________________________________

Overall Result: [ ] PASS  [ ] FAIL

Issues Found:
_____________________________________________
_____________________________________________

Recommendations:
_____________________________________________
_____________________________________________
```

---

## 🎯 Summary

**Total Time:** 5 minutes  
**Total Tests:** 3  
**Pass Criteria:** All 3 tests pass with no console errors

**If all tests pass:**
✅ Student enrollment system is fully functional!

**If any test fails:**
❌ Review the "Common Issues and Solutions" section
❌ Check console logs for specific errors
❌ Verify database records

---

## 🚀 Next Steps After Testing

**If tests pass:**
1. ✅ Enable feature flag for new UI (optional)
2. ✅ Test with real users
3. ✅ Deploy to production

**If tests fail:**
1. ❌ Review error logs
2. ❌ Fix identified issues
3. ❌ Re-run tests
4. ❌ Report issues for investigation

---

**Ready to test? Let's go! 🎉**

