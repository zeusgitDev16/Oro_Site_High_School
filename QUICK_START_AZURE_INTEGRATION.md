# ⚡ QUICK START - Azure AD Integration

## 🎯 Goal
Create users in both Azure AD and Supabase with one click!

---

## ✅ Prerequisites Checklist

- [x] Azure AD permissions granted (Directory.ReadWrite.All)
- [ ] Azure Client Secret created
- [ ] .env file updated
- [ ] Database migration run
- [ ] Enhanced Add User Screen updated

---

## 🚀 5-Minute Setup

### 1️⃣ Create Azure Client Secret (2 min)

```
Azure Portal → App Registrations → Oro Site High School ELMS
→ Certificates & secrets → + New client secret
→ Description: "ELMS User Creation"
→ Expires: 24 months
→ Add → COPY THE VALUE!
```

### 2️⃣ Update .env File (30 sec)

```env
AZURE_CLIENT_SECRET=paste_your_secret_value_here
```

### 3️⃣ Run Database Migration (30 sec)

Supabase Dashboard → SQL Editor → Run:

```sql
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS azure_user_id TEXT;
CREATE INDEX IF NOT EXISTS idx_profiles_azure_user_id ON public.profiles(azure_user_id);
```

### 4️⃣ Update Enhanced Add User Screen (2 min)

**Add import:**
```dart
import '../../services/integrated_user_service.dart';
```

**Add service:**
```dart
final _integratedUserService = IntegratedUserService();
```

**Replace createUser call:**
```dart
final result = await _integratedUserService.createUser(
  email: _emailController.text,
  fullName: fullName,
  roleId: roleId,
  // ... all your existing parameters
  createInAzure: true,
);
```

**Show success:**
```dart
if (result['success']) {
  print('Password: ${result['password']}');
  print('Azure ID: ${result['azure_user_id']}');
}
```

---

## 🧪 Test It!

### Create Test Student:
```
Email: test.student@aezycreativegmail.onmicrosoft.com
Name: Test Student
Role: Student
LRN: 123456789012
Grade: 7
Section: Diamond
```

### Verify:
1. ✅ Check Azure Portal → Users
2. ✅ Check Supabase → profiles table
3. ✅ Check students table
4. ✅ Note the password shown in success dialog

---

## 📋 What Happens

```
You click "Create User"
    ↓
Creates in Azure AD (Microsoft 365 account)
    ↓
Creates in Supabase (database profile)
    ↓
Links both with azure_user_id
    ↓
Shows success with password
```

---

## 🎯 For Thesis Defense

**Demo Script:**
1. "I'll now create a student account"
2. Fill form → Click Create
3. "Notice it creates in both Azure AD and our database"
4. Show Azure Portal (user exists)
5. Show Supabase (profile + azure_user_id)
6. "The user can now login with Microsoft 365"

---

## 🚨 Troubleshooting

**Error: "Failed to get access token"**
→ Check AZURE_CLIENT_SECRET in .env

**Error: "User already exists"**
→ Email is taken, use different email

**Error: "Could not restore admin session"**
→ Warning only, user was created successfully

---

## 📞 Quick Help

**Files Created:**
- `lib/services/azure_user_service.dart`
- `lib/services/integrated_user_service.dart`

**Documentation:**
- `AZURE_USER_CREATION_SETUP.md` (detailed)
- `ENHANCED_ADD_USER_INTEGRATION.md` (code examples)
- `AZURE_INTEGRATION_COMPLETE.md` (full overview)

---

## ✅ Success Criteria

- [ ] Azure Client Secret in .env
- [ ] Database migration run
- [ ] Code updated in enhanced_add_user_screen.dart
- [ ] Test user created successfully
- [ ] User appears in Azure AD
- [ ] User appears in Supabase
- [ ] azure_user_id is populated
- [ ] Password shown in success dialog

---

**Time to Complete**: 5-10 minutes  
**Difficulty**: Easy  
**Impact**: HIGH - Core feature for thesis! 🎓
