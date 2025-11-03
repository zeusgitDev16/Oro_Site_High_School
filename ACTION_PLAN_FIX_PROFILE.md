# 🔧 ACTION PLAN: Fix Profile Creation

## ⚡ DO THESE STEPS IN ORDER

---

## **STEP 1: Run SQL Fix in Supabase** (2 minutes)

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project

2. **Go to SQL Editor**
   - Click "SQL Editor" in left sidebar
   - Click "New query"

3. **Copy and paste this SQL:**

```sql
-- Fix RLS policies to allow profile creation
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

CREATE POLICY "Enable insert for authenticated users"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Enable read for authenticated users"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Ensure roles exist
INSERT INTO roles (id, name, created_at) VALUES
  (1, 'admin', NOW()),
  (2, 'teacher', NOW()),
  (3, 'student', NOW()),
  (4, 'parent', NOW()),
  (5, 'coordinator', NOW())
ON CONFLICT (id) DO NOTHING;
```

4. **Click "Run"**
5. **Verify success** - Should see "Success. No rows returned"

---

## **STEP 2: Clear Your Session** (1 minute)

1. **In your browser:**
   - Press `Ctrl + Shift + Delete`
   - Select "All time"
   - Check "Cookies" and "Cached images"
   - Click "Clear data"

2. **Sign out from Microsoft:**
   - Go to: https://login.microsoftonline.com
   - Click your profile → Sign out

3. **Close all browser windows**

---

## **STEP 3: Run the App with Enhanced Logging** (1 minute)

```bash
flutter run -d chrome --web-port=3000
```

---

## **STEP 4: Login and Watch Console** (2 minutes)

1. **Click "Admin log in (Office 365)"**
2. **Enter your credentials**
3. **Watch the console output carefully**

### **✅ SUCCESS - You should see:**

```
🔧 Creating/updating profile for OAuth user...
🔍 DEBUG: Creating/updating profile
🔍 User ID: 142c7f32-de38-4a9f-a978-2768fe67cdc9
✅ Using email: admin@aezycreativegmail.onmicrosoft.com
🔧 Attempting to insert profile...
🔧 Profile data: id=142c7f32..., email=admin@..., role_id=1
✅ Profile created successfully!
🎭 AuthGate: User role: admin
```

### **❌ FAILURE - If you see:**

```
❌ ERROR inserting profile: [error message]
❌ Postgrest error code: [code]
❌ Postgrest error message: [message]
```

**→ Copy the ENTIRE error message and send it to me!**

---

## **STEP 5: Verify in Supabase** (1 minute)

1. **Go to Supabase → Table Editor → profiles**
2. **Should see your profile:**
   ```
   id: 142c7f32-de38-4a9f-a978-2768fe67cdc9
   email: admin@aezycreativegmail.onmicrosoft.com
   full_name: Admin
   role_id: 1
   is_active: true
   ```

---

## **STEP 6: Test Manage Users Screen** (1 minute)

1. **Click "Users" in sidebar**
2. **Click "Manage All Users"**
3. **Should see your admin account!**

---

## 🐛 **IF STILL FAILS**

### **Check Console for Specific Error**

**Error: "new row violates row-level security policy"**
```sql
-- Run this in Supabase SQL Editor
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Should show 3 policies:
-- 1. Enable insert for authenticated users
-- 2. Enable read for authenticated users  
-- 3. Users can update own profile
```

**Error: "null value in column 'role_id'"**
```sql
-- Check if roles exist
SELECT * FROM roles;

-- Should show 5 roles (admin, teacher, student, parent, coordinator)
```

**Error: "duplicate key value violates unique constraint"**
```sql
-- Profile already exists, just update it
UPDATE profiles 
SET email = 'admin@aezycreativegmail.onmicrosoft.com',
    role_id = 1,
    is_active = true,
    updated_at = NOW()
WHERE id = '142c7f32-de38-4a9f-a978-2768fe67cdc9';
```

---

## 📋 **CHECKLIST**

- [ ] Step 1: SQL fix executed in Supabase
- [ ] Step 2: Browser cache cleared
- [ ] Step 3: App running on port 3000
- [ ] Step 4: Logged in with Azure
- [ ] Step 5: Console shows "✅ Profile created successfully!"
- [ ] Step 6: Profile exists in Supabase
- [ ] Step 7: Manage Users screen shows your account

---

## 📞 **WHAT TO SEND ME IF IT FAILS**

Copy and paste the ENTIRE console output, especially:

1. **The error message:**
   ```
   ❌ ERROR inserting profile: [COPY THIS]
   ❌ Postgrest error code: [COPY THIS]
   ❌ Postgrest error message: [COPY THIS]
   ```

2. **Your user ID:**
   ```
   🔍 User ID: [COPY THIS]
   ```

3. **The email being used:**
   ```
   ✅ Using email: [COPY THIS]
   ```

---

## 🎯 **EXPECTED TIMELINE**

- **Step 1:** 2 minutes
- **Step 2:** 1 minute
- **Step 3:** 1 minute
- **Step 4:** 2 minutes
- **Step 5:** 1 minute
- **Step 6:** 1 minute

**Total: ~8 minutes**

---

## ✅ **SUCCESS INDICATORS**

1. ✅ Console shows "✅ Profile created successfully!"
2. ✅ No error messages in console
3. ✅ Profile exists in Supabase profiles table
4. ✅ Manage Users screen shows your account
5. ✅ Can perform actions (reset password, etc.)

---

**START WITH STEP 1 NOW!** 🚀

Let me know what happens at each step!
