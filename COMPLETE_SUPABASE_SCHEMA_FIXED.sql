-- ============================================
-- ORO SITE HIGH SCHOOL - ELMS DATABASE SCHEMA
-- Complete Supabase SQL Setup (FIXED VERSION)
-- ============================================
-- 
-- This script creates the complete database schema for the
-- Oro Site High School Electronic Learning Management System (ELMS)
-- 
-- INSTRUCTIONS:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Copy and paste this entire file
-- 3. Click "Run" to execute
-- 4. Verify all tables are created in the Table Editor
-- 
-- IMPORTANT: This will create all tables, indexes, triggers, and RLS policies
-- If tables already exist, you may need to drop them first or use migrations
-- ============================================

-- ============================================
-- SECTION 1: ROLES AND PERMISSIONS SYSTEM
-- ============================================

-- Roles table: Defines user roles in the system
CREATE TABLE IF NOT EXISTS public.roles (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  name TEXT NOT NULL UNIQUE
);

COMMENT ON TABLE public.roles IS 'User roles: admin, teacher, student, parent, grade_coordinator';

-- Permissions table: Defines system permissions
CREATE TABLE IF NOT EXISTS public.permissions (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  name TEXT NOT NULL UNIQUE
);

COMMENT ON TABLE public.permissions IS 'System permissions for role-based access control';

-- Role-Permission mapping: Many-to-many relationship
CREATE TABLE IF NOT EXISTS public.role_permissions (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  role_id BIGINT NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE(role_id, permission_id)
);

COMMENT ON TABLE public.role_permissions IS 'Maps permissions to roles';

-- ============================================
-- SECTION 2: USER PROFILES
-- ============================================

-- Profiles table: Core user information
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE ON UPDATE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  role_id BIGINT REFERENCES public.roles(id) ON DELETE SET NULL,
  email TEXT,
  phone TEXT,
  is_active BOOLEAN DEFAULT true NOT NULL
);

COMMENT ON TABLE public.profiles IS 'User profiles extending auth.users with role and additional info';

-- Students table: Extended student information
CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  lrn TEXT UNIQUE NOT NULL,
  grade_level INTEGER NOT NULL,
  section TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  guardian_name TEXT,
  guardian_contact TEXT,
  address TEXT,
  birth_date DATE
);

COMMENT ON TABLE public.students IS 'Extended student information including LRN and grade level';

-- Parent-Student relationships: Links parents to their children
CREATE TABLE IF NOT EXISTS public.parent_students (
  id BIGSERIAL PRIMARY KEY,
  parent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  relationship TEXT NOT NULL,
  is_primary_guardian BOOLEAN DEFAULT false NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(parent_id, student_id)
);

COMMENT ON TABLE public.parent_students IS 'Links parents to their children (students)';

-- ============================================
-- SECTION 3: ACADEMIC STRUCTURE
-- ============================================

-- Courses table: Course catalog
CREATE TABLE IF NOT EXISTS public.courses (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  teacher_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL ON UPDATE CASCADE,
  code TEXT,
  grade_level INTEGER,
  section TEXT,
  school_year TEXT,
  semester TEXT
);

COMMENT ON TABLE public.courses IS 'Course catalog with teacher assignments';

-- Enrollments table: Student-Course relationships
CREATE TABLE IF NOT EXISTS public.enrollments (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  course_id BIGINT NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE ON UPDATE CASCADE,
  status TEXT DEFAULT 'active' NOT NULL,
  enrolled_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(student_id, course_id)
);

COMMENT ON TABLE public.enrollments IS 'Tracks which students are enrolled in which courses';

-- Course Assignments table: Teacher-Course relationships (for multiple teachers per course)
CREATE TABLE IF NOT EXISTS public.course_assignments (
  id BIGSERIAL PRIMARY KEY,
  teacher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  course_id BIGINT NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'active' NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(teacher_id, course_id)
);

COMMENT ON TABLE public.course_assignments IS 'Maps teachers to courses they teach (supports multiple teachers)';

-- Section Assignments table: Class advisers
CREATE TABLE IF NOT EXISTS public.section_assignments (
  id BIGSERIAL PRIMARY KEY,
  teacher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  grade_level INTEGER NOT NULL,
  section TEXT NOT NULL,
  school_year TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(grade_level, section, school_year)
);

COMMENT ON TABLE public.section_assignments IS 'Assigns class advisers to sections';

-- Coordinator Assignments table: Grade level coordinators
CREATE TABLE IF NOT EXISTS public.coordinator_assignments (
  id BIGSERIAL PRIMARY KEY,
  teacher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  grade_level INTEGER NOT NULL,
  school_year TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(grade_level, school_year)
);

COMMENT ON TABLE public.coordinator_assignments IS 'Assigns grade level coordinators';

-- ============================================
-- SECTION 4: COURSE CONTENT
-- ============================================

-- Course Modules table: Organizational units within courses
CREATE TABLE IF NOT EXISTS public.course_modules (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  course_id BIGINT NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE ON UPDATE CASCADE,
  title TEXT NOT NULL,
  "order" INTEGER NOT NULL DEFAULT 0,
  description TEXT
);

COMMENT ON TABLE public.course_modules IS 'Modules/chapters within a course';

-- Lessons table: Individual learning units
CREATE TABLE IF NOT EXISTS public.lessons (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  title TEXT NOT NULL,
  content JSONB,
  video_url TEXT,
  module_id BIGINT NOT NULL REFERENCES public.course_modules(id) ON DELETE CASCADE ON UPDATE CASCADE,
  "order" INTEGER DEFAULT 0,
  duration_minutes INTEGER
);

COMMENT ON TABLE public.lessons IS 'Individual lessons within course modules';

-- ============================================
-- SECTION 5: ASSIGNMENTS AND SUBMISSIONS
-- ============================================

-- Assignments table: Homework and projects
CREATE TABLE IF NOT EXISTS public.assignments (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  course_id BIGINT NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE ON UPDATE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ,
  max_score NUMERIC DEFAULT 100,
  assignment_type TEXT
);

COMMENT ON TABLE public.assignments IS 'Assignments created by teachers';

-- Submissions table: Student work submissions
CREATE TABLE IF NOT EXISTS public.submissions (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  assignment_id BIGINT NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE ON UPDATE CASCADE,
  submitted_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  content TEXT,
  file_url TEXT,
  status TEXT DEFAULT 'submitted' NOT NULL,
  UNIQUE(student_id, assignment_id)
);

COMMENT ON TABLE public.submissions IS 'Student submissions for assignments';

-- ============================================
-- SECTION 6: GRADES (DepEd Compliant)
-- ============================================

-- Grades table: Academic grades with DepEd components
CREATE TABLE IF NOT EXISTS public.grades (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  submission_id BIGINT UNIQUE REFERENCES public.submissions(id) ON DELETE CASCADE ON UPDATE CASCADE,
  grader_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  score NUMERIC,
  comments TEXT,
  graded_at TIMESTAMPTZ DEFAULT NOW(),
  quarter TEXT,
  written_work NUMERIC,
  performance_task NUMERIC,
  quarterly_assessment NUMERIC,
  final_grade NUMERIC
);

COMMENT ON TABLE public.grades IS 'Academic grades with DepEd compliance (WW 30%, PT 50%, QA 20%)';

-- ============================================
-- SECTION 7: ATTENDANCE
-- ============================================

-- Attendance table: Daily attendance records
CREATE TABLE IF NOT EXISTS public.attendance (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  course_id BIGINT NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL,
  time_in TIMESTAMPTZ,
  time_out TIMESTAMPTZ,
  remarks TEXT
);

COMMENT ON TABLE public.attendance IS 'Daily attendance records for students';

-- ============================================
-- SECTION 8: COMMUNICATION
-- ============================================

-- Messages table: Direct messaging between users
CREATE TABLE IF NOT EXISTS public.messages (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false NOT NULL,
  read_at TIMESTAMPTZ,
  parent_message_id BIGINT REFERENCES public.messages(id)
);

COMMENT ON TABLE public.messages IS 'Direct messages between users';

-- Notifications table: System notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false NOT NULL,
  link TEXT,
  notification_type TEXT,
  read_at TIMESTAMPTZ
);

COMMENT ON TABLE public.notifications IS 'System notifications for users';

-- Announcements table: School-wide announcements
CREATE TABLE IF NOT EXISTS public.announcements (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  course_id BIGINT REFERENCES public.courses(id) ON DELETE CASCADE ON UPDATE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  priority TEXT DEFAULT 'normal' NOT NULL,
  target_roles TEXT[],
  grade_level INTEGER,
  is_published BOOLEAN DEFAULT false NOT NULL,
  published_at TIMESTAMPTZ
);

COMMENT ON TABLE public.announcements IS 'School-wide or course-specific announcements';

-- ============================================
-- SECTION 9: CALENDAR AND EVENTS
-- ============================================

-- Calendar Events table: School calendar
CREATE TABLE IF NOT EXISTS public.calendar_events (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  title TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  course_id BIGINT REFERENCES public.courses(id) ON DELETE CASCADE,
  description TEXT,
  event_type TEXT,
  location TEXT
);

COMMENT ON TABLE public.calendar_events IS 'School calendar events';

-- ============================================
-- SECTION 10: ADMINISTRATIVE
-- ============================================

-- Activity Log table: Audit trail
CREATE TABLE IF NOT EXISTS public.activity_log (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  details JSONB,
  ip_address TEXT,
  user_agent TEXT
);

COMMENT ON TABLE public.activity_log IS 'Audit trail of user actions';

-- Batch Upload table: Bulk operations tracking
CREATE TABLE IF NOT EXISTS public.batch_upload (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  uploader_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  upload_type TEXT NOT NULL,
  status TEXT NOT NULL,
  file_path TEXT,
  results JSONB,
  completed_at TIMESTAMPTZ
);

COMMENT ON TABLE public.batch_upload IS 'Tracks bulk upload operations';

-- Teacher Requests table: Teacher requests to admin
CREATE TABLE IF NOT EXISTS public.teacher_requests (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  teacher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  request_type TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' NOT NULL,
  reviewed_by UUID REFERENCES public.profiles(id),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT
);

COMMENT ON TABLE public.teacher_requests IS 'Teacher requests for admin approval';

-- ============================================
-- SECTION 11: SEED DATA (BEFORE INDEXES/FUNCTIONS)
-- ============================================
-- Insert seed data BEFORE creating functions that depend on it

-- Insert roles
INSERT INTO public.roles (id, name) VALUES
  (1, 'admin'),
  (2, 'teacher'),
  (3, 'student'),
  (4, 'parent'),
  (5, 'grade_coordinator')
ON CONFLICT (id) DO NOTHING;

-- Insert permissions
INSERT INTO public.permissions (name) VALUES
  ('manage_users'),
  ('manage_courses'),
  ('manage_grades'),
  ('view_reports'),
  ('manage_attendance'),
  ('send_announcements'),
  ('manage_sections'),
  ('reset_passwords'),
  ('view_all_students'),
  ('manage_enrollments'),
  ('manage_assignments'),
  ('grade_submissions'),
  ('view_analytics'),
  ('manage_calendar'),
  ('send_messages'),
  ('manage_permissions'),
  ('view_activity_logs'),
  ('manage_batch_uploads')
ON CONFLICT (name) DO NOTHING;

-- Assign all permissions to admin role
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT 1, id FROM public.permissions
ON CONFLICT DO NOTHING;

-- Assign permissions to teacher role
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT 2, p.id
FROM public.permissions p
WHERE p.name IN (
  'manage_grades',
  'manage_attendance',
  'view_reports',
  'manage_assignments',
  'grade_submissions',
  'send_messages',
  'manage_calendar'
)
ON CONFLICT DO NOTHING;

-- Assign permissions to grade coordinator
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT 5, p.id
FROM public.permissions p
WHERE p.name IN (
  'manage_grades',
  'manage_attendance',
  'view_reports',
  'reset_passwords',
  'view_all_students',
  'manage_assignments',
  'grade_submissions',
  'send_messages',
  'view_analytics',
  'manage_calendar'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- SECTION 12: INDEXES FOR PERFORMANCE
-- ============================================

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON public.profiles(is_active);

-- Students indexes
CREATE INDEX IF NOT EXISTS idx_students_lrn ON public.students(lrn);
CREATE INDEX IF NOT EXISTS idx_students_grade_section ON public.students(grade_level, section);
CREATE INDEX IF NOT EXISTS idx_students_active ON public.students(is_active);

-- Enrollments indexes
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON public.enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON public.enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON public.enrollments(status);

-- Grades indexes
CREATE INDEX IF NOT EXISTS idx_grades_submission ON public.grades(submission_id);
CREATE INDEX IF NOT EXISTS idx_grades_grader ON public.grades(grader_id);
CREATE INDEX IF NOT EXISTS idx_grades_quarter ON public.grades(quarter);

-- Attendance indexes
CREATE INDEX IF NOT EXISTS idx_attendance_student ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_course ON public.attendance(course_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_student_date ON public.attendance(student_id, date);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON public.messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient_read ON public.messages(recipient_id, is_read);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON public.notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read ON public.notifications(recipient_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(notification_type);

-- Courses indexes
CREATE INDEX IF NOT EXISTS idx_courses_teacher ON public.courses(teacher_id);
CREATE INDEX IF NOT EXISTS idx_courses_grade_section ON public.courses(grade_level, section);

-- Assignments indexes
CREATE INDEX IF NOT EXISTS idx_assignments_course ON public.assignments(course_id);
CREATE INDEX IF NOT EXISTS idx_assignments_due_date ON public.assignments(due_date);

-- Submissions indexes
CREATE INDEX IF NOT EXISTS idx_submissions_student ON public.submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_submissions_assignment ON public.submissions(assignment_id);

-- ============================================
-- SECTION 13: FUNCTIONS AND TRIGGERS
-- ============================================

-- Function: Auto-create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.email
  );
  RETURN NEW;
END;
$$;

-- Trigger: Execute handle_new_user on user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Function: Get current user's role
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT r.name INTO user_role
  FROM public.profiles p
  JOIN public.roles r ON p.role_id = r.id
  WHERE p.id = user_id;
  
  RETURN user_role;
END;
$$;

-- Function: Check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles p
    JOIN public.roles r ON p.role_id = r.id
    WHERE p.id = user_id
    AND r.name = 'admin'
  );
END;
$$;

-- Function: Check if user is teacher of a course
CREATE OR REPLACE FUNCTION public.is_course_teacher(course_id BIGINT, user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.courses c
    WHERE c.id = course_id
    AND c.teacher_id = user_id
  ) OR EXISTS (
    SELECT 1
    FROM public.course_assignments ca
    WHERE ca.course_id = course_id
    AND ca.teacher_id = user_id
    AND ca.status = 'active'
  );
END;
$$;

-- Function: Check if user is enrolled in a course
CREATE OR REPLACE FUNCTION public.is_enrolled(course_id BIGINT, user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.enrollments e
    WHERE e.course_id = course_id
    AND e.student_id = user_id
    AND e.status = 'active'
  );
END;
$$;

-- Function: Check if user is parent of a student
CREATE OR REPLACE FUNCTION public.is_parent_of(student_id UUID, parent_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.parent_students ps
    WHERE ps.student_id = student_id
    AND ps.parent_id = parent_id
    AND ps.is_active = true
  );
END;
$$;

-- ============================================
-- SECTION 14: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.section_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coordinator_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_upload ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_requests ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: PROFILES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can manage profiles" ON public.profiles;
DROP POLICY IF EXISTS "Teachers can view student profiles" ON public.profiles;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.is_admin(auth.uid()));

-- Admins can manage all profiles
CREATE POLICY "Admins can manage profiles"
  ON public.profiles FOR ALL
  USING (public.is_admin(auth.uid()));

-- Teachers can view profiles of their students
CREATE POLICY "Teachers can view student profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.enrollments e
      JOIN public.courses c ON e.course_id = c.id
      WHERE e.student_id = profiles.id
      AND (c.teacher_id = auth.uid() OR public.is_course_teacher(c.id, auth.uid()))
    )
  );

-- ============================================
-- RLS POLICIES: ROLES AND PERMISSIONS
-- ============================================

DROP POLICY IF EXISTS "Authenticated users can view roles" ON public.roles;
DROP POLICY IF EXISTS "Authenticated users can view permissions" ON public.permissions;
DROP POLICY IF EXISTS "Authenticated users can view role_permissions" ON public.role_permissions;

-- Everyone can read roles
CREATE POLICY "Authenticated users can view roles"
  ON public.roles FOR SELECT
  TO authenticated
  USING (true);

-- Everyone can read permissions
CREATE POLICY "Authenticated users can view permissions"
  ON public.permissions FOR SELECT
  TO authenticated
  USING (true);

-- Everyone can read role_permissions
CREATE POLICY "Authenticated users can view role_permissions"
  ON public.role_permissions FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- RLS POLICIES: STUDENTS
-- ============================================

DROP POLICY IF EXISTS "Students can view own data" ON public.students;
DROP POLICY IF EXISTS "Teachers can view their students" ON public.students;
DROP POLICY IF EXISTS "Parents can view their children" ON public.students;
DROP POLICY IF EXISTS "Admins can manage students" ON public.students;

-- Students can view their own data
CREATE POLICY "Students can view own data"
  ON public.students FOR SELECT
  USING (id = auth.uid());

-- Teachers can view their students
CREATE POLICY "Teachers can view their students"
  ON public.students FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.enrollments e
      JOIN public.courses c ON e.course_id = c.id
      WHERE e.student_id = students.id
      AND (c.teacher_id = auth.uid() OR public.is_course_teacher(c.id, auth.uid()))
    )
  );

-- Parents can view their children
CREATE POLICY "Parents can view their children"
  ON public.students FOR SELECT
  USING (public.is_parent_of(id, auth.uid()));

-- Admins can manage all students
CREATE POLICY "Admins can manage students"
  ON public.students FOR ALL
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: PARENT-STUDENT RELATIONSHIPS
-- ============================================

DROP POLICY IF EXISTS "Parents can view own relationships" ON public.parent_students;
DROP POLICY IF EXISTS "Students can view their parents" ON public.parent_students;
DROP POLICY IF EXISTS "Admins can manage parent relationships" ON public.parent_students;

-- Parents can view their own relationships
CREATE POLICY "Parents can view own relationships"
  ON public.parent_students FOR SELECT
  USING (parent_id = auth.uid());

-- Students can view their parent relationships
CREATE POLICY "Students can view their parents"
  ON public.parent_students FOR SELECT
  USING (student_id = auth.uid());

-- Admins can manage all relationships
CREATE POLICY "Admins can manage parent relationships"
  ON public.parent_students FOR ALL
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: COURSES
-- ============================================

DROP POLICY IF EXISTS "Teachers can view their courses" ON public.courses;
DROP POLICY IF EXISTS "Students can view enrolled courses" ON public.courses;
DROP POLICY IF EXISTS "Parents can view children courses" ON public.courses;
DROP POLICY IF EXISTS "Admins can manage courses" ON public.courses;
DROP POLICY IF EXISTS "Teachers can update own courses" ON public.courses;

-- Teachers can view courses they teach
CREATE POLICY "Teachers can view their courses"
  ON public.courses FOR SELECT
  USING (
    teacher_id = auth.uid() OR
    public.is_course_teacher(id, auth.uid())
  );

-- Students can view courses they're enrolled in
CREATE POLICY "Students can view enrolled courses"
  ON public.courses FOR SELECT
  USING (public.is_enrolled(id, auth.uid()));

-- Parents can view their children's courses
CREATE POLICY "Parents can view children courses"
  ON public.courses FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.enrollments e
      JOIN public.parent_students ps ON e.student_id = ps.student_id
      WHERE e.course_id = courses.id
      AND ps.parent_id = auth.uid()
      AND ps.is_active = true
    )
  );

-- Admins can manage all courses
CREATE POLICY "Admins can manage courses"
  ON public.courses FOR ALL
  USING (public.is_admin(auth.uid()));

-- Teachers can update their own courses
CREATE POLICY "Teachers can update own courses"
  ON public.courses FOR UPDATE
  USING (
    teacher_id = auth.uid() OR
    public.is_course_teacher(id, auth.uid())
  );

-- ============================================
-- RLS POLICIES: ENROLLMENTS
-- ============================================

DROP POLICY IF EXISTS "Students can view own enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Teachers can view course enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Parents can view children enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Admins can manage enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Teachers can manage course enrollments" ON public.enrollments;

-- Students can view their own enrollments
CREATE POLICY "Students can view own enrollments"
  ON public.enrollments FOR SELECT
  USING (student_id = auth.uid());

-- Teachers can view enrollments for their courses
CREATE POLICY "Teachers can view course enrollments"
  ON public.enrollments FOR SELECT
  USING (public.is_course_teacher(course_id, auth.uid()));

-- Parents can view their children's enrollments
CREATE POLICY "Parents can view children enrollments"
  ON public.enrollments FOR SELECT
  USING (public.is_parent_of(student_id, auth.uid()));

-- Admins can manage all enrollments
CREATE POLICY "Admins can manage enrollments"
  ON public.enrollments FOR ALL
  USING (public.is_admin(auth.uid()));

-- Teachers can manage enrollments for their courses
CREATE POLICY "Teachers can manage course enrollments"
  ON public.enrollments FOR ALL
  USING (public.is_course_teacher(course_id, auth.uid()));

-- ============================================
-- RLS POLICIES: GRADES
-- ============================================

DROP POLICY IF EXISTS "Students can view own grades" ON public.grades;
DROP POLICY IF EXISTS "Teachers can manage course grades" ON public.grades;
DROP POLICY IF EXISTS "Parents can view children grades" ON public.grades;
DROP POLICY IF EXISTS "Admins can view all grades" ON public.grades;

-- Students can view their own grades
CREATE POLICY "Students can view own grades"
  ON public.grades FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.submissions s
      WHERE s.id = grades.submission_id
      AND s.student_id = auth.uid()
    )
  );

-- Teachers can manage grades for their courses
CREATE POLICY "Teachers can manage course grades"
  ON public.grades FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM public.submissions s
      JOIN public.assignments a ON s.assignment_id = a.id
      WHERE s.id = grades.submission_id
      AND public.is_course_teacher(a.course_id, auth.uid())
    )
  );

-- Parents can view their children's grades
CREATE POLICY "Parents can view children grades"
  ON public.grades FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.submissions s
      WHERE s.id = grades.submission_id
      AND public.is_parent_of(s.student_id, auth.uid())
    )
  );

-- Admins can view all grades
CREATE POLICY "Admins can view all grades"
  ON public.grades FOR SELECT
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: ATTENDANCE
-- ============================================

DROP POLICY IF EXISTS "Students can view own attendance" ON public.attendance;
DROP POLICY IF EXISTS "Teachers can manage course attendance" ON public.attendance;
DROP POLICY IF EXISTS "Parents can view children attendance" ON public.attendance;
DROP POLICY IF EXISTS "Admins can view all attendance" ON public.attendance;

-- Students can view their own attendance
CREATE POLICY "Students can view own attendance"
  ON public.attendance FOR SELECT
  USING (student_id = auth.uid());

-- Teachers can manage attendance for their courses
CREATE POLICY "Teachers can manage course attendance"
  ON public.attendance FOR ALL
  USING (public.is_course_teacher(course_id, auth.uid()));

-- Parents can view their children's attendance
CREATE POLICY "Parents can view children attendance"
  ON public.attendance FOR SELECT
  USING (public.is_parent_of(student_id, auth.uid()));

-- Admins can view all attendance
CREATE POLICY "Admins can view all attendance"
  ON public.attendance FOR SELECT
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: ASSIGNMENTS
-- ============================================

DROP POLICY IF EXISTS "Students can view course assignments" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can manage course assignments" ON public.assignments;
DROP POLICY IF EXISTS "Parents can view children assignments" ON public.assignments;
DROP POLICY IF EXISTS "Admins can view all assignments" ON public.assignments;

-- Students can view assignments for enrolled courses
CREATE POLICY "Students can view course assignments"
  ON public.assignments FOR SELECT
  USING (public.is_enrolled(course_id, auth.uid()));

-- Teachers can manage assignments for their courses
CREATE POLICY "Teachers can manage course assignments"
  ON public.assignments FOR ALL
  USING (public.is_course_teacher(course_id, auth.uid()));

-- Parents can view their children's assignments
CREATE POLICY "Parents can view children assignments"
  ON public.assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.enrollments e
      WHERE e.course_id = assignments.course_id
      AND public.is_parent_of(e.student_id, auth.uid())
    )
  );

-- Admins can view all assignments
CREATE POLICY "Admins can view all assignments"
  ON public.assignments FOR SELECT
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: SUBMISSIONS
-- ============================================

DROP POLICY IF EXISTS "Students can manage own submissions" ON public.submissions;
DROP POLICY IF EXISTS "Teachers can view course submissions" ON public.submissions;
DROP POLICY IF EXISTS "Parents can view children submissions" ON public.submissions;
DROP POLICY IF EXISTS "Admins can view all submissions" ON public.submissions;

-- Students can manage their own submissions
CREATE POLICY "Students can manage own submissions"
  ON public.submissions FOR ALL
  USING (student_id = auth.uid());

-- Teachers can view/grade submissions for their courses
CREATE POLICY "Teachers can view course submissions"
  ON public.submissions FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.assignments a
      WHERE a.id = submissions.assignment_id
      AND public.is_course_teacher(a.course_id, auth.uid())
    )
  );

-- Parents can view their children's submissions
CREATE POLICY "Parents can view children submissions"
  ON public.submissions FOR SELECT
  USING (public.is_parent_of(student_id, auth.uid()));

-- Admins can view all submissions
CREATE POLICY "Admins can view all submissions"
  ON public.submissions FOR SELECT
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: MESSAGES
-- ============================================

DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update sent messages" ON public.messages;
DROP POLICY IF EXISTS "Admins can view all messages" ON public.messages;

-- Users can view messages they sent or received
CREATE POLICY "Users can view their messages"
  ON public.messages FOR SELECT
  USING (
    sender_id = auth.uid() OR
    recipient_id = auth.uid()
  );

-- Users can send messages
CREATE POLICY "Users can send messages"
  ON public.messages FOR INSERT
  WITH CHECK (sender_id = auth.uid());

-- Users can update messages they sent
CREATE POLICY "Users can update sent messages"
  ON public.messages FOR UPDATE
  USING (sender_id = auth.uid());

-- Admins can view all messages
CREATE POLICY "Admins can view all messages"
  ON public.messages FOR SELECT
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: NOTIFICATIONS
-- ============================================

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can manage notifications" ON public.notifications;

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (recipient_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (recipient_id = auth.uid());

-- System can insert notifications (for all authenticated users)
CREATE POLICY "System can create notifications"
  ON public.notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Admins can manage all notifications
CREATE POLICY "Admins can manage notifications"
  ON public.notifications FOR ALL
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: ANNOUNCEMENTS
-- ============================================

DROP POLICY IF EXISTS "Users can view published announcements" ON public.announcements;
DROP POLICY IF EXISTS "Teachers can manage course announcements" ON public.announcements;
DROP POLICY IF EXISTS "Admins can manage announcements" ON public.announcements;

-- Users can view published announcements
CREATE POLICY "Users can view published announcements"
  ON public.announcements FOR SELECT
  USING (
    is_published = true AND
    (
      target_roles IS NULL OR
      public.get_user_role(auth.uid()) = ANY(target_roles)
    )
  );

-- Teachers can manage announcements for their courses
CREATE POLICY "Teachers can manage course announcements"
  ON public.announcements FOR ALL
  USING (
    course_id IS NOT NULL AND
    public.is_course_teacher(course_id, auth.uid())
  );

-- Admins can manage all announcements
CREATE POLICY "Admins can manage announcements"
  ON public.announcements FOR ALL
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: CALENDAR EVENTS
-- ============================================

DROP POLICY IF EXISTS "Users can view calendar events" ON public.calendar_events;
DROP POLICY IF EXISTS "Teachers can manage course events" ON public.calendar_events;
DROP POLICY IF EXISTS "Admins can manage calendar events" ON public.calendar_events;

-- Users can view calendar events
CREATE POLICY "Users can view calendar events"
  ON public.calendar_events FOR SELECT
  TO authenticated
  USING (true);

-- Teachers can manage events for their courses
CREATE POLICY "Teachers can manage course events"
  ON public.calendar_events FOR ALL
  USING (
    course_id IS NOT NULL AND
    public.is_course_teacher(course_id, auth.uid())
  );

-- Admins can manage all events
CREATE POLICY "Admins can manage calendar events"
  ON public.calendar_events FOR ALL
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: COURSE MODULES AND LESSONS
-- ============================================

DROP POLICY IF EXISTS "Students can view course modules" ON public.course_modules;
DROP POLICY IF EXISTS "Teachers can manage course modules" ON public.course_modules;
DROP POLICY IF EXISTS "Students can view course lessons" ON public.lessons;
DROP POLICY IF EXISTS "Teachers can manage course lessons" ON public.lessons;

-- Students can view modules for enrolled courses
CREATE POLICY "Students can view course modules"
  ON public.course_modules FOR SELECT
  USING (public.is_enrolled(course_id, auth.uid()));

-- Teachers can manage modules for their courses
CREATE POLICY "Teachers can manage course modules"
  ON public.course_modules FOR ALL
  USING (public.is_course_teacher(course_id, auth.uid()));

-- Students can view lessons for enrolled courses
CREATE POLICY "Students can view course lessons"
  ON public.lessons FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.course_modules cm
      WHERE cm.id = lessons.module_id
      AND public.is_enrolled(cm.course_id, auth.uid())
    )
  );

-- Teachers can manage lessons for their courses
CREATE POLICY "Teachers can manage course lessons"
  ON public.lessons FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM public.course_modules cm
      WHERE cm.id = lessons.module_id
      AND public.is_course_teacher(cm.course_id, auth.uid())
    )
  );

-- ============================================
-- RLS POLICIES: ADMINISTRATIVE TABLES
-- ============================================

DROP POLICY IF EXISTS "Admins can view activity logs" ON public.activity_log;
DROP POLICY IF EXISTS "System can create activity logs" ON public.activity_log;
DROP POLICY IF EXISTS "Admins can manage batch uploads" ON public.batch_upload;
DROP POLICY IF EXISTS "Teachers can view own requests" ON public.teacher_requests;
DROP POLICY IF EXISTS "Teachers can create requests" ON public.teacher_requests;
DROP POLICY IF EXISTS "Admins can manage teacher requests" ON public.teacher_requests;

-- Admins can view all activity logs
CREATE POLICY "Admins can view activity logs"
  ON public.activity_log FOR SELECT
  USING (public.is_admin(auth.uid()));

-- System can insert activity logs
CREATE POLICY "System can create activity logs"
  ON public.activity_log FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Admins can manage batch uploads
CREATE POLICY "Admins can manage batch uploads"
  ON public.batch_upload FOR ALL
  USING (public.is_admin(auth.uid()));

-- Teachers can view their own requests
CREATE POLICY "Teachers can view own requests"
  ON public.teacher_requests FOR SELECT
  USING (teacher_id = auth.uid());

-- Teachers can create requests
CREATE POLICY "Teachers can create requests"
  ON public.teacher_requests FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

-- Admins can manage all requests
CREATE POLICY "Admins can manage teacher requests"
  ON public.teacher_requests FOR ALL
  USING (public.is_admin(auth.uid()));

-- ============================================
-- RLS POLICIES: COURSE ASSIGNMENTS AND SECTION ASSIGNMENTS
-- ============================================

DROP POLICY IF EXISTS "Teachers can view own course assignments" ON public.course_assignments;
DROP POLICY IF EXISTS "Admins can manage course assignments" ON public.course_assignments;
DROP POLICY IF EXISTS "Teachers can view own section assignments" ON public.section_assignments;
DROP POLICY IF EXISTS "Admins can manage section assignments" ON public.section_assignments;
DROP POLICY IF EXISTS "Teachers can view own coordinator assignments" ON public.coordinator_assignments;
DROP POLICY IF EXISTS "Admins can manage coordinator assignments" ON public.coordinator_assignments;

-- Teachers can view their own course assignments
CREATE POLICY "Teachers can view own course assignments"
  ON public.course_assignments FOR SELECT
  USING (teacher_id = auth.uid());

-- Admins can manage all course assignments
CREATE POLICY "Admins can manage course assignments"
  ON public.course_assignments FOR ALL
  USING (public.is_admin(auth.uid()));

-- Teachers can view their own section assignments
CREATE POLICY "Teachers can view own section assignments"
  ON public.section_assignments FOR SELECT
  USING (teacher_id = auth.uid());

-- Admins can manage all section assignments
CREATE POLICY "Admins can manage section assignments"
  ON public.section_assignments FOR ALL
  USING (public.is_admin(auth.uid()));

-- Teachers can view their own coordinator assignments
CREATE POLICY "Teachers can view own coordinator assignments"
  ON public.coordinator_assignments FOR SELECT
  USING (teacher_id = auth.uid());

-- Admins can manage all coordinator assignments
CREATE POLICY "Admins can manage coordinator assignments"
  ON public.coordinator_assignments FOR ALL
  USING (public.is_admin(auth.uid()));

-- ============================================
-- SECTION 15: STORAGE BUCKETS (Optional)
-- ============================================

-- Create storage buckets for file uploads
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('avatars', 'avatars', true),
  ('assignments', 'assignments', false),
  ('submissions', 'submissions', false),
  ('resources', 'resources', false)
ON CONFLICT DO NOTHING;

-- Storage RLS for avatars
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Students can upload own submissions" ON storage.objects;
DROP POLICY IF EXISTS "Students can view own submissions" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can view course submissions" ON storage.objects;

CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Storage RLS for submissions
CREATE POLICY "Students can upload own submissions"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'submissions' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Students can view own submissions"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'submissions' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Teachers can view course submissions"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'submissions' AND
    EXISTS (
      SELECT 1
      FROM public.submissions s
      JOIN public.assignments a ON s.assignment_id = a.id
      WHERE s.student_id::text = (storage.foldername(name))[1]
      AND public.is_course_teacher(a.course_id, auth.uid())
    )
  );

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ ORO SITE HIGH SCHOOL ELMS DATABASE SCHEMA CREATED SUCCESSFULLY!';
  RAISE NOTICE '';
  RAISE NOTICE '📊 Tables Created: 23';
  RAISE NOTICE '🔐 RLS Policies: 50+';
  RAISE NOTICE '⚡ Indexes: 20+';
  RAISE NOTICE '🔧 Functions: 5';
  RAISE NOTICE '📦 Storage Buckets: 4';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Next Steps:';
  RAISE NOTICE '1. Create test users in Authentication → Users';
  RAISE NOTICE '2. Assign roles to users via profiles table';
  RAISE NOTICE '3. Test your Flutter app connection';
  RAISE NOTICE '4. Verify RLS policies are working';
  RAISE NOTICE '';
  RAISE NOTICE '📚 Documentation: See SUPABASE_TABLES.md for details';
END $$;
