import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_site_high_school/services/submission_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// **Phase 4: Score Edit Dialog**
/// 
/// Allows teacher to edit a student's assignment score.
class ScoreEditDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> assignment;
  final Map<String, dynamic>? submission;

  const ScoreEditDialog({
    super.key,
    required this.student,
    required this.assignment,
    this.submission,
  });

  @override
  State<ScoreEditDialog> createState() => _ScoreEditDialogState();
}

class _ScoreEditDialogState extends State<ScoreEditDialog> {
  final SubmissionService _submissionService = SubmissionService();
  final TextEditingController _scoreController = TextEditingController();
  
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill with existing score
    if (widget.submission != null) {
      final score = widget.submission!['score'];
      if (score != null) {
        _scoreController.text = score.toString();
      }
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _saveScore() async {
    final scoreText = _scoreController.text.trim();
    
    if (scoreText.isEmpty) {
      setState(() => _errorMessage = 'Please enter a score');
      return;
    }

    final score = double.tryParse(scoreText);
    if (score == null) {
      setState(() => _errorMessage = 'Invalid score format');
      return;
    }

    final maxScore = (widget.assignment['total_points'] as num?)?.toDouble() ?? 0;
    if (score < 0 || score > maxScore) {
      setState(() => _errorMessage = 'Score must be between 0 and $maxScore');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final teacherId = Supabase.instance.client.auth.currentUser?.id;
      
      if (widget.submission != null) {
        // Update existing submission
        await _submissionService.updateSubmissionScore(
          submissionId: widget.submission!['id'].toString(),
          score: score,
          gradedBy: teacherId,
        );
      } else {
        // Create new submission (student hasn't submitted yet)
        await _submissionService.createManualSubmission(
          assignmentId: widget.assignment['id'].toString(),
          studentId: widget.student['id'].toString(),
          classroomId: widget.assignment['classroom_id'].toString(),
          score: score,
          gradedBy: teacherId,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error saving score: $e');
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save score: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.student['full_name'] ?? 'Unknown';
    final assignmentTitle = widget.assignment['title'] ?? 'Untitled';
    final maxScore = (widget.assignment['total_points'] as num?)?.toDouble() ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Edit Score',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Student info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Student',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studentName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.assignment, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Assignment',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assignmentTitle,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Score input
            Text(
              'Score (out of ${maxScore.toStringAsFixed(0)})',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _scoreController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                errorText: _errorMessage,
              ),
              style: const TextStyle(fontSize: 13),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onSubmitted: (_) => _saveScore(),
            ),
            
            const SizedBox(height: 20),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveScore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

