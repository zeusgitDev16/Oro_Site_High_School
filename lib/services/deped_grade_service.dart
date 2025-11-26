/// DepEd Grade Calculation Service
/// Implements DepEd Order No. 8, s. 2015 grading system
///
/// Grading Components:
/// - Written Work: 30%
/// - Performance Task: 50%
/// - Quarterly Assessment: 20%

import 'package:oro_site_high_school/models/quarterly_grade.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (writtenWork < 0 ||
        writtenWork > 100 ||
        performanceTask < 0 ||
        performanceTask > 100 ||
        quarterlyAssessment < 0 ||
        quarterlyAssessment > 100) {
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
    return writtenWork >= 0 &&
        writtenWork <= 100 &&
        performanceTask >= 0 &&
        performanceTask <= 100 &&
        quarterlyAssessment >= 0 &&
        quarterlyAssessment <= 100;
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
  List<String> getSubjectsNeedingRemedial(Map<String, double> subjectGrades) {
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
      'Very Satisfactory (85-89)': grades
          .where((g) => g >= 85 && g < 90)
          .length,
      'Satisfactory (80-84)': grades.where((g) => g >= 80 && g < 85).length,
      'Fairly Satisfactory (75-79)': grades
          .where((g) => g >= 75 && g < 80)
          .length,
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

extension _Clamp on num {
  double clampDouble(num lower, num upper) {
    final v = double.tryParse('$this') ?? 0.0;
    final lo = double.tryParse('$lower') ?? 0.0;
    final hi = double.tryParse('$upper') ?? 0.0;
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
  }
}

extension _Round2 on double {
  double roundTo(int fractionDigits) =>
      double.parse(toStringAsFixed(fractionDigits));
}

class DepEdTransmutation {
  // Linear transmutation aligned with common DO 8 practice: 60 + 40*(IG/100)
  static double transmute(double initialGrade) {
    final ig = initialGrade.clampDouble(0, 100);
    final fg = 60.0 + (40.0 * (ig / 100.0));
    // Round to whole number as typically reported on card, but keep 2-decimal option if needed
    return fg.roundToDouble().clampDouble(60, 100);
  }
}

class DepEdWeights {
  // Profiles per subject group from DepEd Order No. 8, s. 2015
  // [WW, PT, QA]
  static const Map<String, List<double>> profiles = {
    'math_science': [0.40, 0.40, 0.20],
    'language': [0.30, 0.50, 0.20], // English/Filipino/AP/EsP
    'mapeh_tle': [0.20, 0.60, 0.20],
  };

  static List<double> autoDetect({String? courseTitle}) {
    final t = (courseTitle ?? '').toLowerCase();
    if (t.contains('math') || t.contains('science')) {
      return profiles['math_science']!;
    }
    if (t.contains('english') ||
        t.contains('filipino') ||
        t.contains('ap') ||
        t.contains('esp')) {
      return profiles['language']!;
    }
    if (t.contains('mapeh') || t.contains('tle') || t.contains('epp')) {
      return profiles['mapeh_tle']!;
    }
    // Default to math/science if unknown
    return profiles['math_science']!;
  }
}

extension DepEdWeightHelper on DepEdGradeService {
  // Helper to get weights either by explicit profile key or auto detect by course title
  List<double> getWeights({String profile = 'auto', String? courseTitle}) {
    if (profile == 'auto')
      return DepEdWeights.autoDetect(courseTitle: courseTitle);
    return DepEdWeights.profiles[profile] ??
        DepEdWeights.autoDetect(courseTitle: courseTitle);
  }

  double transmute(double initialGrade) =>
      DepEdTransmutation.transmute(initialGrade);
}

extension MapGetAs on Map<String, dynamic> {
  T? _as<T>(String k) => this[k] is T ? this[k] as T : null;
}

extension SupaClientExtras on SupabaseClient {
  String? currentUserId() => auth.currentUser?.id;
}

extension DepEdGradePersistence on DepEdGradeService {
  /// Save or update a per-student, per-classroom, per-course, per-quarter grade row.
  /// This expects a table `student_grades` to exist in the DB.
  Future<void> saveOrUpdateStudentQuarterGrade({
    required String studentId,
    required String classroomId,
    required String courseId,
    required int quarter,
    required double initialGrade,
    required double transmutedGrade,
    double? adjustedGrade,
    double plusPoints = 0.0,
    double extraPoints = 0.0,
    String? remarks,
    double? qaScoreOverride,
    double? qaMaxOverride,
    // New: optional custom weight overrides (percent values, e.g., 40 for 40%)
    double? wwWeightPctOverride,
    double? ptWeightPctOverride,
    double? qaWeightPctOverride,
  }) async {
    final supa = Supabase.instance.client;
    final nowIso = DateTime.now().toIso8601String();
    final computedBy = supa.currentUserId();

    Future<void> writeOp({required bool includeOptional}) async {
      final existing = await supa
          .from('student_grades')
          .select()
          .eq('student_id', studentId)
          .eq('classroom_id', classroomId)
          .eq('course_id', courseId)
          .eq('quarter', quarter)
          .maybeSingle();

      final payload = <String, dynamic>{
        'student_id': studentId,
        'classroom_id': classroomId,
        'course_id': courseId,
        'quarter': quarter,
        'initial_grade': initialGrade.roundTo(2),
        'transmuted_grade': transmutedGrade.roundTo(0),
        if (adjustedGrade != null) 'adjusted_grade': adjustedGrade.roundTo(2),
        'plus_points': plusPoints,
        'extra_points': extraPoints,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        'computed_at': nowIso,
        if (computedBy != null) 'computed_by': computedBy,
        'updated_at': nowIso,
      };

      if (includeOptional) {
        // QA manual override only saved when a positive max is specified
        if ((qaMaxOverride ?? 0) > 0) {
          payload['qa_score_override'] = (qaScoreOverride ?? 0).toDouble();
          payload['qa_max_override'] = (qaMaxOverride ?? 0).toDouble();
        }
        // Persist custom weight overrides as FRACTIONS (0.0 - 1.0); set null to clear
        payload['ww_weight_override'] = (wwWeightPctOverride == null)
            ? null
            : (wwWeightPctOverride.clamp(0, 100).toDouble() / 100.0);
        payload['pt_weight_override'] = (ptWeightPctOverride == null)
            ? null
            : (ptWeightPctOverride.clamp(0, 100).toDouble() / 100.0);
        payload['qa_weight_override'] = (qaWeightPctOverride == null)
            ? null
            : (qaWeightPctOverride.clamp(0, 100).toDouble() / 100.0);
        // Debug: log the weights being written (in dev)
        // ignore: avoid_print
        // print('[saveOrUpdateStudentQuarterGrade] includeOptional=$includeOptional ww=${payload['ww_weight_override']} pt=${payload['pt_weight_override']} qa=${payload['qa_weight_override']}');
      }

      if (existing != null) {
        await supa
            .from('student_grades')
            .update(payload)
            .eq('id', existing['id']);
      } else {
        payload['created_at'] = nowIso;
        await supa.from('student_grades').insert(payload);
      }
    }

    try {
      // First attempt: include optional columns (QA + weight overrides)
      await writeOp(includeOptional: true);
    } on PostgrestException catch (e) {
      // Provide a precise, actionable error message for common type/RLS issues
      final code = e.code;
      final message = e.message;
      if (code == '42703' ||
          message.contains('qa_score_override') ||
          message.contains('weight_override')) {
        // Some optional columns do not exist yet; retry without them
        // ignore: avoid_print
        // print('[DepEdGradeService] Optional columns missing, retrying without overrides. err=$code msg=$message');
        await writeOp(includeOptional: false);
        return;
      }
      if (code == '22P02' &&
          (message.contains('uuid') || message.contains('UUID'))) {
        // Likely: student_grades.course_id is UUID while a numeric courseId (e.g., "11") was provided
        // Ask user to run the alignment migration we added to the repo
        throw Exception(
          'Type mismatch (code=22P02): student_grades.course_id expects UUID but received "$courseId". Run database/migrations/FIX_STUDENT_GRADES_COURSE_ID_TYPE.sql to align student_grades.course_id with courses.id.',
        );
      }
      throw Exception(
        'student_grades insert/update failed (code=${code ?? 'unknown'}): $message',
      );
    } catch (e) {
      rethrow;
    }
  }
}

extension DepEdGradeCompute on DepEdGradeService {
  /// Computes DepEd-compliant quarterly grade breakdown for a student
  /// using assignments and submissions filtered by classroom, course and quarter.
  Future<Map<String, dynamic>> computeQuarterlyBreakdown({
    required String classroomId,
    required String courseId,
    required String studentId,
    required int quarter,
    String? courseTitle,
    String weightProfile = 'auto',
    double qaScoreOverride = 0.0,
    double qaMaxOverride = 0.0,
    double plusPoints = 0.0,
    double extraPoints = 0.0,
    // Optional: custom weight overrides as FRACTIONS (0.0 - 1.0)
    double? wwWeightOverride,
    double? ptWeightOverride,
    double? qaWeightOverride,
  }) async {
    final supa = Supabase.instance.client;

    // 1) Load assignments for this class/course/quarter
    //    Include both published and unpublished so the breakdown matches
    //    the teacher's computed grade. Only require is_active=true.
    //
    //    PHASE 5 INTEGRATION: Timeline assignments (with start_time/end_time)
    //    are included regardless of their timeline status. This is correct because:
    //    - Scheduled assignments (before start_time): Included if they have submissions
    //    - Active assignments (between start_time and due_date): Included
    //    - Late assignments (between due_date and end_time): Included
    //    - Ended assignments (after end_time): Included
    //
    //    Grade computation considers ALL assignments in the quarter that have
    //    graded submissions, regardless of timeline visibility to students.
    final assignments = List<Map<String, dynamic>>.from(
      await supa
          .from('assignments')
          .select('id, component, assignment_type, total_points')
          .eq('classroom_id', classroomId)
          .eq('course_id', courseId)
          .eq('is_active', true)
          .or(
            'quarter_no.eq.$quarter,content->meta->>quarter.eq.$quarter,content->meta->>quarter_no.eq.$quarter',
          ),
    );
    final ids = assignments.map((a) => (a['id']).toString()).toList();

    // 2) Load student's submissions for those assignments
    final submissions = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supa
                .from('assignment_submissions')
                .select('assignment_id, score, max_score, status')
                .eq('student_id', studentId)
                .eq('classroom_id', classroomId)
                .inFilter('assignment_id', ids),
          );
    // Consider only graded or scored submissions; ignore missing/ungraded
    final gradedSubs = submissions.where((s) => s['score'] != null).toList();
    final subMap = {
      for (final s in gradedSubs) (s['assignment_id']).toString(): s,
    };

    // 3) Aggregate by component
    double wwScore = 0.0, wwMax = 0.0;
    double ptScore = 0.0, ptMax = 0.0;
    double qaScore = 0.0, qaMax = 0.0;

    for (final a in assignments) {
      final id = (a['id']).toString();
      // Determine component robustly
      String comp = ((a['component'] ?? a['component_type'] ?? '') as String)
          .toString()
          .toLowerCase();
      final String? aType = (a['assignment_type'] as String?)?.toLowerCase();
      // Normalize component variants (e.g., "Performance Task", "performance-task", "PT")
      if (comp.isNotEmpty) {
        var norm = comp.replaceAll(RegExp(r'[^a-z]'), '_');
        if (norm == 'performance_tasks') norm = 'performance_task';
        if (norm == 'written_work') norm = 'written_works';
        if (norm == 'quarterly_assessment' || norm == 'quarterly_assessments') {
          norm = 'quarterly_assessment';
        }
        if (norm != 'written_works' &&
            norm != 'performance_task' &&
            norm != 'quarterly_assessment') {
          if (norm.contains('perform')) {
            norm = 'performance_task';
          } else if (norm.contains('assess') ||
              norm.contains('quarter') ||
              norm.contains('exam')) {
            norm = 'quarterly_assessment';
          } else if (norm.contains('written') ||
              norm.contains('work') ||
              norm.contains('quiz')) {
            norm = 'written_works';
          }
        }
        comp = norm;
      }

      if (comp.isEmpty) {
        // infer from assignment_type
        switch (aType) {
          case 'quiz':
          case 'seatwork':
          case 'worksheet':
          case 'short_answer':
          case 'multiple_choice':
          case 'identification':
          case 'true_false':
          case 'written_work':
          case 'written_works':
            comp = 'written_works';
            break;
          case 'performance_task':
          case 'project':
          case 'presentation':
          case 'essay':
          case 'file_upload':
          case 'performance':
            comp = 'performance_task';
            break;
          case 'exam':
          case 'quarterly_assessment':
          case 'qa':
            comp = 'quarterly_assessment';
            break;
          default:
            if (aType != null) {
              if (aType.contains('perform') ||
                  aType.contains('project') ||
                  aType.contains('present')) {
                comp = 'performance_task';
              } else if (aType.contains('exam') || aType.contains('quarter')) {
                comp = 'quarterly_assessment';
              } else if (aType.contains('quiz') ||
                  aType.contains('written') ||
                  aType.contains('work')) {
                comp = 'written_works';
              }
            }
        }
      }
      if (comp == 'ww') comp = 'written_works';
      if (comp == 'pt') comp = 'performance_task';
      if (comp == 'qa') comp = 'quarterly_assessment';

      // print('[DepEdGradeService.computeQuarterlyBreakdown] id=' + id + ' comp_raw=' + (a['component']?.toString() ?? '') + ' type=' + (aType ?? '') + ' -> comp=' + comp);

      final total = ((a['total_points'] as num?)?.toDouble() ?? 0.0);
      final s = subMap[id];

      // Skip assignments without a graded/scored submission so we don't
      // penalize missing items that were not included in the teacher's compute
      if (s == null) {
        continue;
      }

      final score = ((s['score'] as num?)?.toDouble() ?? 0.0);
      final max = ((s['max_score'] as num?)?.toDouble() ?? total);

      if (comp == 'written_works') {
        wwScore += score;
        wwMax += max;
      } else if (comp == 'performance_task') {
        ptScore += score;
        ptMax += max;
      } else if (comp == 'quarterly_assessment') {
        qaScore += score;
        qaMax += max;
      }
    }

    // If manual QA override provided, use it
    if ((qaMaxOverride) > 0) {
      qaScore = qaScoreOverride;
      qaMax = qaMaxOverride;
    }

    // 4) Compute PS and WS
    double ps(double sc, double mx) => mx > 0 ? (sc / mx) * 100.0 : 0.0;
    final wwPS = ps(wwScore, wwMax);
    final ptPS = ps(ptScore, ptMax);
    final qaPS = ps(qaScore, qaMax);

    final baseWeights = getWeights(
      profile: weightProfile,
      courseTitle: courseTitle,
    );
    // Apply overrides if provided (fractions 0.0-1.0)
    final w0 = (wwWeightOverride ?? baseWeights[0]).clampDouble(0, 1);
    final w1 = (ptWeightOverride ?? baseWeights[1]).clampDouble(0, 1);
    final w2 = (qaWeightOverride ?? baseWeights[2]).clampDouble(0, 1);
    final wwWS = wwPS * w0;
    final ptWS = ptPS * w1;
    final qaWS = qaPS * w2;

    var initial = (wwWS + ptWS + qaWS) + plusPoints + extraPoints;
    initial = initial.clampDouble(0, 100);
    final finalTransmuted = DepEdTransmutation.transmute(initial);

    return {
      'ww_score': wwScore,
      'ww_max': wwMax,
      'ww_ps': wwPS,
      'ww_ws': wwWS,
      'pt_score': ptScore,
      'pt_max': ptMax,
      'pt_ps': ptPS,
      'pt_ws': ptWS,
      'qa_score': qaScore,
      'qa_max': qaMax,
      'qa_ps': qaPS,
      'qa_ws': qaWS,
      'initial_grade': initial,
      'transmuted_grade': finalTransmuted,
      'weights': {'ww': w0, 'pt': w1, 'qa': w2},
    };
  }
}
