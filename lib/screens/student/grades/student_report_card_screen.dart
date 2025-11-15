import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/services/sf9_export_service.dart';

class StudentReportCardScreen extends StatefulWidget {
  const StudentReportCardScreen({super.key});
  @override
  State<StudentReportCardScreen> createState() =>
      _StudentReportCardScreenState();
}

class _StudentReportCardScreenState extends State<StudentReportCardScreen> {
  String? _uid;
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _exportingSf9 = false;

  // Grade rows grouped by quarter
  final Map<int, List<Map<String, dynamic>>> _byQuarter = {
    1: [],
    2: [],
    3: [],
    4: [],
  };

  // Course metadata
  final Map<String, String> _courseTitles = {}; // courseId -> title
  final Map<String, String> _courseTeacherIds = {}; // courseId -> teacherId
  final Map<String, String> _teacherNames = {}; // teacherId -> full_name

  // Student header info
  String? _studentName;
  int? _gradeLevel;
  String? _sectionName;
  String? _schoolYearLabel;

  // UI state
  int _selectedQuarter = 1;

  @override
  void initState() {
    super.initState();
    _uid = Supabase.instance.client.auth.currentUser?.id;
    _subscribe();
    _loadData();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    final uid = _uid;
    if (uid == null) return;
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('student-report:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'student_grades',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: uid,
          ),
          callback: (_) => _loadData(),
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final supa = Supabase.instance.client;

      // Load basic student info for the header (best-effort; ignore failures)
      try {
        final profileRow = await supa
            .from('profiles')
            .select('full_name')
            .eq('id', uid)
            .maybeSingle();

        final sRow = await supa
            .from('students')
            .select('grade_level, section')
            .eq('id', uid)
            .maybeSingle();

        if (profileRow != null) {
          final full = (profileRow['full_name'] as String? ?? '').trim();
          _studentName = full.isEmpty ? null : full;
        }

        if (sRow != null) {
          _gradeLevel = (sRow['grade_level'] as num?)?.toInt();
          _sectionName = (sRow['section'] as String?)?.trim();
        }
      } catch (_) {
        // ignore student info load errors
      }

      // Load all quarterly grades for this student
      final rows = await supa
          .from('student_grades')
          .select()
          .eq('student_id', uid)
          .order('quarter', ascending: true);
      final map = {
        1: <Map<String, dynamic>>[],
        2: <Map<String, dynamic>>[],
        3: <Map<String, dynamic>>[],
        4: <Map<String, dynamic>>[],
      };
      final courseIds = <String>{};
      for (final r in rows) {
        final q = (r['quarter'] as num?)?.toInt() ?? 0;
        if (q >= 1 && q <= 4) map[q]!.add(Map<String, dynamic>.from(r));
        final cid = r['course_id']?.toString();
        if (cid != null) courseIds.add(cid);
      }

      // Load course titles and owning teacher IDs
      _courseTitles.clear();
      _courseTeacherIds.clear();
      _teacherNames.clear();
      if (courseIds.isNotEmpty) {
        final cc = await supa
            .from('courses')
            .select('id, title, teacher_id, school_year')
            .inFilter('id', courseIds.toList());
        final teacherIds = <String>{};
        for (final c in cc) {
          final id = c['id'].toString();
          _courseTitles[id] = (c['title'] as String? ?? '');
          final tid = c['teacher_id']?.toString();
          if (tid != null) {
            _courseTeacherIds[id] = tid;
            teacherIds.add(tid);
          }
          // If student header has no school year yet, derive from courses
          _schoolYearLabel ??= (c['school_year'] as String?)?.trim();
        }
        if (teacherIds.isNotEmpty) {
          final tt = await supa
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', teacherIds.toList());
          for (final t in tt) {
            _teacherNames[t['id'].toString()] =
                (t['full_name'] as String? ?? '').trim();
          }
        }
      }

      if (mounted) {
        setState(() {
          _byQuarter
            ..[1] = map[1]!
            ..[2] = map[2]!
            ..[3] = map[3]!
            ..[4] = map[4]!;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _byQuarter[1] = [];
          _byQuarter[2] = [];
          _byQuarter[3] = [];
          _byQuarter[4] = [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportSf9() async {
    final uid = _uid;
    if (uid == null) return;

    final q = _selectedQuarter;
    final rows = _byQuarter[q] ?? const <Map<String, dynamic>>[];
    if (rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No grades available for Quarter $q')),
        );
      }
      return;
    }

    // Collect classroom IDs for this quarter.
    final classroomIds = <String>{};
    for (final r in rows) {
      final cid = r['classroom_id']?.toString();
      if (cid != null) classroomIds.add(cid);
    }
    if (classroomIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No classroom information for grades.')),
        );
      }
      return;
    }

    final supa = Supabase.instance.client;
    List<dynamic> data;
    try {
      data = await supa
          .from('classrooms')
          .select()
          .inFilter('id', classroomIds.toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classrooms: $e')),
        );
      }
      return;
    }

    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No classrooms found for these grades.'),
          ),
        );
      }
      return;
    }

    final classrooms = <Classroom>[];
    for (final raw in data) {
      try {
        classrooms.add(Classroom.fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {
        // Ignore malformed rows.
      }
    }
    if (classrooms.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read classroom details.')),
        );
      }
      return;
    }

    Classroom? selected;
    if (classrooms.length == 1) {
      selected = classrooms.first;
    } else {
      if (!mounted) return;
      selected = await showDialog<Classroom>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Select classroom for SF9 export'),
            children: [
              for (final c in classrooms)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(c),
                  child: Text(
                    '${c.title} • Grade ${c.gradeLevel} (${c.schoolLevel})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );
        },
      );
      if (selected == null) {
        return;
      }
    }

    setState(() => _exportingSf9 = true);
    try {
      await SF9ExportService.instance.exportSF9ReportCard(
        studentId: uid,
        classroom: selected,
        quarter: q,
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
        setState(() => _exportingSf9 = false);
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Quarter,Subject,Final Grade,Initial Grade,Remarks');
      for (int q = 1; q <= 4; q++) {
        final rows = _byQuarter[q] ?? const <Map<String, dynamic>>[];
        for (final r in rows) {
          final title =
              _courseTitles[r['course_id'].toString()] ??
              r['course_id'].toString();
          final fg = _num(r['transmuted_grade']);
          final ig = _num(r['initial_grade']);
          final rem = (r['remarks'] as String?) ?? '';
          // Escape quotes for CSV safety
          final safeTitle = title.replaceAll('"', '""');
          final safeRem = rem.replaceAll('"', '""');
          buffer.writeln('Q$q,"$safeTitle",$fg,$ig,"$safeRem"');
        }
        if (rows.isNotEmpty) {
          final avg =
              rows
                  .map(
                    (r) => (r['transmuted_grade'] as num?)?.toDouble() ?? 0.0,
                  )
                  .fold<double>(0.0, (a, b) => a + b) /
              rows.length;
          buffer.writeln('Q$q,General Average,${avg.toStringAsFixed(2)},,');
        }
      }
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report card copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card'),
        actions: [
          if (_exportingSf9)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export SF9 Report Card',
            onPressed: _loading || _exportingSf9 ? null : _exportSf9,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: _exportToCSV,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentHeader(),
                  const SizedBox(height: 12),
                  _buildQuarterChips(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildQuarterBody()),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentHeader() {
    final name = _studentName ?? 'Student';
    final gradeLabel = _gradeLevel != null
        ? 'Grade ${_gradeLevel.toString()}'
        : null;
    final section = _sectionName;
    final sy = _schoolYearLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (gradeLabel != null)
              Chip(
                label: Text(gradeLabel, style: const TextStyle(fontSize: 11)),
              ),
            if (section != null && section.isNotEmpty)
              Chip(
                label: Text(
                  'Section $section',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            if (sy != null && sy.isNotEmpty)
              Chip(
                label: Text('S.Y. $sy', style: const TextStyle(fontSize: 11)),
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
            setState(() => _selectedQuarter = q);
          },
        );
      }),
    );
  }

  Widget _buildQuarterBody() {
    final q = _selectedQuarter;
    final rows = _byQuarter[q] ?? const <Map<String, dynamic>>[];
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No grades saved for Quarter $q'),
        ),
      );
    }

    final avg =
        rows
            .map((r) => (r['transmuted_grade'] as num?)?.toDouble() ?? 0.0)
            .fold<double>(0.0, (a, b) => a + b) /
        rows.length;

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
              final courseId = r['course_id'].toString();
              final title = _courseTitles[courseId] ?? courseId;
              final fg = _num(r['transmuted_grade']);
              final teacherId = _courseTeacherIds[courseId];
              final teacherName = teacherId != null
                  ? _teacherNames[teacherId] ?? ''
                  : '';
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
                        fg,
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

  String _num(dynamic n) {
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0.0;
    return d.toStringAsFixed(0);
  }
}
