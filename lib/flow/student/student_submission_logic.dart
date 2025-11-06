import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/services/submission_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';

/// Interactive logic for a single assignment detail + submission draft/submit shell
/// Layer: Interactive Logic (separate from UI and services)
class StudentSubmissionLogic extends ChangeNotifier {
  final SubmissionService _submissionService = SubmissionService();
  final AssignmentService _assignmentService = AssignmentService();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _assignment; // assignments row
  Map<String, dynamic>? get assignment => _assignment;

  Map<String, dynamic>? _submission; // assignment_submissions row
  Map<String, dynamic>? get submission => _submission;

  Future<void> load(String assignmentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch assignment only
      final a = await _assignmentService.getAssignmentById(assignmentId);
      _assignment = a;

      // Try to fetch existing submission (do NOT create here)
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null && a != null) {
        final existing = await _submissionService.getStudentSubmission(
          assignmentId: assignmentId,
          studentId: userId,
        );
        _submission = existing; // may remain null if not yet created
      }
    } catch (_) {
      // keep nulls
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply a fresh submission row (e.g., from realtime payload)
  void applySubmission(Map<String, dynamic>? row) {
    _submission = row;
    notifyListeners();
  }
}
