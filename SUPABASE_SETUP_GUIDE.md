# 🚀 **SUPABASE SETUP GUIDE**
## **Oro Site High School ELMS - Complete Database Setup**

---

## 📋 **Quick Start Checklist**

- [ ] **Step 1:** Run the SQL schema
- [ ] **Step 2:** Create test users
- [ ] **Step 3:** Assign roles to users
- [ ] **Step 4:** Test Flutter app connection
- [ ] **Step 5:** Verify RLS policies

---

## 🎯 **STEP 1: Run the SQL Schema**

### **Instructions:**

1. **Open Supabase Dashboard**
   - Go to: https://fhqzohvtioosycaafnij.supabase.co
   - Login with your credentials

2. **Navigate to SQL Editor**
   - Click on **SQL Editor** in the left sidebar
   - Click **New Query**

3. **Copy the SQL File**
   - Open: `COMPLETE_SUPABASE_SCHEMA.sql`
   - Copy the entire contents (Ctrl+A, Ctrl+C)

4. **Paste and Execute**
   - Paste into the SQL Editor
   - Click **Run** (or press Ctrl+Enter)
   - Wait for completion (should take 10-30 seconds)

5. **Verify Success**
   - Check for success message in the output
   - Go to **Table Editor** → You should see 23 tables
   - Check **Database** → **Roles** → Should see RLS enabled

### **Expected Output:**
```
✅ ORO SITE HIGH SCHOOL ELMS DATABASE SCHEMA CREATED SUCCESSFULLY!

📊 Tables Created: 23
🔐 RLS Policies: 50+
⚡ Indexes: 20+
🔧 Functions: 5
📦 Storage Buckets: 4
```

---

## 👥 **STEP 2: Create Test Users**

### **Method 1: Via Supabase Dashboard (Recommended)**

1. **Navigate to Authentication**
   - Click **Authentication** in left sidebar
   - Click **Users** tab
   - Click **Add User** button

2. **Create Admin User**
   ```
   Email: admin@orosite.edu.ph
   Password: Admin123!
   Auto Confirm User: ✅ YES
   ```
   - Click **Create User**
   - **Copy the User ID** (you'll need this)

3. **Create Teacher User**
   ```
   Email: teacher@orosite.edu.ph
   Password: Teacher123!
   Auto Confirm User: ✅ YES
   ```
   - Click **Create User**
   - **Copy the User ID**

4. **Create Student User**
   ```
   Email: student@orosite.edu.ph
   Password: Student123!
   Auto Confirm User: ✅ YES
   ```
   - Click **Create User**
   - **Copy the User ID**

5. **Create Parent User**
   ```
   Email: parent@orosite.edu.ph
   Password: Parent123!
   Auto Confirm User: ✅ YES
   ```
   - Click **Create User**
   - **Copy the User ID**

### **Method 2: Via SQL (Alternative)**

```sql
-- Note: This requires admin access to auth schema
-- Use Dashboard method if this doesn't work

-- Create admin user
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@orosite.edu.ph',
  crypt('Admin123!', gen_salt('bf')),
  NOW(),
  '{"full_name": "Admin User"}',
  NOW(),
  NOW()
);
```

---

## 🎭 **STEP 3: Assign Roles to Users**

After creating users, you need to assign them roles.

### **Get User IDs First:**

1. Go to **SQL Editor**
2. Run this query:

```sql
SELECT id, email FROM auth.users ORDER BY created_at DESC;
```

3. **Copy the UUIDs** for each user

### **Assign Roles:**

Replace `ADMIN_USER_ID`, `TEACHER_USER_ID`, etc. with actual UUIDs from above:

```sql
-- Update admin user
UPDATE public.profiles
SET role_id = 1, full_name = 'Admin User'
WHERE id = 'ADMIN_USER_ID_HERE';

-- Update teacher user
UPDATE public.profiles
SET role_id = 2, full_name = 'Teacher User'
WHERE id = 'TEACHER_USER_ID_HERE';

-- Update student user
UPDATE public.profiles
SET role_id = 3, full_name = 'Student User'
WHERE id = 'STUDENT_USER_ID_HERE';

-- Update parent user
UPDATE public.profiles
SET role_id = 4, full_name = 'Parent User'
WHERE id = 'PARENT_USER_ID_HERE';
```

### **Verify Roles Assigned:**

```sql
SELECT 
  p.id,
  p.email,
  p.full_name,
  r.name as role
FROM public.profiles p
LEFT JOIN public.roles r ON p.role_id = r.id
ORDER BY p.created_at DESC;
```

**Expected Output:**
```
admin@orosite.edu.ph    | Admin User    | admin
teacher@orosite.edu.ph  | Teacher User  | teacher
student@orosite.edu.ph  | Student User  | student
parent@orosite.edu.ph   | Parent User   | parent
```

---

## 🧪 **STEP 4: Test Flutter App Connection**

### **Test 1: Run the App**

```bash
cd c:\Users\User1\F_Dev\oro_site_high_school
flutter run -d chrome
```

### **Test 2: Login as Admin**

1. Open the app
2. Login with:
   - Email: `admin@orosite.edu.ph`
   - Password: `Admin123!`
3. **Expected:** You should see the Admin Dashboard
4. Check console for errors

### **Test 3: Login as Teacher**

1. Logout
2. Login with:
   - Email: `teacher@orosite.edu.ph`
   - Password: `Teacher123!`
3. **Expected:** You should see the Teacher Dashboard

### **Test 4: Login as Student**

1. Logout
2. Login with:
   - Email: `student@orosite.edu.ph`
   - Password: `Student123!`
3. **Expected:** You should see the Student Dashboard

### **Test 5: Login as Parent**

1. Logout
2. Login with:
   - Email: `parent@orosite.edu.ph`
   - Password: `Parent123!`
3. **Expected:** You should see the Parent Dashboard

---

## 🔐 **STEP 5: Verify RLS Policies**

### **Test RLS with SQL Queries**

1. **Test as Admin (should see all profiles):**

```sql
-- Set the auth context to admin user
SELECT set_config('request.jwt.claims', 
  json_build_object('sub', 'ADMIN_USER_ID_HERE')::text, 
  true);

-- Try to select all profiles
SELECT * FROM public.profiles;
-- Should return all profiles
```

2. **Test as Student (should only see own profile):**

```sql
-- Set the auth context to student user
SELECT set_config('request.jwt.claims', 
  json_build_object('sub', 'STUDENT_USER_ID_HERE')::text, 
  true);

-- Try to select all profiles
SELECT * FROM public.profiles;
-- Should only return student's own profile
```

3. **Test Course Access:**

```sql
-- Create a test course as admin
INSERT INTO public.courses (name, description, teacher_id, grade_level, section)
VALUES ('Math 7', 'Grade 7 Mathematics', 'TEACHER_USER_ID_HERE', 7, 'A');

-- Enroll student in course
INSERT INTO public.enrollments (student_id, course_id)
VALUES ('STUDENT_USER_ID_HERE', (SELECT id FROM courses WHERE name = 'Math 7'));

-- Test: Student should see enrolled course
SELECT set_config('request.jwt.claims', 
  json_build_object('sub', 'STUDENT_USER_ID_HERE')::text, 
  true);
SELECT * FROM public.courses;
-- Should return Math 7 course
```

---

## 📊 **Database Structure Overview**

### **Core Tables (23 Total)**

| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| `profiles` | User accounts | → auth.users, roles |
| `students` | Student data | → profiles |
| `parent_students` | Parent-child links | → profiles, students |
| `roles` | User roles | ← profiles |
| `permissions` | System permissions | ← role_permissions |
| `role_permissions` | Role-permission map | → roles, permissions |
| `courses` | Course catalog | → profiles (teacher) |
| `enrollments` | Student enrollments | → profiles, courses |
| `course_assignments` | Teacher-course map | → profiles, courses |
| `course_modules` | Course chapters | → courses |
| `lessons` | Lesson content | → course_modules |
| `assignments` | Homework/projects | → courses |
| `submissions` | Student work | → profiles, assignments |
| `grades` | Academic grades | → submissions, profiles |
| `attendance` | Daily attendance | → profiles, courses |
| `messages` | Direct messaging | → profiles (sender/recipient) |
| `notifications` | System notifications | → profiles |
| `announcements` | School announcements | → courses |
| `calendar_events` | School calendar | → courses |
| `activity_log` | Audit trail | → profiles |
| `batch_upload` | Bulk operations | → profiles |
| `teacher_requests` | Teacher requests | → profiles |
| `section_assignments` | Class advisers | → profiles |
| `coordinator_assignments` | Grade coordinators | → profiles |

### **Role Hierarchy**

```
Admin (role_id: 1)
├── Full system access
├── Manage all users
├── Manage all courses
└── View all data

Teacher (role_id: 2)
├── Manage own courses
├── View enrolled students
├── Enter grades
└── Take attendance

Grade Coordinator (role_id: 5)
├── All teacher permissions
├── View all students in grade level
├── Reset student passwords
└── Grade-level reports

Student (role_id: 3)
├── View enrolled courses
├── View own grades
├── View own attendance
└── Submit assignments

Parent (role_id: 4)
├── View children's data
├── View children's grades
├── View children's attendance
└── Message teachers
```

---

## 🔧 **Troubleshooting**

### **Issue 1: "relation does not exist"**

**Cause:** Tables not created  
**Solution:** Re-run the SQL schema file

### **Issue 2: "new row violates row-level security policy"**

**Cause:** RLS policy too restrictive  
**Solution:** Check if user has correct role assigned

```sql
-- Check user's role
SELECT p.email, r.name as role
FROM profiles p
LEFT JOIN roles r ON p.role_id = r.id
WHERE p.id = auth.uid();
```

### **Issue 3: "permission denied for table"**

**Cause:** RLS enabled but user can't access  
**Solution:** Verify RLS policies exist

```sql
-- List all policies for a table
SELECT * FROM pg_policies WHERE tablename = 'profiles';
```

### **Issue 4: User can't login**

**Cause:** Email not confirmed  
**Solution:** Confirm email in dashboard

1. Go to Authentication → Users
2. Find the user
3. Click the three dots → Confirm Email

### **Issue 5: Role routing not working**

**Cause:** `role_id` not set in profiles  
**Solution:** Update profile with role

```sql
UPDATE profiles
SET role_id = 1  -- 1=admin, 2=teacher, 3=student, 4=parent
WHERE email = 'user@example.com';
```

---

## 📈 **Next Steps After Setup**

### **1. Create Sample Data**

```sql
-- Create sample courses
INSERT INTO courses (name, description, teacher_id, grade_level, section, school_year)
VALUES 
  ('Mathematics 7', 'Grade 7 Math', 'TEACHER_USER_ID', 7, 'A', '2024-2025'),
  ('Science 7', 'Grade 7 Science', 'TEACHER_USER_ID', 7, 'A', '2024-2025'),
  ('English 7', 'Grade 7 English', 'TEACHER_USER_ID', 7, 'A', '2024-2025');

-- Enroll student in courses
INSERT INTO enrollments (student_id, course_id)
SELECT 'STUDENT_USER_ID', id FROM courses WHERE grade_level = 7;

-- Create sample assignment
INSERT INTO assignments (course_id, title, description, due_date)
VALUES (
  (SELECT id FROM courses WHERE name = 'Mathematics 7'),
  'Chapter 1 Quiz',
  'Complete exercises 1-10',
  NOW() + INTERVAL '7 days'
);
```

### **2. Test Each Feature**

- [ ] Course creation (Admin)
- [ ] Student enrollment (Admin/Teacher)
- [ ] Assignment creation (Teacher)
- [ ] Assignment submission (Student)
- [ ] Grade entry (Teacher)
- [ ] Attendance recording (Teacher)
- [ ] Messaging (All roles)
- [ ] Notifications (All roles)

### **3. Configure Storage**

If you need file uploads:

1. Go to **Storage** in Supabase
2. Verify buckets exist: `avatars`, `assignments`, `submissions`, `resources`
3. Test file upload from Flutter app

### **4. Monitor Performance**

1. Go to **Database** → **Logs**
2. Watch for slow queries
3. Add indexes if needed

---

## 📞 **Support Resources**

### **Supabase Documentation**
- Main Docs: https://supabase.com/docs
- RLS Guide: https://supabase.com/docs/guides/auth/row-level-security
- Flutter Guide: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter

### **Your Project Files**
- Schema Definition: `SUPABASE_TABLES.md`
- Complete SQL: `COMPLETE_SUPABASE_SCHEMA.sql`
- This Guide: `SUPABASE_SETUP_GUIDE.md`

### **Common SQL Queries**

**View all tables:**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

**View all RLS policies:**
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Count records in all tables:**
```sql
SELECT 
  'profiles' as table_name, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'courses', COUNT(*) FROM courses
UNION ALL
SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL
SELECT 'grades', COUNT(*) FROM grades
UNION ALL
SELECT 'attendance', COUNT(*) FROM attendance;
```

---

## ✅ **Success Criteria**

Your setup is complete when:

- ✅ All 23 tables exist in Table Editor
- ✅ All 5 roles exist in roles table
- ✅ Test users can login
- ✅ Each role sees their appropriate dashboard
- ✅ RLS policies prevent unauthorized access
- ✅ No errors in Flutter console
- ✅ Data persists after app restart

---

## 🎉 **Congratulations!**

Your Oro Site High School ELMS database is now fully configured and ready for development!

**Next:** Start connecting your Flutter services to the real database by updating each service file to use Supabase queries instead of mock data.

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Production Ready ✅
