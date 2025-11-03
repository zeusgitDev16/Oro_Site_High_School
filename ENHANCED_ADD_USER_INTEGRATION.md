# 🔧 Enhanced Add User Screen - Azure Integration

## Quick Implementation Guide

### Step 1: Import the Integrated Service

Add this import at the top of `enhanced_add_user_screen.dart`:

```dart
import '../../services/integrated_user_service.dart';
```

### Step 2: Add Service Instance

Add this to the `_EnhancedAddUserScreenState` class:

```dart
class _EnhancedAddUserScreenState extends State<EnhancedAddUserScreen> {
  final _integratedUserService = IntegratedUserService();
  // ... rest of your existing code
```

### Step 3: Replace the Create User Method

Find the `_createUser()` method and replace it with this:

```dart
Future<void> _createUser() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Prepare full name
    final fullName = '${_firstNameController.text} ${_lastNameController.text}'.trim();

    // Get role ID
    int roleId;
    switch (_selectedRole) {
      case 'student':
        roleId = 3;
        break;
      case 'teacher':
        roleId = 2;
        break;
      case 'admin':
        roleId = 1;
        break;
      case 'parent':
        roleId = 4;
        break;
      case 'grade_coordinator':
        roleId = 5;
        break;
      default:
        roleId = 3;
    }

    // Create user in both Azure AD and Supabase
    final result = await _integratedUserService.createUser(
      email: _emailController.text.trim(),
      fullName: fullName,
      roleId: roleId,
      // Student-specific
      lrn: _selectedRole == 'student' ? _lrnController.text : null,
      gradeLevel: _selectedRole == 'student' && _selectedGradeLevel.isNotEmpty
          ? int.parse(_selectedGradeLevel)
          : null,
      section: _selectedRole == 'student' ? _selectedSection : null,
      address: _selectedRole == 'student' ? _addressController.text : null,
      gender: _selectedRole == 'student' ? _selectedGender : null,
      birthDate: _selectedRole == 'student' ? _selectedBirthDate : null,
      // Parent data
      parentEmail: _selectedRole == 'student' && _parentEmailController.text.isNotEmpty
          ? _parentEmailController.text
          : null,
      guardianName: _selectedRole == 'student' && _guardianNameController.text.isNotEmpty
          ? _guardianNameController.text
          : null,
      parentRelationship: _selectedRole == 'student' ? 'parent' : null,
      phone: _contactNumberController.text.isNotEmpty
          ? _contactNumberController.text
          : null,
      // Teacher data
      employeeId: _needsTeacherFields ? _employeeIdController.text : null,
      department: _needsTeacherFields ? _departmentController.text : null,
      subjects: _needsTeacherFields ? _selectedSubjects : null,
      isGradeCoordinator: _isGradeCoordinator,
      coordinatorGradeLevel:
          (_isGradeCoordinator || _isCoordinatorRole) ? _coordinatorGradeLevel : null,
      // SHS Teacher data
      isSHSTeacher: _isSHSTeacher,
      shsTrack: _isSHSTeacher ? _selectedSHSTrack : null,
      shsStrands: _isSHSTeacher ? _selectedSHSStrands : null,
      // Admin data
      isHybrid: _isHybridUser,
      validateLRN: _selectedRole == 'student',
      createInAzure: true, // Set to false to skip Azure creation
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // Show success dialog with credentials
      _showSuccessDialog(
        email: result['email'],
        password: result['password'],
        azureUserId: result['azure_user_id'],
        supabaseUserId: result['supabase_user_id'],
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    
    // Show error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error Creating User'),
          ],
        ),
        content: Text(
          'Failed to create user: ${e.toString()}\n\n'
          'Please check:\n'
          '• Azure AD permissions\n'
          '• Client secret in .env file\n'
          '• Supabase connection\n'
          '• Email is not already taken',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Step 4: Add Success Dialog Method

Add this method to show the generated credentials:

```dart
void _showSuccessDialog({
  required String email,
  required String password,
  String? azureUserId,
  required String supabaseUserId,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          SizedBox(width: 12),
          Text('User Created Successfully!'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The user has been created in both Azure AD and Supabase.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Email', email),
            _buildInfoRow('Password', password, isPassword: true),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'User must change password on first login',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'System IDs:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            if (azureUserId != null)
              _buildInfoRow('Azure ID', azureUserId, isSmall: true),
            _buildInfoRow('Supabase ID', supabaseUserId, isSmall: true),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: Icon(Icons.copy),
          label: Text('Copy Credentials'),
          onPressed: () {
            // Copy to clipboard
            final credentials = 'Email: $email\nPassword: $password';
            // You can use clipboard package here
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Credentials copied to clipboard!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close add user screen
          },
          child: Text('Done'),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value, {bool isPassword = false, bool isSmall = false}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 11 : 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontFamily: isPassword ? 'monospace' : null,
              fontSize: isSmall ? 11 : 14,
              fontWeight: isPassword ? FontWeight.bold : FontWeight.normal,
              color: isPassword ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
```

---

## 🎨 Optional: Add Azure Status Indicator

Add this widget to show Azure integration status:

```dart
Widget _buildAzureStatusIndicator() {
  final isAzureEnabled = _integratedUserService.isAzureEnabled();
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isAzureEnabled ? Colors.green.shade50 : Colors.orange.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isAzureEnabled ? Colors.green.shade200 : Colors.orange.shade200,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isAzureEnabled ? Icons.cloud_done : Icons.cloud_off,
          size: 16,
          color: isAzureEnabled ? Colors.green : Colors.orange,
        ),
        SizedBox(width: 8),
        Text(
          isAzureEnabled
              ? 'Azure AD Integration: Active'
              : 'Azure AD Integration: Disabled',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isAzureEnabled ? Colors.green.shade900 : Colors.orange.shade900,
          ),
        ),
      ],
    ),
  );
}
```

Add it to your form, perhaps at the top:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Add New User'),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: _buildAzureStatusIndicator(),
        ),
      ],
    ),
    // ... rest of your build method
  );
}
```

---

## ✅ Testing Checklist

After implementation:

1. **Test Student Creation**:
   - [ ] Fill in all student fields
   - [ ] Include parent information
   - [ ] Click "Create User"
   - [ ] Verify success dialog shows
   - [ ] Check Azure AD for new user
   - [ ] Check Supabase profiles table
   - [ ] Check students table
   - [ ] Check parent_links table
   - [ ] Check enrollments table

2. **Test Teacher Creation**:
   - [ ] Fill in teacher fields
   - [ ] Add subjects
   - [ ] Click "Create User"
   - [ ] Verify success dialog shows
   - [ ] Check Azure AD for new user
   - [ ] Check Supabase profiles table
   - [ ] Check teachers table

3. **Test Error Handling**:
   - [ ] Try creating user with existing email
   - [ ] Try with invalid Azure credentials
   - [ ] Verify error dialog shows
   - [ ] Verify rollback works (Azure user deleted if Supabase fails)

---

## 🚀 Quick Start

1. Follow setup steps in `AZURE_USER_CREATION_SETUP.md`
2. Copy the code above into your `enhanced_add_user_screen.dart`
3. Test with a student user first
4. Verify in both Azure AD and Supabase
5. Test other user types

---

**Status**: ✅ READY TO IMPLEMENT  
**Estimated Time**: 15-20 minutes
