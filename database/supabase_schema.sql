-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.activity_log (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  user_id uuid,
  action text,
  details jsonb,
  CONSTRAINT activity_log_pkey PRIMARY KEY (id),
  CONSTRAINT activity_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.admin_notifications (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  admin_id uuid,
  title text,
  message text,
  type text,
  priority text NOT NULL DEFAULT '''normal'''::text,
  is_read boolean NOT NULL DEFAULT false,
  action_url text,
  metadata jsonb,
  CONSTRAINT admin_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT admin_notifications_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.admins (
  id uuid NOT NULL,
  employee_id text NOT NULL UNIQUE,
  first_name text NOT NULL,
  last_name text NOT NULL,
  middle_name text,
  admin_level text DEFAULT 'admin'::text CHECK (admin_level = ANY (ARRAY['super_admin'::text, 'admin'::text, 'limited_admin'::text])),
  department text DEFAULT 'Administration'::text,
  position text,
  permissions jsonb DEFAULT '[]'::jsonb,
  can_manage_users boolean DEFAULT true,
  can_manage_courses boolean DEFAULT true,
  can_manage_system boolean DEFAULT true,
  can_view_reports boolean DEFAULT true,
  phone text,
  office_location text,
  emergency_contact text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT admins_pkey PRIMARY KEY (id),
  CONSTRAINT admins_id_fkey FOREIGN KEY (id) REFERENCES public.profiles(id)
);
CREATE TABLE public.announcement_replies (
  id bigint NOT NULL DEFAULT nextval('announcement_replies_id_seq'::regclass),
  announcement_id bigint NOT NULL,
  author_id text NOT NULL,
  content text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false,
  author_id_uuid uuid,
  CONSTRAINT announcement_replies_pkey PRIMARY KEY (id),
  CONSTRAINT announcement_replies_announcement_id_fkey FOREIGN KEY (announcement_id) REFERENCES public.announcements(id),
  CONSTRAINT announcement_replies_author_id_uuid_fkey FOREIGN KEY (author_id_uuid) REFERENCES public.profiles(id),
  CONSTRAINT fk_author_uuid FOREIGN KEY (author_id_uuid) REFERENCES public.profiles(id)
);
CREATE TABLE public.announcements (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  course_id bigint,
  title text,
  content text,
  classroom_id text,
  author_id uuid,
  CONSTRAINT announcements_pkey PRIMARY KEY (id),
  CONSTRAINT announcements_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id),
  CONSTRAINT announcements_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.assignment_files (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  assignment_id bigint,
  submission_id bigint,
  file_name text NOT NULL,
  file_path text NOT NULL,
  file_size bigint NOT NULL,
  file_type text NOT NULL,
  uploaded_by uuid NOT NULL,
  description text,
  CONSTRAINT assignment_files_pkey PRIMARY KEY (id),
  CONSTRAINT assignment_files_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id),
  CONSTRAINT assignment_files_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.assignment_submissions(id),
  CONSTRAINT assignment_files_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES auth.users(id)
);
CREATE TABLE public.assignment_submissions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  assignment_id bigint NOT NULL,
  student_id uuid NOT NULL,
  classroom_id uuid NOT NULL,
  submission_content jsonb DEFAULT '{}'::jsonb,
  status text DEFAULT 'draft'::text CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'graded'::text, 'returned'::text])),
  submitted_at timestamp with time zone,
  is_late boolean DEFAULT false,
  score integer,
  max_score integer,
  feedback text,
  graded_at timestamp with time zone,
  graded_by uuid,
  attempt_number integer DEFAULT 1,
  time_spent_seconds integer DEFAULT 0,
  CONSTRAINT assignment_submissions_pkey PRIMARY KEY (id),
  CONSTRAINT assignment_submissions_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id),
  CONSTRAINT assignment_submissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES auth.users(id),
  CONSTRAINT assignment_submissions_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT assignment_submissions_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES auth.users(id)
);
CREATE TABLE public.assignments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  course_id bigint,
  title text,
  description text,
  due_date timestamp with time zone,
  classroom_id uuid,
  teacher_id uuid,
  assignment_type text,
  is_active boolean DEFAULT true,
  is_published boolean DEFAULT true,
  allow_late_submissions boolean DEFAULT true,
  content jsonb,
  total_points bigint NOT NULL CHECK (total_points > 0),
  updated_at timestamp with time zone DEFAULT now(),
  submission_count integer NOT NULL DEFAULT 0,
  quarter_no integer CHECK (quarter_no IS NULL OR quarter_no >= 1 AND quarter_no <= 4),
  component text CHECK (component IS NULL OR (component = ANY (ARRAY['written_works'::text, 'performance_task'::text, 'quarterly_assessment'::text]))),
  CONSTRAINT assignments_pkey PRIMARY KEY (id),
  CONSTRAINT assignments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.attendance (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  student_id uuid,
  course_id bigint,
  date date,
  status text,
  quarter smallint CHECK (quarter >= 1 AND quarter <= 4),
  CONSTRAINT attendance_pkey PRIMARY KEY (id),
  CONSTRAINT attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.attendance_monthly_summary (
  id bigint NOT NULL DEFAULT nextval('attendance_monthly_summary_id_seq'::regclass),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  student_id uuid NOT NULL,
  school_year text NOT NULL,
  month integer NOT NULL CHECK (month >= 1 AND month <= 12),
  school_days integer NOT NULL DEFAULT 0,
  days_present integer NOT NULL DEFAULT 0,
  days_absent integer NOT NULL DEFAULT 0,
  CONSTRAINT attendance_monthly_summary_pkey PRIMARY KEY (id),
  CONSTRAINT attendance_monthly_summary_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id)
);
CREATE TABLE public.attendance_sessions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  teacher_id uuid,
  course_id bigint,
  session_date date,
  start_time timestamp with time zone,
  end_time timestamp with time zone,
  status text NOT NULL DEFAULT '''active'''::text,
  qr_code text,
  late_threshold_minutes integer NOT NULL DEFAULT 15,
  total_students integer NOT NULL DEFAULT 0,
  present_count integer NOT NULL DEFAULT 0,
  late_count integer NOT NULL DEFAULT 0,
  absent_count integer NOT NULL DEFAULT 0,
  CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT attendance_sessions_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.profiles(id),
  CONSTRAINT attendance_sessions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.azure_ad_sync (
  id bigint NOT NULL DEFAULT nextval('azure_ad_sync_id_seq'::regclass),
  sync_type text NOT NULL,
  status text NOT NULL,
  users_synced integer DEFAULT 0,
  users_created integer DEFAULT 0,
  users_updated integer DEFAULT 0,
  errors jsonb,
  started_at timestamp with time zone DEFAULT now(),
  completed_at timestamp with time zone,
  initiated_by uuid,
  CONSTRAINT azure_ad_sync_pkey PRIMARY KEY (id),
  CONSTRAINT azure_ad_sync_initiated_by_fkey FOREIGN KEY (initiated_by) REFERENCES auth.users(id)
);
CREATE TABLE public.batch_upload (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  uploader_id uuid,
  upload_type text,
  status text,
  file_path text,
  results jsonb,
  CONSTRAINT batch_upload_pkey PRIMARY KEY (id),
  CONSTRAINT batch_upload_uploader_id_fkey FOREIGN KEY (uploader_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.calendar_events (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  title text,
  start_time timestamp with time zone,
  end_time timestamp with time zone,
  course_id bigint,
  CONSTRAINT calendar_events_pkey PRIMARY KEY (id),
  CONSTRAINT calendar_events_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.classroom_active_quarters (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  classroom_id text NOT NULL UNIQUE,
  active_quarter integer NOT NULL CHECK (active_quarter >= 1 AND active_quarter <= 4),
  set_by_teacher_id text NOT NULL,
  set_at timestamp with time zone DEFAULT now(),
  CONSTRAINT classroom_active_quarters_pkey PRIMARY KEY (id)
);
CREATE TABLE public.classroom_courses (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  classroom_id uuid NOT NULL,
  course_id integer NOT NULL,
  added_by uuid NOT NULL,
  added_at timestamp with time zone DEFAULT now(),
  CONSTRAINT classroom_courses_pkey PRIMARY KEY (id),
  CONSTRAINT classroom_courses_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id),
  CONSTRAINT classroom_courses_added_by_fkey FOREIGN KEY (added_by) REFERENCES auth.users(id),
  CONSTRAINT classroom_courses_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id)
);
CREATE TABLE public.classroom_members (
  classroom_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role text NOT NULL DEFAULT 'student'::text CHECK (role = ANY (ARRAY['student'::text, 'teacher'::text, 'assistant'::text])),
  joined_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT classroom_members_pkey PRIMARY KEY (classroom_id, user_id),
  CONSTRAINT classroom_members_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT classroom_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.classroom_students (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  classroom_id uuid NOT NULL,
  student_id uuid NOT NULL,
  enrolled_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT classroom_students_pkey PRIMARY KEY (id),
  CONSTRAINT classroom_students_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT classroom_students_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.classroom_teachers (
  classroom_id uuid NOT NULL,
  teacher_id uuid NOT NULL,
  joined_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT classroom_teachers_pkey PRIMARY KEY (classroom_id, teacher_id),
  CONSTRAINT classroom_teachers_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT classroom_teachers_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.classrooms (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  teacher_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  grade_level integer NOT NULL CHECK (grade_level >= 7 AND grade_level <= 12),
  max_students integer NOT NULL CHECK (max_students >= 1 AND max_students <= 100),
  current_students integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  access_code text UNIQUE,
  CONSTRAINT classrooms_pkey PRIMARY KEY (id),
  CONSTRAINT classrooms_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES auth.users(id)
);
CREATE TABLE public.coordinator_assignments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  teacher_id uuid,
  grade_level integer UNIQUE,
  school_year text UNIQUE,
  is_active boolean NOT NULL DEFAULT true,
  assigned_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT coordinator_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT coordinator_assignments_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.course_active_quarters (
  id bigint NOT NULL DEFAULT nextval('course_active_quarters_id_seq'::regclass),
  course_id integer NOT NULL UNIQUE,
  active_quarter integer NOT NULL CHECK (active_quarter >= 1 AND active_quarter <= 4),
  set_by_teacher_id uuid NOT NULL,
  set_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT course_active_quarters_pkey PRIMARY KEY (id),
  CONSTRAINT course_active_quarters_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.course_assignments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  teacher_id uuid UNIQUE,
  course_id bigint,
  status text NOT NULL DEFAULT '''active'''::text,
  assigned_at timestamp with time zone NOT NULL DEFAULT now(),
  uploaded_at timestamp with time zone,
  file_extension text,
  file_name text,
  file_size text,
  file_url text,
  uploaded_by text,
  CONSTRAINT course_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT course_assignments_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.profiles(id),
  CONSTRAINT course_assignments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.course_modules (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  course_id bigint,
  title text,
  order integer,
  uploaded_at timestamp with time zone,
  file_extension text,
  file_name text,
  file_size text,
  file_url text,
  uploaded_by text,
  CONSTRAINT course_modules_pkey PRIMARY KEY (id),
  CONSTRAINT course_module_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.course_schedules (
  id bigint NOT NULL DEFAULT nextval('course_schedules_id_seq'::regclass),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  course_id bigint NOT NULL,
  day_of_week text NOT NULL CHECK (day_of_week = ANY (ARRAY['Monday'::text, 'Tuesday'::text, 'Wednesday'::text, 'Thursday'::text, 'Friday'::text, 'Saturday'::text, 'Sunday'::text])),
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  room_number text,
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT course_schedules_pkey PRIMARY KEY (id),
  CONSTRAINT course_schedules_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.course_teachers (
  id integer NOT NULL DEFAULT nextval('course_teachers_id_seq'::regclass),
  course_id integer NOT NULL,
  teacher_id text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT course_teachers_pkey PRIMARY KEY (id)
);
CREATE TABLE public.courses (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  name text,
  description text,
  teacher_id uuid,
  course_code text UNIQUE,
  grade_level integer CHECK (grade_level >= 7 AND grade_level <= 12),
  section text,
  subject text,
  school_year text DEFAULT '2024-2025'::text,
  status text DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text, 'archived'::text])),
  room_number text,
  is_active boolean DEFAULT true,
  updated_at timestamp with time zone DEFAULT now(),
  title text,
  CONSTRAINT courses_pkey PRIMARY KEY (id),
  CONSTRAINT courses_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.enrollments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  student_id uuid,
  course_id bigint,
  status text DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'dropped'::text, 'completed'::text, 'pending'::text])),
  enrolled_at timestamp with time zone DEFAULT now(),
  enrollment_type text DEFAULT 'manual'::text CHECK (enrollment_type = ANY (ARRAY['manual'::text, 'auto'::text, 'section_based'::text])),
  CONSTRAINT enrollments_pkey PRIMARY KEY (id),
  CONSTRAINT enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id),
  CONSTRAINT enrollments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.final_grades (
  id bigint NOT NULL DEFAULT nextval('final_grades_id_seq'::regclass),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  student_id uuid NOT NULL,
  course_id bigint NOT NULL,
  student_name text,
  course_name text,
  school_year text NOT NULL,
  quarter_1 numeric,
  quarter_2 numeric,
  quarter_3 numeric,
  quarter_4 numeric,
  final_grade numeric NOT NULL,
  transmuted_grade text NOT NULL,
  grade_remarks text NOT NULL,
  is_passing boolean NOT NULL DEFAULT true,
  CONSTRAINT final_grades_pkey PRIMARY KEY (id),
  CONSTRAINT final_grades_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT final_grades_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.grade_coordinators (
  id uuid NOT NULL,
  employee_id text NOT NULL UNIQUE,
  first_name text NOT NULL,
  last_name text NOT NULL,
  middle_name text,
  grade_level integer NOT NULL CHECK (grade_level >= 7 AND grade_level <= 12),
  department text DEFAULT 'Academic Affairs'::text,
  subjects jsonb DEFAULT '[]'::jsonb,
  is_also_teaching boolean DEFAULT true,
  responsibilities jsonb DEFAULT '[]'::jsonb,
  managed_sections jsonb DEFAULT '[]'::jsonb,
  phone text,
  office_location text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT grade_coordinators_pkey PRIMARY KEY (id),
  CONSTRAINT grade_coordinators_id_fkey FOREIGN KEY (id) REFERENCES public.profiles(id)
);
CREATE TABLE public.grades (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  submission_id bigint NOT NULL UNIQUE,
  grader_id uuid,
  score numeric,
  comments text,
  CONSTRAINT grades_pkey PRIMARY KEY (id),
  CONSTRAINT grades_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.submissions(id),
  CONSTRAINT grades_grader_id_fkey FOREIGN KEY (grader_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.hybrid_users (
  id uuid NOT NULL,
  employee_id text NOT NULL UNIQUE,
  first_name text NOT NULL,
  last_name text NOT NULL,
  middle_name text,
  primary_role text NOT NULL CHECK (primary_role = ANY (ARRAY['admin'::text, 'teacher'::text, 'coordinator'::text, 'ict_coordinator'::text])),
  secondary_roles jsonb DEFAULT '[]'::jsonb,
  admin_level text,
  admin_permissions jsonb DEFAULT '[]'::jsonb,
  department text,
  subjects jsonb DEFAULT '[]'::jsonb,
  is_grade_coordinator boolean DEFAULT false,
  coordinator_grade_level text,
  phone text,
  office_location text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT hybrid_users_pkey PRIMARY KEY (id),
  CONSTRAINT hybrid_users_id_fkey FOREIGN KEY (id) REFERENCES public.profiles(id)
);
CREATE TABLE public.ict_coordinators (
  id uuid NOT NULL,
  employee_id text NOT NULL UNIQUE,
  first_name text NOT NULL,
  last_name text NOT NULL,
  middle_name text,
  department text DEFAULT 'ICT'::text,
  specialization text,
  certifications jsonb DEFAULT '[]'::jsonb,
  tech_skills jsonb DEFAULT '[]'::jsonb,
  is_system_admin boolean DEFAULT false,
  managed_systems jsonb DEFAULT '[]'::jsonb,
  phone text,
  emergency_contact text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ict_coordinators_pkey PRIMARY KEY (id),
  CONSTRAINT ict_coordinators_id_fkey FOREIGN KEY (id) REFERENCES public.profiles(id)
);
CREATE TABLE public.lessons (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  title text,
  content jsonb,
  video_url text,
  module_id bigint,
  CONSTRAINT lessons_pkey PRIMARY KEY (id),
  CONSTRAINT lessons_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.course_modules(id)
);
CREATE TABLE public.messages (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  sender_id uuid,
  recipient_id uuid,
  content text,
  is_read boolean DEFAULT false,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id),
  CONSTRAINT messages_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.notifications (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  recipient_id uuid,
  content text,
  is_read boolean DEFAULT false,
  link text,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.parent_student_links (
  id bigint NOT NULL DEFAULT nextval('parent_student_links_id_seq'::regclass),
  parent_id uuid NOT NULL,
  student_id uuid NOT NULL,
  relationship text NOT NULL CHECK (relationship = ANY (ARRAY['father'::text, 'mother'::text, 'guardian'::text, 'grandfather'::text, 'grandmother'::text, 'aunt'::text, 'uncle'::text, 'sibling'::text, 'other'::text])),
  is_primary_contact boolean DEFAULT false,
  is_emergency_contact boolean DEFAULT true,
  can_pickup boolean DEFAULT true,
  notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT parent_student_links_pkey PRIMARY KEY (id),
  CONSTRAINT parent_student_links_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parents(id),
  CONSTRAINT parent_student_links_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id)
);
CREATE TABLE public.parent_students (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  parent_id uuid UNIQUE,
  student_id uuid UNIQUE,
  student_lrn text,
  relationship text,
  is_primary_guardian boolean NOT NULL DEFAULT false,
  student_first_name text,
  student_last_name text,
  student_middle_name text,
  student_grade_level integer,
  student_section text,
  student_photo_url text,
  parent_first_name text,
  parent_last_name text,
  parent_email text,
  parent_phone text,
  is_active boolean NOT NULL DEFAULT true,
  can_view_grades boolean NOT NULL DEFAULT true,
  can_view_attendance boolean NOT NULL DEFAULT true,
  can_recieve_sms boolean NOT NULL DEFAULT true,
  can_contact_teachers boolean NOT NULL DEFAULT true,
  verified_at timestamp with time zone,
  verified_by uuid,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT parent_students_pkey PRIMARY KEY (id),
  CONSTRAINT parent_students_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.profiles(id),
  CONSTRAINT parent_students_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT parent_students_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.parents (
  id uuid NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  middle_name text,
  email text NOT NULL,
  phone text,
  alternate_phone text,
  address text,
  relationship_to_student text CHECK (relationship_to_student = ANY (ARRAY['father'::text, 'mother'::text, 'guardian'::text, 'grandfather'::text, 'grandmother'::text, 'aunt'::text, 'uncle'::text, 'sibling'::text, 'other'::text])),
  occupation text,
  employer text,
  work_phone text,
  is_emergency_contact boolean DEFAULT true,
  emergency_contact_priority integer DEFAULT 1,
  can_pickup_student boolean DEFAULT true,
  can_view_grades boolean DEFAULT true,
  can_receive_notifications boolean DEFAULT true,
  preferred_contact_method text DEFAULT 'email'::text CHECK (preferred_contact_method = ANY (ARRAY['email'::text, 'sms'::text, 'call'::text, 'app'::text])),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT parents_pkey PRIMARY KEY (id),
  CONSTRAINT parents_id_fkey FOREIGN KEY (id) REFERENCES public.profiles(id)
);
CREATE TABLE public.password_resets (
  id bigint NOT NULL DEFAULT nextval('password_resets_id_seq'::regclass),
  user_id uuid NOT NULL,
  reset_by uuid,
  reset_type text NOT NULL,
  new_password_hash text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT password_resets_pkey PRIMARY KEY (id),
  CONSTRAINT password_resets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT password_resets_reset_by_fkey FOREIGN KEY (reset_by) REFERENCES auth.users(id)
);
CREATE TABLE public.permissions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  name text NOT NULL UNIQUE,
  CONSTRAINT permissions_pkey PRIMARY KEY (id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL DEFAULT auth.uid(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  full_name text,
  avatar_url text,
  role_id bigint,
  email text,
  phone text,
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamp with time zone DEFAULT now(),
  azure_object_id text,
  last_login timestamp with time zone,
  azure_user_id text,
  role text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT profiles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id)
);
CREATE TABLE public.roles (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  name text NOT NULL UNIQUE,
  CONSTRAINT roles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.roles_permissions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  role_id bigint NOT NULL,
  permission_id bigint NOT NULL,
  CONSTRAINT roles_permissions_pkey PRIMARY KEY (id, role_id, permission_id),
  CONSTRAINT roles_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id),
  CONSTRAINT roles_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id)
);
CREATE TABLE public.scanner_data (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  student_lrn text,
  session_id bigint,
  scan_time timestamp with time zone NOT NULL DEFAULT now(),
  status text,
  processed boolean NOT NULL DEFAULT false,
  CONSTRAINT scanner_data_pkey PRIMARY KEY (id),
  CONSTRAINT scanner_data_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.attendance_sessions(id)
);
CREATE TABLE public.scanner_sessions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  session_id text,
  course_id bigint,
  status text NOT NULL DEFAULT '''active'''::text,
  started_at timestamp with time zone NOT NULL DEFAULT now(),
  ended_at timestamp with time zone,
  CONSTRAINT scanner_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT scanner_sessions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.scans (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  student_id text NOT NULL,
  name text,
  scan_type text NOT NULL,
  scanned_at timestamp with time zone NOT NULL,
  CONSTRAINT scans_pkey PRIMARY KEY (id)
);
CREATE TABLE public.section_assignments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  teacher_id uuid,
  grade_level integer UNIQUE,
  section text UNIQUE,
  school_year text UNIQUE,
  is_active boolean NOT NULL DEFAULT true,
  assigned_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT section_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT section_assignments_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.sf9_core_value_ratings (
  id bigint NOT NULL DEFAULT nextval('sf9_core_value_ratings_id_seq'::regclass),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  student_id uuid NOT NULL,
  recorded_by uuid NOT NULL,
  school_year text NOT NULL,
  quarter integer NOT NULL CHECK (quarter >= 1 AND quarter <= 4),
  core_value_code text NOT NULL,
  indicator_code text NOT NULL,
  rating text NOT NULL,
  CONSTRAINT sf9_core_value_ratings_pkey PRIMARY KEY (id),
  CONSTRAINT sf9_core_value_ratings_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT sf9_core_value_ratings_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.student_grades (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  classroom_id uuid NOT NULL,
  course_id bigint,
  quarter smallint NOT NULL CHECK (quarter >= 1 AND quarter <= 4),
  initial_grade numeric NOT NULL,
  transmuted_grade numeric NOT NULL,
  adjusted_grade numeric,
  plus_points numeric DEFAULT 0,
  extra_points numeric DEFAULT 0,
  remarks text,
  computed_at timestamp with time zone NOT NULL DEFAULT now(),
  computed_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  qa_score_override numeric,
  qa_max_override numeric,
  ww_weight_override numeric,
  pt_weight_override numeric,
  qa_weight_override numeric,
  CONSTRAINT student_grades_pkey PRIMARY KEY (id),
  CONSTRAINT student_grades_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.student_transfer_records (
  id bigint NOT NULL DEFAULT nextval('student_transfer_records_id_seq'::regclass),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  student_id uuid NOT NULL,
  school_year text NOT NULL,
  eligibility_for_admission_grade text,
  admitted_grade integer,
  admitted_section text,
  admission_date date,
  from_school text,
  to_school text,
  canceled_in text,
  cancellation_date date,
  created_by uuid,
  approved_by uuid,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT student_transfer_records_pkey PRIMARY KEY (id),
  CONSTRAINT student_transfer_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_transfer_records_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id),
  CONSTRAINT student_transfer_records_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.students (
  id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  lrn text UNIQUE,
  grade_level integer,
  section text,
  is_active boolean NOT NULL DEFAULT true,
  first_name text,
  middle_name text,
  last_name text,
  suffix text,
  birth_date date,
  gender text,
  birth_place text,
  email text,
  contact_number text,
  address text,
  barangay text,
  municipality text,
  province text,
  zip_code text,
  track text,
  strand text,
  school_year text DEFAULT '2025-2026'::text,
  mother_tongue text,
  indigenous_people text,
  is_4ps_beneficiary boolean DEFAULT false,
  learner_type text DEFAULT 'regular'::text,
  mother_name text,
  mother_occupation text,
  mother_contact text,
  father_name text,
  father_occupation text,
  father_contact text,
  guardian_name text,
  guardian_relationship text,
  guardian_contact text,
  user_id uuid,
  status text DEFAULT 'active'::text,
  enrollment_date date DEFAULT CURRENT_DATE,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT students_pkey PRIMARY KEY (id),
  CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT students_id_fkey FOREIGN KEY (id) REFERENCES public.profiles(id)
);
CREATE TABLE public.submissions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  assignment_id bigint,
  student_id uuid,
  submitted_at timestamp with time zone DEFAULT now(),
  content text,
  CONSTRAINT submissions_pkey PRIMARY KEY (id),
  CONSTRAINT submissions_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id),
  CONSTRAINT submissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.teacher_requests (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  teacher_id uuid,
  request_type text,
  description text,
  status text NOT NULL DEFAULT '''pending'''::text,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  review_notes text,
  CONSTRAINT teacher_requests_pkey PRIMARY KEY (id),
  CONSTRAINT teacher_requests_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.profiles(id),
  CONSTRAINT teacher_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.teachers (
  id uuid NOT NULL,
  employee_id text NOT NULL UNIQUE,
  first_name text NOT NULL,
  last_name text NOT NULL,
  middle_name text,
  department text,
  subjects jsonb DEFAULT '[]'::jsonb,
  is_grade_coordinator boolean DEFAULT false,
  coordinator_grade_level text,
  is_shs_teacher boolean DEFAULT false,
  shs_track text,
  shs_strands jsonb DEFAULT '[]'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT teachers_pkey PRIMARY KEY (id),
  CONSTRAINT teachers_id_fkey FOREIGN KEY (id) REFERENCES public.profiles(id)
);
CREATE TABLE public.users (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  lrn text NOT NULL UNIQUE,
  full_name text NOT NULL,
  email text NOT NULL UNIQUE,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);