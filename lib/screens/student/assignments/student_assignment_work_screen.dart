import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:oro_site_high_school/flow/student/student_submission_logic.dart';
import 'package:oro_site_high_school/services/submission_service.dart';
import 'package:oro_site_high_school/services/file_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Student Assignment Work Screen
/// - Renders questions by type
/// - Auto-saves submission_content (UI only for now)
/// - Submit button finalizes the attempt
/// - Back behavior: auto-submit for quiz-like types; draft for essay/file_upload
class StudentAssignmentWorkScreen extends StatefulWidget {
  final String assignmentId;

  const StudentAssignmentWorkScreen({super.key, required this.assignmentId});

  @override
  State<StudentAssignmentWorkScreen> createState() =>
      _StudentAssignmentWorkScreenState();
}

class _StudentAssignmentWorkScreenState
    extends State<StudentAssignmentWorkScreen> {
  final StudentSubmissionLogic _logic = StudentSubmissionLogic();
  final SubmissionService _submissionService = SubmissionService();
  final FileUploadService _fileUploadService = FileUploadService();

  final Map<int, dynamic> _answers = {}; // simple per-question map
  Timer? _debounce;
  RealtimeChannel? _subChannel;
  bool _ensuring = false; // ensure submission fallback if logic failed

  // Phase 3 Task 3.1: File upload state
  final Map<int, List<PlatformFile>> _uploadedFiles = {}; // question index -> files
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _logic.addListener(_onUpdate);
    _logic.load(widget.assignmentId);
    _setupRealtime();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subChannel?.unsubscribe();
    _logic.removeListener(_onUpdate);
    super.dispose();
  }

  void _setupRealtime() {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return;

    _subChannel = supa
        .channel('student-work:${widget.assignmentId}:$uid')
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
            if ((row['student_id'] ?? '').toString() == uid) {
              _logic.applySubmission(row);
            }
          },
        )
        .subscribe();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  bool get _isQuizLike {
    final t = (_logic.assignment?['assignment_type'] ?? '').toString();
    return t == 'quiz' ||
        t == 'multiple_choice' ||
        t == 'identification' ||
        t == 'matching_type';
  }

  Future<bool> _onWillPop() async {
    // If submitted already, allow pop
    final status = _logic.submission?['status']?.toString();
    if (status == 'submitted' || status == 'graded') return true;

    if (_isQuizLike) {
      // Warn and submit on exit
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave and submit?'),
          content: const Text(
            'Once you exit, your answers will be submitted and you cannot go back.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit & Exit'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _submit();
        return true;
      }
      return false;
    }

    // essay/file_upload: optional gentle warning, but do not submit
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave work?'),
        content: const Text(
          'Your current work is saved as draft. You can come back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  void _queueSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _persistAnswers);
  }

  Future<void> _persistAnswers() async {
    final a = _logic.assignment;
    final sub = _logic.submission;
    if (a == null || sub == null) return;

    final content = _buildSubmissionContent(a);

    await _submissionService.saveSubmissionContent(
      assignmentId: a['id'].toString(),
      studentId: sub['student_id'].toString(),
      content: content,
    );
  }

  Future<void> _submit() async {
    print('📝 SUBMIT: Starting submission process...');
    final a = _logic.assignment;
    var sub = _logic.submission;
    if (a == null) {
      print('❌ SUBMIT: Assignment is null');
      return;
    }

    print('📝 SUBMIT: Assignment ID: ${a['id']}, Type: ${a['assignment_type']}');
    print('📝 SUBMIT: Classroom ID: ${a['classroom_id']}');

    final createdNew = sub == null;

    // Ensure submission only at submit time (or exit auto-submit)
    if (sub == null) {
      print('📝 SUBMIT: No existing submission, creating new one...');
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ SUBMIT: User not authenticated');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not authenticated'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      print('📝 SUBMIT: User ID: $userId');
      try {
        print('📝 SUBMIT: Calling getOrCreateSubmission...');
        final ensured = await _submissionService.getOrCreateSubmission(
          assignmentId: a['id'].toString(),
          studentId: userId,
          classroomId: a['classroom_id'].toString(),
        );
        sub = ensured;
        print('✅ SUBMIT: Submission created/retrieved: ${sub['id']}');
      } catch (e, stackTrace) {
        print('❌ SUBMIT: Failed to create submission: $e');
        print('❌ SUBMIT: Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot create submission: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      print('📝 SUBMIT: Using existing submission: ${sub['id']}');
    }

    // Persist answers (save immediately when submission was just created)
    print('📝 SUBMIT: Saving submission content...');
    if (createdNew && sub != null) {
      final content = _buildSubmissionContent(a);
      print('📝 SUBMIT: Content: $content');
      await _submissionService.saveSubmissionContent(
        assignmentId: a['id'].toString(),
        studentId: sub['student_id'].toString(),
        content: content,
      );
      print('✅ SUBMIT: Content saved (new submission)');
    } else {
      await _persistAnswers();
      print('✅ SUBMIT: Content saved (existing submission)');
    }

    // Phase 3 Task 3.2: Upload files for file_upload assignments
    final type = (a['assignment_type'] ?? '').toString();
    if (type == 'file_upload' && _uploadedFiles.isNotEmpty) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading files...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Upload all files
        final allUploadedFiles = <Map<String, dynamic>>[];
        for (final entry in _uploadedFiles.entries) {
          final files = entry.value;
          final uploadedFiles = await _fileUploadService.uploadSubmissionFiles(
            files: files,
            assignmentId: a['id'].toString(),
            studentId: sub['student_id'].toString(),
          );
          allUploadedFiles.addAll(uploadedFiles);
        }

        // Update submission content with file URLs
        await _submissionService.saveSubmissionContent(
          assignmentId: a['id'].toString(),
          studentId: sub['student_id'].toString(),
          content: {'files': allUploadedFiles},
        );

        print('✅ Uploaded ${allUploadedFiles.length} file(s) successfully');
      } catch (e) {
        print('❌ Error uploading files: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload files: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Submit via server-side logic
    int? autoScore;
    int? autoMax;

    print('📝 SUBMIT: Starting submission finalization...');
    print('📝 SUBMIT: Assignment type: $type');

    try {
      if (type == 'quiz' ||
          type == 'multiple_choice' ||
          type == 'identification' ||
          type == 'matching_type') {
        // Objective types: delegate scoring to RPC
        print('📝 SUBMIT: Calling autoGradeAndSubmit RPC...');
        print('📝 SUBMIT: Assignment ID (string): ${a['id'].toString()}');
        final result = await _submissionService.autoGradeAndSubmit(
          assignmentId: a['id'].toString(),
        );
        print('✅ SUBMIT: Auto-grading complete!');
        print('📊 SUBMIT: Result: $result');
        autoScore = (result['score'] as num?)?.toInt();
        autoMax = (result['max_score'] as num?)?.toInt();
        print('📊 SUBMIT: Score: $autoScore/$autoMax');
      } else {
        // Non-objective types: just mark as submitted (score/max_score stay null)
        print('📝 SUBMIT: Calling submitSubmission (non-objective)...');
        await _submissionService.submitSubmission(
          assignmentId: a['id'].toString(),
          studentId: sub['student_id'].toString(),
        );
        print('✅ SUBMIT: Submission marked as submitted');
      }
    } catch (e, stackTrace) {
      print('❌ SUBMIT: Submission failed!');
      print('❌ SUBMIT: Error: $e');
      print('❌ SUBMIT: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (mounted) {
      // Show quick confirmation and return to classroom view
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            autoScore != null && autoMax != null
                ? 'Submitted • Score: $autoScore/$autoMax'
                : 'Submitted!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1200),
        ),
      );
      // Pop Work -> Preview -> back to Classroom
      Navigator.of(context).pop(true); // close Work
      // Delay a frame to ensure previous route can process result
      await Future.delayed(const Duration(milliseconds: 10));
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true); // close Preview
      }
    }
  }

  // Removed eager ensure; submission will be created on submit only.

  /// Phase 3 Task 3.1: Pick files for file_upload assignment type
  Future<void> _pickFiles(int questionIndex) async {
    if (_isUploadingFile) return;

    try {
      setState(() => _isUploadingFile = true);

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _uploadedFiles[questionIndex] = result.files;
          // Store file names in answers for submission content
          _answers[questionIndex] = result.files.map((f) => f.name).toList();
        });
        _queueSave();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.files.length} file(s) selected'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  /// Phase 3 Task 3.1: Remove a selected file
  void _removeFile(int questionIndex, int fileIndex) {
    setState(() {
      final files = _uploadedFiles[questionIndex];
      if (files != null && fileIndex < files.length) {
        files.removeAt(fileIndex);
        if (files.isEmpty) {
          _uploadedFiles.remove(questionIndex);
          _answers.remove(questionIndex);
        } else {
          _answers[questionIndex] = files.map((f) => f.name).toList();
        }
        _queueSave();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = _logic.assignment;
    final sub = _logic.submission;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assignment Work'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            if (sub != null &&
                (sub['status'] == 'submitted' || sub['status'] == 'graded'))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: _submittedBadge(sub),
              ),
          ],
        ),
        body: _logic.isLoading
            ? const Center(child: CircularProgressIndicator())
            : (a == null)
            ? Center(
                child: Text(
                  'Assignment not found',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
            : _buildWorkContent(a, sub),
      ),
    );
  }

  Widget _submittedBadge(Map<String, dynamic> sub) {
    final submittedAt = sub['submitted_at']?.toString();
    final isLate = (sub['is_late'] ?? false) == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLate ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLate ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLate ? Icons.timer_off : Icons.check_circle,
            size: 16,
            color: isLate ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            submittedAt != null
                ? 'Submitted ${submittedAt.replaceFirst('T', ' ').split('.')[0]}'
                : 'Submitted',
            style: TextStyle(
              fontSize: 12,
              color: isLate ? Colors.red.shade900 : Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkContent(Map<String, dynamic> a, Map<String, dynamic>? sub) {
    final type = (a['assignment_type'] ?? '').toString();
    final dueRaw = a['due_date'];
    DateTime? due;
    if (dueRaw != null && dueRaw.toString().isNotEmpty) {
      try {
        due = DateTime.parse(dueRaw.toString());
      } catch (_) {}
    }

    final allowLate = (a['allow_late_submissions'] ?? true) == true;
    final content = (a['content'] as Map<String, dynamic>?) ?? {};

    final readOnly =
        (sub != null &&
        (sub['status'] == 'submitted' || sub['status'] == 'graded'));

    return Column(
      children: [
        // Header info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (a['assignment_type'] ?? 'unknown')
                                .toString()
                                .replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${a['total_points'] ?? 0} pts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (due != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${due.month}/${due.day}/${due.year} ${_formatAmPm(due)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (readOnly && sub != null) _submittedBadge(sub),
            ],
          ),
        ),

        // Body: questions UI
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildQuestionsUI(type, content, readOnly),
          ),
        ),

        // Footer actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              if (!readOnly && sub != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _persistAnswers();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Draft'),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: readOnly ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsUI(
    String type,
    Map<String, dynamic> content,
    bool readOnly,
  ) {
    // Use simple builders; hook onChanged to _queueSave and _answers updates when editable
    switch (type) {
      case 'quiz':
      case 'identification':
        final questions = List<Map<String, dynamic>>.from(
          (content['questions'] as List?) ?? const [],
        );
        if (questions.isEmpty) return _empty('No questions provided.');
        return Column(
          children: questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final qText = (q['question'] ?? '').toString();
            final pts = (q['points'] ?? 0).toString();
            return _questionCard([
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
                enabled: !readOnly,
                onChanged: (v) {
                  _answers[idx] = v;
                  _queueSave();
                },
                decoration: const InputDecoration(
                  hintText: 'Type your answer',
                  border: OutlineInputBorder(),
                ),
              ),
            ]);
          }).toList(),
        );

      case 'multiple_choice':
        final questions = List<Map<String, dynamic>>.from(
          (content['questions'] as List?) ?? const [],
        );
        if (questions.isEmpty) return _empty('No questions provided.');
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
            return _questionCard([
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
                  onChanged: !readOnly
                      ? (val) {
                          setState(() => _answers[idx] = val);
                          _queueSave();
                        }
                      : null,
                  title: Text('${String.fromCharCode(65 + cIdx)}. $cText'),
                );
              }).toList(),
            ]);
          }).toList(),
        );

      case 'matching_type':
        final pairs = List<Map<String, dynamic>>.from(
          (content['pairs'] as List?) ?? const [],
        );
        if (pairs.isEmpty) return _empty('No pairs provided.');
        final columnB = pairs
            .map((p) => (p['columnB'] ?? '').toString())
            .toList();
        return Column(
          children: pairs.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final a = (p['columnA'] ?? '').toString();
            final selected = _answers[idx] as String?;
            return _questionCard([
              Row(children: [_chip('Pair ${idx + 1}'), const Spacer()]),
              const SizedBox(height: 12),
              Row(
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
                      onChanged: !readOnly
                          ? (val) {
                              setState(() => _answers[idx] = val);
                              _queueSave();
                            }
                          : null,
                      decoration: const InputDecoration(
                        hintText: 'Match to…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ]);
          }).toList(),
        );

      case 'essay':
        final questions = List<Map<String, dynamic>>.from(
          (content['questions'] as List?) ?? const [],
        );
        if (questions.isEmpty) return _empty('No prompts provided.');
        return Column(
          children: questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final qText = (q['question'] ?? '').toString();
            final pts = (q['points'] ?? 0).toString();
            final minWords = q['minWords']?.toString();
            return _questionCard([
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
                enabled: !readOnly,
                onChanged: (v) {
                  _answers[idx] = v;
                  _queueSave();
                },
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Write your essay here…',
                  border: OutlineInputBorder(),
                ),
              ),
            ]);
          }).toList(),
        );

      case 'file_upload':
        // Phase 3 Task 3.1: File upload UI with file picker
        final questions = List<Map<String, dynamic>>.from(
          (content['questions'] as List?) ?? const [],
        );
        return Column(
          children: questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final qText = (q['question'] ?? 'Question ${idx + 1}').toString();
            final pts = (q['points'] as num?)?.toInt() ?? 0;
            final files = _uploadedFiles[idx] ?? [];

            return _questionCard([
              // Question header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      qText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _chip('$pts pts', color: Colors.indigo),
                ],
              ),
              const SizedBox(height: 12),

              // Upload button
              if (!readOnly)
                ElevatedButton.icon(
                  onPressed: _isUploadingFile ? null : () => _pickFiles(idx),
                  icon: _isUploadingFile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file, size: 18),
                  label: Text(
                    _isUploadingFile ? 'Selecting...' : 'Choose Files',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),

              // Selected files list
              if (files.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...files.asMap().entries.map((fileEntry) {
                  final fileIdx = fileEntry.key;
                  final file = fileEntry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: Colors.indigo.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${(file.size / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!readOnly)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeFile(idx, fileIdx),
                            color: Colors.red,
                            tooltip: 'Remove file',
                          ),
                      ],
                    ),
                  );
                }),
              ],

              // Read-only view (after submission)
              if (readOnly && files.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No files uploaded',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ]);
          }).toList(),
        );

      default:
        return _empty('Unsupported assignment type: $type');
    }
  }

  Widget _questionCard(
    List<Widget> children, {
    Color? altColor,
    Color? altBorder,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: altColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: altBorder ?? Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _empty(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
  );

  Widget _chip(String text, {Color? color}) {
    final base = color ?? Colors.blue;
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
          color: (base is MaterialColor) ? base.shade700 : base,
        ),
      ),
    );
  }

  Map<String, dynamic> _buildSubmissionContent(Map<String, dynamic> a) {
    final type = (a['assignment_type'] ?? '').toString();
    switch (type) {
      case 'quiz':
      case 'identification':
      case 'multiple_choice':
      case 'matching_type':
      case 'essay':
        return {
          'answers': List<dynamic>.from(
            _answers.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
          ).map((e) => e.value).toList(),
        };
      case 'file_upload':
        return {
          'files': List<dynamic>.from(
            _answers.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
          ).map((e) => e.value).toList(),
        };
      default:
        return {'answers': []};
    }
  }

  /// Returns Tuple(score, maxScore)
  ({int item1, int item2}) _autoGrade(Map<String, dynamic> assignment) {
    final type = (assignment['assignment_type'] ?? '').toString();
    final content = (assignment['content'] as Map<String, dynamic>?) ?? {};

    // Extract student answers from local _answers
    // We assume indices align with teacher's questions order
    int score = 0;
    int maxScore = 0;

    if (type == 'multiple_choice' ||
        type == 'quiz' ||
        type == 'identification') {
      final questions = List<Map<String, dynamic>>.from(
        (content['questions'] as List?) ?? const [],
      );
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final pts = (q['points'] as num?)?.toInt() ?? 0;
        maxScore += pts;
        final correct = q['answer']; // For MCQ we expect an index or value
        final ans = _answers[i];
        if (type == 'multiple_choice') {
          // In our UI we store selected choice index as int
          if (ans is int && (q['correctIndex'] == ans || correct == ans)) {
            score += pts;
          }
        } else {
          // quiz/identification: compare normalized strings
          final corr = (correct ?? '').toString().trim().toLowerCase();
          final got = (ans ?? '').toString().trim().toLowerCase();
          if (corr.isNotEmpty && got.isNotEmpty && corr == got) {
            score += pts;
          }
        }
      }
    } else if (type == 'matching_type') {
      final pairs = List<Map<String, dynamic>>.from(
        (content['pairs'] as List?) ?? const [],
      );
      for (var i = 0; i < pairs.length; i++) {
        final p = pairs[i];
        final pts = (p['points'] as num?)?.toInt() ?? 0;
        maxScore += pts;
        final correctB = (p['columnB'] ?? '').toString().trim().toLowerCase();
        final selB = (_answers[i] ?? '').toString().trim().toLowerCase();
        if (correctB.isNotEmpty && selB.isNotEmpty && correctB == selB) {
          score += pts;
        }
      }
    }

    return (item1: score, item2: maxScore);
  }

  String _formatAmPm(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'pm' : 'am';
    return '$h:$m $ap';
  }
}
