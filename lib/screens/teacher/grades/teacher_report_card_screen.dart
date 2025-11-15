import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/services/sf9_export_service.dart';

class TeacherReportCardScreen extends StatefulWidget {
  final Classroom classroom;
  final Map<String, dynamic> student; // {id, full_name, email}
  final int? initialQuarter;

  const TeacherReportCardScreen({
    super.key,
    required this.classroom,
    required this.student,
    this.initialQuarter,
  });

  @override
  State<TeacherReportCardScreen> createState() =>
      _TeacherReportCardScreenState();
}

class _TeacherReportCardScreenState extends State<TeacherReportCardScreen> {
  bool _loading = false;
  bool _exporting = false;
  int _selectedQuarter = 1;
  late final String _studentId;
  late final String _studentName;
  String? _studentEmail;
  List<Map<String, dynamic>> _rows = [];
  Map<String, String> _courseTitles = {};
  Map<String, String> _courseTeacherIds = {};
  Map<String, String> _teacherNames = {};

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuarter;
    if (q != null && q >= 1 && q <= 4) {
      _selectedQuarter = q;
    }
    final s = widget.student;
    final rawId = s['id'] ?? s['student_id'] ?? s['user_id'];
    _studentId = rawId == null ? '' : rawId.toString();
    final name = (s['full_name'] ?? '').toString().trim();
    _studentName = name.isEmpty ? 'Student' : name;
    final email = (s['email'] ?? '').toString().trim();
    _studentEmail = email.isEmpty ? null : email;
    _loadQuarterData();
  }

  Future<void> _loadQuarterData() async {
    if (_studentId.isEmpty) return;
    setState(() {
      _loading = true;
    });
    try {
      final supa = Supabase.instance.client;
      final rows = await supa
          .from('student_grades')
          .select()
          .eq('student_id', _studentId)
          .eq('classroom_id', widget.classroom.id)
          .eq('quarter', _selectedQuarter);
      final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
      final courseIds = <String>{};
      for (final r in list) {
        final cid = r['course_id']?.toString();
        if (cid != null) courseIds.add(cid);
      }
      final courseTitles = <String, String>{};
      final courseTeacherIds = <String, String>{};
      final teacherNames = <String, String>{};
      if (courseIds.isNotEmpty) {
        final cc = await supa
            .from('courses')
            .select('id, title, teacher_id')
            .inFilter('id', courseIds.toList());
        final teacherIds = <String>{};
        for (final c in cc as List) {
          final id = c['id'].toString();
          courseTitles[id] = (c['title'] as String? ?? '').trim();
          final tid = c['teacher_id']?.toString();
          if (tid != null) {
            courseTeacherIds[id] = tid;
            teacherIds.add(tid);
          }
        }
        if (teacherIds.isNotEmpty) {
          final tt = await supa
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', teacherIds.toList());
          for (final t in tt as List) {
            teacherNames[t['id'].toString()] = (t['full_name'] as String? ?? '')
                .trim();
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _rows = list;
        _courseTitles = courseTitles;
        _courseTeacherIds = courseTeacherIds;
        _teacherNames = teacherNames;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = [];
        _courseTitles = {};
        _courseTeacherIds = {};
        _teacherNames = {};
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _onExportSf9Pressed() async {
    setState(() => _exporting = true);
    try {
      await SF9ExportService.instance.exportSF9ReportCard(
        studentId: _studentId,
        classroom: widget.classroom,
        quarter: _selectedQuarter,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SF9 Report Card exported successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export SF9 Report Card: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  double _gradeFromRow(Map<String, dynamic> r) {
    final v = r['adjusted_grade'] ?? r['transmuted_grade'];
    if (v is num) return v.toDouble();
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card'),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export SF9 Report Card',
            onPressed: _exporting || _loading ? null : _onExportSf9Pressed,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildQuarterChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final gradeLabel = 'Grade ${widget.classroom.gradeLevel}';
    final classroomTitle = widget.classroom.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _studentName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(label: Text(gradeLabel, style: const TextStyle(fontSize: 11))),
            Chip(
              label: Text(classroomTitle, style: const TextStyle(fontSize: 11)),
            ),
            if (_studentEmail != null)
              Chip(
                label: Text(
                  _studentEmail!,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuarterChips() {
    return Wrap(
      spacing: 6,
      children: List.generate(4, (index) {
        final q = index + 1;
        final selected = _selectedQuarter == q;
        return ChoiceChip(
          label: Text('Q$q'),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _selectedQuarter = q;
            });
            _loadQuarterData();
          },
        );
      }),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final rows = _rows;
    final q = _selectedQuarter;
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No final grades saved for Quarter $q'),
        ),
      );
    }

    var sum = 0.0;
    var count = 0;
    for (final r in rows) {
      final g = _gradeFromRow(r);
      if (g > 0) {
        sum += g;
        count += 1;
      }
    }
    final avg = count == 0 ? 0.0 : sum / count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quarter $q',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Chip(
              label: Text(
                'General Average: ${avg.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final r = rows[index];
              final courseId = r['course_id']?.toString() ?? '';
              final title = _courseTitles[courseId] ?? courseId;
              final teacherId = _courseTeacherIds[courseId];
              final teacherName = teacherId != null
                  ? _teacherNames[teacherId] ?? ''
                  : '';
              final g = _gradeFromRow(r).toStringAsFixed(0);
              final rem = (r['remarks'] as String?)?.trim() ?? '';

              return Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (teacherName.isNotEmpty)
                              Text(
                                'Teacher: $teacherName',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            if (rem.isNotEmpty)
                              Text(
                                rem,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        g,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
