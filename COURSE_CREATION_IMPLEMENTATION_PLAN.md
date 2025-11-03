# 🎓 Course Creation Feature - Complete Implementation Plan

## 📋 Executive Summary

**Goal**: Implement a fully functional "Create Course" feature that integrates with Supabase backend, fetches real teachers, supports section assignment with auto-enrollment, manual scheduling, and course status management—all aligned with DepEd Philippines K-12 curriculum standards.

**Timeline**: 6-8 hours (broken into manageable steps)  
**Priority**: CRITICAL for thesis defense  
**Status**: Planning Phase Complete ✅

---

## 🎯 Feature Requirements (Based on UI Mockup)

### 1. **Basic Information Section**
- ✅ Course Name (text input, required)
- ✅ Course Code (text input, unique, uppercase, required)
- ✅ Description (multiline text, optional)
- ✅ Grade Level (dropdown: 7-12, required)
- ✅ Subject (dropdown: DepEd subjects, required)

### 2. **Teacher Assignment Section**
- ⚠️ **NEEDS BACKEND**: Fetch real teachers from Supabase `profiles` + `teachers` tables
- ✅ Display teacher names as selectable chips
- ✅ Support multiple teacher assignment
- ✅ Validation: At least one teacher required

### 3. **Section Assignment Section**
- ⚠️ **NEEDS BACKEND**: Fetch sections based on selected grade level
- ✅ Dynamic section loading (depends on grade level selection)
- ✅ Multiple section selection
- ⚠️ **NEEDS BACKEND**: Auto-enroll all students in selected sections

### 4. **Schedule Section**
- ✅ Add multiple schedules (day, start time, end time, room)
- ✅ Display schedule list with delete option
- ✅ Empty state when no schedules added

### 5. **Course Status Section**
- ✅ Active/Inactive toggle switch
- ✅ Status description (visible/hidden, enrollment enabled/disabled)

### 6. **Action Buttons**
- ✅ Save Draft (optional, for later)
- ✅ Cancel (with unsaved changes warning)
- ⚠️ **NEEDS BACKEND**: Create Course (save to Supabase)

---

## 🗄️ Database Analysis

### Current Tables (from SUPABASE_TABLES.md & SUPABASE_TABLES_PART2.md)

#### **Table: `courses`** (Table #8)
```
Columns:
- id (int8, primary key, auto-increment)
- created_at (timestamptz, default: now())
- name (text, nullable)
- description (text, nullable)
- teacher_id (uuid, nullable, FK → profiles.id)
```

**⚠️ MISSING COLUMNS NEEDED:**
- `course_code` (text, unique, required)
- `grade_level` (int4, required)
- `section` (text, nullable) - OR use junction table
- `subject` (text, required)
- `school_year` (text, required, e.g., "2024-2025")
- `status` (text, default: 'active') - 'active' or 'inactive'
- `room_number` (text, nullable)
- `is_active` (bool, default: true)
- `updated_at` (timestamptz, default: now())

#### **Table: `enrollments`** (Table #9)
```
Columns:
- id (int8, primary key, auto-increment)
- created_at (timestamptz, default: now())
- student_id (uuid, FK → profiles.id)
- course_id (int8, FK → courses.id)
```

**⚠️ MISSING COLUMNS NEEDED:**
- `status` (text, default: 'active') - 'active', 'dropped', 'completed'
- `enrolled_at` (timestamptz, default: now())
- `enrollment_type` (text) - 'manual', 'auto', 'section_based'

#### **Table: `course_assignments`** (Table #21 - EXISTS!)
```
Columns:
- id (int8, primary key)
- created_at (timestamptz)
- teacher_id (uuid, FK → profiles.id)
- course_id (int8, FK → courses.id)
- status (text, default: 'active')
- assigned_at (timestamptz)
```
✅ **This table is perfect for multi-teacher assignment!**

#### **Table: `students`** (Table #19 - EXISTS!)
```
Columns:
- id (uuid, primary key, FK → profiles.id)
- lrn (text, unique)
- grade_level (int4)
- section (text)
- is_active (bool)
- ... (other fields)
```
✅ **Perfect for querying students by grade_level + section**

#### **Table: `teachers`** (NEEDS VERIFICATION)
Based on `profile_service.dart`, this table should exist with:
```
Columns:
- id (uuid, primary key, FK → profiles.id)
- employee_id (text)
- full_name (text)
- department (text)
- subjects (text[] or jsonb)
- is_active (bool)
- ... (other fields)
```

#### **NEW TABLE NEEDED: `course_schedules`**
```sql
CREATE TABLE course_schedules (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  course_id BIGINT REFERENCES courses(id) ON DELETE CASCADE,
  day_of_week TEXT NOT NULL, -- 'Monday', 'Tuesday', etc.
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room_number TEXT,
  is_active BOOLEAN DEFAULT TRUE
);
```

---

## 🔧 Required Database Modifications

### **Step 1: Alter `courses` Table**

```sql
-- Add missing columns to courses table
ALTER TABLE courses
ADD COLUMN course_code TEXT UNIQUE NOT NULL DEFAULT '',
ADD COLUMN grade_level INT4,
ADD COLUMN section TEXT,
ADD COLUMN subject TEXT,
ADD COLUMN school_year TEXT DEFAULT '2024-2025',
ADD COLUMN status TEXT DEFAULT 'active',
ADD COLUMN room_number TEXT,
ADD COLUMN is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create index for faster queries
CREATE INDEX idx_courses_grade_level ON courses(grade_level);
CREATE INDEX idx_courses_subject ON courses(subject);
CREATE INDEX idx_courses_status ON courses(status);
CREATE INDEX idx_courses_school_year ON courses(school_year);
CREATE INDEX idx_courses_code ON courses(course_code);

-- Add constraint to ensure valid grade levels (7-12)
ALTER TABLE courses
ADD CONSTRAINT check_grade_level CHECK (grade_level >= 7 AND grade_level <= 12);

-- Add constraint for status values
ALTER TABLE courses
ADD CONSTRAINT check_status CHECK (status IN ('active', 'inactive', 'archived'));
```

### **Step 2: Alter `enrollments` Table**

```sql
-- Add missing columns to enrollments table
ALTER TABLE enrollments
ADD COLUMN status TEXT DEFAULT 'active',
ADD COLUMN enrolled_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN enrollment_type TEXT DEFAULT 'manual';

-- Create indexes
CREATE INDEX idx_enrollments_status ON enrollments(status);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);

-- Add constraint for status values
ALTER TABLE enrollments
ADD CONSTRAINT check_enrollment_status CHECK (status IN ('active', 'dropped', 'completed', 'pending'));

-- Add constraint for enrollment type
ALTER TABLE enrollments
ADD CONSTRAINT check_enrollment_type CHECK (enrollment_type IN ('manual', 'auto', 'section_based'));

-- Prevent duplicate enrollments
CREATE UNIQUE INDEX idx_unique_enrollment ON enrollments(student_id, course_id) WHERE status = 'active';
```

### **Step 3: Create `course_schedules` Table**

```sql
-- Create course schedules table
CREATE TABLE course_schedules (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  day_of_week TEXT NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room_number TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_course_schedules_course ON course_schedules(course_id);
CREATE INDEX idx_course_schedules_day ON course_schedules(day_of_week);

-- Add constraint for valid days
ALTER TABLE course_schedules
ADD CONSTRAINT check_day_of_week CHECK (
  day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
);

-- Add constraint to ensure end_time > start_time
ALTER TABLE course_schedules
ADD CONSTRAINT check_time_order CHECK (end_time > start_time);
```

### **Step 4: Verify `teachers` Table Exists**

```sql
-- Check if teachers table exists and has required columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'teachers';

-- If missing, create it (based on profile_service.dart logic)
CREATE TABLE IF NOT EXISTS teachers (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  employee_id TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  department TEXT,
  subjects JSONB, -- Array of subjects
  is_grade_coordinator BOOLEAN DEFAULT FALSE,
  coordinator_grade_level TEXT,
  is_shs_teacher BOOLEAN DEFAULT FALSE,
  shs_track TEXT,
  shs_strands JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_teachers_active ON teachers(is_active);
CREATE INDEX idx_teachers_department ON teachers(department);
```

---

## 📝 Code Files to Modify/Create

### **1. Models**

#### **A. Enhance `lib/models/course.dart`**

**Current State**: Basic model with only `id`, `name`, `description`, `teacherId`

**Required Changes**:
```dart
class Course {
  final int id;
  final DateTime createdAt;
  final String name;
  final String courseCode; // NEW
  final String? description;
  final int gradeLevel; // NEW
  final String? section; // NEW (nullable if multi-section)
  final String subject; // NEW
  final String schoolYear; // NEW
  final String status; // NEW ('active', 'inactive')
  final String? roomNumber; // NEW
  final bool isActive; // NEW
  final String? teacherId; // Keep for backward compatibility
  final DateTime updatedAt; // NEW

  // Constructor, fromMap, toMap methods need updating
}
```

#### **B. Create `lib/models/course_schedule.dart`**

```dart
class CourseSchedule {
  final int id;
  final int courseId;
  final String dayOfWeek;
  final String startTime; // Store as "HH:mm" format
  final String endTime;
  final String? roomNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor, fromMap, toMap, etc.
}
```

#### **C. Create `lib/models/teacher.dart`** (if not exists)

```dart
class Teacher {
  final String id; // UUID from profiles
  final String employeeId;
  final String fullName;
  final String? department;
  final List<String> subjects;
  final bool isGradeCoordinator;
  final String? coordinatorGradeLevel;
  final bool isSHSTeacher;
  final String? shsTrack;
  final List<String>? shsStrands;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor, fromMap, toMap, etc.
}
```

---

### **2. Services**

#### **A. Enhance `lib/services/course_service.dart`**

**Current State**: Basic CRUD (getCourses, getCourseById, createCourse)

**Required Methods**:

```dart
class CourseService {
  final _supabase = Supabase.instance.client;

  // ============================================
  // CREATE OPERATIONS
  // ============================================

  /// Create course with full details
  Future<Course> createCourse({
    required String name,
    required String courseCode,
    String? description,
    required int gradeLevel,
    String? section,
    required String subject,
    required String schoolYear,
    String status = 'active',
    String? roomNumber,
    bool isActive = true,
    required List<String> teacherIds, // Multiple teachers
    List<String>? sectionIds, // Multiple sections for auto-enrollment
    List<Map<String, dynamic>>? schedules, // Schedule data
  }) async {
    // 1. Validate course code uniqueness
    // 2. Insert into courses table
    // 3. Insert teacher assignments into course_assignments
    // 4. Insert schedules into course_schedules
    // 5. Auto-enroll students if sections provided
    // 6. Return created course
  }

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Get all courses with filters
  Future<List<Course>> getCourses({
    int? gradeLevel,
    String? subject,
    String? status,
    String? schoolYear,
  }) async {
    // Query with filters
  }

  /// Get course by ID with full details (teachers, schedules, enrollments)
  Future<Course?> getCourseById(int id) async {
    // Join with course_assignments, course_schedules
  }

  /// Get courses by teacher
  Future<List<Course>> getCoursesByTeacher(String teacherId) async {
    // Join with course_assignments
  }

  /// Get courses by student (enrolled courses)
  Future<List<Course>> getCoursesByStudent(String studentId) async {
    // Join with enrollments
  }

  /// Get courses by grade and section
  Future<List<Course>> getCoursesByGradeSection(int grade, String section) async {
    // Filter by grade_level and section
  }

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  /// Update course details
  Future<void> updateCourse(int courseId, Map<String, dynamic> updates) async {
    // Update courses table
  }

  /// Assign teacher to course
  Future<void> assignTeacher(int courseId, String teacherId) async {
    // Insert into course_assignments
  }

  /// Remove teacher from course
  Future<void> removeTeacher(int courseId, String teacherId) async {
    // Delete from course_assignments or set status='inactive'
  }

  // ============================================
  // DELETE OPERATIONS
  // ============================================

  /// Delete course (soft delete - set status='archived')
  Future<void> deleteCourse(int courseId) async {
    // Update status to 'archived'
  }

  // ============================================
  // ENROLLMENT OPERATIONS
  // ============================================

  /// Auto-enroll students by section
  Future<void> enrollStudentsBySection({
    required int courseId,
    required int gradeLevel,
    required String section,
  }) async {
    // 1. Get all active students in grade_level + section
    // 2. Bulk insert into enrollments with enrollment_type='section_based'
    // 3. Log activity
  }

  /// Enroll single student
  Future<void> enrollStudent(String studentId, int courseId) async {
    // Insert into enrollments with enrollment_type='manual'
  }

  /// Enroll multiple students
  Future<void> enrollStudents(List<String> studentIds, int courseId) async {
    // Bulk insert
  }

  // ============================================
  // SCHEDULE OPERATIONS
  // ============================================

  /// Add schedule to course
  Future<void> addSchedule({
    required int courseId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? roomNumber,
  }) async {
    // Insert into course_schedules
  }

  /// Get schedules for course
  Future<List<CourseSchedule>> getSchedules(int courseId) async {
    // Query course_schedules
  }

  /// Delete schedule
  Future<void> deleteSchedule(int scheduleId) async {
    // Delete from course_schedules
  }

  // ============================================
  // VALIDATION OPERATIONS
  // ============================================

  /// Check if course code is unique
  Future<bool> isCourseCodeUnique(String courseCode) async {
    final result = await _supabase
        .from('courses')
        .select('id')
        .eq('course_code', courseCode)
        .maybeSingle();
    return result == null;
  }

  /// Validate course data
  Future<Map<String, String>> validateCourse({
    required String courseCode,
    required int gradeLevel,
    required String subject,
  }) async {
    final errors = <String, String>{};
    
    // Check code uniqueness
    if (!await isCourseCodeUnique(courseCode)) {
      errors['courseCode'] = 'Course code already exists';
    }
    
    // Validate grade level
    if (gradeLevel < 7 || gradeLevel > 12) {
      errors['gradeLevel'] = 'Grade level must be between 7 and 12';
    }
    
    return errors;
  }
}
```

#### **B. Create `lib/services/teacher_service.dart`** (if not exists)

```dart
class TeacherService {
  final _supabase = Supabase.instance.client;

  /// Get all active teachers
  Future<List<Teacher>> getActiveTeachers() async {
    final response = await _supabase
        .from('teachers')
        .select('*, profiles!inner(full_name, email)')
        .eq('is_active', true)
        .order('full_name');
    
    return (response as List).map((json) => Teacher.fromMap(json)).toList();
  }

  /// Get teachers by subject
  Future<List<Teacher>> getTeachersBySubject(String subject) async {
    final response = await _supabase
        .from('teachers')
        .select('*, profiles!inner(full_name, email)')
        .contains('subjects', [subject])
        .eq('is_active', true);
    
    return (response as List).map((json) => Teacher.fromMap(json)).toList();
  }

  /// Get teacher by ID
  Future<Teacher?> getTeacherById(String id) async {
    final response = await _supabase
        .from('teachers')
        .select('*, profiles!inner(full_name, email)')
        .eq('id', id)
        .maybeSingle();
    
    return response != null ? Teacher.fromMap(response) : null;
  }
}
```

#### **C. Enhance `lib/services/enrollment_service.dart`**

**Add methods**:
```dart
/// Bulk enroll students
Future<void> bulkEnrollStudents({
  required List<String> studentIds,
  required int courseId,
  String enrollmentType = 'manual',
}) async {
  final enrollments = studentIds.map((studentId) => {
    'student_id': studentId,
    'course_id': courseId,
    'status': 'active',
    'enrollment_type': enrollmentType,
    'enrolled_at': DateTime.now().toIso8601String(),
  }).toList();

  await _supabase.from('enrollments').insert(enrollments);
}

/// Get students by grade and section
Future<List<String>> getStudentIdsBySection(int gradeLevel, String section) async {
  final response = await _supabase
      .from('students')
      .select('id')
      .eq('grade_level', gradeLevel)
      .eq('section', section)
      .eq('is_active', true);
  
  return (response as List).map((item) => item['id'] as String).toList();
}
```

---

### **3. UI Screens**

#### **A. Modify `lib/screens/admin/courses/create_course_screen.dart`**

**Current State**: Uses mock data for teachers

**Required Changes**:

1. **Add imports**:
```dart
import 'package:oro_site_high_school/services/course_service.dart';
import 'package:oro_site_high_school/services/teacher_service.dart';
import 'package:oro_site_high_school/models/teacher.dart';
```

2. **Replace mock teacher data with real data**:
```dart
class _CreateCourseScreenState extends State<CreateCourseScreen> {
  // ... existing fields ...
  
  final CourseService _courseService = CourseService();
  final TeacherService _teacherService = TeacherService();
  
  List<Teacher> _availableTeachers = [];
  List<String> _selectedTeacherIds = []; // Store IDs instead of names
  bool _isLoadingTeachers = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
    });

    try {
      final teachers = await _teacherService.getActiveTeachers();
      setState(() {
        _availableTeachers = teachers;
        _isLoadingTeachers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTeachers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading teachers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

3. **Update Teacher Assignment Section**:
```dart
Widget _buildTeacherAssignmentSection() {
  if (_isLoadingTeachers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  if (_availableTeachers.isEmpty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 48),
            SizedBox(height: 8),
            Text('No teachers available'),
            Text('Please add teachers first', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teacher Assignment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select one or more teachers for this course',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTeachers.map((teacher) {
              final isSelected = _selectedTeacherIds.contains(teacher.id);
              return FilterChip(
                label: Text(teacher.fullName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTeacherIds.add(teacher.id);
                    } else {
                      _selectedTeacherIds.remove(teacher.id);
                    }
                  });
                },
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue.shade700,
              );
            }).toList(),
          ),
          if (_selectedTeacherIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'At least one teacher should be assigned',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
            ),
        ],
      ),
    ),
  );
}
```

4. **Update _saveCourse() method**:
```dart
Future<void> _saveCourse() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (_selectedTeacherIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please assign at least one teacher'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    // Create course with all data
    final course = await _courseService.createCourse(
      name: _courseNameController.text.trim(),
      courseCode: _courseCodeController.text.trim().toUpperCase(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      gradeLevel: int.parse(_selectedGradeLevel!),
      section: _selectedSections.isNotEmpty ? _selectedSections.join(',') : null,
      subject: _selectedSubject!,
      schoolYear: '2024-2025', // TODO: Make this dynamic
      status: _isActive ? 'active' : 'inactive',
      roomNumber: _roomNumberController.text.trim().isNotEmpty
          ? _roomNumberController.text.trim()
          : null,
      isActive: _isActive,
      teacherIds: _selectedTeacherIds,
      sectionIds: _selectedSections,
      schedules: _schedules,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course "${course.name}" created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating course: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## 🎓 DepEd Philippines K-12 Curriculum Context

### **Grade Levels**
- **Junior High School (JHS)**: Grades 7-10
- **Senior High School (SHS)**: Grades 11-12

### **Core Subjects (Grades 7-10)**
1. **Mathematics** (Math 7, Math 8, Math 9, Math 10)
2. **Science** (Science 7, Science 8, Science 9, Science 10)
3. **English** (English 7, English 8, English 9, English 10)
4. **Filipino** (Filipino 7, Filipino 8, Filipino 9, Filipino 10)
5. **Araling Panlipunan** (AP 7, AP 8, AP 9, AP 10) - Social Studies
6. **MAPEH** (Music, Arts, PE, Health)
7. **TLE** (Technology and Livelihood Education)
8. **Edukasyon sa Pagpapakatao** (EsP) - Values Education

### **SHS Tracks (Grades 11-12)**
1. **Academic Track**:
   - STEM (Science, Technology, Engineering, Mathematics)
   - ABM (Accountancy, Business, Management)
   - HUMSS (Humanities and Social Sciences)
   - GAS (General Academic Strand)

2. **Technical-Vocational-Livelihood (TVL) Track**:
   - Home Economics
   - Agri-Fishery Arts
   - Industrial Arts
   - ICT

3. **Sports Track**
4. **Arts and Design Track**

### **Section Naming Convention**
- **JHS**: Often named after gemstones/metals (Diamond, Sapphire, Gold, etc.)
- **SHS**: Named after tracks (STEM, ABM, HUMSS, etc.)

---

## 🔄 Implementation Steps (Breakdown)

### **Phase 1: Database Setup** (30 minutes)

**Step 1.1**: Execute SQL to alter `courses` table
**Step 1.2**: Execute SQL to alter `enrollments` table
**Step 1.3**: Execute SQL to create `course_schedules` table
**Step 1.4**: Verify `teachers` table exists (create if missing)
**Step 1.5**: Test queries in Supabase SQL Editor

**Verification**:
- [ ] All columns added successfully
- [ ] Indexes created
- [ ] Constraints working
- [ ] Sample INSERT works

---

### **Phase 2: Models Update** (45 minutes)

**Step 2.1**: Update `lib/models/course.dart`
- Add new fields
- Update `fromMap()` method
- Update `toMap()` method
- Add validation methods

**Step 2.2**: Create `lib/models/course_schedule.dart`
- Define model
- Add `fromMap()` and `toMap()`

**Step 2.3**: Create/Update `lib/models/teacher.dart`
- Define model if not exists
- Ensure compatibility with `teachers` table

**Step 2.4**: Update `lib/models/enrollment.dart`
- Add new fields (`status`, `enrolled_at`, `enrollment_type`)
- Update methods

**Verification**:
- [ ] Models compile without errors
- [ ] JSON serialization works
- [ ] All fields mapped correctly

---

### **Phase 3: Services Enhancement** (90 minutes)

**Step 3.1**: Enhance `lib/services/course_service.dart`
- Implement `createCourse()` with full logic
- Implement validation methods
- Implement enrollment methods
- Implement schedule methods
- Add error handling

**Step 3.2**: Create/Enhance `lib/services/teacher_service.dart`
- Implement `getActiveTeachers()`
- Implement `getTeachersBySubject()`
- Add caching if needed

**Step 3.3**: Enhance `lib/services/enrollment_service.dart`
- Implement `bulkEnrollStudents()`
- Implement `getStudentIdsBySection()`

**Step 3.4**: Test services independently
- Create test script or use Dart DevTools
- Test each method with sample data

**Verification**:
- [ ] All service methods work
- [ ] Database operations succeed
- [ ] Error handling works
- [ ] Transactions are atomic

---

### **Phase 4: UI Integration** (90 minutes)

**Step 4.1**: Update `create_course_screen.dart`
- Replace mock teacher data with real data
- Add loading states
- Update teacher selection logic
- Update save method to call service

**Step 4.2**: Add real-time validation
- Check course code uniqueness on blur
- Validate grade level
- Show inline errors

**Step 4.3**: Improve UX
- Add loading indicators
- Add success/error messages
- Add confirmation dialogs

**Step 4.4**: Test UI flow
- Test with real teacher data
- Test validation
- Test save operation
- Test error scenarios

**Verification**:
- [ ] Teachers load from database
- [ ] Course creation works end-to-end
- [ ] Auto-enrollment triggers
- [ ] Schedules save correctly
- [ ] Error messages display properly

---

### **Phase 5: Auto-Enrollment Logic** (60 minutes)

**Step 5.1**: Implement section-based enrollment
- Query students by grade + section
- Bulk insert enrollments
- Handle duplicates gracefully

**Step 5.2**: Add enrollment logging
- Log who enrolled whom
- Track enrollment type

**Step 5.3**: Test auto-enrollment
- Create course with sections
- Verify students enrolled
- Check enrollment count

**Verification**:
- [ ] Students auto-enrolled when sections selected
- [ ] No duplicate enrollments
- [ ] Enrollment type set correctly
- [ ] Activity logged

---

### **Phase 6: Testing & Polish** (60 minutes)

**Step 6.1**: End-to-end testing
- Create course as admin
- Verify in database
- Check teacher assignment
- Check student enrollment
- Verify schedules

**Step 6.2**: Edge case testing
- Empty sections
- No teachers available
- Duplicate course code
- Invalid grade level
- Network errors

**Step 6.3**: UI polish
- Improve error messages
- Add tooltips
- Improve loading states
- Add success animations

**Step 6.4**: Documentation
- Update README
- Add inline comments
- Document API methods

**Verification**:
- [ ] All happy paths work
- [ ] All edge cases handled
- [ ] UI is polished
- [ ] Code is documented

---

## ✅ Success Criteria

### **Functional Requirements**
- [ ] Admin can create course with all fields
- [ ] Real teachers fetched from database
- [ ] Multiple teachers can be assigned
- [ ] Sections can be selected based on grade
- [ ] Students auto-enrolled when sections selected
- [ ] Schedules can be added/removed
- [ ] Course status can be toggled
- [ ] Course code uniqueness validated
- [ ] Data persists to Supabase
- [ ] Errors handled gracefully

### **Non-Functional Requirements**
- [ ] Page loads in < 2 seconds
- [ ] Teacher list loads in < 1 second
- [ ] Course creation completes in < 3 seconds
- [ ] UI is responsive and intuitive
- [ ] Error messages are clear
- [ ] No console errors
- [ ] Code follows project conventions

### **Defense Demo Requirements**
- [ ] Can demonstrate full flow in 2 minutes
- [ ] Shows real backend integration
- [ ] Shows auto-enrollment working
- [ ] Shows teacher assignment
- [ ] Shows schedule management
- [ ] Shows DepEd compliance (subjects, grades)

---

## 🚨 Potential Issues & Solutions

### **Issue 1: Teachers table doesn't exist**
**Solution**: Create it using SQL from Step 4 in database modifications

### **Issue 2: Course code uniqueness not enforced**
**Solution**: Add UNIQUE constraint in database + validation in service

### **Issue 3: Auto-enrollment fails silently**
**Solution**: Add try-catch, log errors, show user feedback

### **Issue 4: Multiple sections per course**
**Solution**: Store as comma-separated string OR create junction table `course_sections`

### **Issue 5: Schedule conflicts**
**Solution**: Add validation to check for overlapping schedules (future enhancement)

### **Issue 6: Performance with many students**
**Solution**: Use batch inserts, add indexes, implement pagination

---

## 📊 Database Schema Diagram

```
┌─────────────────┐
│    profiles     │
│  (auth users)   │
└────────┬────────┘
         │
         ├──────────────────┐
         │                  │
┌────────▼────────┐  ┌──────▼──────────┐
│    teachers     │  │    students     │
│  - employee_id  │  │  - lrn          │
│  - subjects     │  │  - grade_level  │
│  - department   │  │  - section      │
└────────┬────��───┘  └──────┬──────────┘
         │                  │
         │                  │
         │         ┌────────▼────────┐
         │         │   enrollments   │
         │         │  - student_id   │
         │         │  - course_id    │
         │         │  - status       │
         │         └────────┬────────┘
         │                  │
         │         ┌────────▼────────────┐
         └────────►│      courses        │
                   │  - course_code      │
                   │  - name             │
                   │  - grade_level      │
                   │  - subject          │
                   │  - status           │
                   └────────┬────────────┘
                            │
                   ┌────────┴────────┐
                   │                 │
          ┌────────▼────────┐  ┌─────▼──────────────┐
          │ course_         │  │ course_schedules   │
          │ assignments     │  │  - day_of_week     │
          │  - teacher_id   │  │  - start_time      │
          │  - course_id    │  │  - end_time        │
          └─────────────────┘  │  - room_number     │
                               └────────────────────┘
```

---

## 🎯 Next Steps After This Plan

1. **Review this plan** with you to confirm understanding
2. **Execute Phase 1** (Database Setup) - Get your approval on SQL
3. **Execute Phase 2** (Models) - Update Dart models
4. **Execute Phase 3** (Services) - Implement backend logic
5. **Execute Phase 4** (UI) - Wire up the screen
6. **Execute Phase 5** (Auto-enrollment) - Implement enrollment logic
7. **Execute Phase 6** (Testing) - Test and polish

**Estimated Total Time**: 6-8 hours (can be done in 1-2 days)

---

## 📝 Open Questions for You

1. **School Year**: Should it be hardcoded as "2024-2025" or selectable?
2. **Multiple Sections**: Should one course support multiple sections, or create separate courses per section?
3. **Schedule Conflicts**: Should we validate that teachers don't have overlapping schedules?
4. **Room Assignment**: Is room number per course or per schedule?
5. **Teacher Subjects**: Should we filter teachers by subject when assigning?
6. **Enrollment Approval**: Should enrollments be auto-approved or require admin approval?
7. **Azure Integration**: Do we need to sync course creation with Azure AD?

---

## 🎓 DepEd Compliance Checklist

- [ ] Grade levels 7-12 supported
- [ ] Core subjects included (Math, Science, English, Filipino, AP, MAPEH, TLE, EsP)
- [ ] SHS tracks supported (STEM, ABM, HUMSS, GAS, TVL)
- [ ] LRN (Learner Reference Number) used for students
- [ ] School year format (e.g., "2024-2025")
- [ ] Section naming follows conventions
- [ ] Course codes follow DepEd format (e.g., MATH7, SCI8)

---

**Document Version**: 1.0  
**Created**: January 2025  
**Status**: ✅ Planning Complete - Ready for Implementation  
**Priority**: 🔴 CRITICAL for Thesis Defense

---

## 🚀 Ready to Start?

Reply with:
- **"Proceed with Phase 1"** - I'll start with database modifications
- **"Answer questions first"** - I'll wait for your answers to open questions
- **"Modify the plan"** - Tell me what needs changing

This plan ensures we build a **production-ready, DepEd-compliant course creation feature** that will impress your thesis defense panel! 💪
