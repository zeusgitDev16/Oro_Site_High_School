### i have total of 56 tables

1. Profiles

###COLUMNS:
    - created_at, timestampz, now()
    - full_name, text, NULL
    - avatar_url, text, NULL
    - role_id, int8, NULL
    - email, text, NULL
    - phone, text, NULL
    - is_active, bool, true
    - updated_at, timestampz, now()
    - azure_object, text, NULL
    - last_login, timestampz, NULL

###FOREIGN KEYS:
- profiles_id_fkey, relation to auth.users, id -> auth.users.id
- profiles_role_id_fkey, relation to public.roles, role_id -> public.roles.id

###RLS POLICIES:

first policy:
- policy name: profiles_delete_admin
- table on clause, public.profiles
- policy behavior, Permissive
- policy command, DELETE
- target roles, authenticated

###SQL:
alter policy "profiles_delete_admin"


on "public"."profiles"


to authenticated


using (


  is_admin()

);

second policy:
- policy name, profiles_insert_admin
- table on clause, public.profiles
- policy behavior, Permissive
- policy command, INSERT
- target roles, authenticated

###SQL:
alter policy "profiles_insert_admin"


on "public"."profiles"


to authenticated


with check (


  is_admin()

);

third policy:
- profiles_select_own_or_admin
- table on clause, public.profiles
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "profiles_select_own_or_admin"


on "public"."profiles"


to authenticated


using (


  ((auth.uid() = id) OR is_admin())

);

fourth policy:
- policy name, profiles_update_own_or_admin
- table on clause, public.profiles
- policy behavior, Permissive
- policy command, UPDATE
- target roles, authenticated

###SQL:
alter policy "profiles_update_own_or_admin"


on "public"."profiles"


to authenticated


using (


  ((auth.uid() = id) OR is_admin())

);

2. students:

###COLUMNS:
    - created_at, timestampz, now()
    - lrn, text, NULL
    - grade_level, int4, NULL
    - section, text, NULL
    - is_active, bool, true
    - first_name, text, NULL
    - middle_name, text, NULL
    - last_name, text, NULL
    - suffix, text, NULL
    - birth_date, date, NULL
    - gender, text, NULL
    - birth_place, text, NULL
    - email, text, NULL
    - contact_number, text, NULL
    - address, text, NULL
    - barangay, text, NULL
    - municipality, text, NULL
    - province, text, NULL
    - zip_code, text, NULL
    - track, text, NULL
    - strand, text, NULL
    - school_year, text, 2025-2026
    - mother_tongue, text, NULL
    - indigenous_people, text, NULL
    - is_4ps_beneficiary, bool, false
    - learner_type, text, regular
    - mother_name, text, NULL
    - mother_occupation, text, NULL
    - mother_contact, text, NULL
    - father_name, text, NULL
    - father_occupation, text, NULL
    - father_contact, text, NULL
    - guardian_name, text, NULL
    - guardian_relationship, text, NULL
    - guardian_contact, text, NULL
    - user_id, uuid, NULL
    - status, text, active
    - enrollment_date, date, CURRENT_DATE()
    - updated_at, timestampz, now()

 ###FOREIGN KEYS:
 - students_id_fkey, relation to public.profiles, id -> public.profiles.id
 - students_user_id_fkey, relation to auth.users, user_id -> auth.users.id

 ###RLS POLICIES:
 first policy:
 - policy name, students_delete_admin
 - table on clause, public.students
 - policy behavior, Permissive
 - policy command, DELETE
 - target roles, authenticated

 ###SQL:
 alter policy "students_delete_admin"


on "public"."students"


to authenticated


using (


  is_admin()

);

second policy:
- policy name, students_insert_admin
- table on clause, public.students
- policy behavior, Permissive
- policy command, INSERT
- target roles, authenticated

###SQL:
alter policy "students_insert_admin"


on "public"."students"


to authenticated


with check (


  is_admin()

);

third policy:
- policy name, students_select_own_or_admin
- table on clause, public.students
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "students_select_own_or_admin"


on "public"."students"


to authenticated


using (


  ((auth.uid() = id) OR is_admin())

);

fourth policy:
- policy name, students_update_admin
- table on clause, public.students
- policy behavior, Permissive
- policy command, UPDATE
- target roles, authenticated

###SQL:
alter policy "students_update_admin"


on "public"."students"


to authenticated


using (


  is_admin()

);

3. teachers

###COLUMNS:

    - id, uuid, NULL
    - employee_id, text, NULL
    - first_name, text, NULL
    - last_name, text, NULL
    - middle_name, text, NULL
    - department, text, NULL
    - subjects, {}jsonb, '[]'::jsonb
    - is_grade_coordinator, bool, false
    - coordinator_grade_level, text, NULL
    - is_shs_teacher, bool, false
    - shs_track, text, NULL
    - shs_strands, {}jsonb, '[]'::jsonb
    - is_active, bool, true
    - created_at, timestampz, now()
    - updated_at, timestampz, now()

###FOREIGN KEYS:
- teachers_id_fkey, relation to public.profiles, id -> public.profiles.id

###RLS POLICIES:
 - NONE

4. classrooms

###COLUMNS:
- id, uuid, uuid_generate_v4()
- teacher_id, uuid, NULL
- title, text, NULL
- description, text, NULL
- grade_level, int4, NULL
- max_students, int4, NULL
- current_students, int4, NULL
- is_active, bool, true
- created_at, timestampz, now()
- updated_at, timestampz, now()
- access_code, text, NULL

###FOREIGN KEYS:
- classrooms_teacher_id_fkey, relation to auth.users, teacher_id -> auth.users.id

###RLS POLICIES:
first policy:
- policy name, admins_view_all_classrooms
- table on clause, public.classrooms
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "admins_view_all_classrooms"


on "public"."classrooms"


to authenticated


using (

  (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text))))

);

second policy:
- policy name, co_teachers_update_joined_classrooms
- table on clause, public.classrooms
- policy behavior, Permissive
- policy command, UPDATE
- target roles, authenticated

###SQL:
alter policy "co_teachers_update_joined_classrooms"


on "public"."classrooms"


to authenticated


using (


  (EXISTS ( SELECT 1
   FROM classroom_teachers ct
  WHERE ((ct.classroom_id = classrooms.id) AND (ct.teacher_id = auth.uid()))))

) with check (


  (EXISTS ( SELECT 1
   FROM classroom_teachers ct
  WHERE ((ct.classroom_id = classrooms.id) AND (ct.teacher_id = auth.uid()))))

);

third policy:
- policy name, co_teachers_view_joined_classrooms
- table on clause, public.classrooms
- policy behavior, Permisive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "co_teachers_view_joined_classrooms"


on "public"."classrooms"


to authenticated


using (


  (EXISTS ( SELECT 1
   FROM classroom_teachers ct
  WHERE ((ct.classroom_id = classrooms.id) AND (ct.teacher_id = auth.uid()))))

);

fourth policy:
- policy name, students_search_by_access_code
- table on clause, public.classrooms
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "students_search_by_access_code"


on "public"."classrooms"


to authenticated


using (


  ((is_active = true) AND (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'student'::text)))))

);

fifth policy:
- policy name, students_view_enrolled_classrooms
- table on clause, public.classrooms
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "students_view_enrolled_classrooms"


on "public"."classrooms"


to authenticated


using (


  (EXISTS ( SELECT 1
   FROM classroom_students cs
  WHERE ((cs.classroom_id = classrooms.id) AND (cs.student_id = auth.uid()))))

);

sixth policy:
- policy name, teachers_create_classrooms
- table on clause, public.classrooms
- policy behavior, Permissive
- policy command, INSERT
- target roles, authenticated

###SQL:
alter policy "teachers_create_classrooms"


on "public"."classrooms"


to authenticated


with check (


  ((auth.uid() = teacher_id) AND (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'teacher'::text)))))

);

seventh policy:
- policy name, teachers_delete_own_classrooms
- table on clause, public.classrooms
- policy behavior, Permissive
- policy command, DELETE
- target roles, authenticated

###SQL:
alter policy "teachers_delete_own_classrooms"


on "public"."classrooms"


to authenticated


using (


  (auth.uid() = teacher_id)

);

eighth policy:
- policy name, teachers_update_own_classrooms
- table on clause, public.classrooms
- policy behavior, Permissive
- policy command, UPDATE
- target roles, authenticated

###SQL:
alter policy "teachers_update_own_classrooms"


on "public"."classrooms"


to authenticated


using (


  (auth.uid() = teacher_id)

) with check (


  (auth.uid() = teacher_id)

);

ninth policy:
- policy name, teachers_view_own_classrooms
- table on clause, public.classrooms
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "teachers_view_own_classrooms"


on "public"."classrooms"


to authenticated


using (


  (auth.uid() = teacher_id)

);

5. classroom_students

###COLUMNS:
    - id, uuid, uuid_generate_v4()
    - classroom_id, uuid, NULL
    - student_id, uuid, NULL
    - enrolled_at, timestampz, now()
    created_at, timestampz, now()

###FOREIGN KEYS:
- classroom_students_classroom_id_fkey, relation to public.classrooms, classroom_id -> public.classrooms.id
- classroom_students_student_id_fkey, relation to public.profiles, student_id -> public.profiles.id

###RLS POLICIES:
first policy:
- policy name, Teachers can add students to own classrooms 
- table on clause, public.classroom_students
- policy behavior, Permissive
- policy command, INSERT
- target roles, authenticated

###SQL:
alter policy "Teachers can add students to own classrooms"


on "public"."classroom_students"


to authenticated


with check (

  is_classroom_manager(classroom_id, auth.uid())

);

second policy:
- policy name, Teachers can remove students from own classrooms 
- table on clause, public.classroom_students
- policy behavior, Permissive
- policy command, DELETE
- target roles, authenticated

###SQL:
alter policy "Teachers can remove students from own classrooms"


on "public"."classroom_students"


to authenticated


using (


  is_classroom_manager(classroom_id, auth.uid())

);

third policy:
- policy name, Teachers can view enrollments
- table on clause, public.classroom_students
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "Teachers can view enrollments"


on "public"."classroom_students"


to authenticated


using (


  (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'teacher'::text))))

);

6. classroom_teachers

###COLUMNS:
    - classroom_id, uuid, NULL, primary key
    - teacher_id, uuid, NUll, primary key
    - joined_at, timestampz, now()
    
###FOREIGN KEYS:
- classroom_teachers_classroom_id_fkey, relation to public.classrooms, classroom_id -> public.classrooms.id
- classroom_teachers_teacher_id_fkey, relation to public.profiles, teacher_id -> public.profiles.id

###RLS POLICIES:
- NONE

### note: this table classroom_teachers has a view table named classroom_teacher_view.

7. classroom_courses

###COLUMNS:
    - id, uuid, uuid_generate_v4()
    - classroom_id, uuid, NULL
    - course_id, int4, NULL
    - added_by, uuid, NULL
    - added_at, timestampz, now()

###FOREIGN KEYS:
- classroom_courses_classroom_id_fkey, relation to public.classrooms, classroom_id -> public.classrooms.id
- classroom_courses_course_id_fkey, relation to public.courses, course_id -> public.courses.id
- classroom_courses_added_by_fkey, relation to auth.users, added_by -> auth.users.id

###RLS POLICIES:
- NONE

8. assignments

###COLUMNS:
    - id, int8, NULL, primary key
    - created_at, timestampz, now()
    - course_id, int8, NULL
    - title, text, NULL
    - description, text, NULL
    - due_date, timestampz, NULL
    - classroom_id, uuid, NULL
    - teacher_id, uuid, NULL
    - assignment_type, text, NULL
    - is_active, bool, true
    - is_published, bool, true
    - allow_late_submissions, bool, true
    - content, jsonb, '[]'::jsonb
    - total_points, int8, NULL
    - updated_at, timestampz, now()
    - submission_count, int4, 0
    - quarter_no, int4, NULL
    - component, text, NULL

###FOREIGN KEYS:
- assignments_course_id_fkey, relation to public.courses, course_id -> public.courses.id

###RLS POLICIES:
first policy:
- policy name, assignments_delete_admin
- table on clause, public.assignments
- policy behavior, Permissive
- policy command, DELETE
- target roles, authenticated

###SQL:
alter policy "assignments_delete_admin"


on "public"."assignments"


to authenticated


using (

  is_admin()

);

second policy:
- policy name, assignments_insert_admin
- table on clause, public.assignments
- policy behavior, Permissive
- policy command, INSERT
- target roles, authenticated

###SQL:
alter policy "assignments_insert_admin"


on "public"."assignments"


to authenticated


with check (

  is_admin()

);

third policy:
- policy name, assignments_select_all
- table on clause, public.assignments
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "assignments_select_all"


on "public"."assignments"


to authenticated


using (

  true

);

fourth policy:
- policy name, assignments_update_admin
- table on clause, public.assignments
- policy behavior, Permissive
- policy command, UPDATE
- target roles, authenticated

###SQL:
alter policy "assignments_update_admin"


on "public"."assignments"


to authenticated


using (

  is_admin()

);

9. assignment_submissions

###COLUMNS:
    - id, int8, NULL, primary key
    - created_at, timestampz, now()
    - updated_at, timestampz, now()
    - assignment_id, int8, NULL
    - student_id, uuid, NULL
    - classroom_id, uuid, NULL
    - submission_content, jsonb, '[]'::jsonb
    - status, text, 'draft'::text
    - submitted_at, timestampz, NULL
    - is_late, bool, false
    - score, int4, NULL
    - max_score, int4, NULL
    - feedback, text, NULL
    - graded_at, timestampz, NULL
    - graded_by, uuid, NULL
    - attempt_number, int4, 1
    - time_spent_seconds, int4, 0

###FOREIGN KEYS:
- assignment_submissions_assignment_id_fkey, relation to public.assignments, assignment_id -> public.assignments.id
- assignment_submissions_student_id_fkey, relation to auth.users, student_id -> auth.users.id
- assignment_submissions_classroom_id_fkey, relation to public.classrooms, classroom_id -> public.classrooms.id
- assignment_submissions_graded_by_fkey, relation to auth.users, graded_by -> auth.users.id

###RLS POLICIES:
- NONE

10. assignment_files

###COLUMNS:
    - id, int8, NULL, primary key
    - created_at, timestampz, now()
    - assignment_id, int8, NULL
    - submission_id, int8, NULL
    - file_name, text, NULL
    - file_path, text, NULL
    - file_size, int8, NULL
    - file_type, text, NULL
    - uploaded_by, uuid, NULL
    - description, text, NULL

###FOREIGN KEYS:
- assignment_files_assignment_id_fkey, relation to public.assignments, assignment_id -> public.assignments.id
- assignment_files_submission_id_fkey, relation to public.assignment_submissions, submission_id -> public.assignment_submissions.id
- assignment_files_uploaded_by_fkey, relation to auth.users, uploaded_by -> auth.users.id

###RLS POLICIES:
- NONE

11. student_grades

###COLUMNS:
    - id, uuid, get_random_uuid(), primary key
    - student_id, uuid, NULL
    - classroom_id, uuid, NULL
    - course_id, int8, NULL
    - quarter, int2, NULL
    - initial_grade, numeric, NULL
    - transmuted_grade, numeric, NULL
    - adjusted_grade, numeric, NULL
    - plus_points, numeric, 0
    - extra_points, numeric, 0
    - remarks, text, NULL
    - computed_at, timestampz, now()
    - computed_by, uuid, NULL
    - created_at, timestampz, now()
    - updated_at, timestampz, now()
    - qa_score_override, numeric, NULL
    - qa_max_override, numeric, NULL
    - ww_weight_override, numeric, NULL
    - pt_weight_override, numeric, NULL
    - qa_weight_override, numeric, NULL

###FOREIGN KEYS:
- student_grades_course_id_fkey, relation to public.courses, course_id -> public.courses.id

###RLS POLICIES:
- NONE

12. attendance

###COLUMNS:
    - id, int8, NULL, primary key
    - created_at, timestampz, now()
    - student_id, uuid, NULL
    - course_id, int8, NULL
    - date, date, NULL
    - status, text, NULL
    - quarter, int2, NULL

###FOREIGN KEYS:
- attendance_student_id_fkey, relation to public.profiles, student_id -> public.profiles.id

###RLS POLICIES:
first policy:
- policy name, attendance_insert_admin
- table on clause, public.attendance
- policy behavior, Permissive
- policy command, INSERT
- target roles, authenticated

###SQL:
alter policy "attendance_insert_admin"


on "public"."attendance"


to authenticated


with check (


  is_admin()

);

second policy:
- policy name, attendance_select_own_or_admin
- table on clause, public.attendance
- policy behavior, Permissive
- policy command, SELECT
- target roles, authenticated

###SQL:
alter policy "attendance_select_own_or_admin"


on "public"."attendance"


to authenticated


using (


  ((student_id = auth.uid()) OR is_admin())

);

third policy:
- policy name, attendance_update_admin
- table on clause, public.attendance
- policy behavior, Permissive
- policy command, UPDATE
- target roles, authenticated

###SQL:
alter policy "attendance_update_admin"


on "public"."attendance"


to authenticated


using (


  is_admin()

);

13. attendance_sessions

###COLUMNS:
    - id, int8, NULL, primary key
    - created_at, timestampz, now()
    - teacher_id, uuid, NULL
    - course_id, int8, NULL
    - session_date, date, NULL
    - start_time, timestampz, NULL
    - end_time, timestampz, NULL
    - status, text, 'active'::text
    - qr_code, text, NULL
    - late_threshold_minutes, int4, 15
    - total_students, int4, 0
    - present_count, int4, 0
    - late_count, int4, 0
    - absent_count, int4, 0

###FOREIGN KEYS:
- attendance_sessions_teacher_id_fkey, relation to public.profiles, teacher_id -> public.profiles.id
- attendance_sessions_course_id_fkey, relation to public.courses, course_id -> public.courses.id

###RLS POLICIES:
- NONE

14. course_active_quarters

###COLUMNS:
    - id, int8, nextval('course_active_quarters_id_seq'::regclass), primary key
    - course_id, int4, NULL, unique
    - active_quarter, int4, NULL
    - set_by_teacher_id, uuid, NULL
    - set_at, timestampz, now()

###FOREIGN KEYS:
- course_active_quarters_course_id_fkey, relation to public.courses, course_id -> public.courses.id

###RLS POLICIES:
-NONE

15. classroom_active_quarters

###COLUMNS:
    - id, uuid, get_random_uuid(), primary key
    - classroom_id, text, NULL, unique
    - active_quarter, int4, NULL
    - set_by_teacher_id, text, NULL
    - set_at, timestampz, now()

###FOREIGN KEYS:
- NONE

###RLS POLICIES:
- NONE

### this is the first 15 crucial tables as per your requested.


  16. announcements

  ###COLUMNS:
    - id, int8, NULL, primary key
    - course_id, int8, NULL
    - title, text, NULL
    - content, text, NULL
    - created_at, timestampz, now()
    - classroom_id, text, NULL
    - author_id, uuid, NULL

  ###FOREIGN KEYS:
  - announcements_course_id_fkey, relation to public.courses, course_id -> public.courses.id
  - announcements_author_id_fkey, relation to auth.users, author_id -> auth.users.id

  ###RLS POLICIES:
  - NONE

  17. announcement_replies

  ###COLUMNS:
    - id, int8, NULL, primary key
    - announcement_id, int8, NULL
    - author_id, text, NULL
    - content, text, NULL
    - created_at, timestampz, now()
    - is_deleted, bool, false
    - author_id_uuid, uuid, NULL

  ###FOREIGN KEYS:
  - announcement_replies_announcement_id_fkey, relation to public.announcements, announcement_id -> public.announcements.id
  - announcement_replies_author_id_uuid_fkey, relation to public.profiles, author_id_uuid -> public.profiles.id
  - fk_author_uuid, relation to public.profiles, author_id_uuid -> public.profiles.id

  ###RLS POLICIES:
  - NONE








