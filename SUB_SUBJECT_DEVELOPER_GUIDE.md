# 📘 Sub-Subject Tree Enhancement - Developer Guide

## 🎯 QUICK START

This guide shows you how to use the new sub-subject tree enhancement feature in your code.

---

## 📦 IMPORTS

```dart
// Models
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/models/student_subject_enrollment.dart';

// Services
import 'package:oro_site_high_school/services/classroom_subject_service.dart';
import 'package:oro_site_high_school/services/student_subject_enrollment_service.dart';
import 'package:oro_site_high_school/services/deped_grade_service.dart';
```

---

## 🎵 MAPEH IMPLEMENTATION

### 1. Add MAPEH Subject (Auto-creates 4 sub-subjects)

```dart
final subjectService = ClassroomSubjectService();

// Add MAPEH parent subject
final mapehSubject = await subjectService.addMAPEHSubject(
  classroomId: 'classroom-uuid',
  teacherId: 'teacher-uuid', // Optional
  description: 'Music, Arts, PE, Health',
);

// ✅ This automatically creates 4 sub-subjects:
// - Music
// - Arts
// - Physical Education (PE)
// - Health
```

### 2. Get MAPEH Sub-Subjects

```dart
// Get all sub-subjects for MAPEH
final subSubjects = await subjectService.getSubSubjects(
  parentSubjectId: mapehSubject.id,
);

// subSubjects will contain 4 items:
// [Music, Arts, Physical Education (PE), Health]
```

### 3. Check Subject Type

```dart
if (subject.isMAPEHParent) {
  print('This is MAPEH parent subject');
}

if (subject.isMAPEHSub) {
  print('This is a MAPEH sub-subject (Music/Arts/PE/Health)');
}
```

### 4. Grade MAPEH Sub-Subjects

```dart
final gradeService = DepEdGradeService();

// Grade Music (sub-subject)
await gradeService.saveSubSubjectGrade(
  studentId: 'student-uuid',
  classroomId: 'classroom-uuid',
  subjectId: musicSubjectId,
  quarter: 1,
  initialGrade: 88.5,
  transmutedGrade: 86.0,
  wwScore: 45, wwMax: 50, wwPS: 90, wwWS: 27,
  ptScore: 85, ptMax: 100, ptPS: 85, ptWS: 42.5,
  qaScore: 38, qaMax: 50, qaPS: 76, qaWS: 15.2,
);

// Repeat for Arts, PE, Health...

// Compute MAPEH final grade (average of 4 sub-subjects)
final mapehGrade = await gradeService.computeParentSubjectGrade(
  studentId: 'student-uuid',
  classroomId: 'classroom-uuid',
  parentSubjectId: mapehSubject.id,
  quarter: 1,
);

// mapehGrade = (Music + Arts + PE + Health) / 4
print('MAPEH Final Grade: $mapehGrade');
```

---

## 🔧 TLE IMPLEMENTATION

### 1. Add TLE Parent Subject

```dart
final subjectService = ClassroomSubjectService();

// Add TLE parent subject
final tleSubject = await subjectService.addTLESubject(
  classroomId: 'classroom-uuid',
  teacherId: 'teacher-uuid', // Optional
  description: 'Technology and Livelihood Education',
);
```

### 2. Add TLE Sub-Subjects (Admin/Teacher)

```dart
// Add Cookery
final cookery = await subjectService.addTLESubSubject(
  classroomId: 'classroom-uuid',
  tleParentId: tleSubject.id,
  subjectName: 'Cookery',
  teacherId: 'teacher-uuid', // Optional
  description: 'Culinary arts and food preparation',
);

// Add ICT
final ict = await subjectService.addTLESubSubject(
  classroomId: 'classroom-uuid',
  tleParentId: tleSubject.id,
  subjectName: 'ICT',
  teacherId: 'teacher-uuid',
  description: 'Information and Communications Technology',
);

// Add more TLE sub-subjects as needed...
```

### 3. Enroll Students in TLE (Grades 7-8: Teacher Enrollment)

```dart
final enrollmentService = StudentSubjectEnrollmentService();

// Enroll single student
await enrollmentService.enrollStudentInTLE(
  studentId: 'student-uuid',
  classroomId: 'classroom-uuid',
  tleParentId: tleSubject.id,
  tleSubId: cookery.id, // Student takes Cookery
);

// Bulk enroll multiple students
await enrollmentService.bulkEnrollStudentsInTLE(
  enrollments: [
    {'student_id': 'student-1-uuid', 'tle_sub_id': cookery.id},
    {'student_id': 'student-2-uuid', 'tle_sub_id': ict.id},
    {'student_id': 'student-3-uuid', 'tle_sub_id': cookery.id},
  ],
  classroomId: 'classroom-uuid',
  tleParentId: tleSubject.id,
);
```

### 4. Student Self-Enrollment (Grades 9-10)

```dart
// Student chooses their TLE sub-subject
await enrollmentService.selfEnrollInTLE(
  studentId: 'student-uuid',
  classroomId: 'classroom-uuid',
  tleParentId: tleSubject.id,
  tleSubId: ict.id, // Student chooses ICT
);

// ⚠️ Note: RPC function validates grade level 9-10
// Will throw error if student is in grades 7-8
```

### 5. Get Student's TLE Enrollment

```dart
// Get which TLE sub-subject the student is enrolled in
final enrolledSubId = await enrollmentService.getStudentTLEEnrollment(
  studentId: 'student-uuid',
  classroomId: 'classroom-uuid',
  tleParentId: tleSubject.id,
);

if (enrolledSubId != null) {
  print('Student is enrolled in TLE sub-subject: $enrolledSubId');
} else {
  print('Student not enrolled in any TLE sub-subject yet');
}
```

### 6. Grade TLE Sub-Subject

```dart
final gradeService = DepEdGradeService();

// Grade the student's enrolled TLE sub-subject
await gradeService.saveSubSubjectGrade(
  studentId: 'student-uuid',
  classroomId: 'classroom-uuid',
  subjectId: enrolledSubId!, // The sub-subject they're enrolled in
  quarter: 1,
  initialGrade: 92.0,
  transmutedGrade: 90.0,
  wwScore: 48, wwMax: 50, wwPS: 96, wwWS: 28.8,
  ptScore: 95, ptMax: 100, ptPS: 95, ptWS: 47.5,
  qaScore: 42, qaMax: 50, qaPS: 84, qaWS: 16.8,
);

// Get TLE grade (equals enrolled sub-subject grade, no averaging)
final tleGrade = await gradeService.computeParentSubjectGrade(
  studentId: 'student-uuid',
  classroomId: 'classroom-uuid',
  parentSubjectId: tleSubject.id,
  quarter: 1,
);

// tleGrade = enrolled sub-subject grade (no averaging)
print('TLE Grade: $tleGrade');
```

---

## 🔍 HELPER METHODS

### Check Subject Type

```dart
// Check if subject is a parent subject
if (subject.isParentSubject) {
  print('This is a parent subject (MAPEH or TLE)');
}

// Check if subject is a sub-subject
if (subject.isSubSubject) {
  print('This is a sub-subject');
}

// Check specific types
if (subject.isTLEParent) {
  print('This is TLE parent');
}

if (subject.isTLESub) {
  print('This is TLE sub-subject');
}

if (subject.isStandard) {
  print('This is a standard subject (Math, English, etc.)');
}
```

---

## ⚠️ IMPORTANT NOTES

1. **MAPEH Sub-Subjects are Hardcoded**
   - Cannot modify names: Music, Arts, Physical Education (PE), Health
   - Cannot delete MAPEH sub-subjects (protected by RLS)
   - Auto-created when MAPEH parent is added

2. **TLE Sub-Subjects are Customizable**
   - Admin/teacher can add custom names
   - Can be deleted (if no students enrolled)

3. **TLE Enrollment Rules**
   - **Grades 7-8:** Teacher enrolls students
   - **Grades 9-10:** Students self-enroll
   - Each student takes ONE TLE sub-subject (not all)

4. **Grading Differences**
   - **MAPEH:** Final grade = Average of 4 sub-subjects
   - **TLE:** Final grade = Enrolled sub-subject grade (no averaging)

---

## 🎉 SUMMARY

- ✅ Use `addMAPEHSubject()` to create MAPEH with 4 sub-subjects
- ✅ Use `addTLESubject()` + `addTLESubSubject()` to create TLE with custom sub-subjects
- ✅ Use `enrollStudentInTLE()` for teacher enrollment (Grades 7-8)
- ✅ Use `selfEnrollInTLE()` for student self-enrollment (Grades 9-10)
- ✅ Use `saveSubSubjectGrade()` to grade sub-subjects
- ✅ Use `computeParentSubjectGrade()` to get MAPEH/TLE final grade

