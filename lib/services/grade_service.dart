import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grade.dart';

class GradeService {
  final _supabase = Supabase.instance.client;

  Future<Grade?> getGradeForSubmission(int submissionId) async {
    final response = await _supabase
        .from('grades')
        .select()
        .eq('submission_id', submissionId)
        .maybeSingle();
    return response != null ? Grade.fromMap(response) : null;
  }

  Future<Grade> createGrade(Grade grade) async {
    final response = await _supabase
        .from('grades')
        .insert({
          'submission_id': grade.submissionId,
          'grader_id': grade.graderId,
          'score': grade.score,
          'comments': grade.comments,
        })
        .select()
        .single();
    return Grade.fromMap(response);
  }
}
