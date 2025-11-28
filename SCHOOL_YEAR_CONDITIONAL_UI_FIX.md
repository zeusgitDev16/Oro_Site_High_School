# 🔧 SCHOOL YEAR CONDITIONAL UI SWITCH

**Feature:** Role-based school year display in classroom left sidebar
**Status:** ✅ IMPLEMENTED
**Date:** 2025-11-27

---

## 🎯 **OBJECTIVE**

Implement a conditional UI switch for the school year selector in the reusable classroom left sidebar:
- **Admin/ICT Coordinator/Hybrid**: Full dropdown with ability to select and manage school years
- **All other roles** (Teacher, Student, Parent, Grade Coordinator): Read-only display of current school year set by admin

---

## 🐛 **PROBLEM DESCRIPTION**

### **User Request (verbatim):**
> "in the left sidebar school year, this is from the admin right? can you create a conditional UI switch that when distributed/ reused in a non admin user role, meaning all roles will get this except admins, ict coordinator and hybrid. implement a simple conditional UI switch that it displays the current year that the admin set it to. this is in the classroom and on the reusable left sidebar. please proceed precisely."

### **Current Behavior:**
- School year selector shows dropdown for all users
- Non-admin users can see and potentially interact with school year selection
- Inconsistent UX across different user roles

### **Desired Behavior:**
- **Admin/ICT Coordinator/Hybrid**: Full dropdown with "Add school year" button
- **Teacher/Student/Parent/Grade Coordinator**: Read-only display showing current school year
- Current school year is fetched from database (`school_years` table where `is_current = true`)

---

## ✅ **SOLUTION IMPLEMENTED**

### **1. Added Admin Permission Check**

**File:** `lib/widgets/classroom/classroom_left_sidebar_stateful.dart`

**Added getter method:**
```dart
/// Check if current user has admin-like permissions (can manage school years)
/// Includes: admin, ict_coordinator, hybrid, null (backward compatible for admin screens)
/// Excludes: teacher, student, parent, grade_coordinator
bool get _hasAdminPermissions {
  final role = widget.userRole?.toLowerCase();
  // If userRole is null, assume admin (backward compatible)
  if (role == null) return true;
  return role == 'admin' || role == 'ict_coordinator' || role == 'hybrid';
}
```

**Lines:** 141-149

---

### **2. Implemented Conditional UI in School Year Selector**

**File:** `lib/widgets/classroom/classroom_left_sidebar_stateful.dart`

**Modified `_buildSchoolYearSelector()` method:**

**ADMIN VIEW (lines 658-728):**
```dart
if (_hasAdminPermissions) ...[
  // ADMIN VIEW: Full dropdown with add button
  // Add School Year Button
  if (widget.canManageSchoolYears && widget.onAddSchoolYear != null)
    InkWell(
      onTap: widget.onAddSchoolYear,
      child: Container(
        // ... "Add school year" button UI
      ),
    ),

  // School Year Dropdown (clickable)
  InkWell(
    key: _schoolYearButtonKey,
    onTap: _openSchoolYearMenu,
    child: Container(
      // ... Dropdown with arrow icon
      child: Row(
        children: [
          Text(widget.selectedSchoolYear ?? 'Select school year'),
          Icon(Icons.arrow_drop_down),
        ],
      ),
    ),
  ),
]
```

**NON-ADMIN VIEW (lines 729-769):**
```dart
else ...[
  // NON-ADMIN VIEW: Read-only display of current school year
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.purple.shade300, width: 1),
    ),
    child: Row(
      children: [
        Icon(
          Icons.lock_outline,  // ✅ Lock icon indicates read-only
          size: 12,
          color: Colors.purple.shade400,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.selectedSchoolYear ?? 'No school year set',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.selectedSchoolYear != null
                  ? Colors.purple.shade900
                  : Colors.purple.shade400,
            ),
          ),
        ),
      ],
    ),
  ),
],
```

---

### **3. Updated Teacher Screens to Fetch Current School Year**

#### **A. Teacher Classroom Screen V2**

**File:** `lib/screens/teacher/classroom/my_classroom_screen_v2.dart`

**Changes:**
1. Added import: `import 'package:oro_site_high_school/services/school_year_service.dart';`
2. Added service: `final SchoolYearService _schoolYearService = SchoolYearService();`
3. Added state variable: `String? _currentSchoolYear;`
4. Added method to load current school year:
```dart
/// Load current school year set by admin
Future<void> _loadCurrentSchoolYear() async {
  try {
    final currentYear = await _schoolYearService.getCurrentSchoolYear();
    setState(() {
      _currentSchoolYear = currentYear?.yearLabel;
    });
    print('✅ Current school year: $_currentSchoolYear');
  } catch (e) {
    print('❌ Error loading current school year: $e');
  }
}
```
5. Updated `_initializeTeacher()` to call `_loadCurrentSchoolYear()`
6. Updated sidebar widget to pass `selectedSchoolYear: _currentSchoolYear`

**Lines modified:** 1-12, 34-58, 66-100, 264-286

---

#### **B. Gradebook Screen**

**File:** `lib/screens/teacher/grades/gradebook_screen.dart`

**Changes:**
1. Added import: `import 'package:oro_site_high_school/services/school_year_service.dart';`
2. Added service: `final SchoolYearService _schoolYearService = SchoolYearService();`
3. Added state variable: `String? _currentSchoolYear;`
4. Added method to load current school year (same as above)
5. Updated `_initializeTeacher()` to call `_loadCurrentSchoolYear()`
6. Updated sidebar widget to pass `selectedSchoolYear: _currentSchoolYear`

**Lines modified:** 1-11, 28-51, 65-97, 196-210

---

## 🧪 **TESTING SCENARIOS**

### **Scenario 1: Admin User**
1. Login as admin
2. Navigate to Classroom Management
3. **Expected:** School year selector shows dropdown with "Add school year" button
4. **Expected:** Can click dropdown to select different school years
5. **Expected:** Can click "Add school year" to create new school year

### **Scenario 2: Teacher User**
1. Login as teacher (e.g., Manly Pajara)
2. Navigate to My Classrooms or Gradebook
3. **Expected:** School year selector shows read-only display with lock icon
4. **Expected:** Displays current school year (e.g., "2024-2025")
5. **Expected:** Cannot click to change school year

### **Scenario 3: Student User**
1. Login as student
2. Navigate to My Classrooms
3. **Expected:** School year selector shows read-only display with lock icon
4. **Expected:** Displays current school year
5. **Expected:** Cannot interact with school year selector

### **Scenario 4: ICT Coordinator User**
1. Login as ICT coordinator
2. Navigate to Classroom Management
3. **Expected:** School year selector shows full dropdown (same as admin)
4. **Expected:** Can manage school years

### **Scenario 5: Hybrid User**
1. Login as hybrid user (admin who also teaches)
2. Navigate to any classroom screen
3. **Expected:** School year selector shows full dropdown (same as admin)
4. **Expected:** Can manage school years

---

## 📊 **IMPACT ANALYSIS**

### **Backward Compatibility:** ✅ MAINTAINED
- Admin screens that don't pass `userRole` parameter default to admin view (null = admin)
- Existing functionality preserved for all user types
- No breaking changes to API or widget interface

### **Performance:** ✅ MINIMAL IMPACT
- One additional database query per screen load to fetch current school year
- Query is cached by SchoolYearService
- Negligible performance overhead

### **User Experience:** ✅ GREATLY IMPROVED
- Clear visual distinction between admin and non-admin users
- Lock icon indicates read-only status
- Prevents confusion and accidental interactions
- Consistent UX across all screens

---

## 🔄 **ROLE MAPPING**

| Role | Permission Level | School Year UI | Can Manage |
|------|-----------------|----------------|------------|
| **admin** | Full | Dropdown | ✅ Yes |
| **ict_coordinator** | Full | Dropdown | ✅ Yes |
| **hybrid** | Full | Dropdown | ✅ Yes |
| **teacher** | Limited | Read-only | ❌ No |
| **student** | Limited | Read-only | ❌ No |
| **parent** | Limited | Read-only | ❌ No |
| **grade_coordinator** | Limited | Read-only | ❌ No |

---

## 📝 **FILES MODIFIED**

1. **`lib/widgets/classroom/classroom_left_sidebar_stateful.dart`**
   - Added `_hasAdminPermissions` getter
   - Modified `_buildSchoolYearSelector()` with conditional UI
   - Lines: 141-149, 624-769

2. **`lib/screens/teacher/classroom/my_classroom_screen_v2.dart`**
   - Added SchoolYearService import and instance
   - Added `_currentSchoolYear` state variable
   - Added `_loadCurrentSchoolYear()` method
   - Updated sidebar to pass current school year
   - Lines: 1-12, 34-58, 66-100, 264-286

3. **`lib/screens/teacher/grades/gradebook_screen.dart`**
   - Added SchoolYearService import and instance
   - Added `_currentSchoolYear` state variable
   - Added `_loadCurrentSchoolYear()` method
   - Updated sidebar to pass current school year
   - Lines: 1-11, 28-51, 65-97, 196-210

---

## 🎉 **SUMMARY**

**Status:** ✅ **IMPLEMENTED**

**Key Features:**
1. ✅ Conditional UI based on user role
2. ✅ Admin/ICT Coordinator/Hybrid see full dropdown
3. ✅ Teacher/Student/Parent/Grade Coordinator see read-only display
4. ✅ Current school year fetched from database
5. ✅ Lock icon indicates read-only status
6. ✅ Backward compatible with existing code
7. ✅ Minimal performance impact

**User Experience:**
- Clear visual distinction between admin and non-admin users
- Prevents confusion and accidental interactions
- Consistent UX across all screens
- Professional and polished UI

---

**Implementation Complete!** ✅

