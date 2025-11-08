import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class StudentReportCardScreen extends StatefulWidget {
  const StudentReportCardScreen({super.key});
  @override
  State<StudentReportCardScreen> createState() =>
      _StudentReportCardScreenState();
}

class _StudentReportCardScreenState extends State<StudentReportCardScreen>
    with SingleTickerProviderStateMixin {
  String? _uid;
  RealtimeChannel? _channel;
  late TabController _tab;
  bool _loading = true;
  final Map<int, List<Map<String, dynamic>>> _byQuarter = {
    1: [],
    2: [],
    3: [],
    4: [],
  };
  final Map<String, String> _courseTitles = {}; // courseId -> title

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _uid = Supabase.instance.client.auth.currentUser?.id;
    _subscribe();
    _loadData();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _tab.dispose();
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
      if (courseIds.isNotEmpty) {
        final cc = await supa
            .from('courses')
            .select('id, title')
            .inFilter('id', courseIds.toList());
        _courseTitles.clear();
        for (final c in cc) {
          _courseTitles[c['id'].toString()] = (c['title'] as String? ?? '');
        }
      }
      if (mounted)
        setState(() {
          _byQuarter
            ..[1] = map[1]!
            ..[2] = map[2]!
            ..[3] = map[3]!
            ..[4] = map[4]!;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _byQuarter[1] = [];
          _byQuarter[2] = [];
          _byQuarter[3] = [];
          _byQuarter[4] = [];
        });
    } finally {
      if (mounted) setState(() => _loading = false);
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
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: _exportToCSV,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Q1'),
            Tab(text: 'Q2'),
            Tab(text: 'Q3'),
            Tab(text: 'Q4'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _quarterTable(1),
                _quarterTable(2),
                _quarterTable(3),
                _quarterTable(4),
              ],
            ),
    );
  }

  Widget _quarterTable(int q) {
    final rows = _byQuarter[q] ?? [];
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No grades saved for Quarter $q'),
        ),
      );
    }
    final avg = rows.isEmpty
        ? 0.0
        : rows
                  .map(
                    (r) => (r['transmuted_grade'] as num?)?.toDouble() ?? 0.0,
                  )
                  .fold<double>(0.0, (a, b) => a + b) /
              rows.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quarter $q',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Chip(label: Text('General Average: ${avg.toStringAsFixed(0)}')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('Final')),
                  DataColumn(label: Text('Initial')),
                  DataColumn(label: Text('Remarks')),
                ],
                rows: rows.map((r) {
                  final title =
                      _courseTitles[r['course_id'].toString()] ??
                      r['course_id'].toString();
                  final fg = _num(r['transmuted_grade']);
                  final ig = _num(r['initial_grade']);
                  final rem = (r['remarks'] as String?) ?? '';
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(Text(fg)),
                      DataCell(Text(ig)),
                      DataCell(Text(rem.isEmpty ? '—' : rem)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _num(dynamic n) {
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0.0;
    return d.toStringAsFixed(0);
  }
}
