import 'package:flutter/material.dart';

/// Interactive logic for Student Grades
/// Handles state management for grades and academic performance
/// Separated from UI as per architecture guidelines
class StudentGradesLogic extends ChangeNotifier {
  // Loading states
  bool _isLoadingGrades = false;
  bool _isLoadingCourseGrades = false;

  bool get isLoadingGrades => _isLoadingGrades;
  bool get isLoadingCourseGrades => _isLoadingCourseGrades;

  // Filter and view options
  String _selectedPeriod = 'Current Quarter'; // Current Quarter, Quarter 1, Quarter 2, etc.
  String _selectedView = 'All Courses'; // All Courses, By Subject

  String get selectedPeriod => _selectedPeriod;
  String get selectedView => _selectedView;

  // Current selections
  int? _selectedCourseId;
  int? get selectedCourseId => _selectedCourseId;

  // Mock grades data - organized by course
  final List<Map<String, dynamic>> _courseGrades = [
    {
      'courseId': 1,
      'courseName': 'Mathematics 7',
      'courseCode': 'MATH-7',
      'teacher': 'Maria Santos',
      'color': Colors.blue,
      'currentGrade': 92.5,
      'letterGrade': 'A',
      'gradeStatus': 'excellent', // excellent, good, satisfactory, needs_improvement
      'quarters': {
        'Q1': {'grade': 90.0, 'letterGrade': 'A'},
        'Q2': {'grade': 93.0, 'letterGrade': 'A'},
        'Q3': {'grade': 94.0, 'letterGrade': 'A'},
        'Q4': null, // Not yet graded
      },
      'components': [
        {
          'name': 'Written Works',
          'weight': 30,
          'score': 185,
          'total': 200,
          'percentage': 92.5,
        },
        {
          'name': 'Performance Tasks',
          'weight': 50,
          'total': 100,
          'score': 93,
          'percentage': 93.0,
        },
        {
          'name': 'Quarterly Assessment',
          'weight': 20,
          'score': 46,
          'total': 50,
          'percentage': 92.0,
        },
      ],
      'recentGrades': [
        {
          'id': 1,
          'assignmentName': 'Quiz 3: Integers',
          'type': 'Written Work',
          'score': 45,
          'total': 50,
          'percentage': 90.0,
          'gradedDate': DateTime.now().subtract(const Duration(days: 2)),
          'feedback': 'Excellent work! Minor error on problem 15.',
        },
        {
          'id': 2,
          'assignmentName': 'Problem Set 5',
          'type': 'Performance Task',
          'score': 48,
          'total': 50,
          'percentage': 96.0,
          'gradedDate': DateTime.now().subtract(const Duration(days: 5)),
          'feedback': 'Outstanding! All solutions are correct and well-explained.',
        },
        {
          'id': 3,
          'assignmentName': 'Quiz 2: Fractions',
          'type': 'Written Work',
          'score': 42,
          'total': 50,
          'percentage': 84.0,
          'gradedDate': DateTime.now().subtract(const Duration(days: 8)),
          'feedback': 'Good effort. Review simplifying complex fractions.',
        },
      ],
    },
    {
      'courseId': 2,
      'courseName': 'Science 7',
      'courseCode': 'SCI-7',
      'teacher': 'Juan Cruz',
      'color': Colors.green,
      'currentGrade': 88.5,
      'letterGrade': 'B+',
      'gradeStatus': 'good',
      'quarters': {
        'Q1': {'grade': 87.0, 'letterGrade': 'B+'},
        'Q2': {'grade': 89.0, 'letterGrade': 'B+'},
        'Q3': {'grade': 90.0, 'letterGrade': 'A'},
        'Q4': null,
      },
      'components': [
        {
          'name': 'Written Works',
          'weight': 30,
          'score': 170,
          'total': 200,
          'percentage': 85.0,
        },
        {
          'name': 'Performance Tasks',
          'weight': 50,
          'score': 90,
          'total': 100,
          'percentage': 90.0,
        },
        {
          'name': 'Quarterly Assessment',
          'weight': 20,
          'score': 44,
          'total': 50,
          'percentage': 88.0,
        },
      ],
      'recentGrades': [
        {
          'id': 4,
          'assignmentName': 'Lab Report: Plant Cells',
          'type': 'Performance Task',
          'score': 45,
          'total': 50,
          'percentage': 90.0,
          'gradedDate': DateTime.now().subtract(const Duration(days: 1)),
          'feedback': 'Great observations and detailed drawings!',
        },
        {
          'id': 5,
          'assignmentName': 'Quiz: Photosynthesis',
          'type': 'Written Work',
          'score': 40,
          'total': 50,
          'percentage': 80.0,
          'gradedDate': DateTime.now().subtract(const Duration(days: 4)),
          'feedback': 'Review the light-dependent reactions.',
        },
      ],
    },
    {
      'courseId': 3,
      'courseName': 'English 7',
      'courseCode': 'ENG-7',
      'teacher': 'Ana Reyes',
      'color': Colors.purple,
      'currentGrade': 94.0,
      'letterGrade': 'A',
      'gradeStatus': 'excellent',
      'quarters': {
        'Q1': {'grade': 93.0, 'letterGrade': 'A'},
        'Q2': {'grade': 94.0, 'letterGrade': 'A'},
        'Q3': {'grade': 95.0, 'letterGrade': 'A'},
        'Q4': null,
      },
      'components': [
        {
          'name': 'Written Works',
          'weight': 30,
          'score': 190,
          'total': 200,
          'percentage': 95.0,
        },
        {
          'name': 'Performance Tasks',
          'weight': 50,
          'score': 94,
          'total': 100,
          'percentage': 94.0,
        },
        {
          'name': 'Quarterly Assessment',
          'weight': 20,
          'score': 46,
          'total': 50,
          'percentage': 92.0,
        },
      ],
      'recentGrades': [
        {
          'id': 6,
          'assignmentName': 'Essay: My Hero',
          'type': 'Performance Task',
          'score': 48,
          'total': 50,
          'percentage': 96.0,
          'gradedDate': DateTime.now().subtract(const Duration(days: 3)),
          'feedback': 'Beautifully written! Strong thesis and supporting details.',
        },
        {
          'id': 7,
          'assignmentName': 'Vocabulary Quiz 4',
          'type': 'Written Work',
          'score': 47,
          'total': 50,
          'percentage': 94.0,
          'gradedDate': DateTime.now().subtract(const Duration(days: 6)),
          'feedback': 'Excellent vocabulary mastery!',
        },
      ],
    },
    {
      'courseId': 4,
      'courseName': 'Filipino 7',
      'courseCode': 'FIL-7',
      'teacher': 'Pedro Santos',
      'color': Colors.orange,
      'currentGrade': 86.0,
      'letterGrade': 'B',
      'gradeStatus': 'good',
      'quarters': {
        'Q1': {'grade': 85.0, 'letterGrade': 'B'},
        'Q2': {'grade': 86.0, 'letterGrade': 'B'},
        'Q3': {'grade': 87.0, 'letterGrade': 'B+'},
        'Q4': null,
      },
      'components': [
        {
          'name': 'Written Works',
          'weight': 30,
          'score': 165,
          'total': 200,
          'percentage': 82.5,
        },
        {
          'name': 'Performance Tasks',
          'weight': 50,
          'score': 88,
          'total': 100,
          'percentage': 88.0,
        },
        {
          'name': 'Quarterly Assessment',
          'weight': 20,
          'score': 43,
          'total': 50,
          'percentage': 86.0,
        },
      ],
      'recentGrades': [
        {
          'id': 8,
          'assignmentName': 'Tula: Pamilya',
          'type': 'Performance Task',
          'score': 42,
          'total': 50,
          'percentage': 84.0,
          'gradedDate': DateTime.now().subtract(const Duration(days: 7)),
          'feedback': 'Maganda ang iyong tula. Dagdagan pa ang paggamit ng tayutay.',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get courseGrades => _courseGrades;

  // Get overall statistics
  Map<String, dynamic> getOverallStatistics() {
    if (_courseGrades.isEmpty) {
      return {
        'gpa': 0.0,
        'averageGrade': 0.0,
        'totalCourses': 0,
        'excellentCount': 0,
        'goodCount': 0,
        'needsImprovementCount': 0,
      };
    }

    final totalGrade = _courseGrades.fold<double>(
      0,
      (sum, course) => sum + (course['currentGrade'] as double),
    );
    final averageGrade = totalGrade / _courseGrades.length;

    // Calculate GPA (4.0 scale)
    final gpa = _calculateGPA(averageGrade);

    // Count by status
    int excellentCount = 0;
    int goodCount = 0;
    int needsImprovementCount = 0;

    for (var course in _courseGrades) {
      switch (course['gradeStatus']) {
        case 'excellent':
          excellentCount++;
          break;
        case 'good':
          goodCount++;
          break;
        case 'needs_improvement':
          needsImprovementCount++;
          break;
      }
    }

    return {
      'gpa': gpa,
      'averageGrade': averageGrade,
      'totalCourses': _courseGrades.length,
      'excellentCount': excellentCount,
      'goodCount': goodCount,
      'needsImprovementCount': needsImprovementCount,
    };
  }

  // Calculate GPA on 4.0 scale
  double _calculateGPA(double percentage) {
    if (percentage >= 95) return 4.0;
    if (percentage >= 90) return 3.5;
    if (percentage >= 85) return 3.0;
    if (percentage >= 80) return 2.5;
    if (percentage >= 75) return 2.0;
    return 1.0;
  }

  // Get course by ID
  Map<String, dynamic>? getCourseGrade(int courseId) {
    try {
      return _courseGrades.firstWhere((c) => c['courseId'] == courseId);
    } catch (e) {
      return null;
    }
  }

  // Get grade trend data for charts
  List<Map<String, dynamic>> getGradeTrend(int courseId) {
    final course = getCourseGrade(courseId);
    if (course == null) return [];

    final quarters = course['quarters'] as Map<String, dynamic>;
    List<Map<String, dynamic>> trend = [];

    quarters.forEach((quarter, data) {
      if (data != null) {
        trend.add({
          'quarter': quarter,
          'grade': data['grade'],
          'letterGrade': data['letterGrade'],
        });
      }
    });

    return trend;
  }

  // Get all recent grades across all courses
  List<Map<String, dynamic>> getAllRecentGrades() {
    List<Map<String, dynamic>> allGrades = [];

    for (var course in _courseGrades) {
      final recentGrades = course['recentGrades'] as List;
      for (var grade in recentGrades) {
        allGrades.add({
          ...grade,
          'courseName': course['courseName'],
          'courseColor': course['color'],
        });
      }
    }

    // Sort by date (most recent first)
    allGrades.sort((a, b) => (b['gradedDate'] as DateTime).compareTo(a['gradedDate'] as DateTime));

    return allGrades;
  }

  // Set filter
  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void setView(String view) {
    _selectedView = view;
    notifyListeners();
  }

  void selectCourse(int courseId) {
    _selectedCourseId = courseId;
    notifyListeners();
  }

  // Load grades
  Future<void> loadGrades() async {
    _isLoadingGrades = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation:
    // final enrollments = await EnrollmentService.getEnrollmentsByStudent(studentId);
    // final courseIds = enrollments.map((e) => e.courseId).toList();
    // final grades = await GradeService.getGradesByCourses(courseIds, studentId);

    _isLoadingGrades = false;
    notifyListeners();
  }

  // Load course-specific grades
  Future<void> loadCourseGrades(int courseId) async {
    _isLoadingCourseGrades = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    // In real implementation:
    // final grades = await GradeService.getCourseGrades(courseId, studentId);
    // final components = await GradeService.getGradeComponents(courseId, studentId);

    _isLoadingCourseGrades = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
