import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/backend_service.dart';

/// Student Profile Logic - Interactive logic for student profile management
/// Handles profile data, sidebar navigation, and tab state
/// UI components in lib/screens/student/profile/
class StudentProfileLogic extends ChangeNotifier {
  // Sidebar selection state (0=Profile, 1=Settings, 2=Security)
  int _sidebarSelectedIndex = 0;

  final BackendService _backendService = BackendService();

  // Mock student data - will be overridden by backend when available
  final Map<String, dynamic> _studentData = {
    'studentId': 'S-2024-001',
    'lrn': '123456789012', // Learner Reference Number (12 digits)
    'firstName': 'Juan',
    'lastName': 'Dela Cruz',
    'middleName': 'Santos',
    'email': 'juan.delacruz@oshs.edu.ph',
    'phone': '+63 912 345 6789',
    'gradeLevel': 'Grade 7',
    'section': '7-Diamond',
    'adviser': 'Maria Santos',
    'enrollmentDate': 'August 15, 2024',
    'birthDate': 'January 15, 2010',
    'age': 14,
    'address': 'Brgy. Carmen, Cagayan de Oro City',
    'guardian': 'Pedro Dela Cruz',
    'guardianRelation': 'Father',
    'guardianPhone': '+63 912 345 6780',
    'guardianEmail': 'pedro.delacruz@gmail.com',
    'bio':
        'I am a Grade 7 student passionate about mathematics and science. I enjoy learning new things and participating in school activities. My goal is to excel in my studies and contribute positively to our school community.',
    'interests': ['Mathematics', 'Science', 'Reading', 'Basketball'],
    'achievements': [
      'Honor Student - 1st Quarter',
      'Math Quiz Bee - 2nd Place',
      'Perfect Attendance - September',
    ],
  };

  // Academic statistics
  final Map<String, dynamic> _academicStats = {
    'gpa': 92.5,
    'attendanceRate': 98.5,
    'assignmentsCompleted': 24,
    'totalAssignments': 26,
    'coursesEnrolled': 8,
    'rank': 5,
    'totalStudents': 35,
  };

  // Weekly schedule
  final List<Map<String, dynamic>> _weeklySchedule = [
    {
      'day': 'Monday',
      'schedule': [
        {
          'time': '7:30 AM - 8:30 AM',
          'subject': 'Mathematics 7',
          'room': 'Room 101',
        },
        {
          'time': '8:30 AM - 9:30 AM',
          'subject': 'Science 7',
          'room': 'Room 102',
        },
        {
          'time': '9:30 AM - 10:30 AM',
          'subject': 'English 7',
          'room': 'Room 103',
        },
        {
          'time': '10:30 AM - 11:30 AM',
          'subject': 'Filipino 7',
          'room': 'Room 104',
        },
        {
          'time': '1:00 PM - 2:00 PM',
          'subject': 'Araling Panlipunan 7',
          'room': 'Room 105',
        },
        {'time': '2:00 PM - 3:00 PM', 'subject': 'MAPEH 7', 'room': 'Gym'},
      ],
    },
    {
      'day': 'Tuesday',
      'schedule': [
        {
          'time': '7:30 AM - 8:30 AM',
          'subject': 'Mathematics 7',
          'room': 'Room 101',
        },
        {
          'time': '8:30 AM - 9:30 AM',
          'subject': 'Science 7',
          'room': 'Room 102',
        },
        {
          'time': '9:30 AM - 10:30 AM',
          'subject': 'English 7',
          'room': 'Room 103',
        },
        {
          'time': '10:30 AM - 11:30 AM',
          'subject': 'Filipino 7',
          'room': 'Room 104',
        },
        {'time': '1:00 PM - 2:00 PM', 'subject': 'TLE 7', 'room': 'Room 106'},
        {
          'time': '2:00 PM - 3:00 PM',
          'subject': 'Values Education',
          'room': 'Room 107',
        },
      ],
    },
    {
      'day': 'Wednesday',
      'schedule': [
        {
          'time': '7:30 AM - 8:30 AM',
          'subject': 'Mathematics 7',
          'room': 'Room 101',
        },
        {
          'time': '8:30 AM - 9:30 AM',
          'subject': 'Science 7',
          'room': 'Room 102',
        },
        {
          'time': '9:30 AM - 10:30 AM',
          'subject': 'English 7',
          'room': 'Room 103',
        },
        {
          'time': '10:30 AM - 11:30 AM',
          'subject': 'Filipino 7',
          'room': 'Room 104',
        },
        {
          'time': '1:00 PM - 2:00 PM',
          'subject': 'Araling Panlipunan 7',
          'room': 'Room 105',
        },
        {'time': '2:00 PM - 3:00 PM', 'subject': 'MAPEH 7', 'room': 'Gym'},
      ],
    },
    {
      'day': 'Thursday',
      'schedule': [
        {
          'time': '7:30 AM - 8:30 AM',
          'subject': 'Mathematics 7',
          'room': 'Room 101',
        },
        {
          'time': '8:30 AM - 9:30 AM',
          'subject': 'Science 7',
          'room': 'Room 102',
        },
        {
          'time': '9:30 AM - 10:30 AM',
          'subject': 'English 7',
          'room': 'Room 103',
        },
        {
          'time': '10:30 AM - 11:30 AM',
          'subject': 'Filipino 7',
          'room': 'Room 104',
        },
        {'time': '1:00 PM - 2:00 PM', 'subject': 'TLE 7', 'room': 'Room 106'},
        {
          'time': '2:00 PM - 3:00 PM',
          'subject': 'Values Education',
          'room': 'Room 107',
        },
      ],
    },
    {
      'day': 'Friday',
      'schedule': [
        {
          'time': '7:30 AM - 8:30 AM',
          'subject': 'Mathematics 7',
          'room': 'Room 101',
        },
        {
          'time': '8:30 AM - 9:30 AM',
          'subject': 'Science 7',
          'room': 'Room 102',
        },
        {
          'time': '9:30 AM - 10:30 AM',
          'subject': 'English 7',
          'room': 'Room 103',
        },
        {
          'time': '10:30 AM - 11:30 AM',
          'subject': 'Filipino 7',
          'room': 'Room 104',
        },
        {
          'time': '1:00 PM - 2:00 PM',
          'subject': 'Araling Panlipunan 7',
          'room': 'Room 105',
        },
        {'time': '2:00 PM - 3:00 PM', 'subject': 'MAPEH 7', 'room': 'Gym'},
      ],
    },
  ];

  // Enrolled courses
  final List<Map<String, dynamic>> _enrolledCourses = [
    {
      'code': 'MATH7',
      'name': 'Mathematics 7',
      'teacher': 'Maria Santos',
      'grade': 94,
    },
    {'code': 'SCI7', 'name': 'Science 7', 'teacher': 'Juan Cruz', 'grade': 92},
    {'code': 'ENG7', 'name': 'English 7', 'teacher': 'Ana Reyes', 'grade': 91},
    {
      'code': 'FIL7',
      'name': 'Filipino 7',
      'teacher': 'Pedro Santos',
      'grade': 93,
    },
    {
      'code': 'AP7',
      'name': 'Araling Panlipunan 7',
      'teacher': 'Rosa Garcia',
      'grade': 90,
    },
    {
      'code': 'MAPEH7',
      'name': 'MAPEH 7',
      'teacher': 'Carlos Ramos',
      'grade': 95,
    },
    {'code': 'TLE7', 'name': 'TLE 7', 'teacher': 'Linda Torres', 'grade': 92},
    {
      'code': 'VE7',
      'name': 'Values Education',
      'teacher': 'Sofia Martinez',
      'grade': 94,
    },
  ];

  // Getters
  int get sidebarSelectedIndex => _sidebarSelectedIndex;
  Map<String, dynamic> get studentData => _studentData;
  Map<String, dynamic> get academicStats => _academicStats;
  List<Map<String, dynamic>> get weeklySchedule => _weeklySchedule;
  List<Map<String, dynamic>> get enrolledCourses => _enrolledCourses;

  // Methods
  void setSidebarIndex(int index) {
    _sidebarSelectedIndex = index;
    notifyListeners();
  }

  /// Load current student data from backend and map into this logic's
  /// studentData structure. Safe to call multiple times.
  Future<void> loadFromBackend() async {
    try {
      final student = await _backendService.getCurrentStudent();
      if (student == null) {
        return;
      }

      // Map database fields (snake_case) into the existing UI keys
      _studentData['studentId'] =
          student['id'] as String? ?? _studentData['studentId'];
      _studentData['lrn'] = (student['lrn'] ?? _studentData['lrn']) as String;
      _studentData['firstName'] =
          (student['first_name'] ?? _studentData['firstName']) as String;
      _studentData['lastName'] =
          (student['last_name'] ?? _studentData['lastName']) as String;
      _studentData['middleName'] =
          (student['middle_name'] ?? _studentData['middleName']) as String;
      _studentData['email'] =
          (student['email'] ?? _studentData['email']) as String? ??
          _studentData['email'];
      _studentData['phone'] =
          (student['contact_number'] ?? _studentData['phone']) as String;

      final gradeLevel = student['grade_level'];
      if (gradeLevel != null) {
        _studentData['gradeLevel'] = 'Grade $gradeLevel';
      }

      _studentData['section'] =
          (student['section'] ?? _studentData['section']) as String;
      _studentData['address'] =
          (student['address'] ?? _studentData['address']) as String;

      // Guardian info: map from guardian_name/guardian_contact when available
      _studentData['guardian'] =
          (student['guardian_name'] ?? _studentData['guardian']) as String;
      _studentData['guardianRelation'] =
          (student['guardian_relationship'] ?? _studentData['guardianRelation'])
              as String;
      _studentData['guardianPhone'] =
          (student['guardian_contact'] ?? _studentData['guardianPhone'])
              as String;

      // Keep guardianEmail from mock for now; we don't yet store it in DB

      // Enrollment date: use ISO string or keep existing friendly text
      if (student['enrollment_date'] != null) {
        _studentData['enrollmentDate'] = student['enrollment_date'].toString();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading student profile (StudentProfileLogic): $e');
    }
  }

  void updateStudentData(Map<String, dynamic> updates) {
    _studentData.addAll(updates);
    notifyListeners();
  }

  void updateBio(String newBio) {
    _studentData['bio'] = newBio;
    notifyListeners();
  }

  void updateContactInfo({String? phone, String? address}) {
    if (phone != null) _studentData['phone'] = phone;
    if (address != null) _studentData['address'] = address;
    notifyListeners();
  }

  void updateGuardianInfo({
    String? guardianName,
    String? guardianPhone,
    String? guardianEmail,
  }) {
    if (guardianName != null) _studentData['guardian'] = guardianName;
    if (guardianPhone != null) _studentData['guardianPhone'] = guardianPhone;
    if (guardianEmail != null) _studentData['guardianEmail'] = guardianEmail;
    notifyListeners();
  }

  // Calculate completion percentage
  double getAssignmentCompletionRate() {
    final completed = _academicStats['assignmentsCompleted'] as int;
    final total = _academicStats['totalAssignments'] as int;
    return (completed / total) * 100;
  }

  // Get initials for avatar
  String getInitials() {
    final firstName = _studentData['firstName'] as String;
    final lastName = _studentData['lastName'] as String;
    return '${firstName[0]}${lastName[0]}';
  }

  // Get full name
  String getFullName() {
    final firstName = _studentData['firstName'] as String;
    final middleName = _studentData['middleName'] as String;
    final lastName = _studentData['lastName'] as String;
    return '$firstName $middleName $lastName';
  }

  // Get grade level and section
  String getGradeAndSection() {
    final gradeLevel = _studentData['gradeLevel'] as String;
    final section = _studentData['section'] as String;
    return '$gradeLevel - $section';
  }
}
