## ✅ AZURE AD USER CREATION - COMPLETE SETUP GUIDE

**Status**: Ready to implement  
**Permissions**: ✅ Directory.ReadWrite.All granted  
**Integration**: Azure AD + Supabase

---

## 🎯 What This Does

When you create a user in the admin dashboard:
1. ✅ **Creates user in Azure AD** (Microsoft 365 account)
2. ✅ **Creates user in Supabase** (database profile)
3. ✅ **Links both accounts** (stores Azure ID in Supabase)
4. ✅ **Auto-enrolls students** (in section courses)
5. ✅ **Creates role-specific records** (students, teachers, parents)

---

## 📋 SETUP STEPS

### **Step 1: Create Azure Client Secret**

1. Go to **Azure Portal**: https://portal.azure.com
2. Navigate to **Azure Active Directory** → **App registrations**
3. Select **"Oro Site High School ELMS"**
4. Click **"Certificates & secrets"** in the left menu
5. Click **"+ New client secret"**
6. Add description: `"ELMS User Creation Secret"`
7. Set expiration: **24 months** (recommended)
8. Click **"Add"**
9. **IMPORTANT**: Copy the **Value** immediately (you won't see it again!)

### **Step 2: Add Client Secret to .env File**

Open `.env` file and replace `YOUR_CLIENT_SECRET_HERE` with your actual secret:

```env
AZURE_CLIENT_SECRET=your_actual_secret_value_here
```

**Example**:
```env
AZURE_CLIENT_SECRET=abc123~XyZ789.DefGhi456-JklMno
```

### **Step 3: Run Database Migration**

Run this SQL in your Supabase SQL Editor:

```sql
-- Add azure_user_id column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS azure_user_id TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_azure_user_id 
ON public.profiles(azure_user_id);
```

Or run the migration file:
```bash
# In Supabase Dashboard → SQL Editor
# Copy and paste: database/add_azure_user_id_column.sql
```

### **Step 4: Update Enhanced Add User Screen**

Replace the user creation call in `enhanced_add_user_screen.dart`:

**OLD CODE** (ProfileService only):
```dart
await _profileService.createUser(
  email: _emailController.text,
  fullName: fullName,
  roleId: roleId,
  // ... other parameters
);
```

**NEW CODE** (Integrated service):
```dart
import '../services/integrated_user_service.dart';

// At the top of the class
final _integratedUserService = IntegratedUserService();

// In the create user method
final result = await _integratedUserService.createUser(
  email: _emailController.text,
  fullName: fullName,
  roleId: roleId,
  lrn: _selectedRole == 'student' ? _lrnController.text : null,
  gradeLevel: _selectedRole == 'student' ? int.parse(_selectedGradeLevel) : null,
  section: _selectedRole == 'student' ? _selectedSection : null,
  address: _selectedRole == 'student' ? _addressController.text : null,
  gender: _selectedRole == 'student' ? _selectedGender : null,
  birthDate: _selectedRole == 'student' ? _selectedBirthDate : null,
  parentEmail: _selectedRole == 'student' ? _parentEmailController.text : null,
  guardianName: _selectedRole == 'student' ? _guardianNameController.text : null,
  parentRelationship: _selectedRole == 'student' ? 'parent' : null,
  phone: _contactNumberController.text.isNotEmpty ? _contactNumberController.text : null,
  employeeId: _needsTeacherFields ? _employeeIdController.text : null,
  department: _needsTeacherFields ? _departmentController.text : null,
  subjects: _needsTeacherFields ? _selectedSubjects : null,
  isGradeCoordinator: _isGradeCoordinator,
  coordinatorGradeLevel: (_isGradeCoordinator || _isCoordinatorRole) ? _coordinatorGradeLevel : null,
  isSHSTeacher: _isSHSTeacher,
  shsTrack: _isSHSTeacher ? _selectedSHSTrack : null,
  shsStrands: _isSHSTeacher ? _selectedSHSStrands : null,
  isHybrid: _isHybridUser,
  validateLRN: _selectedRole == 'student',
  createInAzure: true, // Set to false to skip Azure creation
);

// Show success message with password
if (result['success']) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'User created!\n'
        'Email: ${result['email']}\n'
        'Password: ${result['password']}\n'
        'Azure ID: ${result['azure_user_id'] ?? 'N/A'}',
      ),
      duration: Duration(seconds: 10),
      backgroundColor: Colors.green,
    ),
  );
}
```

---

## 🔧 SERVICES CREATED

### 1. **AzureUserService** (`lib/services/azure_user_service.dart`)
Handles all Azure AD operations:
- ✅ Create user in Azure AD
- ✅ Update user details
- ✅ Reset password
- ✅ Enable/disable account
- ✅ Delete user
- ✅ Get user by email
- ✅ Get all users

### 2. **IntegratedUserService** (`lib/services/integrated_user_service.dart`)
Orchestrates both Azure AD and Supabase:
- ✅ Creates user in both systems
- ✅ Links Azure ID to Supabase profile
- ✅ Handles rollback if creation fails
- ✅ Logs all operations
- ✅ Syncs updates between systems

---

## 📊 USER CREATION FLOW

```
Admin Creates User
    ↓
Generate Password
    ↓
Create in Azure AD
    ├── Set displayName
    ├── Set userPrincipalName (email)
    ├── Set password
    ├── Set jobTitle (based on role)
    ├── Set department
    └── Get Azure User ID
    ↓
Create in Supabase
    ├── Create auth user
    ├── Create profile
    ├── Store Azure User ID
    ├── Create role-specific records
    │   ├── Student → students table
    │   ├── Teacher → teachers table
    │   └── Parent → parent_links table
    └── Auto-enroll (if student)
    ↓
Link Accounts
    └── Update profile.azure_user_id
    ↓
Log Activity
    └── Record in activity_log
    ↓
Return Result
    ├── Supabase User ID
    ├── Azure User ID
    ├── Email
    └── Generated Password
```

---

## 🧪 TESTING

### Test 1: Create Student
```dart
final result = await _integratedUserService.createUser(
  email: 'juan.delacruz@aezycreativegmail.onmicrosoft.com',
  fullName: 'Juan Dela Cruz',
  roleId: 3, // Student
  lrn: '123456789012',
  gradeLevel: 7,
  section: 'Diamond',
  phone: '09123456789',
  parentEmail: 'parent@example.com',
  guardianName: 'Maria Dela Cruz',
);

print('Supabase ID: ${result['supabase_user_id']}');
print('Azure ID: ${result['azure_user_id']}');
print('Password: ${result['password']}');
```

### Test 2: Create Teacher
```dart
final result = await _integratedUserService.createUser(
  email: 'teacher@aezycreativegmail.onmicrosoft.com',
  fullName: 'Maria Santos',
  roleId: 2, // Teacher
  employeeId: 'EMP-2025-001',
  department: 'Mathematics',
  subjects: ['Math 7', 'Math 8'],
  phone: '09123456789',
);
```

### Test 3: Create Admin
```dart
final result = await _integratedUserService.createUser(
  email: 'admin@aezycreativegmail.onmicrosoft.com',
  fullName: 'Admin User',
  roleId: 1, // Admin
  phone: '09123456789',
);
```

---

## ✅ VERIFICATION CHECKLIST

After creating a user, verify:

### In Azure AD:
- [ ] Go to Azure Portal → Azure Active Directory → Users
- [ ] Search for the email
- [ ] User exists with correct:
  - [ ] Display name
  - [ ] User principal name (email)
  - [ ] Job title
  - [ ] Department
  - [ ] Account enabled

### In Supabase:
- [ ] Go to Supabase Dashboard → Table Editor → profiles
- [ ] Find the user by email
- [ ] Check fields:
  - [ ] `id` (UUID)
  - [ ] `email`
  - [ ] `full_name`
  - [ ] `role_id`
  - [ ] `azure_user_id` (should match Azure ID)
  - [ ] `is_active` = true

### For Students:
- [ ] Check `students` table has record
- [ ] Check `enrollments` table for auto-enrollment
- [ ] If parent info provided, check `parent_links` table

### For Teachers:
- [ ] Check `teachers` table has record
- [ ] Verify `subjects` array
- [ ] Check `is_grade_coordinator` flag

---

## 🚨 TROUBLESHOOTING

### Error: "Failed to get access token"
**Solution**: Check your Azure Client Secret in `.env` file

### Error: "User already exists in Azure AD"
**Solution**: The email is already taken. Use a different email or delete the existing user first.

### Error: "Failed to create Supabase user"
**Solution**: Check Supabase connection and RLS policies

### Error: "Could not restore admin session"
**Solution**: This is a warning, not an error. The user was still created successfully.

### Azure user created but Supabase failed
**Solution**: The service automatically rolls back (deletes) the Azure user. Check the error message for details.

---

## 🔐 SECURITY NOTES

1. **Client Secret**: Keep it secret! Never commit to Git.
2. **Passwords**: Generated passwords follow pattern: `{identifier}@{year}`
3. **Force Password Change**: Users must change password on first login
4. **Session Management**: Admin session is preserved during user creation
5. **Rollback**: If Supabase creation fails, Azure user is automatically deleted

---

## 📝 PASSWORD FORMAT

Generated passwords follow this pattern:
- **Student**: `{LRN}@{year}` → `123456789012@2025`
- **Teacher**: `{CleanName}@{year}` → `MariaSantos@2025`
- **Admin**: `{CleanName}@{year}` → `AdminUser@2025`

Users are forced to change password on first login.

---

## 🎯 NEXT STEPS

1. ✅ **Setup Complete**: Follow steps 1-4 above
2. ⏳ **Test User Creation**: Create test users for each role
3. ⏳ **Verify in Azure**: Check users appear in Azure AD
4. ⏳ **Verify in Supabase**: Check profiles and role tables
5. ⏳ **Test Login**: Users should be able to login with generated password
6. ⏳ **Test Password Change**: Users should be prompted to change password

---

## 📞 SUPPORT

If you encounter issues:
1. Check Azure permissions (Directory.ReadWrite.All should be granted)
2. Verify Client Secret is correct in `.env`
3. Check Supabase connection
4. Review console logs for detailed error messages
5. Check `activity_log` table for creation records

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Priority**: 🔴 CRITICAL - Core functionality for thesis defense  
**Estimated Setup Time**: 10-15 minutes
