# ⚡ **SUPABASE QUICK REFERENCE**
## **Oro Site High School ELMS - Common Operations**

---

## 🚀 **Quick Setup (5 Minutes)**

```bash
# 1. Open Supabase Dashboard
https://fhqzohvtioosycaafnij.supabase.co

# 2. Go to SQL Editor → New Query

# 3. Copy and paste COMPLETE_SUPABASE_SCHEMA.sql

# 4. Click Run

# 5. Create test users in Authentication → Users

# 6. Assign roles (see below)
```

---

## 👥 **User Management**

### **Create Test Users (Dashboard)**

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@orosite.edu.ph | Admin123! |
| Teacher | teacher@orosite.edu.ph | Teacher123! |
| Student | student@orosite.edu.ph | Student123! |
| Parent | parent@orosite.edu.ph | Parent123! |

### **Assign Roles (SQL)**

```sql
-- Get user IDs first
SELECT id, email FROM auth.users;

-- Assign admin role
UPDATE profiles SET role_id = 1 WHERE id = 'USER_ID_HERE';

-- Assign teacher role
UPDATE profiles SET role_id = 2 WHERE id = 'USER_ID_HERE';

-- Assign student role
UPDATE profiles SET role_id = 3 WHERE id = 'USER_ID_HERE';

-- Assign parent role
UPDATE profiles SET role_id = 4 WHERE id = 'USER_ID_HERE';
```

### **Verify Roles**

```sql
SELECT p.email, r.name as role, p.full_name
FROM profiles p
LEFT JOIN roles r ON p.role_id = r.id;
```

---

## 📚 **Course Management**

### **Create Course**

```sql
INSERT INTO courses (name, description, teacher_id, grade_level, section, school_year)
VALUES (
  'Mathematics 7',
  'Grade 7 Mathematics',
  'TEACHER_USER_ID_HERE',
  7,
  'A',
  '2024-2025'
);
```

### **Enroll Student**

```sql
INSERT INTO enrollments (student_id, course_id)
VALUES (
  'STUDENT_USER_ID_HERE',
  (SELECT id FROM courses WHERE name = 'Mathematics 7')
);
```

### **View Course Enrollments**

```sql
SELECT 
  c.name as course,
  p.full_name as student,
  e.status,
  e.enrolled_at
FROM enrollments e
JOIN courses c ON e.course_id = c.id
JOIN profiles p ON e.student_id = p.id
WHERE c.id = COURSE_ID_HERE;
```

---

## 📝 **Assignment & Grades**

### **Create Assignment**

```sql
INSERT INTO assignments (course_id, title, description, due_date, max_score)
VALUES (
  COURSE_ID_HERE,
  'Chapter 1 Quiz',
  'Complete exercises 1-10',
  NOW() + INTERVAL '7 days',
  100
);
```

### **Submit Assignment**

```sql
INSERT INTO submissions (student_id, assignment_id, content)
VALUES (
  'STUDENT_USER_ID_HERE',
  ASSIGNMENT_ID_HERE,
  'My submission content here'
);
```

### **Grade Submission**

```sql
INSERT INTO grades (submission_id, grader_id, score, comments)
VALUES (
  SUBMISSION_ID_HERE,
  'TEACHER_USER_ID_HERE',
  85,
  'Good work!'
);
```

### **View Student Grades**

```sql
SELECT 
  c.name as course,
  a.title as assignment,
  g.score,
  g.comments,
  g.graded_at
FROM grades g
JOIN submissions s ON g.submission_id = s.id
JOIN assignments a ON s.assignment_id = a.id
JOIN courses c ON a.course_id = c.id
WHERE s.student_id = 'STUDENT_USER_ID_HERE'
ORDER BY g.graded_at DESC;
```

---

## 📊 **Attendance**

### **Record Attendance**

```sql
INSERT INTO attendance (student_id, course_id, date, status, time_in)
VALUES (
  'STUDENT_USER_ID_HERE',
  COURSE_ID_HERE,
  CURRENT_DATE,
  'present',  -- or 'late', 'absent'
  NOW()
);
```

### **View Attendance Records**

```sql
SELECT 
  p.full_name as student,
  c.name as course,
  a.date,
  a.status,
  a.time_in
FROM attendance a
JOIN profiles p ON a.student_id = p.id
JOIN courses c ON a.course_id = c.id
WHERE a.student_id = 'STUDENT_USER_ID_HERE'
ORDER BY a.date DESC
LIMIT 30;
```

### **Attendance Statistics**

```sql
SELECT 
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM attendance
WHERE student_id = 'STUDENT_USER_ID_HERE'
GROUP BY status;
```

---

## 💬 **Messaging**

### **Send Message**

```sql
INSERT INTO messages (sender_id, recipient_id, content)
VALUES (
  'SENDER_USER_ID_HERE',
  'RECIPIENT_USER_ID_HERE',
  'Hello, this is a test message'
);
```

### **View Messages**

```sql
SELECT 
  sender.full_name as from_user,
  recipient.full_name as to_user,
  m.content,
  m.is_read,
  m.created_at
FROM messages m
JOIN profiles sender ON m.sender_id = sender.id
JOIN profiles recipient ON m.recipient_id = recipient.id
WHERE m.sender_id = 'USER_ID_HERE' OR m.recipient_id = 'USER_ID_HERE'
ORDER BY m.created_at DESC;
```

### **Mark as Read**

```sql
UPDATE messages
SET is_read = true, read_at = NOW()
WHERE id = MESSAGE_ID_HERE;
```

---

## 🔔 **Notifications**

### **Create Notification**

```sql
INSERT INTO notifications (recipient_id, content, notification_type, link)
VALUES (
  'USER_ID_HERE',
  'You have a new grade posted',
  'grade',
  '/grades'
);
```

### **View Unread Notifications**

```sql
SELECT content, notification_type, created_at
FROM notifications
WHERE recipient_id = 'USER_ID_HERE'
AND is_read = false
ORDER BY created_at DESC;
```

### **Mark All as Read**

```sql
UPDATE notifications
SET is_read = true, read_at = NOW()
WHERE recipient_id = 'USER_ID_HERE'
AND is_read = false;
```

---

## 👨‍👩‍👧 **Parent-Student Links**

### **Link Parent to Student**

```sql
-- First, create student record if not exists
INSERT INTO students (id, lrn, grade_level, section)
VALUES (
  'STUDENT_USER_ID_HERE',
  '123456789012',  -- 12-digit LRN
  7,
  'A'
);

-- Then link parent to student
INSERT INTO parent_students (parent_id, student_id, relationship, is_primary_guardian)
VALUES (
  'PARENT_USER_ID_HERE',
  'STUDENT_USER_ID_HERE',
  'mother',  -- or 'father', 'guardian'
  true
);
```

### **View Parent's Children**

```sql
SELECT 
  s.lrn,
  p.full_name as child_name,
  s.grade_level,
  s.section,
  ps.relationship
FROM parent_students ps
JOIN students s ON ps.student_id = s.id
JOIN profiles p ON s.id = p.id
WHERE ps.parent_id = 'PARENT_USER_ID_HERE'
AND ps.is_active = true;
```

---

## 📢 **Announcements**

### **Create Announcement**

```sql
INSERT INTO announcements (title, content, priority, target_roles, is_published)
VALUES (
  'School Year Opening',
  'Welcome to the new school year!',
  'high',
  ARRAY['student', 'parent', 'teacher'],
  true
);
```

### **View Published Announcements**

```sql
SELECT title, content, priority, created_at
FROM announcements
WHERE is_published = true
ORDER BY created_at DESC
LIMIT 10;
```

---

## 🔍 **Useful Queries**

### **Count All Records**

```sql
SELECT 
  'Users' as entity, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'Students', COUNT(*) FROM students
UNION ALL
SELECT 'Courses', COUNT(*) FROM courses
UNION ALL
SELECT 'Enrollments', COUNT(*) FROM enrollments
UNION ALL
SELECT 'Grades', COUNT(*) FROM grades
UNION ALL
SELECT 'Attendance', COUNT(*) FROM attendance
UNION ALL
SELECT 'Messages', COUNT(*) FROM messages
UNION ALL
SELECT 'Notifications', COUNT(*) FROM notifications;
```

### **View All Tables**

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

### **View RLS Policies**

```sql
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename;
```

### **Check User Permissions**

```sql
SELECT 
  r.name as role,
  p.name as permission
FROM role_permissions rp
JOIN roles r ON rp.role_id = r.id
JOIN permissions p ON rp.permission_id = p.id
WHERE r.name = 'teacher'  -- Change role as needed
ORDER BY p.name;
```

---

## 🔐 **Security Checks**

### **Test RLS as Specific User**

```sql
-- Set auth context to specific user
SELECT set_config('request.jwt.claims', 
  json_build_object('sub', 'USER_ID_HERE')::text, 
  true);

-- Now run queries to test what they can see
SELECT * FROM profiles;
SELECT * FROM courses;
SELECT * FROM grades;
```

### **Reset Auth Context**

```sql
SELECT set_config('request.jwt.claims', NULL, true);
```

### **View Current User Context**

```sql
SELECT current_setting('request.jwt.claims', true);
```

---

## 🧹 **Cleanup Operations**

### **Delete Test Data**

```sql
-- Delete all enrollments
DELETE FROM enrollments WHERE id > 0;

-- Delete all courses
DELETE FROM courses WHERE id > 0;

-- Delete all grades
DELETE FROM grades WHERE id > 0;

-- Delete all attendance
DELETE FROM attendance WHERE id > 0;

-- Delete all messages
DELETE FROM messages WHERE id > 0;

-- Delete all notifications
DELETE FROM notifications WHERE id > 0;
```

### **Reset Sequences**

```sql
-- Reset auto-increment IDs
ALTER SEQUENCE courses_id_seq RESTART WITH 1;
ALTER SEQUENCE enrollments_id_seq RESTART WITH 1;
ALTER SEQUENCE grades_id_seq RESTART WITH 1;
ALTER SEQUENCE attendance_id_seq RESTART WITH 1;
```

---

## 🐛 **Debugging**

### **Check for Orphaned Records**

```sql
-- Enrollments without valid student
SELECT e.* 
FROM enrollments e
LEFT JOIN profiles p ON e.student_id = p.id
WHERE p.id IS NULL;

-- Courses without valid teacher
SELECT c.* 
FROM courses c
LEFT JOIN profiles p ON c.teacher_id = p.id
WHERE c.teacher_id IS NOT NULL AND p.id IS NULL;
```

### **Find Duplicate Enrollments**

```sql
SELECT student_id, course_id, COUNT(*)
FROM enrollments
GROUP BY student_id, course_id
HAVING COUNT(*) > 1;
```

### **Check RLS Policy Coverage**

```sql
-- Tables without RLS enabled
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
AND tablename NOT IN (
  SELECT tablename FROM pg_policies WHERE schemaname = 'public'
);
```

---

## 📊 **Reports**

### **Student Grade Report**

```sql
SELECT 
  c.name as course,
  AVG(g.score) as average_grade,
  COUNT(g.id) as total_grades,
  MIN(g.score) as lowest,
  MAX(g.score) as highest
FROM grades g
JOIN submissions s ON g.submission_id = s.id
JOIN assignments a ON s.assignment_id = a.id
JOIN courses c ON a.course_id = c.id
WHERE s.student_id = 'STUDENT_USER_ID_HERE'
GROUP BY c.name;
```

### **Course Enrollment Report**

```sql
SELECT 
  c.name as course,
  c.grade_level,
  c.section,
  COUNT(e.id) as enrolled_students,
  p.full_name as teacher
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id AND e.status = 'active'
LEFT JOIN profiles p ON c.teacher_id = p.id
GROUP BY c.id, c.name, c.grade_level, c.section, p.full_name
ORDER BY c.grade_level, c.section;
```

### **Attendance Summary**

```sql
SELECT 
  p.full_name as student,
  COUNT(CASE WHEN a.status = 'present' THEN 1 END) as present,
  COUNT(CASE WHEN a.status = 'late' THEN 1 END) as late,
  COUNT(CASE WHEN a.status = 'absent' THEN 1 END) as absent,
  COUNT(*) as total_days
FROM attendance a
JOIN profiles p ON a.student_id = p.id
WHERE a.date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.id, p.full_name
ORDER BY p.full_name;
```

---

## 🎯 **Role IDs Reference**

| Role ID | Role Name | Description |
|---------|-----------|-------------|
| 1 | admin | Full system access |
| 2 | teacher | Manage courses and students |
| 3 | student | View courses and grades |
| 4 | parent | View children's data |
| 5 | grade_coordinator | Enhanced teacher permissions |

---

## 📱 **Flutter Integration**

### **Get Current User Profile**

```dart
final profile = await Supabase.instance.client
    .from('profiles')
    .select('*, roles(*)')
    .eq('id', Supabase.instance.client.auth.currentUser!.id)
    .single();
```

### **Get Student Courses**

```dart
final courses = await Supabase.instance.client
    .from('enrollments')
    .select('courses(*)')
    .eq('student_id', userId)
    .eq('status', 'active');
```

### **Get Student Grades**

```dart
final grades = await Supabase.instance.client
    .from('grades')
    .select('''
      *,
      submissions!inner(
        student_id,
        assignments!inner(
          *,
          courses(*)
        )
      )
    ''')
    .eq('submissions.student_id', userId);
```

---

## 🔗 **Useful Links**

- **Supabase Dashboard:** https://fhqzohvtioosycaafnij.supabase.co
- **Table Editor:** Dashboard → Table Editor
- **SQL Editor:** Dashboard → SQL Editor
- **Authentication:** Dashboard → Authentication → Users
- **Storage:** Dashboard → Storage
- **Logs:** Dashboard → Database → Logs

---

## 💡 **Pro Tips**

1. **Always test RLS policies** before deploying to production
2. **Use transactions** for related operations (e.g., create course + enroll students)
3. **Add indexes** on frequently queried columns
4. **Monitor slow queries** in Database → Logs
5. **Backup regularly** using Dashboard → Database → Backups
6. **Use prepared statements** in Flutter to prevent SQL injection
7. **Enable real-time** for messages and notifications
8. **Set up storage buckets** for file uploads
9. **Use foreign keys** to maintain data integrity
10. **Document custom functions** for future reference

---

**Quick Reference Version:** 1.0  
**Last Updated:** January 2025  
**For:** Oro Site High School ELMS
