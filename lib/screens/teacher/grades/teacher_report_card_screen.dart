import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/screens/teacher/grades/teacher_sf9_panel.dart';
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
  bool _exporting = false;
  int _selectedQuarter = 1;
  late final String _studentId;
  late final String _studentName;
  String? _studentEmail;
  String? _lrn;

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
    _loadStudentMeta();
  }

  Future<void> _loadStudentMeta() async {
    if (_studentId.isEmpty) return;
    try {
      final supa = Supabase.instance.client;
      final row = await supa
          .from('students')
          .select('lrn')
          .eq('id', _studentId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        if (row is Map<String, dynamic>) {
          final lrn = (row['lrn'] as String?)?.trim();
          _lrn = (lrn != null && lrn.isNotEmpty) ? lrn : null;
        }
      });
    } catch (_) {
      // ignore metadata load errors
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
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export SF9 Report Card (Excel)',
            onPressed: _exporting ? null : _onExportSf9Pressed,
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
            Expanded(
              child: TeacherSf9Panel(
                studentId: _studentId,
                studentName: _studentName,
              ),
            ),
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
            if (_lrn != null)
              Chip(
                label: Text(
                  'LRN ${_lrn!}',
                  style: const TextStyle(fontSize: 11),
                ),
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
          },
        );
      }),
    );
  }
}
