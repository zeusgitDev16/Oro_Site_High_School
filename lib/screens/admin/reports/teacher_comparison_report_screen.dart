import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/report_service.dart';
import 'package:oro_site_high_school/screens/admin/reports/dialogs/share_report_dialog.dart';

/// Teacher Comparison Report Screen
/// Shows comparative analysis of all teachers
/// UI-only component following OSHS architecture
class TeacherComparisonReportScreen extends StatefulWidget {
  const TeacherComparisonReportScreen({super.key});

  @override
  State<TeacherComparisonReportScreen> createState() => _TeacherComparisonReportScreenState();
}

class _TeacherComparisonReportScreenState extends State<TeacherComparisonReportScreen> {
  final ReportService _reportService = ReportService();
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String _sortBy = 'performance'; // performance, courses, students, requests

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _reportService.generateTeacherComparisonReport();
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSortedTeachers() {
    if (_reportData == null) return [];
    
    final teachers = List<Map<String, dynamic>>.from(_reportData!['teachers']);
    
    teachers.sort((a, b) {
      switch (_sortBy) {
        case 'performance':
          return (b['performance'] as num).compareTo(a['performance'] as num);
        case 'courses':
          return (b['courses'] as int).compareTo(a['courses'] as int);
        case 'students':
          return (b['students'] as int).compareTo(a['students'] as int);
        case 'requests':
          return (b['requests'] as int).compareTo(a['requests'] as int);
        default:
          return 0;
      }
    });
    
    return teachers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Comparison Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _handleExport,
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
          ),
          IconButton(
            onPressed: _handleShare,
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatistics(),
                  const SizedBox(height: 32),
                  _buildSortControls(),
                  const SizedBox(height: 16),
                  _buildTeacherTable(),
                  const SizedBox(height: 32),
                  _buildPerformanceChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people_alt, color: Colors.blue, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teacher Comparison Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated: ${DateTime.now().toString().split('.')[0]}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'School Year: ${_reportData?['schoolYear'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _reportData?['statistics'] as Map<String, dynamic>?;
    if (stats == null) return const SizedBox();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg Courses',
            stats['avgCourses'].toString(),
            Icons.school,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avg Students',
            stats['avgStudents'].toStringAsFixed(0),
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avg Performance',
            '${stats['avgPerformance'].toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Requests',
            stats['totalRequests'].toString(),
            Icons.inbox,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortControls() {
    return Row(
      children: [
        const Text(
          'Sort by:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'performance', label: Text('Performance')),
            ButtonSegment(value: 'courses', label: Text('Courses')),
            ButtonSegment(value: 'students', label: Text('Students')),
            ButtonSegment(value: 'requests', label: Text('Requests')),
          ],
          selected: {_sortBy},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _sortBy = newSelection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTeacherTable() {
    final teachers = _getSortedTeachers();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Teacher', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Courses', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Students', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Performance', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Requests', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: teachers.asMap().entries.map((entry) {
            final index = entry.key;
            final teacher = entry.value;
            final performance = teacher['performance'] as num;
            final performanceColor = performance >= 90
                ? Colors.green
                : performance >= 85
                    ? Colors.blue
                    : Colors.orange;

            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: index < 3 ? Colors.amber.withOpacity(0.2) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight: index < 3 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(
                  teacher['name'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
                DataCell(Text(teacher['role'])),
                DataCell(Text('Grade ${teacher['gradeLevel']}')),
                DataCell(Text('${teacher['courses']}')),
                DataCell(Text('${teacher['students']}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: performanceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${performance.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: performanceColor,
                      ),
                    ),
                  ),
                ),
                DataCell(Text('${teacher['requests']}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final teachers = _getSortedTeachers();
    final maxPerformance = teachers.fold<double>(
      0,
      (max, t) => (t['performance'] as num) > max ? (t['performance'] as num).toDouble() : max,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...teachers.map((teacher) {
              final performance = (teacher['performance'] as num).toDouble();
              final percentage = (performance / maxPerformance) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            teacher['name'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${performance.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _handleShare() async {
    if (_reportData == null) return;

    showDialog(
      context: context,
      builder: (context) => ShareReportDialog(
        report: _reportData!,
        reportType: 'Teacher Comparison',
      ),
    );
  }
}
