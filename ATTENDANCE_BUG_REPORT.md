# 🐛 ATTENDANCE SYSTEM BUG REPORT

**Date:** 2025-11-27  
**Status:** 🔍 **BUG HUNT COMPLETE**  
**Total Bugs Found:** 8 (3 Critical, 3 High, 2 Medium)

---

## 🚨 **CRITICAL BUGS (MUST FIX)**

### **BUG #1: RLS Policies Don't Support New Fields** 🔴 **CRITICAL**

**Severity:** 🔴 **CRITICAL** - Teachers cannot save attendance for new classrooms!

**Location:** Database RLS policies on `attendance` table

**Problem:**
All RLS policies only check `course_id`, but new system uses `subject_id` and `classroom_id`:

```sql
-- Current policies check ONLY course_id
attendance_teachers_insert_by_course: 
  WHERE c.id = attendance.course_id AND c.teacher_id = auth.uid()

attendance_teachers_delete_by_course:
  WHERE c.id = attendance.course_id AND c.teacher_id = auth.uid()

attendance_teachers_update_by_course:
  WHERE c.id = attendance.course_id AND c.teacher_id = auth.uid()
```

**Impact:**
- ❌ Teachers CANNOT insert attendance for new classrooms (no course_id)
- ❌ Teachers CANNOT delete attendance for new classrooms
- ❌ Teachers CANNOT update attendance for new classrooms
- ❌ Save button will fail silently or throw permission error

**Example:**
```dart
// Teacher tries to save attendance for Amanpulo (new classroom)
await supabase.from('attendance').insert({
  'classroom_id': 'uuid-123',
  'subject_id': 'uuid-456',
  'course_id': null,  // No course_id!
  ...
});
// ❌ FAILS: RLS policy checks course_id which is NULL
```

**Fix Required:**
Update RLS policies to check BOTH `course_id` (old) AND `classroom_id` + `subject_id` (new)

---

### **BUG #2: Missing Classroom Teacher Check** 🔴 **CRITICAL**

**Severity:** 🔴 **CRITICAL** - Wrong teachers can access attendance

**Location:** RLS policies

**Problem:**
No RLS policy checks if teacher owns the classroom via `classrooms.teacher_id`

**Current Logic:**
- ✅ Checks if teacher owns course (`courses.teacher_id`)
- ✅ Checks if teacher is in `classroom_teachers` table
- ❌ Does NOT check if teacher is classroom owner (`classrooms.teacher_id`)

**Impact:**
- ❌ Advisory teachers (classroom owners) may not have access
- ❌ Only works if teacher is in `classroom_teachers` junction table

**Fix Required:**
Add check for `classrooms.teacher_id = auth.uid()`

---

### **BUG #3: Student Can't View Own Attendance (New System)** 🔴 **CRITICAL**

**Severity:** 🔴 **CRITICAL** - Students see empty attendance

**Location:** RLS policy `attendance_select_own_or_admin`

**Problem:**
```sql
-- Current policy
(student_id = auth.uid()) OR is_admin()
```

This works, BUT the widget filters by `subject_id` which may not match if:
1. Student loads attendance for subject
2. Query filters by `subject_id`
3. RLS policy allows (student_id matches)
4. BUT query returns 0 rows if subject_id doesn't match old data

**Impact:**
- ❌ Students may see empty attendance even if records exist
- ❌ Happens when migrating from old to new system

**Fix Required:**
Ensure query logic handles NULL subject_id in old records

---

## ⚠️ **HIGH PRIORITY BUGS**

### **BUG #4: Widget Doesn't Reload on Classroom Change** ⚠️ **HIGH**

**Severity:** ⚠️ **HIGH** - Stale data shown

**Location:** `lib/widgets/attendance/attendance_tab_widget.dart` (Line 79-85)

**Problem:**
```dart
@override
void didUpdateWidget(AttendanceTabWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  // Reload if subject changes
  if (oldWidget.subject.id != widget.subject.id) {
    _loadStudents();
  }
}
```

Only checks if `subject.id` changes, but NOT if `classroomId` changes!

**Impact:**
- ❌ If user switches classrooms but same subject name, widget shows old data
- ❌ Attendance from previous classroom displayed incorrectly

**Example:**
1. User views Amanpulo → Filipino → Attendance
2. User switches to Sampaguita → Filipino → Attendance
3. Widget still shows Amanpulo students (wrong!)

**Fix Required:**
```dart
if (oldWidget.subject.id != widget.subject.id || 
    oldWidget.classroomId != widget.classroomId) {
  _loadStudents();
  _loadMarkedDates();
}
```

---

### **BUG #5: No Validation for Empty Attendance Status** ⚠️ **HIGH**

**Severity:** ⚠️ **HIGH** - Can save without marking anyone

**Location:** `lib/widgets/attendance/attendance_tab_widget.dart` (Line 295-303)

**Problem:**
```dart
if (_attendanceStatus.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please mark attendance for at least one student'),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

This prevents saving if NO students are marked, but what if:
- Teacher loads attendance for date with existing records
- Teacher doesn't change anything
- Teacher clicks "Save"
- `_attendanceStatus` is populated from loaded data
- Save proceeds even though teacher didn't mark anyone

**Impact:**
- ⚠️ Confusing UX - save button enabled even when no changes made
- ⚠️ Unnecessary database writes

**Fix Required:**
Track if any changes were made before enabling save

---

### **BUG #6: Marked Dates Not Reloaded on Quarter Change** ⚠️ **HIGH**

**Severity:** ⚠️ **HIGH** - Calendar shows wrong marked dates

**Location:** `lib/widgets/attendance/attendance_tab_widget.dart` (Line 180-188)

**Problem:**
```dart
void _onQuarterChanged(int quarter) {
  setState(() {
    _selectedQuarter = quarter;
    _attendanceStatus.clear();
  });
  // Reload attendance for new quarter
  _loadAttendanceForSelectedDate();
  _loadMarkedDates();  // ✅ This is called
}
```

Actually, this looks correct! But let me verify the `_loadMarkedDates()` implementation...

**Status:** ✅ **FALSE ALARM** - This is actually implemented correctly

---

## 📋 **MEDIUM PRIORITY BUGS**

### **BUG #7: No Loading State for Marked Dates** 📋 **MEDIUM**

**Severity:** 📋 **MEDIUM** - Minor UX issue

**Location:** `lib/widgets/attendance/attendance_tab_widget.dart`

**Problem:**
No loading indicator when fetching marked dates for calendar

**Impact:**
- ⚠️ Calendar may show stale marked dates briefly
- ⚠️ No visual feedback during loading

**Fix Required:**
Add `_isLoadingMarkedDates` state variable

---

### **BUG #8: Potential Null Safety Issue in Student ID** 📋 **MEDIUM**

**Severity:** 📋 **MEDIUM** - Edge case

**Location:** `lib/widgets/attendance/attendance_tab_widget.dart` (Line 208)

**Problem:**
```dart
final studentIds = _students.map((s) => s['id']).toList();
```

If `s['id']` is null, this will include null in the list

**Impact:**
- ⚠️ Query may fail if null IDs passed to `inFilter()`
- ⚠️ Rare edge case (students should always have IDs)

**Fix Required:**
```dart
final studentIds = _students
    .map((s) => s['id'])
    .whereType<String>()
    .toList();
```

---

## 📊 **BUG SUMMARY**

| Severity | Count | Bugs |
|----------|-------|------|
| 🔴 **CRITICAL** | 3 | #1, #2, #3 |
| ⚠️ **HIGH** | 2 | #4, #5 |
| 📋 **MEDIUM** | 2 | #7, #8 |
| ✅ **FALSE ALARM** | 1 | #6 |

---

## 🎯 **FIX PRIORITY**

### **Phase 1: Critical Fixes (MUST DO NOW)**
1. ✅ Fix RLS policies to support `classroom_id` + `subject_id`
2. ✅ Add classroom teacher check to RLS policies
3. ✅ Fix student attendance visibility

### **Phase 2: High Priority Fixes (DO NEXT)**
4. ✅ Fix widget reload on classroom change
5. ✅ Add change tracking for save button

### **Phase 3: Medium Priority Fixes (NICE TO HAVE)**
7. ✅ Add loading state for marked dates
8. ✅ Add null safety for student IDs

---

## 🚀 **NEXT STEPS**

1. ⏳ Review bug report with team
2. ⏳ Approve fixes
3. ⏳ Implement Phase 1 (Critical) fixes
4. ⏳ Test thoroughly
5. ⏳ Implement Phase 2 & 3 fixes

**Status:** ✅ **BUG REPORT COMPLETE - READY FOR FIXES**

