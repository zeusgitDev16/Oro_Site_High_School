import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/flow/student/student_submission_logic.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_assignment_work_screen.dart';

/// Student Assignment Read Screen
/// Preview-first: shows only meta/description/instructions until the student clicks Start.
/// After Start, render type-specific question UI (no persistence yet).
class StudentAssignmentReadScreen extends StatefulWidget {
  final String assignmentId;

  const StudentAssignmentReadScreen({super.key, required this.assignmentId});

  @override
  State<StudentAssignmentReadScreen> createState() =>
      _StudentAssignmentReadScreenState();
}

class _StudentAssignmentReadScreenState
    extends State<StudentAssignmentReadScreen> {
  final StudentSubmissionLogic _logic = StudentSubmissionLogic();
  bool _started = false; // gates rendering of questions

  // Local transient answers (UI-only placeholders, not persisted yet)
  final Map<int, dynamic> _answers = {};

  RealtimeChannel? _subChannel;

  @override
  void initState() {
    super.initState();
    _logic.addListener(_onUpdate);
    _logic.load(widget.assignmentId);
    _setupRealtime();
  }

  @override
  void dispose() {
    _subChannel?.unsubscribe();
    _logic.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _setupRealtime() {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return;

    _subChannel = supa
        .channel('student-sub:${widget.assignmentId}:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignment_submissions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'assignment_id',
            value: widget.assignmentId,
          ),
          callback: (payload) {
            final map = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final row = Map<String, dynamic>.from(map);
            final rowStudentId = (row['student_id'] ?? '').toString();
            if (rowStudentId == uid) {
              _logic.applySubmission(row);
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final a = _logic.assignment;
    final submitted =
        (_logic.submission != null &&
        ((_logic.submission!['status']?.toString() == 'submitted') ||
            (_logic.submission!['status']?.toString() == 'graded')));
    final submittedAt = _logic.submission?['submitted_at']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _logic.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (a == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Assignment not found or not accessible',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            )
          : _buildContent(a),
    );
  }

  Widget _buildContent(Map<String, dynamic> a) {
    final submitted =
        (_logic.submission != null &&
        ((_logic.submission!['status']?.toString() == 'submitted') ||
            (_logic.submission!['status']?.toString() == 'graded')));
    final submittedAt = _logic.submission?['submitted_at']?.toString();
    final dueRaw = a['due_date'];
    DateTime? due;
    if (dueRaw != null && dueRaw.toString().isNotEmpty) {
      try {
        due = DateTime.parse(dueRaw.toString());
      } catch (_) {}
    }

    final type = (a['assignment_type'] ?? 'unknown').toString();
    final points = (a['total_points'] ?? 0).toString();
    final allowLate = (a['allow_late_submissions'] ?? true) == true;
    final content = (a['content'] as Map<String, dynamic>?) ?? {};
    final instructions = (content['instructions'] ?? '').toString();

    final now = DateTime.now();
    final isPastDue = (due != null) && now.isAfter(due);

    // NEW: Check end_time - assignment ended
    final endTime = a['end_time'] != null
        ? DateTime.tryParse(a['end_time'].toString())
        : null;
    final isEnded = endTime != null && now.isAfter(endTime);

    // NEW: Check start_time - assignment not yet started
    final startTime = a['start_time'] != null
        ? DateTime.tryParse(a['start_time'].toString())
        : null;
    final notYetStarted = startTime != null && now.isBefore(startTime);

    // Disable if: ended, not yet started, or (past due and late not allowed)
    final startDisabled = isEnded || notYetStarted || (isPastDue && !allowLate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            a['title'] ?? 'Untitled',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Meta row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$points pts',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              if (due != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${due.month}/${due.day}/${due.year} ${_formatAmPm(due)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Submitted banner (if already submitted)
          if (submitted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      submittedAt != null
                          ? 'Submitted ${submittedAt.replaceFirst('T', ' ').split('.')[0]}'
                          : 'Submitted',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSubmissionStatusSection(a),
            const SizedBox(height: 16),
          ],

          // Description (teacher-provided). This is allowed in preview.
          if ((a['description'] ?? '').toString().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                a['description'],
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),

          // Instructions (from content.instructions). Also allowed in preview.
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Instructions', Icons.info_outline),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                instructions,
                style: TextStyle(fontSize: 14, color: Colors.blue.shade900),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // NEW: Timeline status banners
          if (notYetStarted && startTime != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This assignment will be available on ${_formatDateTime(startTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (isEnded && endTime != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.stop_circle, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This assignment ended on ${_formatDateTime(endTime)}. Submissions are no longer accepted.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          _buildDuePolicyBanner(allowLate, due),
          const SizedBox(height: 24),

          // Start/Continue button
          if (!submitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: startDisabled
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => StudentAssignmentWorkScreen(
                              assignmentId: widget.assignmentId,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.play_arrow),
                label: Text(startDisabled
                    ? (isEnded ? 'Assignment Ended'
                        : notYetStarted ? 'Not Yet Available'
                        : 'Closed')
                    : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: startDisabled ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Format date/time for display
  String _formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.month}/${dt.day}/${dt.year} $h:$m $ap';
  }

  Widget _buildDuePolicyBanner(bool allowLate, DateTime? due) {
    final now = DateTime.now();
    final past = due != null && now.isAfter(due);
    if (past && !allowLate) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This assignment is past due and late submissions are NOT allowed.',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              allowLate
                  ? 'Late submissions are allowed.'
                  : 'Please submit before the due date.',
              style: TextStyle(
                color: Colors.green.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsUI(String type, Map<String, dynamic> content) {
    switch (type) {
      case 'quiz':
      case 'identification':
        final questions = List<Map<String, dynamic>>.from(
          (content['questions'] as List?) ?? const [],
        );
        if (questions.isEmpty) return _emptyBlock('No questions provided.');
        return Column(
          children: questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final qText = (q['question'] ?? '').toString();
            final pts = (q['points'] ?? 0).toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _chip('Q${idx + 1}'),
                      const Spacer(),
                      _chip('$pts pts', color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    qText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => _answers[idx] = v,
                    decoration: const InputDecoration(
                      hintText: 'Type your answer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 'multiple_choice':
        final questions = List<Map<String, dynamic>>.from(
          (content['questions'] as List?) ?? const [],
        );
        if (questions.isEmpty) return _emptyBlock('No questions provided.');
        return Column(
          children: questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final qText = (q['question'] ?? '').toString();
            final choices = List<String>.from(
              (q['choices'] as List?)?.map((e) => e.toString()).toList() ??
                  const [],
            );
            final pts = (q['points'] ?? 0).toString();
            final selected = _answers[idx] as int?;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _chip('Q${idx + 1}'),
                      const Spacer(),
                      _chip('$pts pts', color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    qText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...choices.asMap().entries.map((c) {
                    final cIdx = c.key;
                    final cText = c.value;
                    return RadioListTile<int>(
                      value: cIdx,
                      groupValue: selected,
                      onChanged: (val) => setState(() => _answers[idx] = val),
                      title: Text('${String.fromCharCode(65 + cIdx)}. $cText'),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        );

      case 'matching_type':
        final pairs = List<Map<String, dynamic>>.from(
          (content['pairs'] as List?) ?? const [],
        );
        if (pairs.isEmpty) return _emptyBlock('No pairs provided.');
        // Build Column B options for dropdowns
        final columnB = pairs
            .map((p) => (p['columnB'] ?? '').toString())
            .toList();
        return Column(
          children: pairs.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final a = (p['columnA'] ?? '').toString();
            final selected = _answers[idx] as String?;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      a,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: selected,
                      items: columnB
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _answers[idx] = val),
                      decoration: const InputDecoration(
                        hintText: 'Match to…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 'essay':
        final questions = List<Map<String, dynamic>>.from(
          (content['questions'] as List?) ?? const [],
        );
        if (questions.isEmpty) return _emptyBlock('No prompts provided.');
        return Column(
          children: questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final qText = (q['question'] ?? '').toString();
            final pts = (q['points'] ?? 0).toString();
            final minWords = q['minWords']?.toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _chip('Essay ${idx + 1}'),
                      const Spacer(),
                      _chip('$pts pts', color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    qText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (minWords != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Minimum words: $minWords',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => _answers[idx] = v,
                    minLines: 6,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Write your essay here…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 'file_upload':
        // No actual upload yet; show instructions and placeholder
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration().copyWith(
            color: Colors.indigo.shade50,
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.upload_file, color: Colors.indigo.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'File uploads coming soon. Follow the instructions above for what to prepare.',
                  style: TextStyle(color: Colors.indigo.shade900),
                ),
              ),
            ],
          ),
        );

      default:
        return _emptyBlock('Unsupported assignment type: $type');
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    );
  }

  Widget _chip(String text, {Color? color}) {
    final Color base = color ?? Colors.blue;
    // Pick a readable text color: use shade700 if available, otherwise the base color.
    Color textColor;
    if (base is MaterialColor) {
      textColor = (base as MaterialColor).shade700;
    } else if (base is MaterialAccentColor) {
      textColor = (base as MaterialAccentColor).shade700;
    } else {
      textColor = base;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: base.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: base.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _emptyBlock(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
    );
  }

  Widget _buildWorkInProgressNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Answer saving and submission will be enabled next. For now this is a preview of the working area after you press Start.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shows either auto-graded Score or "Waiting for grade" for manual types
  Widget _buildSubmissionStatusSection(Map<String, dynamic> assignment) {
    final sub = _logic.submission;
    if (sub == null) return const SizedBox.shrink();

    final type = (assignment['assignment_type'] ?? '').toString();
    final score = sub['score'] as num?;
    final maxScore =
        (sub['max_score'] as num?) ?? (assignment['total_points'] as num?) ?? 0;

    // If a score is present (auto-graded or teacher-graded), show it regardless of type
    if (score != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Score: ${score.toString()} / ${maxScore.toString()}',
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // For essay/file_upload or when score is not (yet) available, show waiting for grade
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Waiting for grade',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmPm(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'pm' : 'am';
    return '$h:$m $ap';
  }
}
