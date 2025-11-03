# Backend Integration Summary for Enhanced Add User Screen

## Current Status

### ✅ **What's Already Done:**
1. **ProfileService Extended** - Added comprehensive parameters to `createUser()` method
2. **Role-Specific Logic** - Service handles Student, Teacher, Coordinator, Admin, and Hybrid roles
3. **Parent Linking** - Service calls `_createParentLink()` for students
4. **Teacher Records** - Service calls `_createTeacherRecord()` for teachers/coordinators
5. **Activity Logging** - All user creation is logged

### ❌ **What's Missing:**
The helper methods `_createTeacherRecord()` and `_createParentLink()` are **called but not defined** in ProfileService.

---

## Required Fix: Add Missing Methods to ProfileService

Add these two methods to `lib/services/profile_service.dart` **before the HELPER METHODS section**:

```dart
  // ============================================
  // TEACHER-SPECIFIC OPERATIONS
  // ============================================

  /// Create teacher record with optional SHS specialization
  Future<void> _createTeacherRecord({
    required String userId,
    required String employeeId,
    required String fullName,
    required String department,
    required List<String> subjects,
    required bool isGradeCoordinator,
    String? coordinatorGradeLevel,
    required bool isSHSTeacher,
    String? shsTrack,
    List<String>? shsStrands,
  }) async {
    try {
      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';

      await _supabase.from('teachers').insert({
        'id': userId,
        'employee_id': employeeId,
        'first_name': firstName,
        'last_name': lastName,
        'department': department,
        'subjects': subjects,
        'is_grade_coordinator': isGradeCoordinator,
        'coordinator_grade_level': coordinatorGradeLevel,
        'is_shs_teacher': isSHSTeacher,
        'shs_track': shsTrack,
        'shs_strands': shsStrands,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Teacher record created for $fullName');
    } catch (e) {
      print('Error creating teacher record: $e');
    }
  }

  // ============================================
  // PARENT-SPECIFIC OPERATIONS
  // ============================================

  /// Create parent/guardian link to student
  Future<void> _createParentLink({
    required String studentId,
    required String parentEmail,
    required String guardianName,
    required String relationship,
    String? contactNumber,
  }) async {
    try {
      var parentProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', parentEmail)
          .maybeSingle();

      String parentId;

      if (parentProfile == null) {
        parentId = _generateUUID();
        await _supabase.from('profiles').insert({
          'id': parentId,
          'email': parentEmail,
          'full_name': guardianName,
          'role_id': 4,
          'phone': contactNumber,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ Parent profile created: $parentEmail');
      } else {
        parentId = parentProfile['id'];
        print('✅ Linked to existing parent: $parentEmail');
      }

      await _supabase.from('parent_students').insert({
        'parent_id': parentId,
        'student_id': studentId,
        'relationship': relationship,
        'is_primary': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Parent-student link created');
    } catch (e) {
      print('Error creating parent link: $e');
    }
  }
```

---

## Next Step: Update Enhanced Add User Screen

Update `lib/screens/admin/users/enhanced_add_user_screen.dart` to pass ALL collected data to the service:

### Current (Incomplete):
```dart
await _profileService.createUser(
  email: _emailController.text,
  fullName: fullName,
  roleId: roleId,
  lrn: _selectedRole == 'student' ? _lrnController.text : null,
  gradeLevel: _selectedRole == 'student' ? int.parse(_selectedGradeLevel) : null,
  section: _selectedRole == 'student' ? _selectedSection : null,
  phone: _contactNumberController.text.isNotEmpty ? _contactNumberController.text : null,
  validateLRN: _selectedRole == 'student',
);
```

### Required (Complete):
```dart
await _profileService.createUser(
  email: _emailController.text,
  fullName: fullName,
  roleId: roleId,
  // Student data
  lrn: _selectedRole == 'student' ? _lrnController.text : null,
  gradeLevel: _selectedRole == 'student' ? int.parse(_selectedGradeLevel) : null,
  section: _selectedRole == 'student' ? _selectedSection : null,
  address: _selectedRole == 'student' ? _addressController.text : null,
  gender: _selectedRole == 'student' ? _selectedGender : null,
  birthDate: _selectedRole == 'student' ? _selectedBirthDate : null,
  // Parent data
  parentEmail: _selectedRole == 'student' ? _parentEmailController.text : null,
  guardianName: _selectedRole == 'student' ? _guardianNameController.text : null,
  parentRelationship: _selectedRole == 'student' ? 'parent' : null,
  phone: _contactNumberController.text.isNotEmpty ? _contactNumberController.text : null,
  // Teacher data
  employeeId: _needsTeacherFields ? _employeeIdController.text : null,
  department: _needsTeacherFields ? _departmentController.text : null,
  subjects: _needsTeacherFields ? _selectedSubjects : null,
  isGradeCoordinator: _isGradeCoordinator,
  coordinatorGradeLevel: (_isGradeCoordinator || _isCoordinatorRole) ? _coordinatorGradeLevel : null,
  // SHS Teacher data
  isSHSTeacher: _isSHSTeacher,
  shsTrack: _isSHSTeacher ? _selectedSHSTrack : null,
  shsStrands: _isSHSTeacher ? _selectedSHSStrands : null,
  // Admin data
  isHybrid: _isHybridUser,
  validateLRN: _selectedRole == 'student',
);
```

---

## 4-Layer Separation Compliance

### ✅ **Layer 1: UI (enhanced_add_user_screen.dart)**
- Collects user input
- Validates form fields
- Displays loading states
- Shows success/error messages
- **NO business logic**

### ✅ **Layer 2: Service (profile_service.dart)**
- Handles all business logic
- Manages database operations
- Creates role-specific records
- Links parent-student relationships
- Logs activities
- **NO UI concerns**

### ✅ **Layer 3: Data (Supabase)**
- Stores profiles, students, teachers, parents
- Enforces RLS policies
- Maintains referential integrity

### ✅ **Layer 4: Models (profile.dart)**
- Data structures
- Serialization/deserialization

---

## Benefits of This Architecture

1. **Separation of Concerns** - UI doesn't know about database structure
2. **Reusability** - Service methods can be called from anywhere
3. **Testability** - Service logic can be unit tested independently
4. **Maintainability** - Changes to business logic don't affect UI
5. **Scalability** - Easy to add new roles or features

---

## Testing Checklist

After implementing the fixes:

- [ ] Student creation with parent linking works
- [ ] Teacher creation with subjects works
- [ ] SHS Teacher with tracks/strands works
- [ ] Coordinator creation works
- [ ] Admin creation works
- [ ] Hybrid Admin+Teacher works
- [ ] All data persists to correct tables
- [ ] Activity logging works
- [ ] Error handling works
- [ ] Success messages display correctly

---

## Database Tables Required

Ensure these tables exist in Supabase:

1. **profiles** - Main user profiles
2. **students** - Student-specific data
3. **teachers** - Teacher-specific data (with SHS fields)
4. **parent_students** - Parent-student relationships
5. **activity_log** - User activity tracking
6. **roles** - Role definitions

---

## Summary

The architecture is **properly designed** with 4-layer separation. The only missing piece is adding the two helper methods (`_createTeacherRecord` and `_createParentLink`) to ProfileService, then updating the UI to pass all collected data to the service.

This ensures:
- ✅ UI only handles presentation
- ✅ Service handles all business logic
- ✅ Clean separation maintained
- ✅ Easy to test and maintain
