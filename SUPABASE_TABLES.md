# this document describes my current supabase tables, your goal is to analyze if the tables is now ready for connection or should we enhance it further.

table #1

NAME: activity_log

 name:             type:           default value:          Primary:
 id                 int8            NULL                true, isIdentity
 created_at         timestamptz     now()               false, none
 user_id            uuid            NULL                false, isNullable
 action             text            NULL                false, isNullable
 details            jsonb           NULL                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    public.activity_log = user_id
    public.profiles = id

- Action if referenced row is updated = No action
- Action if referenced row is removed = Set NULL

table #2

NAME: announcements

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 course_id      int8                NULL                false, isNullable
 title          text                NULL                false, isNullable
 content        text                NULL                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = courses
- Select columns from public.courses to reference to:
    public.announcements = course_id
    public.courses = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

table #3

Name: assignments

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 course_id      int8                NULL                false, isNullable
 title          text                NULL                false, isNullable
 description    text                NULL                false, isNullable
 due_date       timestamptz         NULL                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = courses
- Select columns from public.courses to reference to:
    public.assignments = course_id
    public.courses = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

table #4

Name: attendance

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 student_id     uuid                NULL                false, isNullable
 course_id      int8                NULL                false, isNullable
 date           date                NULL                false, isNullable
 status         text                NULL                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = profiles
- Select columns from public.profiles to reference to:
    public.attendance = student_id
    public.profiles = id

- Action if referenced row is updated = No action
- Action if referenced row is removed = CASCADE

table #5

NAME: batch_upload

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 uploader_id    uuid                NULL                false, isNullable
 upload_type    text                NULL                false, isNullable
 status         text                NULL                false, isNullable
 file_path      text                NULL                false, isNullable
 results        jsonb               NULL                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = profiles
- select columns from public.profiles to reference to:
    public.batch_upload = uploader_id
    public.profiles = id

- Action if referenced row is updated = No action
- Action if referenced row is removed = Set NULL

table #6

NAME: calendar_events

 name:          type:               default value:          Primary:
 id             int8                null                true, isIdentity
 created_at     timestamptz         now()               false, none
 title          text                null                false, isNullable
 start_time     timestamptz         null                false, isNullable
 end_time       timestamptz         null                false, isNullable
 course_id      int8                null                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = courses
- select columns from public.courses to reference to:
    public.calendar_events = course_id
    public.courses = id

- Action if referenced row is updated = No action
- Action if referenced row is removed = CASCADE

table #7

NAME: course_modules

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 course_id      int8                NULL                false, isNullable
 title          text                null                false, isNullable
 order          int4                NULL                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = courses
- select columns from public.courses to reference to:
    public.course_modules = course_id
    public.courses = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

table #8

NAME: courses

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestampz           now()               false, none
 name           text                NULL                false, isNullable
 description    text                NULL                false, isNullable
 teacher_id     uuid                NULL                false, isNullable

 FOREIGN KEY:
 - schema = public
 - select a table to reference to = profiles
 - select columns from public.profiles to reference to:
    public.courses = teacher_id
    public.profiles = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = Set NULL

table #9

NAME: enrollments

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestampz          now()               false, none
 student_id     uuid                NULL                false, isNullable
 course_id      int8                NULL                false, isNullable

 FOREIGN KEY:
 - schema = public
 - select a table to reference to = profiles
 - select columns from public.profiles to reference to:
    public.enrollments = student_id
    public.profiles = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

FOREIGN KEY#2:
- schema = public
- select a table to reference to = courses
- select columns from public.courses to reference to:
    public.enrollments = course_id
    public.courses = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

table #10

NAME: grades

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 submission_id  int8                NULL                false, isUnique
 grader_id      uuid                NULL                false, isNullable
 score          numeric             NULL                false, isNullable
 comments       text                NULL                false, isNullable

 FOREIGN KEY:
 - schema = public
 - select a table to reference to = submissions
 - select columns from public.submissions to reference to:
    public.grades = submission_id
    public.submissions = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

FOREIGN KEY#2
- schema = public
- select a table to reference to = profiles
- select columns from public.profiles to reference to:
    public.grades = grader_id
    public.profiles = id

- Action if referenced row is updated = No action
- Action if referenced row is removed = Set NULL

table #11

NAME: lessons

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 title          text                NULL                false, isNullable
 content        jsonb               NULL                false, isNullable
 video_url      text                NULL                false, isNullable
 module_id      int8                NULL                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = course_modules
- select columns from public.course_modules to reference to:
    public.lessons = module_id
    public.course_modules = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

table #12

NAME: messages

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 sender_id      uuid                NULL                false, isNullable
 recipient_id   uuid                NULL                false, isNullable
 content        text                NULL                false, isNullable
 is_read        bool                false               false, isNullable

 FOREIGN KEY:
 - schema = public
 - select a table to reference to = profiles
 - select columns from public.profiles to reference to:
    public.messages = sender_id
    public.profiles = id

- Action if referenced row is updated = No action
- Action if referenced row is removed = Set NUll

FOREIGN KEY#2
- schema = public
- select a table to reference to = profiles
- select columns from public.profiles to reference to:
    public.messages = recipient_id
    public.profiles = id

- Action if referenced row is updated = No action
- Action if referenced row is removed = CASCADE

table #13

NAME: notifications

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 recipient_id   uuid                NULL                false, isNullable
 content        text                NULL                false, isNullable
 is_read        bool                false               false, isNullable
 link           text                NULL                false, isNullable

FOREIGN KEY:
- schema = public
- select a table to reference to = profiles
- select columns from public.profiles to reference to:
    public.notifications = recipient_id
    public.profiles = id

- Action if referenced row is updated = No action
- Action if referenced row is removed = CASCADE

table #14

NAME: permissions

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 name           text                NULL                false, isNullable

table #15

NAME: profiles

 name:          type:               default value:          Primary:
 id             uuid                auth.uid()          true
 created_at     timestamptz         now()               false, none
 full_name      text                NULL                false, isNullable
 avatar_url     text                NULL                false, isNullable
 
 FOREIGN KEY:
 - schema = auth
 - select a table to reference to = users
 - select columns from auth.users to reference to:
    public.profiles = id
    auth.users = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

table #16

NAME: roles

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 name           text                NULL                false, isNullable

 table #17

 NAME: role_permissions

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 role_id        int8                NULL                true
 permission_id  int8                NULL                true

 FOREIGN KEY:
 - schema = public
 - select a table to reference to = roles
 - select columns from public.roles to reference to:
    public.role_permissions = role_id
    public.roles = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

FOREIGN KEY#2
- schema = public
- select a table to reference to = permissions
- select columns from public.permissions to reference to:
    public.role_permissions = permission_id
    public.permissions = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

table #18

NAME: submissions

 name:          type:               default value:          Primary:
 id             int8                NULL                true, isIdentity
 created_at     timestamptz         now()               false, none
 student_id     uuid                NULL                false, isNullable
 assignment_id  int8                NULL                false, isNullable
 submitted_at   timestamptz         now()               false, isNullable
 content        text                NULL                false, isNullable

 FOREIGN KEY:
 - schema = public
 - select a table to reference to = assignments
 - select columns from public.assignments to reference to:
    public.submissions = assignment_id
    public.assignments = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE

FOREIGN KEY#2
- schema = public
- select a table to reference to = profiles
- select columns from public.profiles to reference to:
    public.submissions = student_id
    public.profiles = id

- Action if referenced row is updated = CASCADE
- Action if referenced row is removed = CASCADE









 










