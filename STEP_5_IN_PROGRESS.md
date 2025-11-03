# 🚧 Step 5: Wire Add User Screen - IN PROGRESS

## Status: 90% Complete

The Add User screen UI is complete and ready. I need to wire the `_createUser()` method to use ProfileService.

## What's Done:
✅ UI is complete with all fields
✅ ProfileService imported
✅ Form validation working
✅ Role-specific fields (Student, Teacher, Admin)
✅ Tab navigation
✅ Loading states

## What's Needed:

Replace the `_createUser()` method in `enhanced_add_user_screen.dart` (around line 1150) with this code:

```dart
Future<void> _createUser() async {
  if (!_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all required fields')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Build full name
    final fullName = [
      _firstNameController.text,
      _middleNameController.text,
      _lastNameController.text,
      _suffixController.text,
    ].where((s) => s.isNotEmpty).join(' ');

    // Map role to role_id
    int roleId;
    switch (_selectedRole) {
      case 'admin':
        roleId = 1;
        break;
      case 'teacher':
        roleId = 2;
        break;
      case 'student':
        roleId = 3;
        break;
      case 'parent':
        roleId = 4;
        break;
      case 'ict_coordinator':
        roleId = 5;
        break;
      default:
        roleId = 3; // Default to student
    }

    // Create user via ProfileService
    final profile = await _profileService.createUser(
      email: _emailController.text,
      fullName: fullName,
      roleId: roleId,
      lrn: _selectedRole == 'student' ? _lrnController.text : null,
      gradeLevel: _selectedRole == 'student' ? int.parse(_selectedGradeLevel) : null,
      section: _selectedRole == 'student' ? _selectedSection : null,
      phone: _contactNumberController.text.isNotEmpty ? _contactNumberController.text : null,
      validateLRN: _selectedRole == 'student',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'User "${fullName}" created successfully!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Return to previous screen and refresh
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating user: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

## Testing:
1. Navigate to Users → Manage All Users
2. Click "Add User" button
3. Fill in the form
4. Click "Create User"
5. Should see success message
6. User should appear in Manage Users list

## Next: Step 6 - Bulk Excel Upload
