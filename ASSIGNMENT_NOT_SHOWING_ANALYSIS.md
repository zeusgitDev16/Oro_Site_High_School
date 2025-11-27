# 🔍 ASSIGNMENT NOT SHOWING TO STUDENTS - ANALYSIS

**Date:** 2025-11-27  
**Issue:** Teacher created assignment "01 quiz-1" but students cannot see it  
**Status:** ✅ **ROOT CAUSE IDENTIFIED**

---

## 📊 **DATABASE EVIDENCE**

### **Assignment Exists in Database** ✅
```sql
SELECT id, title, is_published, is_active, teacher_id, classroom_id, subject_id
FROM assignments
WHERE classroom_id = 'a675fef0-bc95-4d3e-8eab-d1614fa376d0';

Result:
- id: 41
- title: "01 quiz-1"
- is_published: FALSE ❌
- is_active: TRUE ✅
- teacher_id: bb9f4092-3b81-4227-8886-0706b5f027b6 (Manly Pajara)
- classroom_id: a675fef0-bc95-4d3e-8eab-d1614fa376d0 (Amanpulo)
- subject_id: df9ac7be-3757-48c3-9447-fafbeb761c83 (TLE)
- quarter_no: 1
- due_date: 2025-11-28 14:49:00+00
```

---

## 🔴 **ROOT CAUSE**

### **Assignment is in DRAFT Mode**

**The Problem:**
- Assignment was created with `is_published = FALSE`
- Students can only see assignments where `is_published = TRUE`
- Teacher needs to **manually publish** the assignment

**Student RLS Policy:**
```sql
CREATE POLICY "assignments_select_students_published"
  ON assignments FOR SELECT
  USING (
    is_admin() OR
    (
      is_published = true AND  -- ❌ This check fails!
      is_active = true AND
      EXISTS (
        SELECT 1 FROM classroom_students cs
        WHERE cs.classroom_id = assignments.classroom_id
        AND cs.student_id = auth.uid()
      )
    )
  );
```

**Why Students Can't See It:**
1. ✅ Student is enrolled in Amanpulo classroom
2. ✅ Assignment is active (`is_active = true`)
3. ❌ Assignment is NOT published (`is_published = false`)
4. ❌ RLS policy blocks access

---

## ✅ **THE SOLUTION**

### **Teacher Must Publish the Assignment**

**How to Publish:**
1. Teacher goes to their classroom (Amanpulo)
2. Clicks on "Assignments" tab
3. Finds the assignment "01 quiz-1"
4. Sees "draft" badge (orange)
5. Clicks the **"Publish" button** (eye icon)
6. Assignment status changes to "published" (green)
7. Students can now see it

**UI Location:**
- File: `lib/screens/teacher/classroom/my_classroom_screen.dart`
- Lines: 4060-4072 (Publish button)
- Lines: 4073-4085 (Unpublish button)

**Code:**
```dart
IconButton(
  tooltip: 'Publish',
  icon: const Icon(Icons.visibility_outlined, size: 18),
  color: Colors.green.shade700,
  onPressed: (a['is_published'] == true)
      ? null
      : () async {
          await _togglePublishAssignment(
            a['id'].toString(),
            true,
          );
        },
),
```

---

## 🎯 **VERIFICATION**

### **Test 1: Check Assignment Status**
```sql
SELECT id, title, is_published FROM assignments WHERE id = 41;
```
**Current Result:** `is_published = false` ❌  
**After Publishing:** `is_published = true` ✅

### **Test 2: Student Query**
```sql
-- This is what students see (with RLS policies)
SELECT * FROM assignments
WHERE classroom_id = 'a675fef0-bc95-4d3e-8eab-d1614fa376d0'
AND is_published = true
AND is_active = true;
```
**Current Result:** 0 assignments ❌  
**After Publishing:** 1 assignment ✅

---

## 📋 **DATA FLOW**

### **Current Flow (Assignment NOT Visible)**
```
Teacher creates assignment
  ↓
Assignment saved with is_published = FALSE
  ↓
Student queries assignments
  ↓
RLS Policy checks: is_published = true? NO ❌
  ↓
Assignment BLOCKED by RLS
  ↓
Student sees: "No assignments" ❌
```

### **After Publishing (Assignment Visible)**
```
Teacher clicks "Publish" button
  ↓
Assignment updated: is_published = TRUE
  ↓
Student queries assignments
  ↓
RLS Policy checks: is_published = true? YES ✅
  ↓
Assignment ALLOWED by RLS
  ↓
Student sees: "01 quiz-1" ✅
```

---

## 🚀 **INSTRUCTIONS FOR TEACHER**

### **Step 1: Go to Classroom**
1. Log in as teacher (Manly Pajara)
2. Go to "My Classrooms"
3. Click on "Amanpulo" classroom

### **Step 2: Find the Assignment**
1. Click on "Assignments" tab
2. You should see "01 quiz-1" with an **orange "draft" badge**

### **Step 3: Publish the Assignment**
1. Find the assignment card
2. Look for the **eye icon** button (Publish)
3. Click the **"Publish" button**
4. You should see a green snackbar: "Assignment published"
5. The badge should change from **orange "draft"** to **green "published"**

### **Step 4: Verify Students Can See It**
1. Log in as a student enrolled in Amanpulo
2. Go to "Assignments" or "Amanpulo Classroom"
3. You should now see "01 quiz-1" in the assignments list

---

## 🎉 **SUMMARY**

### **This is NOT a Bug** ✅
- The system is working as designed
- Assignments are created in **DRAFT mode** by default
- Teachers must **manually publish** assignments to make them visible to students
- This allows teachers to:
  - Create assignments in advance
  - Review and edit before publishing
  - Control when students can see assignments

### **Why This Design?**
1. ✅ **Quality Control** - Teachers can review before publishing
2. ✅ **Scheduling** - Teachers can prepare assignments ahead of time
3. ✅ **Flexibility** - Teachers can unpublish if needed
4. ✅ **Safety** - Prevents accidental early release

### **What Teacher Needs to Do:**
1. Click the **"Publish" button** (eye icon) on the assignment
2. That's it! Students will immediately see the assignment

**No code changes needed - this is expected behavior!** ✅

---

## 📝 **OPTIONAL IMPROVEMENT**

If you want assignments to be **automatically published** when created, you can:

### **Option 1: Change Default in Create Assignment Screen**
Update `lib/screens/teacher/assignments/create_assignment_screen_new.dart`:
```dart
// Line 2675: Change isPublished default
subjectId: widget.subjectId,
isPublished: true,  // ✅ Auto-publish new assignments
```

### **Option 2: Add Confirmation Dialog**
Add a dialog asking "Publish now?" after creating assignment.

### **Option 3: Add UI Hint**
Add a banner in teacher view: "Remember to publish assignments so students can see them!"

**Recommendation:** Keep current behavior (manual publish) for better control.

