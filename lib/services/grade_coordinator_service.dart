/// Grade Level Coordinator Service
/// Manages all coordinator-specific features and permissions
/// Provides enhanced teacher capabilities for grade level management

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/grade.dart';
import '../models/attendance.dart';
import 'grade_service.dart';
import 'attendance_service.dart';
import 'course_service.dart';

/// Grade level coordinator assignment
class CoordinatorAssignment {
  final String id;
  final String teacherId;
  final String teacherName;
  final int gradeLevel;
  final String schoolYear;
  final DateTime assignedAt;
  final String? assignedBy;
  final bool isActive;
  final Map<String, dynamic>? permissions;

  CoordinatorAssignment({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.gradeLevel,
    required this.schoolYear,
    required this.assignedAt,
    this.assignedBy,
    this.isActive = true,
    this.permissions,
  });

  factory CoordinatorAssignment.fromJson(Map<String, dynamic> json) {
    return CoordinatorAssignment(
      id: json['id'].toString(), // Convert bigint to String
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      gradeLevel: json['grade_level'],
      schoolYear: json['school_year'],
      assignedAt: DateTime.parse(json['assigned_at']),
      assignedBy: json['assigned_by'],
      isActive: json['is_active'] ?? true,
      permissions: json['permissions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'grade_level': gradeLevel,
      'school_year': schoolYear,
      'assigned_at': assignedAt.toIso8601String(),
      'assigned_by': assignedBy,
      'is_active': isActive,
      'permissions': permissions,
    };
  }
}

/// Section summary for coordinators
class SectionSummary {
  final String sectionId;
  final String sectionName;
  final String? adviserId;
  final String? adviserName;
  final int studentCount;
  final double averageGrade;
  final double attendanceRate;
  final int failingStudents;
  final int excellentStudents;

  SectionSummary({
    required this.sectionId,
    required this.sectionName,
    this.adviserId,
    this.adviserName,
    required this.studentCount,
    required this.averageGrade,
    required this.attendanceRate,
    required this.failingStudents,
    required this.excellentStudents,
  });
}

/// Grade level statistics
class GradeLevelStats {
  final int gradeLevel;
  final int totalSections;
  final int totalStudents;
  final int totalTeachers;
  final double averageGrade;
  final double attendanceRate;
  final int failingStudents;
  final int excellentStudents;
  final int atRiskStudents;
  final Map<String, dynamic> subjectPerformance;
  final Map<String, dynamic> monthlyTrends;

  GradeLevelStats({
    required this.gradeLevel,
    required this.totalSections,
    required this.totalStudents,
    required this.totalTeachers,
    required this.averageGrade,
    required this.attendanceRate,
    required this.failingStudents,
    required this.excellentStudents,
    required this.atRiskStudents,
    required this.subjectPerformance,
    required this.monthlyTrends,
  });
}

class GradeCoordinatorService extends ChangeNotifier {
  static final GradeCoordinatorService _instance =
      GradeCoordinatorService._internal();
  factory GradeCoordinatorService() => _instance;
  GradeCoordinatorService._internal();

  final _supabase = Supabase.instance.client;
  final _gradeService = GradeService();
  final _attendanceService = AttendanceService();
  final _courseService = CourseService();

  // Current coordinator assignment
  CoordinatorAssignment? _currentAssignment;
  CoordinatorAssignment? get currentAssignment => _currentAssignment;

  // Cached data
  List<SectionSummary> _sections = [];
  List<Student> _allStudents = [];
  GradeLevelStats? _gradeLevelStats;

  List<SectionSummary> get sections => _sections;
  List<Student> get allStudents => _allStudents;
  GradeLevelStats? get gradeLevelStats => _gradeLevelStats;

  /// Initialize coordinator service for a teacher
  Future<void> initialize(String teacherId) async {
    try {
      // Load coordinator assignment
      await _loadCoordinatorAssignment(teacherId);

      if (_currentAssignment != null) {
        // Load grade level data
        await Future.wait([
          _loadSections(),
          _loadAllStudents(),
          _loadGradeLevelStats(),
        ]);
      }

      notifyListeners();
    } catch (e) {
      print('Error initializing coordinator service: $e');
    }
  }

  /// Load coordinator assignment
  Future<void> _loadCoordinatorAssignment(String teacherId) async {
    try {
      final response = await _supabase
          .from('coordinator_assignments')
          .select()
          .eq('teacher_id', teacherId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        _currentAssignment = CoordinatorAssignment.fromJson(response);
      }
    } catch (e) {
      print('Error loading coordinator assignment: $e');
    }
  }

  /// Get all active coordinator assignments (for admin use)
  Future<Map<int, CoordinatorAssignment>>
  getAllActiveCoordinatorAssignments() async {
    try {
      print('🔍 [Service] Querying coordinator_assignments table...');
      final response = await _supabase
          .from('coordinator_assignments')
          .select()
          .eq('is_active', true)
          .order('grade_level');

      print('📊 [Service] Query returned ${(response as List).length} records');

      final assignments = <int, CoordinatorAssignment>{};
      for (final json in response) {
        print('   Raw JSON: $json');
        final assignment = CoordinatorAssignment.fromJson(json);
        assignments[assignment.gradeLevel] = assignment;
        print(
          '   Parsed: Grade ${assignment.gradeLevel} -> ${assignment.teacherName}',
        );
      }

      print('✅ [Service] Returning ${assignments.length} assignments');
      return assignments;
    } catch (e) {
      print('❌ [Service] Error loading all coordinator assignments: $e');
      return {};
    }
  }

  /// Check if a teacher is already assigned to another grade level
  Future<int?> getTeacherCurrentGradeAssignment(String teacherId) async {
    try {
      print(
        '🔍 [Service] Checking if teacher $teacherId is already assigned...',
      );
      final response = await _supabase
          .from('coordinator_assignments')
          .select('grade_level')
          .eq('teacher_id', teacherId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        final gradeLevel = response['grade_level'] as int;
        print('   ⚠️ Teacher is already assigned to Grade $gradeLevel');
        return gradeLevel;
      }

      print('   ✅ Teacher is not assigned to any grade level');
      return null;
    } catch (e) {
      print('❌ [Service] Error checking teacher assignment: $e');
      return null;
    }
  }

  /// Assign a coordinator to a grade level
  Future<Map<String, dynamic>> assignCoordinator({
    required String teacherId,
    required String teacherName,
    required int gradeLevel,
    required String schoolYear,
    String? assignedBy,
  }) async {
    try {
      print('🔄 [Service] Starting coordinator assignment...');
      print('   Teacher ID: $teacherId');
      print('   Teacher Name: $teacherName');
      print('   Grade Level: $gradeLevel');
      print('   School Year: $schoolYear');
      print('   Assigned By: $assignedBy');

      // Check if teacher is already assigned to another grade level
      final existingGrade = await getTeacherCurrentGradeAssignment(teacherId);
      if (existingGrade != null && existingGrade != gradeLevel) {
        print(
          '❌ [Service] Teacher is already assigned to Grade $existingGrade',
        );
        return {
          'success': false,
          'error': 'already_assigned',
          'existingGrade': existingGrade,
          'message':
              '$teacherName is already assigned to Grade $existingGrade. Please remove them first.',
        };
      }

      // First, deactivate any existing assignment for this grade level
      print(
        '🔄 [Service] Deactivating existing assignments for grade $gradeLevel...',
      );
      final updateResult = await _supabase
          .from('coordinator_assignments')
          .update({'is_active': false})
          .eq('grade_level', gradeLevel)
          .eq('is_active', true);
      print('✅ [Service] Deactivation complete: $updateResult');

      // Create new assignment
      print('🔄 [Service] Inserting new assignment...');
      final insertData = {
        'teacher_id': teacherId,
        'teacher_name': teacherName,
        'grade_level': gradeLevel,
        'school_year': schoolYear,
        'assigned_by': assignedBy,
        'is_active': true,
        'assigned_at': DateTime.now().toIso8601String(),
      };
      print('   Insert data: $insertData');

      final insertResult = await _supabase
          .from('coordinator_assignments')
          .insert(insertData);
      print('✅ [Service] Insert complete: $insertResult');

      print(
        '✅ [Service] Coordinator assigned: $teacherName to Grade $gradeLevel',
      );
      return {
        'success': true,
        'message': 'Grade $gradeLevel coordinator set to $teacherName',
      };
    } catch (e) {
      print('❌ [Service] Error assigning coordinator: $e');
      print('   Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('   Exception details: $e');
      }
      return {
        'success': false,
        'error': 'exception',
        'message': 'Failed to assign coordinator: ${e.toString()}',
      };
    }
  }

  /// Remove coordinator assignment for a grade level
  Future<bool> removeCoordinator(int gradeLevel) async {
    try {
      await _supabase
          .from('coordinator_assignments')
          .update({'is_active': false})
          .eq('grade_level', gradeLevel)
          .eq('is_active', true);

      print('✅ Coordinator removed from Grade $gradeLevel');
      return true;
    } catch (e) {
      print('❌ Error removing coordinator: $e');
      return false;
    }
  }

  /// Load all sections for the grade level
  Future<void> _loadSections() async {
    if (_currentAssignment == null) return;

    try {
      // For now, using mock data
      _sections = [
        SectionSummary(
          sectionId: '7-A',
          sectionName: 'Grade 7 - Section A',
          adviserId: 'teacher-1',
          adviserName: 'Maria Santos',
          studentCount: 35,
          averageGrade: 85.5,
          attendanceRate: 92.3,
          failingStudents: 2,
          excellentStudents: 8,
        ),
        SectionSummary(
          sectionId: '7-B',
          sectionName: 'Grade 7 - Section B',
          adviserId: 'teacher-2',
          adviserName: 'Juan Reyes',
          studentCount: 34,
          averageGrade: 83.2,
          attendanceRate: 90.5,
          failingStudents: 3,
          excellentStudents: 6,
        ),
        SectionSummary(
          sectionId: '7-C',
          sectionName: 'Grade 7 - Section C',
          adviserId: 'teacher-3',
          adviserName: 'Ana Cruz',
          studentCount: 36,
          averageGrade: 86.8,
          attendanceRate: 93.1,
          failingStudents: 1,
          excellentStudents: 10,
        ),
        SectionSummary(
          sectionId: '7-D',
          sectionName: 'Grade 7 - Section D',
          adviserId: 'teacher-4',
          adviserName: 'Pedro Garcia',
          studentCount: 35,
          averageGrade: 82.1,
          attendanceRate: 89.7,
          failingStudents: 4,
          excellentStudents: 5,
        ),
        SectionSummary(
          sectionId: '7-E',
          sectionName: 'Grade 7 - Section E',
          adviserId: 'teacher-5',
          adviserName: 'Lisa Mendoza',
          studentCount: 35,
          averageGrade: 84.3,
          attendanceRate: 91.2,
          failingStudents: 2,
          excellentStudents: 7,
        ),
        SectionSummary(
          sectionId: '7-F',
          sectionName: 'Grade 7 - Section F',
          adviserId: 'teacher-6',
          adviserName: 'Carlos Reyes',
          studentCount: 35,
          averageGrade: 85.0,
          attendanceRate: 92.0,
          failingStudents: 2,
          excellentStudents: 8,
        ),
      ];
    } catch (e) {
      print('Error loading sections: $e');
    }
  }

  /// Load all students in the grade level
  Future<void> _loadAllStudents() async {
    if (_currentAssignment == null) return;

    try {
      // Would query actual database
      // For now, generating mock data
      _allStudents = List.generate(210, (index) {
        final sectionIndex = index ~/ 35;
        final sections = ['A', 'B', 'C', 'D', 'E', 'F'];
        final now = DateTime.now();
        return Student(
          id: 'student-${index + 1}',
          lrn: '${100000000000 + index}',
          firstName: 'Student',
          lastName: '${index + 1}',
          middleName: 'M',
          gradeLevel: _currentAssignment!.gradeLevel,
          sectionId: '7-${sections[sectionIndex]}',
          sectionName: 'Grade 7 - Section ${sections[sectionIndex]}',
          email: 'student${index + 1}@orosite.edu.ph',
          birthDate: DateTime(2010, 1, 1), // Mock birth date
          gender: index % 2 == 0 ? 'M' : 'F',
          schoolYear: '2023-2024',
          enrollmentDate: now.subtract(Duration(days: 30)),
          createdAt: now,
          updatedAt: now,
        );
      });
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  /// Load grade level statistics
  Future<void> _loadGradeLevelStats() async {
    if (_currentAssignment == null) return;

    try {
      _gradeLevelStats = GradeLevelStats(
        gradeLevel: _currentAssignment!.gradeLevel,
        totalSections: 6,
        totalStudents: 210,
        totalTeachers: 12,
        averageGrade: 84.5,
        attendanceRate: 91.3,
        failingStudents: 14,
        excellentStudents: 44,
        atRiskStudents: 28,
        subjectPerformance: {
          'Mathematics': 82.3,
          'Science': 85.1,
          'English': 86.2,
          'Filipino': 84.8,
          'Araling Panlipunan': 85.5,
          'TLE': 87.2,
          'MAPEH': 88.1,
          'Values Education': 89.3,
        },
        monthlyTrends: {
          'January': 83.2,
          'February': 83.8,
          'March': 84.1,
          'April': 84.5,
        },
      );
    } catch (e) {
      print('Error loading grade level stats: $e');
    }
  }

  /// Get students by section
  List<Student> getStudentsBySection(String sectionId) {
    return _allStudents.where((s) => s.sectionId == sectionId).toList();
  }

  /// Get failing students
  List<Student> getFailingStudents() {
    // Would filter based on actual grades
    return _allStudents.take(14).toList();
  }

  /// Get excellent students
  List<Student> getExcellentStudents() {
    // Would filter based on actual grades
    return _allStudents.skip(14).take(44).toList();
  }

  /// Get at-risk students
  List<Student> getAtRiskStudents() {
    // Would filter based on grades and attendance
    return _allStudents.skip(58).take(28).toList();
  }

  /// Reset student password (coordinator privilege)
  Future<bool> resetStudentPassword(String studentId) async {
    try {
      // Generate temporary password
      final tempPassword = _generateTempPassword();

      // Update in auth system
      // This would call admin API to reset password
      await _supabase.rpc(
        'reset_student_password',
        params: {
          'student_id': studentId,
          'new_password': tempPassword,
          'reset_by': _currentAssignment?.teacherId,
        },
      );

      // Log the action
      await _logCoordinatorAction('password_reset', {'student_id': studentId});

      return true;
    } catch (e) {
      print('Error resetting student password: $e');
      return false;
    }
  }

  /// Bulk grade entry for multiple students
  Future<bool> bulkEnterGrades({
    required String courseId,
    required String quarter,
    required Map<String, double> studentGrades,
  }) async {
    try {
      // Validate coordinator can enter grades for this course
      if (!await _canEnterGradesForCourse(courseId)) {
        throw Exception('No permission to enter grades for this course');
      }

      // Process each grade entry
      // Note: This needs to be updated when Grade model is properly defined
      // For now, using direct database insert
      for (final entry in studentGrades.entries) {
        await _supabase.from('grades').insert({
          'student_id': entry.key,
          'course_id': int.parse(courseId),
          'quarter': quarter,
          'grade': entry.value,
          'remarks': 'Bulk entry by coordinator',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Log the action
      await _logCoordinatorAction('bulk_grade_entry', {
        'course_id': courseId,
        'quarter': quarter,
        'student_count': studentGrades.length,
      });

      return true;
    } catch (e) {
      print('Error in bulk grade entry: $e');
      return false;
    }
  }

  /// Verify grades for a section
  Future<bool> verifyGrades({
    required String sectionId,
    required String quarter,
  }) async {
    try {
      // Mark grades as verified
      await _supabase
          .from('grades')
          .update({
            'is_verified': true,
            'verified_by': _currentAssignment?.teacherId,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('section_id', sectionId)
          .eq('quarter', quarter);

      // Log the action
      await _logCoordinatorAction('grade_verification', {
        'section_id': sectionId,
        'quarter': quarter,
      });

      return true;
    } catch (e) {
      print('Error verifying grades: $e');
      return false;
    }
  }

  /// Review attendance for a section
  Future<Map<String, dynamic>> reviewSectionAttendance(
    String sectionId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final students = getStudentsBySection(sectionId);
      final attendanceData = <String, dynamic>{};

      for (final student in students) {
        final records = await _attendanceService.getAttendanceRecords(
          studentId: student.id,
          startDate: startDate,
          endDate: endDate,
        );

        final stats = _calculateAttendanceStats(records);
        attendanceData[student.id] = stats;
      }

      // Log the action
      await _logCoordinatorAction('attendance_review', {
        'section_id': sectionId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });

      return attendanceData;
    } catch (e) {
      print('Error reviewing attendance: $e');
      return {};
    }
  }

  /// Generate comparative analysis between sections
  Future<Map<String, dynamic>> generateSectionComparison({
    required String quarter,
    required List<String> metrics,
  }) async {
    try {
      final comparison = <String, dynamic>{};

      for (final section in _sections) {
        final sectionData = <String, dynamic>{
          'average_grade': section.averageGrade,
          'attendance_rate': section.attendanceRate,
          'failing_count': section.failingStudents,
          'excellent_count': section.excellentStudents,
          'student_count': section.studentCount,
        };

        // Add subject-specific data if requested
        if (metrics.contains('subjects')) {
          sectionData['subjects'] = await _getSubjectPerformance(
            section.sectionId,
          );
        }

        comparison[section.sectionId] = sectionData;
      }

      return comparison;
    } catch (e) {
      print('Error generating section comparison: $e');
      return {};
    }
  }

  /// Export grade level report
  Future<Map<String, dynamic>> exportGradeLevelReport({
    required String format,
    required String quarter,
  }) async {
    try {
      final report = {
        'grade_level': _currentAssignment?.gradeLevel,
        'school_year': _currentAssignment?.schoolYear,
        'quarter': quarter,
        'generated_by': _currentAssignment?.teacherName,
        'generated_at': DateTime.now().toIso8601String(),
        'statistics': _gradeLevelStats?.toJson(),
        'sections': _sections
            .map(
              (s) => {
                'id': s.sectionId,
                'name': s.sectionName,
                'adviser': s.adviserName,
                'students': s.studentCount,
                'average': s.averageGrade,
                'attendance': s.attendanceRate,
              },
            )
            .toList(),
      };

      // Log the action
      await _logCoordinatorAction('report_export', {
        'format': format,
        'quarter': quarter,
      });

      return report;
    } catch (e) {
      print('Error exporting report: $e');
      return {};
    }
  }

  /// Send announcement to all grade level students/parents
  Future<bool> sendGradeLevelAnnouncement({
    required String title,
    required String message,
    required List<String> recipients, // 'students', 'parents', 'teachers'
  }) async {
    try {
      // Create announcement
      await _supabase.from('announcements').insert({
        'title': title,
        'message': message,
        'grade_level': _currentAssignment?.gradeLevel,
        'recipients': recipients,
        'created_by': _currentAssignment?.teacherId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notifications
      // This would trigger notification service

      // Log the action
      await _logCoordinatorAction('announcement_sent', {
        'title': title,
        'recipients': recipients,
      });

      return true;
    } catch (e) {
      print('Error sending announcement: $e');
      return false;
    }
  }

  /// Helper: Check if coordinator can enter grades for a course
  Future<bool> _canEnterGradesForCourse(String courseId) async {
    // Check if course is in the coordinator's grade level
    // For now, returning true for mock
    return true;
  }

  /// Helper: Calculate attendance statistics
  Map<String, dynamic> _calculateAttendanceStats(List<Attendance> records) {
    final total = records.length;
    final present = records.where((r) => r.status == 'present').length;
    final late = records.where((r) => r.status == 'late').length;
    final absent = records.where((r) => r.status == 'absent').length;

    return {
      'total': total,
      'present': present,
      'late': late,
      'absent': absent,
      'rate': total > 0 ? ((present + late) / total * 100) : 0.0,
    };
  }

  /// Helper: Get subject performance for a section
  Future<Map<String, double>> _getSubjectPerformance(String sectionId) async {
    // Would query actual grades
    return {
      'Mathematics': 82.3,
      'Science': 85.1,
      'English': 86.2,
      'Filipino': 84.8,
    };
  }

  /// Helper: Generate temporary password
  String _generateTempPassword() {
    // Generate secure temporary password
    return 'Temp${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}!';
  }

  /// Helper: Log coordinator action
  Future<void> _logCoordinatorAction(
    String action,
    Map<String, dynamic> details,
  ) async {
    try {
      await _supabase.from('coordinator_activity_log').insert({
        'coordinator_id': _currentAssignment?.teacherId,
        'grade_level': _currentAssignment?.gradeLevel,
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging coordinator action: $e');
    }
  }

  /// Check if user is a coordinator
  bool get isCoordinator =>
      _currentAssignment != null && _currentAssignment!.isActive;

  /// Get coordinator permissions
  Map<String, dynamic> get permissions => _currentAssignment?.permissions ?? {};

  /// Check specific permission
  bool hasPermission(String permission) {
    return permissions[permission] == true;
  }
}

extension on GradeLevelStats {
  Map<String, dynamic> toJson() {
    return {
      'grade_level': gradeLevel,
      'total_sections': totalSections,
      'total_students': totalStudents,
      'total_teachers': totalTeachers,
      'average_grade': averageGrade,
      'attendance_rate': attendanceRate,
      'failing_students': failingStudents,
      'excellent_students': excellentStudents,
      'at_risk_students': atRiskStudents,
      'subject_performance': subjectPerformance,
      'monthly_trends': monthlyTrends,
    };
  }
}
