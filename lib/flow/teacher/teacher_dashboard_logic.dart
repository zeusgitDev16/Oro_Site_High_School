import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/services/profile_service.dart';
import 'package:oro_site_high_school/services/course_assignment_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/services/attendance_service.dart';
import 'package:oro_site_high_school/services/course_schedule_service.dart';
import 'package:oro_site_high_school/models/course_assignment.dart';

class TeacherDashboardLogic extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final CourseAssignmentService _courseAssignmentService =
      CourseAssignmentService();
  final AssignmentService _assignmentService = AssignmentService();
  final AttendanceService _attendanceService = AttendanceService();
  final CourseScheduleService _courseScheduleService = CourseScheduleService();
  final _supabase = Supabase.instance.client;

  Map<String, dynamic> _teacherData = {
    'firstName': '',
    'lastName': '',
    'email': '',
    'role': '',
    'department': '',
  };

  Map<String, dynamic> _dashboardData = {
    'activeCourses': 0,
    'totalStudents': 0,
    'pendingAssignments': 0,
    'attendanceRate': '0%',
    'upcomingClasses': [],
    'recentActivity': [],
    'upcomingDeadlines': [],
    'myCourses': [],
  };

  bool _isLoading = true;
  String? _error;

  // Getters
  Map<String, dynamic> get teacherData => _teacherData;
  Map<String, dynamic> get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get notificationUnreadCount =>
      5; // TODO: Implement real notification count
  int get messageUnreadCount => 3; // TODO: Implement real message count

  Future<void> loadTeacherProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _error = 'No user logged in';
        notifyListeners();
        return;
      }

      final profile = await _profileService.getProfile(user.id);
      if (profile != null) {
        final fullName = profile.fullName ?? 'Teacher';
        final nameParts = fullName.split(' ');
        _teacherData = {
          'firstName': nameParts.first,
          'lastName': nameParts.length > 1 ? nameParts.last : '',
          'email': profile.email ?? '',
          'role': profile.roleName,
          // TODO: Fetch department from teacher record if needed
          'department': 'General',
        };
        notifyListeners();
      }
    } catch (e) {
      print('Error loading teacher profile: $e');
      _error = e.toString();
    }
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final teacherId = user.id;

      // 1. Fetch active courses (assignments)
      final assignments = await _courseAssignmentService
          .getAssignmentsByTeacher(teacherId);
      final activeCoursesCount = assignments.length;

      // 2. Calculate total students
      int totalStudents = 0;
      for (var assignment in assignments) {
        totalStudents += assignment.studentCount;
      }

      // 3. Fetch pending assignments (pending grading)
      final pendingAssignmentsCount = await _assignmentService
          .getPendingGradingCount(teacherId);

      // 4. Fetch attendance rate
      final attendanceRate = await _attendanceService.getTeacherAttendanceRate(
        teacherId,
      );

      // 5. Fetch upcoming classes
      final courseIds = assignments
          .map((a) => int.tryParse(a.courseId) ?? 0)
          .where((id) => id > 0)
          .toList();
      final upcomingSchedules = await _courseScheduleService
          .getUpcomingClassesForCourses(courseIds);
      final upcomingClasses = upcomingSchedules.map((s) {
        // Find course name from assignments
        final assignment = assignments.firstWhere(
          (a) => a.courseId == s.courseId.toString(),
          orElse: () => CourseAssignment(
            id: '',
            courseId: '',
            teacherId: '',
            teacherName: '',
            courseName: 'Unknown Course',
            section: '',
            assignedDate: DateTime.now(),
            status: '',
            studentCount: 0,
            schoolYear: '',
          ),
        );
        return '${assignment.courseName} (${s.startTime} - ${s.endTime})';
      }).toList();

      // 6. Fetch upcoming deadlines
      final deadlines = await _assignmentService.getTeacherUpcomingDeadlines(
        teacherId,
      );
      final upcomingDeadlines = deadlines.map((d) {
        final date = DateTime.parse(d['due_date']);
        final now = DateTime.now();
        final diff = date.difference(now);
        String status;
        if (diff.inDays < 1) {
          status = 'Urgent';
        } else if (diff.inDays < 3) {
          status = '${diff.inDays} days left';
        } else {
          status = 'Upcoming';
        }

        return {
          'title': d['title'],
          'date':
              '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
          'status': status,
        };
      }).toList();

      // 7. My Courses (just take first 2 for the home view)
      final myCourses = assignments
          .take(2)
          .map(
            (a) => {
              'courseName': a.courseName,
              'courseCode': 'Code', // TODO: Get real code
              'section': a.section,
              'students': a.studentCount,
              'schedule': 'TBA', // TODO: Get real schedule
              'color': Colors.blue, // Placeholder
            },
          )
          .toList();

      _dashboardData = {
        'activeCourses': activeCoursesCount,
        'totalStudents': totalStudents,
        'pendingAssignments': pendingAssignmentsCount,
        'attendanceRate': '${attendanceRate.toStringAsFixed(1)}%',
        'upcomingClasses': upcomingClasses,
        'recentActivity': [], // TODO: Implement recent activity
        'upcomingDeadlines': upcomingDeadlines,
        'myCourses': myCourses,
      };

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading dashboard data: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get initials
  String getInitials() {
    final first = _teacherData['firstName']?.isNotEmpty == true
        ? _teacherData['firstName'][0]
        : '';
    final last = _teacherData['lastName']?.isNotEmpty == true
        ? _teacherData['lastName'][0]
        : '';
    if (first.isEmpty && last.isEmpty) return 'T';
    return '$first$last'.toUpperCase();
  }
}
