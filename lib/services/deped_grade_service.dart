/// DepEd Grade Calculation Service
/// Implements DepEd Order No. 8, s. 2015 grading system
/// 
/// Grading Components:
/// - Written Work: 30%
/// - Performance Task: 50%
/// - Quarterly Assessment: 20%

import 'package:oro_site_high_school/models/quarterly_grade.dart';

class DepEdGradeService {
  // Singleton pattern
  static final DepEdGradeService _instance = DepEdGradeService._internal();
  factory DepEdGradeService() => _instance;
  DepEdGradeService._internal();

  // DepEd Grading Weights
  static const double WRITTEN_WORK_WEIGHT = 0.30;
  static const double PERFORMANCE_TASK_WEIGHT = 0.50;
  static const double QUARTERLY_ASSESSMENT_WEIGHT = 0.20;
  static const double PASSING_GRADE = 75.0;

  /// Calculate quarter grade using DepEd formula
  double calculateQuarterGrade({
    required double writtenWork,
    required double performanceTask,
    required double quarterlyAssessment,
  }) {
    // Validate inputs (0-100 scale)
    if (writtenWork < 0 || writtenWork > 100 ||
        performanceTask < 0 || performanceTask > 100 ||
        quarterlyAssessment < 0 || quarterlyAssessment > 100) {
      throw ArgumentError('All grades must be between 0 and 100');
    }

    return (writtenWork * WRITTEN_WORK_WEIGHT) +
           (performanceTask * PERFORMANCE_TASK_WEIGHT) +
           (quarterlyAssessment * QUARTERLY_ASSESSMENT_WEIGHT);
  }

  /// Calculate final grade (average of 4 quarters)
  double calculateFinalGrade(List<double> quarterGrades) {
    if (quarterGrades.isEmpty) {
      throw ArgumentError('Quarter grades cannot be empty');
    }

    if (quarterGrades.length > 4) {
      throw ArgumentError('Cannot have more than 4 quarter grades');
    }

    return quarterGrades.reduce((a, b) => a + b) / quarterGrades.length;
  }

  /// Get grade descriptor based on DepEd scale
  String getGradeDescriptor(double grade) {
    if (grade >= 90) return 'Outstanding';
    if (grade >= 85) return 'Very Satisfactory';
    if (grade >= 80) return 'Satisfactory';
    if (grade >= 75) return 'Fairly Satisfactory';
    return 'Did Not Meet Expectations';
  }

  /// Check if student passed
  bool isPassing(double grade) {
    return grade >= PASSING_GRADE;
  }

  /// Get grade remarks for report card
  String getGradeRemarks(double grade) {
    if (grade >= 90) {
      return 'The student has shown outstanding performance in the learning competencies.';
    } else if (grade >= 85) {
      return 'The student has shown very satisfactory performance in the learning competencies.';
    } else if (grade >= 80) {
      return 'The student has shown satisfactory performance in the learning competencies.';
    } else if (grade >= 75) {
      return 'The student has shown fairly satisfactory performance in the learning competencies.';
    } else {
      return 'The student did not meet expectations. Remedial classes are recommended.';
    }
  }

  /// Transmute raw score to percentage (if needed)
  /// For example, if written work is out of 50 points
  double transmuteScore({
    required double rawScore,
    required double totalPoints,
  }) {
    if (totalPoints == 0) return 0.0;
    return (rawScore / totalPoints) * 100;
  }

  /// Calculate weighted score for a component
  double calculateWeightedScore({
    required double score,
    required double weight,
  }) {
    return score * weight;
  }

  /// Validate quarter grade components
  bool validateGradeComponents({
    required double writtenWork,
    required double performanceTask,
    required double quarterlyAssessment,
  }) {
    return writtenWork >= 0 && writtenWork <= 100 &&
           performanceTask >= 0 && performanceTask <= 100 &&
           quarterlyAssessment >= 0 && quarterlyAssessment <= 100;
  }

  /// Round grade to 2 decimal places
  double roundGrade(double grade) {
    return double.parse(grade.toStringAsFixed(2));
  }

  /// Check if student needs remedial (below 75%)
  bool needsRemedial(double grade) {
    return grade < PASSING_GRADE;
  }

  /// Calculate grade improvement needed to pass
  double gradeImprovementNeeded(double currentGrade) {
    if (currentGrade >= PASSING_GRADE) return 0.0;
    return PASSING_GRADE - currentGrade;
  }

  /// Get honor roll status
  String? getHonorStatus(double finalGrade) {
    if (finalGrade >= 98) return 'With Highest Honors';
    if (finalGrade >= 95) return 'With High Honors';
    if (finalGrade >= 90) return 'With Honors';
    return null;
  }

  /// Calculate GPA (General Point Average) for multiple subjects
  double calculateGPA(List<double> subjectGrades) {
    if (subjectGrades.isEmpty) return 0.0;
    return subjectGrades.reduce((a, b) => a + b) / subjectGrades.length;
  }

  /// Check if student is eligible for promotion
  bool isEligibleForPromotion(List<double> finalGrades) {
    // Student must pass all subjects (75% or higher)
    return finalGrades.every((grade) => grade >= PASSING_GRADE);
  }

  /// Get subjects that need remedial
  List<String> getSubjectsNeedingRemedial(
    Map<String, double> subjectGrades,
  ) {
    return subjectGrades.entries
        .where((entry) => entry.value < PASSING_GRADE)
        .map((entry) => entry.key)
        .toList();
  }

  /// Calculate class average
  double calculateClassAverage(List<double> studentGrades) {
    if (studentGrades.isEmpty) return 0.0;
    return studentGrades.reduce((a, b) => a + b) / studentGrades.length;
  }

  /// Get grade distribution
  Map<String, int> getGradeDistribution(List<double> grades) {
    return {
      'Outstanding (90-100)': grades.where((g) => g >= 90).length,
      'Very Satisfactory (85-89)': grades.where((g) => g >= 85 && g < 90).length,
      'Satisfactory (80-84)': grades.where((g) => g >= 80 && g < 85).length,
      'Fairly Satisfactory (75-79)': grades.where((g) => g >= 75 && g < 80).length,
      'Did Not Meet Expectations (<75)': grades.where((g) => g < 75).length,
    };
  }

  /// Calculate percentile rank
  int calculatePercentileRank(double studentGrade, List<double> allGrades) {
    if (allGrades.isEmpty) return 0;
    
    final sorted = List<double>.from(allGrades)..sort();
    final position = sorted.where((g) => g < studentGrade).length;
    
    return ((position / allGrades.length) * 100).round();
  }

  /// Mock data for testing (will be replaced with backend)
  List<QuarterlyGrade> getMockQuarterlyGrades() {
    final now = DateTime.now();
    return [
      QuarterlyGrade(
        id: 'qg-001',
        studentId: 'student-001',
        studentName: 'Juan Dela Cruz',
        courseId: 'course-001',
        courseName: 'Mathematics 7',
        quarter: 1,
        schoolYear: '2023-2024',
        writtenWork: 85.0,
        performanceTask: 90.0,
        quarterlyAssessment: 88.0,
        quarterGrade: calculateQuarterGrade(
          writtenWork: 85.0,
          performanceTask: 90.0,
          quarterlyAssessment: 88.0,
        ),
        transmutedGrade: '88',
        teacherId: 'teacher-001',
        teacherName: 'Maria Santos',
        status: 'approved',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
