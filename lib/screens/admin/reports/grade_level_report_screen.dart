import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/report_service.dart';

/// Grade Level Report Screen
/// Shows performance analysis by grade level
/// UI-only component following OSHS architecture
class GradeLevelReportScreen extends StatefulWidget {
  const GradeLevelReportScreen({super.key});

  @override
  State<GradeLevelReportScreen> createState() => _GradeLevelReportScreenState();
}

class _GradeLevelReportScreenState extends State<GradeLevelReportScreen> {
  final ReportService _reportService = ReportService();
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  int _selectedGradeLevel = 7;

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
      final data = await _reportService.generateGradeLevelReport(_selectedGradeLevel);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Level Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
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
                  _buildGradeLevelSelector(),
                  const SizedBox(height: 24),
                  _buildSummary(),
                  const SizedBox(height: 24),
                  _buildSectionsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGradeLevelSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text(
              'Select Grade Level:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('Grade 7')),
                ButtonSegment(value: 8, label: Text('Grade 8')),
                ButtonSegment(value: 9, label: Text('Grade 9')),
                ButtonSegment(value: 10, label: Text('Grade 10')),
              ],
              selected: {_selectedGradeLevel},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedGradeLevel = newSelection.first;
                });
                _loadReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final summary = _reportData?['summary'] as Map<String, dynamic>?;
    if (summary == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade $_selectedGradeLevel Summary',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Sections',
                    '${summary['totalSections']}',
                    Icons.class_,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Students',
                    '${summary['totalStudents']}',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Average',
                    '${summary['overallAverage']}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Passing Rate',
                    '${summary['passingRate']}%',
                    Icons.check_circle,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionsList() {
    final sections = _reportData?['sections'] as List<dynamic>?;
    if (sections == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Section Performance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...sections.map((section) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            section['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Avg: ${section['average']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adviser: ${section['adviser']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSectionStat(Icons.people, '${section['students']}', 'Students'),
                        const SizedBox(width: 24),
                        _buildSectionStat(Icons.check_circle, '${section['passing']}', 'Passing'),
                        const SizedBox(width: 24),
                        _buildSectionStat(Icons.warning, '${section['failing']}', 'At Risk'),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSectionStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
