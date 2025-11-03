// Student Repository
// Handles all student-related database operations

import '../base_repository.dart';
import '../models/database_models.dart';

class StudentRepository extends BaseRepository<Student> {
  // Singleton pattern
  static final StudentRepository _instance = StudentRepository._internal();
  factory StudentRepository() => _instance;
  StudentRepository._internal();

  @override
  String get tableName => 'students';

  @override
  Student fromJson(Map<String, dynamic> json) {
    return Student.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Student model) {
    return model.toJson();
  }

  @override
  List<Map<String, dynamic>> getMockData() {
    return List.generate(35, (index) {
      final i = index + 1;
      return {
        'id': 'student-$i',
        'lrn': '${100000000000 + i}',
        'grade_level': 7 + (index ~/ 35), // Distribute across grades
        'section': '${7 + (index ~/ 35)}-${String.fromCharCode(65 + (index % 4))}', // 7-A, 7-B, etc.
        'is_active': true,
        'guardian_name': 'Guardian $i',
        'guardian_contact': '09${170000000 + i}',
        'address': 'Address $i, Oro Site, CDO',
        'birth_date': DateTime(2010 + (index ~/ 35), (index % 12) + 1, (index % 28) + 1).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };
    });
  }

  // ==================== CUSTOM QUERIES ====================

  /// Get students by grade level and section
  Future<List<Student>> getByGradeAndSection({
    required int gradeLevel,
    required String section,
    bool activeOnly = true,
  }) async {
    final filters = [
      QueryFilter(column: 'grade_level', value: gradeLevel),
      QueryFilter(column: 'section', value: section),
    ];
    
    if (activeOnly) {
      filters.add(QueryFilter(column: 'is_active', value: true));
    }
    
    return await getAll(
      filters: filters,
      sortOrder: SortOrder(column: 'lrn'),
    );
  }

  /// Get student by LRN
  Future<Student?> getByLrn(String lrn) async {
    return await getOne(
      filters: [QueryFilter(column: 'lrn', value: lrn)],
    );
  }

  /// Get students with profile information
  Future<List<Map<String, dynamic>>> getStudentsWithProfiles({
    int? gradeLevel,
    String? section,
  }) async {
    try {
      if (useMockData) {
        // Return mock data with profile info
        return getMockData().map((student) {
          return {
            ...student,
            'profile': {
              'id': student['id'],
              'full_name': 'Student ${student['id'].split('-').last}',
              'email': 'student${student['id'].split('-').last}@orosite.edu.ph',
              'avatar_url': null,
            },
          };
        }).toList();
      }

      var query = client
          .from(tableName)
          .select('*, profiles!inner(*)');
      
      if (gradeLevel != null) {
        query = query.eq('grade_level', gradeLevel);
      }
      
      if (section != null) {
        query = query.eq('section', section);
      }
      
      return await query;
      
    } catch (e) {
      throw RepositoryException('Failed to fetch students with profiles', e);
    }
  }

  /// Get student enrollments
  Future<List<Map<String, dynamic>>> getStudentEnrollments(String studentId) async {
    try {
      if (useMockData) {
        return [
          {
            'id': 'enrollment-1',
            'student_id': studentId,
            'course_id': 1,
            'status': 'active',
            'course': {
              'id': 1,
              'name': 'Mathematics 7',
              'code': 'MATH7',
            },
          },
          {
            'id': 'enrollment-2',
            'student_id': studentId,
            'course_id': 2,
            'status': 'active',
            'course': {
              'id': 2,
              'name': 'Science 7',
              'code': 'SCI7',
            },
          },
        ];
      }

      return await client
          .from('enrollments')
          .select('*, courses(*)')
          .eq('student_id', studentId)
          .eq('status', 'active');
      
    } catch (e) {
      throw RepositoryException('Failed to fetch student enrollments', e);
    }
  }

  /// Get student grades
  Future<List<Map<String, dynamic>>> getStudentGrades(
    String studentId, {
    String? quarter,
    int? courseId,
  }) async {
    try {
      if (useMockData) {
        return [
          {
            'id': 1,
            'student_id': studentId,
            'course_id': courseId ?? 1,
            'quarter': quarter ?? 'Q1',
            'written_work': 85.0,
            'performance_task': 88.0,
            'quarterly_exam': 82.0,
            'final_grade': 85.0,
            'course': {
              'name': 'Mathematics 7',
              'code': 'MATH7',
            },
          },
        ];
      }

      var query = client
          .from('grades')
          .select('*, courses(*)')
          .eq('student_id', studentId);
      
      if (quarter != null) {
        query = query.eq('quarter', quarter);
      }
      
      if (courseId != null) {
        query = query.eq('course_id', courseId);
      }
      
      return await query;
      
    } catch (e) {
      throw RepositoryException('Failed to fetch student grades', e);
    }
  }

  /// Get student attendance
  Future<List<Map<String, dynamic>>> getStudentAttendance(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (useMockData) {
        final now = DateTime.now();
        return List.generate(20, (index) {
          final date = now.subtract(Duration(days: index));
          return {
            'id': 'attendance-$index',
            'student_id': studentId,
            'date': date.toIso8601String(),
            'status': index % 10 == 0 ? 'absent' : (index % 5 == 0 ? 'late' : 'present'),
            'time_in': date.add(Duration(hours: 7, minutes: 30)).toIso8601String(),
          };
        });
      }

      var query = client
          .from('attendance')
          .select()
          .eq('student_id', studentId);
      
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }
      
      return await query.order('date', ascending: false);
      
    } catch (e) {
      throw RepositoryException('Failed to fetch student attendance', e);
    }
  }

  /// Update student section
  Future<bool> updateSection(String studentId, String newSection) async {
    try {
      await update(studentId, {'section': newSection});
      return true;
    } catch (e) {
      log('Failed to update student section: $e');
      return false;
    }
  }

  /// Promote students to next grade level
  Future<bool> promoteStudents(List<String> studentIds, int newGradeLevel) async {
    try {
      await updateMany(
        filters: [QueryFilter(column: 'id', value: studentIds, operator: 'in')],
        data: {'grade_level': newGradeLevel},
      );
      return true;
    } catch (e) {
      log('Failed to promote students: $e');
      return false;
    }
  }

  /// Get attendance summary
  Future<Map<String, dynamic>> getAttendanceSummary(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final attendance = await getStudentAttendance(
        studentId,
        startDate: startDate,
        endDate: endDate,
      );
      
      int present = 0;
      int late = 0;
      int absent = 0;
      
      for (final record in attendance) {
        switch (record['status']) {
          case 'present':
            present++;
            break;
          case 'late':
            late++;
            break;
          case 'absent':
            absent++;
            break;
        }
      }
      
      final total = present + late + absent;
      final attendanceRate = total > 0 ? ((present + late) / total * 100) : 0.0;
      
      return {
        'present': present,
        'late': late,
        'absent': absent,
        'total': total,
        'attendance_rate': attendanceRate,
      };
      
    } catch (e) {
      throw RepositoryException('Failed to get attendance summary', e);
    }
  }

  /// Search students
  Future<List<Student>> searchStudents(String query) async {
    try {
      if (useMockData) {
        final mockData = getMockData();
        final filtered = mockData.where((student) {
          final lrn = student['lrn'].toString().toLowerCase();
          final searchQuery = query.toLowerCase();
          return lrn.contains(searchQuery);
        }).toList();
        
        return filtered.map((json) => fromJson(json)).toList();
      }

      final response = await client
          .from(tableName)
          .select()
          .or('lrn.ilike.%$query%');
      
      return (response as List).map((json) => fromJson(json)).toList();
      
    } catch (e) {
      throw RepositoryException('Failed to search students', e);
    }
  }

  /// Get class list for a section
  Future<List<Map<String, dynamic>>> getClassList({
    required int gradeLevel,
    required String section,
  }) async {
    try {
      final students = await getStudentsWithProfiles(
        gradeLevel: gradeLevel,
        section: section,
      );
      
      // Sort by last name
      students.sort((a, b) {
        final aName = a['profile']?['full_name'] ?? '';
        final bName = b['profile']?['full_name'] ?? '';
        return aName.compareTo(bName);
      });
      
      return students;
      
    } catch (e) {
      throw RepositoryException('Failed to get class list', e);
    }
  }
}