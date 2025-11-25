# Classroom Left Sidebar - Reusable Widget Usage Guide

## Overview

The `ClassroomLeftSidebarStateful` widget is a reusable left sidebar component for classroom management that can be used across **Admin**, **Teacher**, and **Student** screens. It implements **RLS (Row Level Security) policy filtering** through permissions, avoiding code duplication.

## Features

- ✅ **Grade Level Navigation** (Grades 7-12)
- ✅ **Classroom List** (expandable per grade)
- ✅ **Grade Coordinator Management** (permission-based)
- ✅ **School Year Selection** (with real-time search)
- ✅ **School Year Management** (add new years, permission-based)
- ✅ **Responsive Design** (small, minimalist, aesthetic)
- ✅ **RLS-Ready** (permissions control visibility)

## Quick Start

### 1. Import the Widget

```dart
import 'package:oro_site_high_school/widgets/classroom/classroom_left_sidebar_stateful.dart';
```

### 2. Replace Your Existing Sidebar

**Before:**
```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Row(
      children: [
        _buildSidebar(),  // ❌ Old custom sidebar
        Expanded(child: _buildMainContent()),
        _buildRightSidebar(),
      ],
    ),
  );
}
```

**After:**
```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Row(
      children: [
        ClassroomLeftSidebarStateful(  // ✅ New reusable sidebar
          title: 'CLASSROOM MANAGEMENT',
          onBackPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          ),
          expandedGrades: _expandedGrades,
          onGradeToggle: (grade) {
            setState(() {
              _expandedGrades[grade] = !(_expandedGrades[grade] ?? false);
            });
          },
          allClassrooms: _allClassrooms,
          selectedClassroom: _selectedClassroom,
          onClassroomSelected: (classroom) {
            setState(() {
              _selectedClassroom = classroom;
            });
          },
          gradeCoordinators: _gradeCoordinators,
          onSetGradeCoordinator: (grade) => _openGradeCoordinatorMenu(grade),
          schoolYears: _schoolYears,
          selectedSchoolYear: _selectedSchoolYear,
          onSchoolYearChanged: (year) async => await _handleSchoolYearChange(year),
          onAddSchoolYear: () => _showAddSchoolYearDialog(),
          canManageCoordinators: true,  // Admin: true, Others: false
          canManageSchoolYears: true,   // Admin: true, Others: false
        ),
        Expanded(child: _buildMainContent()),
        _buildRightSidebar(),
      ],
    ),
  );
}
```

### 3. Required State Variables

```dart
// Grade expansion state
Map<int, bool> _expandedGrades = {};

// Classrooms
List<Classroom> _allClassrooms = [];
Classroom? _selectedClassroom;

// Grade coordinators
Map<int, Teacher?> _gradeCoordinators = {};

// School years
List<SchoolYearSimple> _schoolYears = [];
String? _selectedSchoolYear;
```

### 4. School Year Change Handler

The sidebar calls `onSchoolYearChanged` when a year is selected. You should implement confirmation logic:

```dart
Future<void> _handleSchoolYearChange(String yearLabel) async {
  // Skip if already selected
  if (_selectedSchoolYear == yearLabel) return;

  // Show confirmation dialog
  final confirmed = await _showSchoolYearConfirmationDialog(yearLabel);

  if (confirmed == true) {
    setState(() => _selectedSchoolYear = yearLabel);
    await _saveSchoolYearPreference(yearLabel);
    await _loadClassroomsForSelectedYear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📅 School year changed to $yearLabel'),
          backgroundColor: Colors.green.shade500,
        ),
      );
    }
  }
}
```

## Permission-Based Features

### Admin Screen
```dart
canManageCoordinators: true,   // ✅ Shows "+" button to set coordinators
canManageSchoolYears: true,    // ✅ Shows "Add school year" button
```

### Teacher Screen
```dart
canManageCoordinators: false,  // ❌ Hides "+" button
canManageSchoolYears: false,   // ❌ Hides "Add school year" button
```

### Student Screen
```dart
canManageCoordinators: false,  // ❌ Hides "+" button
canManageSchoolYears: false,   // ❌ Hides "Add school year" button
```

## Benefits

1. **No Code Duplication** - Write once, use everywhere
2. **RLS Policy Filtering** - Permissions control visibility
3. **Consistent UI** - Same look and feel across all screens
4. **Easy Maintenance** - Update once, applies everywhere
5. **Type-Safe** - Full Dart type checking
6. **Flexible** - Callbacks allow custom behavior per screen

## Migration Checklist

- [ ] Import `ClassroomLeftSidebarStateful`
- [ ] Replace `_buildSidebar()` with `ClassroomLeftSidebarStateful`
- [ ] Implement `_handleSchoolYearChange()` method
- [ ] Set correct permissions (`canManageCoordinators`, `canManageSchoolYears`)
- [ ] Test grade expansion
- [ ] Test classroom selection
- [ ] Test school year selection
- [ ] Test grade coordinator assignment (if admin)
- [ ] Test add school year (if admin)
- [ ] Remove old sidebar code

## Design Principles

- **Small** - Font sizes are small (9-12px)
- **Minimalist** - Subtle colors, clean layout
- **Aesthetic** - Modern design with proper spacing

