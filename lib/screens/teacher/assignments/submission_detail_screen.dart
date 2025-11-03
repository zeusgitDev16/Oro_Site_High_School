import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/services/submission_service.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final String assignmentId;
  final String studentId;
  final String? studentName;
  final String? studentEmail;

  const SubmissionDetailScreen({
    super.key,
    required this.assignmentId,
    required this.studentId,
    this.studentName,
    this.studentEmail,
  });

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final SubmissionService _submissionService = SubmissionService();

  bool _isLoading = true;
  Map<String, dynamic>? _assignment;
  Map<String, dynamic>? _submission;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final a = await _assignmentService.getAssignmentById(widget.assignmentId);
      final s = await _submissionService.getStudentSubmission(
        assignmentId: widget.assignmentId,
        studentId: widget.studentId,
      );
      setState(() {
        _assignment = a;
        _submission = s;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading submission: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Detail'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_assignment == null || _submission == null)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text('Assignment or submission not found', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = _assignment!;
    final s = _submission!;
    final type = (a['assignment_type'] ?? '').toString();
    final title = (a['title'] ?? 'Assignment').toString();
    final totalPts = (a['total_points'] as num?)?.toInt() ?? 0;
    final submittedAt = s['submitted_at']?.toString();
    final isLate = (s['is_late'] ?? false) == true;
    final score = s['score'] as num?;
    final maxScore = (s['max_score'] as num?) ?? totalPts;

    final content = (a['content'] as Map<String, dynamic>?) ?? {};
    final answers = _extractAnswers(s['submission_content']);

    // Pre-compute evaluation for objective types
    final evaluation = _evaluate(a, answers);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(_initials(widget.studentName ?? 'S'))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.studentName ?? widget.studentId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    if ((widget.studentEmail ?? '').isNotEmpty)
                      Text(widget.studentEmail!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip(type.replaceAll('_', ' '), color: Colors.blue),
                        const SizedBox(width: 8),
                        _chip('$totalPts pts', color: Colors.amber),
                        const SizedBox(width: 8),
                        if (submittedAt != null) ...[
                          Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(submittedAt.replaceFirst('T', ' ').split('.') [0], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLate ? Colors.red.shade50 : Colors.green.shade50,
                            border: Border.all(color: isLate ? Colors.red.shade200 : Colors.green.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(isLate ? 'late' : 'on time', style: TextStyle(fontSize: 11, color: isLate ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score summary for objective types (if score available or computed)
          if (evaluation != null) _buildScoreSummary(evaluation),
          if (evaluation != null) const SizedBox(height: 16),

          // Title
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          // Answers overview
          _buildAnswersView(a, answers, evaluation),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'S';
    final chars = parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
    return chars.isEmpty ? 'S' : chars.toUpperCase();
  }

  Widget _chip(String text, {Color? color}) {
    final base = color ?? Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: base.withOpacity(0.08),
        border: Border.all(color: base.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (base is MaterialColor) ? base.shade700 : base)),
    );
  }

  List<dynamic>? _extractAnswers(dynamic submissionContent) {
    try {
      if (submissionContent == null) return null;
      if (submissionContent is Map) {
        final map = Map<String, dynamic>.from(submissionContent as Map);
        final raw = map['answers'];
        if (raw is List) return List<dynamic>.from(raw);
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          final entries = m.entries
              .map((e) => MapEntry(int.tryParse(e.key) ?? 0, e.value))
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          return entries.map((e) => e.value).toList();
        }
      } else if (submissionContent is List) {
        return List<dynamic>.from(submissionContent);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  ({int score, int max, List<Map<String, dynamic>> items})? _evaluate(Map<String, dynamic> a, List? answers) {
    final type = (a['assignment_type'] ?? '').toString();
    final content = (a['content'] as Map<String, dynamic>?) ?? {};

    if (!(type == 'quiz' || type == 'multiple_choice' || type == 'identification' || type == 'matching_type')) {
      return null; // manual grading types
    }

    int score = 0;
    int max = 0;
    final items = <Map<String, dynamic>>[];

    if (type == 'multiple_choice' || type == 'quiz' || type == 'identification') {
      final qs = List<Map<String, dynamic>>.from((content['questions'] as List?) ?? const []);
      for (var i = 0; i < qs.length; i++) {
        final q = qs[i];
        final pts = (q['points'] as num?)?.toInt() ?? 0;
        max += pts;
        final correct = q['answer'];
        final ans = answers != null && i < answers.length ? answers[i] : null;
        bool ok = false;
        String studentText = '';
        String correctText = '';
        if (type == 'multiple_choice') {
          final choices = List<String>.from(((q['choices'] as List?) ?? const []).map((e) => e.toString()));
          final correctIndex = q['correctIndex'];

          int? ansIndex;
          if (ans is int) {
            ansIndex = ans;
          } else if (ans is String) {
            final parsed = int.tryParse(ans);
            if (parsed != null) {
              ansIndex = parsed;
            } else {
              final idx = choices.indexWhere((c) => c.trim().toLowerCase() == ans.trim().toLowerCase());
              if (idx != -1) ansIndex = idx;
            }
          }

          if (correctIndex is int && ansIndex != null && ansIndex == correctIndex) {
            ok = true;
          } else if (ans != null && (ans.toString().trim().toLowerCase() == (correct ?? '').toString().trim().toLowerCase())) {
            ok = true;
          }

          if (ansIndex != null && ansIndex >= 0 && ansIndex < choices.length) {
            studentText = choices[ansIndex];
          } else {
            studentText = (ans ?? '').toString();
          }

          if (correctIndex is int && correctIndex >= 0 && correctIndex < choices.length) {
            correctText = choices[correctIndex];
          } else {
            correctText = (correct ?? '').toString();
          }
        } else {
          final corr = (correct ?? '').toString().trim().toLowerCase();
          final got = (ans ?? '').toString().trim().toLowerCase();
          ok = corr.isNotEmpty && got.isNotEmpty && corr == got;
          studentText = (ans ?? '').toString();
          correctText = (correct ?? '').toString();
        }
        if (ok) score += pts;
        items.add({
          'index': i,
          'question': q['question'] ?? 'Question ${i + 1}',
          'student': studentText,
          'correct': correctText,
          'points': pts,
          'ok': ok,
        });
      }
    } else if (type == 'matching_type') {
      final pairs = List<Map<String, dynamic>>.from((content['pairs'] as List?) ?? const []);
      for (var i = 0; i < pairs.length; i++) {
        final p = pairs[i];
        final pts = (p['points'] as num?)?.toInt() ?? 0;
        max += pts;
        final correctB = (p['columnB'] ?? '').toString();
        final selB = (answers != null && i < answers.length) ? (answers[i] ?? '').toString() : '';
        final ok = correctB.trim().toLowerCase() == selB.trim().toLowerCase() && selB.isNotEmpty;
        if (ok) score += pts;
        items.add({
          'index': i,
          'left': p['columnA'] ?? '',
          'student': selB,
          'correct': correctB,
          'points': pts,
          'ok': ok,
        });
      }
    }

    return (score: score, max: max, items: items);
  }

  Widget _buildScoreSummary(({int score, int max, List<Map<String, dynamic>> items}) eval) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.grade, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Auto score: ${eval.score}/${eval.max}', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersView(Map<String, dynamic> assignment, List? answers, ({int score, int max, List<Map<String, dynamic>> items})? eval) {
    final type = (assignment['assignment_type'] ?? '').toString();
    final content = (assignment['content'] as Map<String, dynamic>?) ?? {};

    if (type == 'essay') {
      final qs = List<Map<String, dynamic>>.from((content['questions'] as List?) ?? const []);
      final ans = List.from(answers ?? const []);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _manualNote('Essay answers require manual grading.'),
          const SizedBox(height: 12),
          ...qs.asMap().entries.map((e) {
            final i = e.key; final q = e.value;
            return _qCard([
              Text(q['question']?.toString() ?? 'Essay ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Text((i < ans.length ? ans[i]?.toString() : '') ?? ''),
              ),
            ]);
          }),
        ],
      );
    }

    if (type == 'file_upload') {
      return _manualNote('Uploaded files and feedback will appear here once implemented. Manual grading required.');
    }

    // Objective types rendering using evaluation
    if (eval == null) {
      return _manualNote('No answers available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...eval.items.asMap().entries.map((e) {
          final i = e.key; final item = e.value;
          final ok = (item['ok'] == true);
          return _qCard([
            Row(
              children: [
                _chip('Q${(i + 1)}', color: ok ? Colors.green : Colors.red),
                const Spacer(),
                _chip('${item['points']} pts', color: Colors.amber),
              ],
            ),
            const SizedBox(height: 8),
            if (item['question'] != null) Text(item['question'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
            if (item['left'] != null) Text(item['left'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(ok ? Icons.check_circle : Icons.cancel, size: 18, color: ok ? Colors.green : Colors.red),
              const SizedBox(width: 6),
              Text(ok ? 'Correct' : 'Incorrect', style: TextStyle(color: ok ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            _kv('Student answer', (item['student'] ?? '').toString()),
            _kv('Correct answer', (item['correct'] ?? '').toString()),
          ]);
        }),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(k, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600))),
        Expanded(child: Text(v.isEmpty ? '-' : v)),
      ],
    );
  }

  Widget _qCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _manualNote(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
