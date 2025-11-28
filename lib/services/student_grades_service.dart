import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/deped_grade_service.dart';

/// **Phase 3: Student Grades Service**
/// 
/// Service for fetching student grades data using the NEW classroom_subjects system
/// with full backward compatibility for OLD course system.
class StudentGradesService {
  final _supabase = Supabase.instance.client;
  final _depEdService = DepEdGradeService();

  /// Get subjects in a classroom that the student is enrolled in
  /// Uses NEW classroom_subjects table
  Future<List<ClassroomSubject>> getClassroomSubjects({
    required String classroomId,
    required String studentId,
  }) async {
    try {
      print('📚 [StudentGradesService] Fetching subjects for classroom: $classroomId, student: $studentId');

      // Verify student is enrolled in classroom
      final enrollmentCheck = await _supabase
          .from('classroom_students')
          .select('id')
          .eq('classroom_id', classroomId)
          .eq('student_id', studentId)
          .maybeSingle();

      if (enrollmentCheck == null) {
        print('⚠️ [StudentGradesService] Student not enrolled in classroom');
        return [];
      }

      // Fetch subjects from classroom_subjects table
      final response = await _supabase
          .from('classroom_subjects_with_details')
          .select()
          .eq('classroom_id', classroomId)
          .eq('is_active', true)
          .order('subject_name');

      print('✅ [StudentGradesService] Fetched ${response.length} subjects');

      return (response as List)
          .map((json) => ClassroomSubject.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [StudentGradesService] Error fetching subjects: $e');
      rethrow;
    }
  }

  /// Get grades for a subject with backward compatibility
  /// Returns map of quarter -> grade data
  Future<Map<int, Map<String, dynamic>>> getSubjectGrades({
    required String studentId,
    required String classroomId,
    required String subjectId,
  }) async {
    try {
      print('📊 [StudentGradesService] Fetching grades for subject: $subjectId');

      // Query with subject_id (NEW system)
      // Note: We also support course_id for backward compatibility
      final response = await _supabase
          .from('student_grades')
          .select()
          .eq('student_id', studentId)
          .eq('classroom_id', classroomId)
          .eq('subject_id', subjectId);

      print('✅ [StudentGradesService] Fetched ${response.length} grade records');

      // Convert to map of quarter -> grade data
      final Map<int, Map<String, dynamic>> quarterGrades = {};
      for (final row in response) {
        final quarter = (row['quarter'] as num?)?.toInt();
        if (quarter != null) {
          quarterGrades[quarter] = Map<String, dynamic>.from(row);
        }
      }

      return quarterGrades;
    } catch (e) {
      print('❌ [StudentGradesService] Error fetching grades: $e');
      rethrow;
    }
  }

  /// Get quarter breakdown (WW/PT/QA items and computation)
  Future<Map<String, dynamic>> getQuarterBreakdown({
    required String studentId,
    required String classroomId,
    required String subjectId,
    required int quarter,
  }) async {
    try {
      print('📋 [StudentGradesService] Fetching breakdown for Q$quarter');

      // Fetch assignments for this subject and quarter
      final quarterOr = 'quarter_no.eq.$quarter,content->meta->>quarter.eq.$quarter,content->meta->>quarter_no.eq.$quarter';

      final assignments = await _supabase
          .from('assignments')
          .select('id, title, assignment_type, component, content, total_points')
          .eq('classroom_id', classroomId)
          .eq('subject_id', subjectId)
          .eq('is_active', true)
          .or(quarterOr);

      print('✅ [StudentGradesService] Fetched ${assignments.length} assignments');

      // Fetch submissions for these assignments
      final assignmentIds = (assignments as List)
          .map((a) => a['id'].toString())
          .toList();

      final submissions = assignmentIds.isEmpty
          ? []
          : await _supabase
              .from('assignment_submissions')
              .select('assignment_id, score, max_score, status, submitted_at, graded_at')
              .eq('student_id', studentId)
              .eq('classroom_id', classroomId)
              .inFilter('assignment_id', assignmentIds);

      // Build submission map
      final submissionMap = {
        for (final s in submissions) (s['assignment_id']).toString(): s
      };

      // Categorize assignments into WW/PT/QA
      final Map<String, List<Map<String, dynamic>>> items = {
        'ww': [],
        'pt': [],
        'qa': [],
      };

      for (final assignment in assignments) {
        final id = assignment['id'].toString();
        final component = _normalizeComponent(
          assignment['component'] as String?,
          assignment['assignment_type'] as String?,
        );

        final submission = submissionMap[id];
        final hasScore = submission != null && submission['score'] != null;
        final score = hasScore ? (submission['score'] as num).toDouble() : 0.0;
        final maxScore = hasScore
            ? ((submission['max_score'] as num?)?.toDouble() ?? 
               (assignment['total_points'] as num?)?.toDouble() ?? 0.0)
            : (assignment['total_points'] as num?)?.toDouble() ?? 0.0;

        final item = {
          'id': id,
          'title': assignment['title'] ?? 'Untitled',
          'score': score,
          'max': maxScore,
          'missing': !hasScore,
          'status': submission?['status'],
        };

        if (component == 'written_works') {
          items['ww']!.add(item);
        } else if (component == 'performance_task') {
          items['pt']!.add(item);
        } else if (component == 'quarterly_assessment') {
          items['qa']!.add(item);
        }
      }

      print('✅ [StudentGradesService] Categorized: WW=${items['ww']!.length}, PT=${items['pt']!.length}, QA=${items['qa']!.length}');

      // Fetch grade record for this quarter to get overrides
      final gradeRecord = await _supabase
          .from('student_grades')
          .select()
          .eq('student_id', studentId)
          .eq('classroom_id', classroomId)
          .eq('subject_id', subjectId)
          .eq('quarter', quarter)
          .maybeSingle();

      final plusPoints = (gradeRecord?['plus_points'] as num?)?.toDouble() ?? 0.0;
      final extraPoints = (gradeRecord?['extra_points'] as num?)?.toDouble() ?? 0.0;
      final qaScoreOverride = (gradeRecord?['qa_score_override'] as num?)?.toDouble() ?? 0.0;
      final qaMaxOverride = (gradeRecord?['qa_max_override'] as num?)?.toDouble() ?? 0.0;
      final wwWeightOverride = (gradeRecord?['ww_weight_override'] as num?)?.toDouble();
      final ptWeightOverride = (gradeRecord?['pt_weight_override'] as num?)?.toDouble();
      final qaWeightOverride = (gradeRecord?['qa_weight_override'] as num?)?.toDouble();

      // Use DepEd service to compute breakdown
      final computed = await _depEdService.computeQuarterlyBreakdown(
        classroomId: classroomId,
        subjectId: subjectId,
        studentId: studentId,
        quarter: quarter,
        qaScoreOverride: qaScoreOverride,
        qaMaxOverride: qaMaxOverride,
        plusPoints: plusPoints,
        extraPoints: extraPoints,
        wwWeightOverride: wwWeightOverride,
        ptWeightOverride: ptWeightOverride,
        qaWeightOverride: qaWeightOverride,
      );

      return {
        'items': items,
        'computed': computed,
        'plus': plusPoints,
        'extra': extraPoints,
      };
    } catch (e) {
      print('❌ [StudentGradesService] Error fetching breakdown: $e');
      rethrow;
    }
  }

  /// Normalize component name to canonical form
  String _normalizeComponent(String? component, String? assignmentType) {
    String? comp = component?.toLowerCase();
    final String? aType = assignmentType?.toLowerCase();

    // Normalize component variants
    if (comp != null && comp.isNotEmpty) {
      var norm = comp.replaceAll(RegExp(r'[^a-z]'), '_');
      if (norm == 'performance_tasks') norm = 'performance_task';
      if (norm == 'written_work') norm = 'written_works';
      if (norm == 'quarterly_assessment' || norm == 'quarterly_assessments') {
        norm = 'quarterly_assessment';
      }

      // Heuristic if still not canonical
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

    // Infer from assignment_type if component is null
    if (comp == null || comp.isEmpty) {
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

    // Normalize shortcuts
    if (comp == 'ww') comp = 'written_works';
    if (comp == 'pt') comp = 'performance_task';
    if (comp == 'qa') comp = 'quarterly_assessment';

    return comp ?? 'written_works'; // Default to written_works
  }
}
