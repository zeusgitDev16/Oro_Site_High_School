# 🧪 Test Step 4 - Quick Guide

## ⚡ Quick Test (5 minutes)

### **1. Logout & Clear Cache**
```
1. Sign out from your app
2. Press Ctrl + Shift + Delete
3. Clear "All time" → Cookies and cached files
4. Close browser
```

### **2. Run the App**
```bash
flutter run -d chrome --web-port=3000
```

### **3. Login with Azure**
```
1. Click "Admin log in (Office 365)"
2. Enter: admin@aezycreativegmail.onmicrosoft.com
3. Enter your password
4. Complete authentication
```

### **4. Watch Console Output**

**✅ SUCCESS - You should see:**
```
✅ AuthGate: User signed in via OAuth
🔧 Creating/updating profile for OAuth user...
🔍 DEBUG: Creating/updating profile
✅ Using email: admin@aezycreativegmail.onmicrosoft.com
🎭 AuthGate: User role: admin
```

**❌ FAILURE - If you see:**
```
❌ ERROR: Could not extract email from any source
```
→ Contact me, we need to debug Azure token

### **5. Check Supabase**

Open Supabase → Table Editor → profiles

**Should see:**
```
id: 142c7f32-de38-4a9f-a978-2768fe67cdc9
email: admin@aezycreativegmail.onmicrosoft.com
full_name: Admin User
role_id: 1
is_active: true
```

### **6. Test Manage Users Screen**

```
1. Click "Users" in left sidebar
2. Click "Manage All Users"
3. Should see your admin account
4. Try these actions:
   - Search for your name
   - Click ⋮ menu → Reset Password
   - Should show new password dialog
```

---

## ✅ Success Checklist

- [ ] Console shows "Creating/updating profile"
- [ ] Console shows "Using email: [your email]"
- [ ] Console shows "User role: admin"
- [ ] Profile exists in Supabase profiles table
- [ ] Manage Users screen shows your account
- [ ] Can reset password (shows dialog with new password)
- [ ] Tab counts are accurate (not 0)

---

## 🐛 If Something Fails

### **Profile not created?**

Run this SQL in Supabase:

```sql
-- Check if your auth user exists
SELECT id, email FROM auth.users 
WHERE email = 'admin@aezycreativegmail.onmicrosoft.com';

-- If it exists, manually create profile
INSERT INTO profiles (id, email, full_name, role_id, is_active, created_at)
VALUES (
  'YOUR_USER_ID_FROM_ABOVE',  -- Copy the ID
  'admin@aezycreativegmail.onmicrosoft.com',
  'Admin User',
  1,
  true,
  NOW()
);
```

### **"Unable to determine user role"?**

```sql
-- Check if roles exist
SELECT * FROM roles;

-- If empty, insert roles
INSERT INTO roles (id, name) VALUES
  (1, 'admin'),
  (2, 'teacher'),
  (3, 'student'),
  (4, 'parent'),
  (5, 'coordinator')
ON CONFLICT DO NOTHING;
```

### **Manage Users screen empty?**

```sql
-- Check if profiles table has data
SELECT COUNT(*) FROM profiles;

-- If 0, your profile wasn't created
-- Use the manual insert above
```

---

## 🎯 What to Test

1. ✅ **Login** - Azure AD authentication works
2. ✅ **Profile Creation** - Profile appears in database
3. ✅ **Role Assignment** - Correct role assigned
4. ✅ **User List** - Appears in Manage Users screen
5. ✅ **Search** - Can search for your name
6. ✅ **Reset Password** - Shows new password dialog
7. ✅ **Tab Counts** - Shows accurate counts

---

## 📊 Expected Results

### **Console Output:**
```
🔐 Starting Azure AD authentication...
🔐 OAuth initiated: true
✅ User signed in: admin@aezycreativegmail.onmicrosoft.com
🔧 Creating/updating profile for OAuth user...
✅ Using email: admin@aezycreativegmail.onmicrosoft.com
🎭 AuthGate: User role: admin
```

### **Supabase profiles table:**
```
1 row with your email and role_id = 1
```

### **Manage Users screen:**
```
All (1)
Students (0)
Teachers (0)
Admins (1)  ← Your account here
Parents (0)
```

---

## 🚀 Ready to Proceed?

If all tests pass:
- ✅ Step 4 is complete!
- ✅ Profile auto-creation works!
- ✅ Ready for Step 5 (Add User screen)

**Let me know the results!** 🎉
