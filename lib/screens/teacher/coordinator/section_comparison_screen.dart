import 'package:flutter/material.dart';

/// Section Comparison Screen for Grade Level Coordinators
/// Compare performance across all sections in a grade level
/// UI-only component following OSHS architecture
class SectionComparisonScreen extends StatefulWidget {
  const SectionComparisonScreen({super.key});

  @override
  State<SectionComparisonScreen> createState() => _SectionComparisonScreenState();
}

class _SectionComparisonScreenState extends State<SectionComparisonScreen> {
  String _selectedSubject = 'All Subjects';
  String _selectedQuarter = 'Q1';

  // Mock section data for Grade 7
  final List<Map<String, dynamic>> _sections = [
    {
      'name': 'Grade 7 - Diamond',
      'students': 35,
      'average': 88.5,
      'highest': 96.0,
      'lowest': 78.0,
      'passing': 33,
      'failing': 2,
      'adviser': 'Maria Santos',
    },
    {
      'name': 'Grade 7 - Emerald',
      'students': 36,
      'average': 86.2,
      'highest': 94.0,
      'lowest': 75.0,
      'passing': 34,
      'failing': 2,
      'adviser': 'Juan Reyes',
    },
    {
      'name': 'Grade 7 - Ruby',
      'students': 35,
      'average': 90.1,
      'highest': 98.0,
      'lowest': 82.0,
      'passing': 35,
      'failing': 0,
      'adviser': 'Ana Cruz',
    },
    {
      'name': 'Grade 7 - Sapphire',
      'students': 34,
      'average': 84.7,
      'highest': 92.0,
      'lowest': 72.0,
      'passing': 31,
      'failing': 3,
      'adviser': 'Pedro Garcia',
    },
    {
      'name': 'Grade 7 - Pearl',
      'students': 36,
      'average': 87.3,
      'highest': 95.0,
      'lowest': 76.0,
      'passing': 34,
      'failing': 2,
      'adviser': 'Rosa Mendoza',
    },
    {
      'name': 'Grade 7 - Jade',
      'students': 35,
      'average': 85.9,
      'highest': 93.0,
      'lowest': 74.0,
      'passing': 33,
      'failing': 2,
      'adviser': 'Carlos Lopez',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section Comparison'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallStats(),
                  const SizedBox(height: 32),
                  _buildSectionCards(),
                  const SizedBox(height: 32),
                  _buildPerformanceChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Grade 7 Sections',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                'All Subjects',
                'Mathematics 7',
                'Science 7',
                'English 7',
                'Filipino 7',
              ].map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: _selectedQuarter,
              decoration: InputDecoration(
                labelText: 'Quarter',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['Q1', 'Q2', 'Q3', 'Q4'].map((quarter) {
                return DropdownMenuItem(
                  value: quarter,
                  child: Text(quarter),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuarter = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    final totalStudents = _sections.fold<int>(0, (sum, s) => sum + (s['students'] as int));
    final overallAverage = _sections.fold<double>(0, (sum, s) => sum + (s['average'] as double)) / _sections.length;
    final totalPassing = _sections.fold<int>(0, (sum, s) => sum + (s['passing'] as int));
    final totalFailing = _sections.fold<int>(0, (sum, s) => sum + (s['failing'] as int));

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Students',
            '$totalStudents',
            Icons.people,
            Colors.blue,
            'Across ${_sections.length} sections',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Overall Average',
            overallAverage.toStringAsFixed(2),
            Icons.trending_up,
            Colors.green,
            'Grade level performance',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Passing Rate',
            '${((totalPassing / totalStudents) * 100).toStringAsFixed(1)}%',
            Icons.check_circle,
            Colors.purple,
            '$totalPassing of $totalStudents students',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'At Risk',
            '$totalFailing',
            Icons.warning,
            Colors.orange,
            'Students need intervention',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCards() {
    // Sort sections by average (highest first)
    final sortedSections = List<Map<String, dynamic>>.from(_sections)
      ..sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Section Performance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...sortedSections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          return _buildSectionCard(section, index + 1);
        }),
      ],
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section, int rank) {
    final passingRate = (section['passing'] / section['students']) * 100;
    final isTopPerformer = rank <= 2;
    final needsAttention = section['failing'] > 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopPerformer ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTopPerformer
            ? BorderSide(color: Colors.green.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isTopPerformer ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isTopPerformer ? Colors.green : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            section['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isTopPerformer) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.star, size: 12, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'TOP PERFORMER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (needsAttention) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning, size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    'NEEDS ATTENTION',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adviser: ${section['adviser']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        section['average'].toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(
                        'Average',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSectionStat(Icons.people, '${section['students']}', 'Students'),
                const SizedBox(width: 24),
                _buildSectionStat(Icons.arrow_upward, '${section['highest']}', 'Highest'),
                const SizedBox(width: 24),
                _buildSectionStat(Icons.arrow_downward, '${section['lowest']}', 'Lowest'),
                const SizedBox(width: 24),
                _buildSectionStat(Icons.check_circle, '${passingRate.toStringAsFixed(0)}%', 'Passing'),
                const SizedBox(width: 24),
                _buildSectionStat(Icons.warning, '${section['failing']}', 'At Risk'),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildPerformanceChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ..._sections.map((section) {
              final maxAverage = _sections.fold<double>(
                0,
                (max, s) => (s['average'] as double) > max ? s['average'] as double : max,
              );
              final percentage = (section['average'] / maxAverage) * 100;

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
                            section['name'],
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
                          width: 50,
                          child: Text(
                            section['average'].toStringAsFixed(1),
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
}
