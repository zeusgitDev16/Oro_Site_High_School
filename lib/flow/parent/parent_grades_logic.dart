import 'package:flutter/material.dart';

/// Interactive logic for Parent Grades View
/// Handles grade data, filtering, and calculations
/// Separated from UI as per architecture guidelines
class ParentGradesLogic extends ChangeNotifier {
  // Selected child
  String? _selectedChildId;
  String? get selectedChildId => _selectedChildId;

  // Selected quarter
  String _selectedQuarter = 'Q1';
  String get selectedQuarter => _selectedQuarter;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Mock grades data
  List<Map<String, dynamic>> _grades = [
    {
      'subject': 'Mathematics 7',
      'teacher': 'Maria Santos',
      'quarter': 'Q1',
      'assignments': [
        {
          'title': 'Quiz 1',
          'score': 45,
          'total': 50,
          'percentage': 90,
          'date': '2024-01-08',
          'weight': 0.2,
        },
        {
          'title': 'Project 1',
          'score': 95,
          'total': 100,
          'percentage': 95,
          'date': '2024-01-12',
          'weight': 0.3,
        },
        {
          'title': 'Exam 1',
          'score': 88,
          'total': 100,
          'percentage': 88,
          'date': '2024-01-15',
          'weight': 0.5,
        },
      ],
      'quarterGrade': 91.0,
      'letterGrade': 'A',
    },
    {
      'subject': 'Science 7',
      'teacher': 'Juan Cruz',
      'quarter': 'Q1',
      'assignments': [
        {
          'title': 'Lab Report 1',
          'score': 38,
          'total': 40,
          'percentage': 95,
          'date': '2024-01-09',
          'weight': 0.3,
        },
        {
          'title': 'Quiz 1',
          'score': 42,
          'total': 50,
          'percentage': 84,
          'date': '2024-01-11',
          'weight': 0.2,
        },
        {
          'title': 'Midterm Exam',
          'score': 90,
          'total': 100,
          'percentage': 90,
          'date': '2024-01-14',
          'weight': 0.5,
        },
      ],
      'quarterGrade': 89.5,
      'letterGrade': 'A',
    },
    {
      'subject': 'English 7',
      'teacher': 'Ana Reyes',
      'quarter': 'Q1',
      'assignments': [
        {
          'title': 'Essay 1',
          'score': 42,
          'total': 50,
          'percentage': 84,
          'date': '2024-01-10',
          'weight': 0.3,
        },
        {
          'title': 'Reading Quiz',
          'score': 45,
          'total': 50,
          'percentage': 90,
          'date': '2024-01-12',
          'weight': 0.2,
        },
        {
          'title': 'Oral Presentation',
          'score': 92,
          'total': 100,
          'percentage': 92,
          'date': '2024-01-15',
          'weight': 0.5,
        },
      ],
      'quarterGrade': 89.8,
      'letterGrade': 'A',
    },
    {
      'subject': 'Filipino 7',
      'teacher': 'Pedro Garcia',
      'quarter': 'Q1',
      'assignments': [
        {
          'title': 'Pagsusulit 1',
          'score': 47,
          'total': 50,
          'percentage': 94,
          'date': '2024-01-08',
          'weight': 0.2,
        },
        {
          'title': 'Sanaysay',
          'score': 88,
          'total': 100,
          'percentage': 88,
          'date': '2024-01-13',
          'weight': 0.3,
        },
        {
          'title': 'Eksamen',
          'score': 95,
          'total': 100,
          'percentage': 95,
          'date': '2024-01-15',
          'weight': 0.5,
        },
      ],
      'quarterGrade': 92.6,
      'letterGrade': 'A',
    },
  ];

  List<Map<String, dynamic>> get grades => _grades;

  // Set selected child
  void setSelectedChild(String childId) {
    _selectedChildId = childId;
    notifyListeners();
  }

  // Set quarter
  void setQuarter(String quarter) {
    _selectedQuarter = quarter;
    notifyListeners();
  }

  // Load grades
  Future<void> loadGrades(String childId, String quarter) async {
    _isLoading = true;
    _selectedChildId = childId;
    _selectedQuarter = quarter;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, this would call:
    // - GradeService.getGradesByStudent(childId, quarter)

    _isLoading = false;
    notifyListeners();
  }

  // Calculate overall grade
  double calculateOverallGrade() {
    if (_grades.isEmpty) return 0.0;
    
    final sum = _grades.fold<double>(
      0.0,
      (sum, subject) => sum + (subject['quarterGrade'] as num).toDouble(),
    );
    return sum / _grades.length;
  }

  // Get grades by subject
  List<Map<String, dynamic>> getGradesBySubject(String subject) {
    try {
      final subjectData = _grades.firstWhere((g) => g['subject'] == subject);
      return List<Map<String, dynamic>>.from(subjectData['assignments']);
    } catch (e) {
      return [];
    }
  }

  // Get letter grade from percentage
  String getLetterGrade(double percentage) {
    if (percentage >= 95) return 'A+';
    if (percentage >= 90) return 'A';
    if (percentage >= 85) return 'B+';
    if (percentage >= 80) return 'B';
    if (percentage >= 75) return 'C';
    return 'F';
  }

  // Export grades as PDF (mock)
  Future<void> exportGradesAsPdf() async {
    // Simulate export process
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // In real implementation, this would:
    // - Generate PDF with grades data
    // - Save to device or share
  }

  @override
  void dispose() {
    super.dispose();
  }
}
