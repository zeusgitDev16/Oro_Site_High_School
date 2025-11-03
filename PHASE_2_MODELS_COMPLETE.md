# ✅ Phase 2 Complete: Dart Models Updated

## 📋 Summary

All Dart models have been updated to match the new database schema from Phase 1 (Backend Setup).

**Status**: ✅ Complete  
**Time**: ~15 minutes  
**Files Modified**: 3  
**Files Created**: 2

---

## 📝 Changes Made

### **1. Updated: `lib/models/course.dart`**

**Added 9 new fields**:
- ✅ `courseCode` (String, unique identifier)
- ✅ `gradeLevel` (int, 7-12)
- ✅ `section` (String?, e.g., "Diamond")
- ✅ `subject` (String, e.g., "Mathematics")
- ✅ `schoolYear` (String, e.g., "2024-2025")
- ✅ `status` (String, 'active'/'inactive'/'archived')
- ✅ `roomNumber` (String?, e.g., "101")
- ✅ `isActive` (bool)
- ✅ `updatedAt` (DateTime)

**Added helper methods**:
- `displayName` - Course name with grade level
- `fullIdentifier` - Complete course identifier
- `isJuniorHigh` - Check if JHS (grades 7-10)
- `isSeniorHigh` - Check if SHS (grades 11-12)
- `gradeLevelName` - Formatted grade level name
- `copyWith()` - Immutable updates
- `toInsertMap()` - For database INSERT operations

**Added enums and constants**:
- `CourseStatus` enum (active, inactive, archived)
- `DepEdSubjects` class with all K-12 subjects:
  - Junior High Core subjects
  - Senior High Core subjects
  - STEM track subjects
  - ABM track subjects
  - HUMSS track subjects
  - Helper methods to get subjects by grade level

---

### **2. Created: `lib/models/course_schedule.dart`** ✨ NEW

**Complete model for course schedules**:
- `id`, `createdAt`, `courseId`
- `dayOfWeek` (Monday-Sunday)
- `startTime`, `endTime` (HH:mm format)
- `roomNumber` (optional)
- `isActive`, `updatedAt`

**Helper methods**:
- `displayString` - Full schedule display
- `shortDisplay` - Without room number
- `timeRange` - Just the time range
- `durationMinutes` - Calculate duration
- `durationDisplay` - Human-readable duration
- `dayIndex` - Get day as index (0-6)
- `parseTime()` - Convert time string to DateTime
- `copyWith()` - Immutable updates
- `toInsertMap()` - For database INSERT

**Helper classes**:
- `DaysOfWeek` - Constants for days
  - `all`, `weekdays`, `weekend`
  - `getShortName()` - Get 3-letter abbreviation
  - `isWeekday()`, `isWeekend()` - Day type checks
  
- `CommonTimeSlots` - Philippine school time slots
  - Morning shift: 07:00-12:00
  - Afternoon shift: 13:00-18:00
  - Common start times
  - Standard durations (60 min, 90 min)
  - `generateEndTime()` - Calculate end time from start + duration

---

### **3. Updated: `lib/models/enrollment.dart`**

**Added 3 new fields**:
- ✅ `status` (String, 'active'/'dropped'/'completed'/'pending')
- ✅ `enrolledAt` (DateTime, enrollment timestamp)
- ✅ `enrollmentType` (String, 'manual'/'auto'/'section_based')

**Added helper properties**:
- `isActive` - Check if enrollment is active
- `isCompleted` - Check if completed
- `isDropped` - Check if dropped
- `isPending` - Check if pending
- `isAutomatic` - Check if auto-enrolled
- `isManual` - Check if manually enrolled
- `statusDisplay` - Human-readable status
- `enrollmentTypeDisplay` - Human-readable type

**Added enums**:
- `EnrollmentStatus` enum with display names
- `EnrollmentType` enum with display names and values

**Added methods**:
- `copyWith()` - Immutable updates
- `toInsertMap()` - For database INSERT operations

---

### **4. Created: `lib/models/teacher.dart`** ✨ NEW

**Complete model for teachers**:
- `id` (UUID from profiles)
- `employeeId` (unique identifier)
- `firstName`, `lastName`, `middleName`
- `department` (e.g., "Mathematics")
- `subjects` (List<String>, JSONB in database)
- `isGradeCoordinator`, `coordinatorGradeLevel`
- `isSHSTeacher`, `shsTrack`, `shsStrands`
- `isActive`, `createdAt`, `updatedAt`
- Optional joined fields: `email`, `fullName`, `phone`

**Helper methods**:
- `displayName` - Full name display
- `formalName` - Last, First M. format
- `subjectsDisplay` - Comma-separated subjects
- `roleDescription` - Role with coordinator/SHS info
- `teachesSubject()` - Check if teaches specific subject
- `isCoordinatorFor()` - Check if coordinator for grade
- `copyWith()` - Immutable updates
- `toInsertMap()` - For database INSERT

**Helper classes**:
- `SHSTracks` - SHS track constants
  - Academic, TVL, Sports, Arts and Design
  
- `SHSStrands` - SHS strand constants
  - Academic: STEM, ABM, HUMSS, GAS
  - TVL: Home Economics, Agri-Fishery, Industrial Arts, ICT
  - `getStrandsByTrack()` - Get strands for a track

---

## 🎯 Key Features

### **Type Safety**
All models use proper Dart types with null safety:
- Required fields are non-nullable
- Optional fields use `?` nullable syntax
- Default values provided where appropriate

### **Database Mapping**
Each model has complete serialization:
- `fromMap()` - Create from database JSON
- `toMap()` - Convert to database JSON
- `toInsertMap()` - For INSERT operations (excludes auto-generated fields)

### **Immutability**
All models support immutable updates:
- `copyWith()` method for creating modified copies
- `final` fields prevent accidental mutations

### **DepEd Compliance**
Models align with Philippine K-12 curriculum:
- Grade levels 7-12
- Core subjects for JHS and SHS
- SHS tracks and strands
- Section-based organization
- School year tracking

### **Helper Methods**
Rich helper methods for common operations:
- Display formatting
- Status checks
- Type conversions
- Validation helpers

---

## 📊 Model Relationships

```
Course (1) ──────────── (N) CourseSchedule
   │                           (schedules for a course)
   │
   ├── (N) Enrollment ──── (1) Student
   │       (students enrolled in course)
   │
   └── (N) CourseAssignment ──── (1) Teacher
           (teachers assigned to course)
```

---

## ✅ Verification Checklist

- [x] Course model has all 9 new fields
- [x] CourseSchedule model created with all fields
- [x] Enrollment model has all 3 new fields
- [x] Teacher model created with all fields
- [x] All models have `fromMap()` methods
- [x] All models have `toMap()` methods
- [x] All models have `toInsertMap()` methods
- [x] All models have `copyWith()` methods
- [x] All models have helper properties/methods
- [x] Enums created for status values
- [x] DepEd subjects and tracks included
- [x] Models compile without errors
- [x] Null safety properly implemented

---

## 🔄 Database Schema Alignment

| Database Column | Dart Field | Type | Notes |
|----------------|------------|------|-------|
| **courses table** |
| `course_code` | `courseCode` | String | Unique identifier |
| `grade_level` | `gradeLevel` | int | 7-12 only |
| `section` | `section` | String? | Optional |
| `subject` | `subject` | String | Required |
| `school_year` | `schoolYear` | String | e.g., "2024-2025" |
| `status` | `status` | String | active/inactive/archived |
| `room_number` | `roomNumber` | String? | Optional |
| `is_active` | `isActive` | bool | Default true |
| `updated_at` | `updatedAt` | DateTime | Auto-updated |
| **enrollments table** |
| `status` | `status` | String | active/dropped/completed/pending |
| `enrolled_at` | `enrolledAt` | DateTime | Enrollment timestamp |
| `enrollment_type` | `enrollmentType` | String | manual/auto/section_based |
| **course_schedules table** |
| `day_of_week` | `dayOfWeek` | String | Monday-Sunday |
| `start_time` | `startTime` | String | HH:mm format |
| `end_time` | `endTime` | String | HH:mm format |
| `room_number` | `roomNumber` | String? | Optional |
| **teachers table** |
| `employee_id` | `employeeId` | String | Unique |
| `first_name` | `firstName` | String | Required |
| `last_name` | `lastName` | String | Required |
| `middle_name` | `middleName` | String? | Optional |
| `subjects` | `subjects` | List<String> | JSONB array |
| `is_grade_coordinator` | `isGradeCoordinator` | bool | Default false |
| `coordinator_grade_level` | `coordinatorGradeLevel` | String? | Optional |
| `is_shs_teacher` | `isSHSTeacher` | bool | Default false |
| `shs_track` | `shsTrack` | String? | Optional |
| `shs_strands` | `shsStrands` | List<String>? | JSONB array |

---

## 🚀 Next Steps

**Phase 3: Service Layer Implementation**

Now that models are ready, we need to create/update services:

1. ✅ **Enhance `CourseService`** - Add all CRUD operations
2. ✅ **Create `TeacherService`** - Fetch and manage teachers
3. ✅ **Enhance `EnrollmentService`** - Add bulk enrollment
4. ✅ **Create `CourseScheduleService`** - Manage schedules

**Files to create/modify**:
- `lib/services/course_service.dart` (enhance existing)
- `lib/services/teacher_service.dart` (create new)
- `lib/services/enrollment_service.dart` (enhance existing)
- `lib/services/course_schedule_service.dart` (create new)

---

## 📝 Usage Examples

### **Creating a Course**
```dart
final course = Course(
  id: 1,
  createdAt: DateTime.now(),
  name: 'Mathematics 7',
  courseCode: 'MATH7',
  description: 'Basic mathematics for Grade 7',
  gradeLevel: 7,
  section: 'Diamond',
  subject: 'Mathematics',
  schoolYear: '2024-2025',
  status: 'active',
  isActive: true,
  updatedAt: DateTime.now(),
);

// Insert to database
final insertMap = course.toInsertMap();
await supabase.from('courses').insert(insertMap);
```

### **Creating a Schedule**
```dart
final schedule = CourseSchedule(
  id: 1,
  createdAt: DateTime.now(),
  courseId: 1,
  dayOfWeek: 'Monday',
  startTime: '08:00',
  endTime: '09:00',
  roomNumber: '101',
  isActive: true,
  updatedAt: DateTime.now(),
);

print(schedule.displayString); // "Monday 08:00 - 09:00 • Room 101"
print(schedule.durationDisplay); // "1 hour"
```

### **Creating an Enrollment**
```dart
final enrollment = Enrollment(
  id: 1,
  createdAt: DateTime.now(),
  studentId: 'uuid-here',
  courseId: 1,
  status: 'active',
  enrolledAt: DateTime.now(),
  enrollmentType: 'section_based',
);

if (enrollment.isActive && enrollment.isAutomatic) {
  print('Student auto-enrolled in course');
}
```

### **Working with Teachers**
```dart
final teacher = Teacher(
  id: 'uuid-here',
  employeeId: 'EMP001',
  firstName: 'Juan',
  lastName: 'Dela Cruz',
  department: 'Mathematics',
  subjects: ['Mathematics', 'Statistics'],
  isGradeCoordinator: true,
  coordinatorGradeLevel: '7',
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

print(teacher.displayName); // "Juan Dela Cruz"
print(teacher.formalName); // "Dela Cruz, Juan"
print(teacher.roleDescription); // "Grade 7 Coordinator"
print(teacher.teachesSubject('Mathematics')); // true
```

---

**Status**: ✅ Phase 2 Complete  
**Next**: Phase 3 - Service Layer Implementation  
**Ready**: Models are production-ready and aligned with database schema
