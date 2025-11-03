# SUPABASE TABLES PART 2 - COMPLETE DATABASE SCHEMA
## Oro Site High School ELMS - All Required Tables

**Purpose:** This document provides the COMPLETE list of all tables needed for the system, including those missing from SUPABASE_TABLES.md

**Instructions:** Create each table manually in Supabase Dashboard → Table Editor

**Total Tables:** 28 tables (18 from Part 1 + 10 additional tables below)

---

## ADDITIONAL TABLES NEEDED (Not in Part 1)

These tables are required by your services but were missing from the original SUPABASE_TABLES.md

---

### Table #19

**NAME:** students

**Purpose:** Extended student information (separate from profiles)

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | uuid | NULL | true |
| created_at | timestamptz | now() | false, none |
| lrn | text | NULL | false, isNullable, isUnique |
| grade_level | int4 | NULL | false, isNullable |
| section | text | NULL | false, isNullable |
| is_active | bool | true | false, none |
| guardian_name | text | NULL | false, isNullable |
| guardian_contact | text | NULL | false, isNullable |
| address | text | NULL | false, isNullable |
| birth_date | date | NULL | false, isNullable |

**FOREIGN KEY:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.students = id
    - public.profiles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**UNIQUE CONSTRAINT:**
- Column: lrn (Learner Reference Number must be unique)

---

### Table #20

**NAME:** parent_students

**Purpose:** Links parents to their children with detailed information

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| parent_id | uuid | NULL | false, isNullable |
| student_id | uuid | NULL | false, isNullable |
| student_lrn | text | NULL | false, isNullable |
| relationship | text | NULL | false, isNullable |
| is_primary_guardian | bool | false | false, none |
| student_first_name | text | NULL | false, isNullable |
| student_last_name | text | NULL | false, isNullable |
| student_middle_name | text | NULL | false, isNullable |
| student_grade_level | int4 | NULL | false, isNullable |
| student_section | text | NULL | false, isNullable |
| student_photo_url | text | NULL | false, isNullable |
| parent_first_name | text | NULL | false, isNullable |
| parent_last_name | text | NULL | false, isNullable |
| parent_email | text | NULL | false, isNullable |
| parent_phone | text | NULL | false, isNullable |
| is_active | bool | true | false, none |
| can_view_grades | bool | true | false, none |
| can_view_attendance | bool | true | false, none |
| can_receive_sms | bool | true | false, none |
| can_contact_teachers | bool | true | false, none |
| verified_at | timestamptz | NULL | false, isNullable |
| verified_by | uuid | NULL | false, isNullable |
| updated_at | timestamptz | now() | false, none |

**FOREIGN KEY #1:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.parent_students = parent_id
    - public.profiles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**FOREIGN KEY #2:**
- schema = public
- select a table to reference to = students
- Select columns from public.students to reference to:
    - public.parent_students = student_id
    - public.students = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**FOREIGN KEY #3:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.parent_students = verified_by
    - public.profiles = id
- Action if referenced row is updated = No action
- Action if referenced row is removed = Set NULL

**UNIQUE CONSTRAINT:**
- Columns: parent_id, student_id (one relationship per parent-student pair)

---

### Table #21

**NAME:** course_assignments

**Purpose:** Maps teachers to courses they teach (supports multiple teachers per course)

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| teacher_id | uuid | NULL | false, isNullable |
| course_id | int8 | NULL | false, isNullable |
| status | text | 'active' | false, none |
| assigned_at | timestamptz | now() | false, none |

**FOREIGN KEY #1:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.course_assignments = teacher_id
    - public.profiles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**FOREIGN KEY #2:**
- schema = public
- select a table to reference to = courses
- Select columns from public.courses to reference to:
    - public.course_assignments = course_id
    - public.courses = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**UNIQUE CONSTRAINT:**
- Columns: teacher_id, course_id (one assignment per teacher-course pair)

---

### Table #22

**NAME:** section_assignments

**Purpose:** Assigns class advisers to sections

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| teacher_id | uuid | NULL | false, isNullable |
| grade_level | int4 | NULL | false, isNullable |
| section | text | NULL | false, isNullable |
| school_year | text | NULL | false, isNullable |
| is_active | bool | true | false, none |
| assigned_at | timestamptz | now() | false, none |

**FOREIGN KEY:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.section_assignments = teacher_id
    - public.profiles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**UNIQUE CONSTRAINT:**
- Columns: grade_level, section, school_year (one adviser per section per year)

---

### Table #23

**NAME:** coordinator_assignments

**Purpose:** Assigns grade level coordinators

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| teacher_id | uuid | NULL | false, isNullable |
| grade_level | int4 | NULL | false, isNullable |
| school_year | text | NULL | false, isNullable |
| is_active | bool | true | false, none |
| assigned_at | timestamptz | now() | false, none |

**FOREIGN KEY:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.coordinator_assignments = teacher_id
    - public.profiles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**UNIQUE CONSTRAINT:**
- Columns: grade_level, school_year (one coordinator per grade level per year)

---

### Table #24

**NAME:** teacher_requests

**Purpose:** Teacher requests to admin (leave, resources, etc.)

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| teacher_id | uuid | NULL | false, isNullable |
| request_type | text | NULL | false, isNullable |
| description | text | NULL | false, isNullable |
| status | text | 'pending' | false, none |
| reviewed_by | uuid | NULL | false, isNullable |
| reviewed_at | timestamptz | NULL | false, isNullable |
| review_notes | text | NULL | false, isNullable |

**FOREIGN KEY #1:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.teacher_requests = teacher_id
    - public.profiles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**FOREIGN KEY #2:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.teacher_requests = reviewed_by
    - public.profiles = id
- Action if referenced row is updated = No action
- Action if referenced row is removed = Set NULL

---

### Table #25

**NAME:** attendance_sessions

**Purpose:** Tracks active QR scanning sessions for attendance

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| teacher_id | uuid | NULL | false, isNullable |
| course_id | int8 | NULL | false, isNullable |
| session_date | date | NULL | false, isNullable |
| start_time | timestamptz | NULL | false, isNullable |
| end_time | timestamptz | NULL | false, isNullable |
| status | text | 'active' | false, none |
| qr_code | text | NULL | false, isNullable |
| late_threshold_minutes | int4 | 15 | false, none |
| total_students | int4 | 0 | false, none |
| present_count | int4 | 0 | false, none |
| late_count | int4 | 0 | false, none |
| absent_count | int4 | 0 | false, none |

**FOREIGN KEY #1:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.attendance_sessions = teacher_id
    - public.profiles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

**FOREIGN KEY #2:**
- schema = public
- select a table to reference to = courses
- Select columns from public.courses to reference to:
    - public.attendance_sessions = course_id
    - public.courses = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

---

### Table #26

**NAME:** scanner_data

**Purpose:** Real-time QR scan data from external scanner subsystem

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| student_lrn | text | NULL | false, isNullable |
| session_id | int8 | NULL | false, isNullable |
| scan_time | timestamptz | now() | false, none |
| status | text | NULL | false, isNullable |
| processed | bool | false | false, none |

**FOREIGN KEY:**
- schema = public
- select a table to reference to = attendance_sessions
- Select columns from public.attendance_sessions to reference to:
    - public.scanner_data = session_id
    - public.attendance_sessions = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

---

### Table #27

**NAME:** scanner_sessions

**Purpose:** Configuration for scanner subsystem integration

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| session_id | text | NULL | false, isNullable |
| course_id | int8 | NULL | false, isNullable |
| status | text | 'active' | false, none |
| started_at | timestamptz | now() | false, none |
| ended_at | timestamptz | NULL | false, isNullable |

**FOREIGN KEY:**
- schema = public
- select a table to reference to = courses
- Select columns from public.courses to reference to:
    - public.scanner_sessions = course_id
    - public.courses = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

---

### Table #28

**NAME:** admin_notifications

**Purpose:** Admin-specific notifications (separate from general notifications)

| name | type | default value | Primary |
|------|------|---------------|---------|
| id | int8 | NULL | true, isIdentity |
| created_at | timestamptz | now() | false, none |
| admin_id | uuid | NULL | false, isNullable |
| title | text | NULL | false, isNullable |
| message | text | NULL | false, isNullable |
| type | text | NULL | false, isNullable |
| priority | text | 'normal' | false, none |
| is_read | bool | false | false, none |
| action_url | text | NULL | false, isNullable |
| metadata | jsonb | NULL | false, isNullable |

**FOREIGN KEY:**
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    - public.admin_notifications = admin_id
    - public.profiles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

---

## CRITICAL UPDATES TO EXISTING TABLES

### ⚠️ IMPORTANT: Update Table #15 (profiles)

**ADD THIS COLUMN to the profiles table:**

| name | type | default value | Primary |
|------|------|---------------|---------|
| role_id | int8 | NULL | false, isNullable |
| email | text | NULL | false, isNullable |
| phone | text | NULL | false, isNullable |
| is_active | bool | true | false, none |

**ADD FOREIGN KEY:**
- schema = public
- select a table to reference to = roles
- Select columns from public.roles to reference to:
    - public.profiles = role_id
    - public.roles = id
- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = Set NULL

---

## SUMMARY OF ALL 28 TABLES

### From SUPABASE_TABLES.md (Part 1):
1. activity_log
2. announcements
3. assignments
4. attendance
5. batch_upload
6. calendar_events
7. course_modules
8. courses
9. enrollments
10. grades
11. lessons
12. messages
13. notifications
14. permissions
15. profiles (⚠️ NEEDS role_id column added)
16. roles
17. role_permissions
18. submissions

### Additional Tables (Part 2):
19. students
20. parent_students
21. course_assignments
22. section_assignments
23. coordinator_assignments
24. teacher_requests
25. attendance_sessions
26. scanner_data
27. scanner_sessions
28. admin_notifications

---

## INDEXES TO CREATE (For Performance)

After creating all tables, create these indexes in SQL Editor:

```sql
-- Profiles indexes
CREATE INDEX idx_profiles_role_id ON public.profiles(role_id);
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_active ON public.profiles(is_active);

-- Students indexes
CREATE INDEX idx_students_lrn ON public.students(lrn);
CREATE INDEX idx_students_grade_section ON public.students(grade_level, section);
CREATE INDEX idx_students_active ON public.students(is_active);

-- Parent-Students indexes
CREATE INDEX idx_parent_students_parent ON public.parent_students(parent_id);
CREATE INDEX idx_parent_students_student ON public.parent_students(student_id);
CREATE INDEX idx_parent_students_active ON public.parent_students(is_active);

-- Course Assignments indexes
CREATE INDEX idx_course_assignments_teacher ON public.course_assignments(teacher_id);
CREATE INDEX idx_course_assignments_course ON public.course_assignments(course_id);
CREATE INDEX idx_course_assignments_status ON public.course_assignments(status);

-- Attendance Sessions indexes
CREATE INDEX idx_attendance_sessions_teacher ON public.attendance_sessions(teacher_id);
CREATE INDEX idx_attendance_sessions_course ON public.attendance_sessions(course_id);
CREATE INDEX idx_attendance_sessions_status ON public.attendance_sessions(status);
CREATE INDEX idx_attendance_sessions_date ON public.attendance_sessions(session_date);

-- Scanner Data indexes
CREATE INDEX idx_scanner_data_lrn ON public.scanner_data(student_lrn);
CREATE INDEX idx_scanner_data_session ON public.scanner_data(session_id);
CREATE INDEX idx_scanner_data_processed ON public.scanner_data(processed);

-- Admin Notifications indexes
CREATE INDEX idx_admin_notifications_admin ON public.admin_notifications(admin_id);
CREATE INDEX idx_admin_notifications_read ON public.admin_notifications(is_read);
CREATE INDEX idx_admin_notifications_type ON public.admin_notifications(type);
```

---

## VERIFICATION CHECKLIST

After creating all tables, verify:

- [ ] All 28 tables exist in Table Editor
- [ ] profiles table has role_id column
- [ ] All foreign keys are properly set
- [ ] All unique constraints are created
- [ ] All indexes are created
- [ ] No errors in Supabase logs

---

## NOTES

1. **Create tables in order** - Start with tables that have no dependencies (roles, permissions) then work your way to dependent tables

2. **Foreign keys matter** - Make sure referenced tables exist before creating tables that reference them

3. **Unique constraints** - Don't forget to add unique constraints where specified

4. **Default values** - Set default values as specified for each column

5. **Nullable vs Not Null** - Pay attention to which columns allow NULL values

---

**Document Version:** 2.0  
**Created:** January 2025  
**Purpose:** Complete database schema for Oro Site High School ELMS  
**Total Tables:** 28  
**Status:** Ready for manual creation in Supabase
