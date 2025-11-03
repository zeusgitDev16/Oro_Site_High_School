import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/parent/parent_grades_logic.dart';
import 'package:oro_site_high_school/screens/parent/widgets/grade_summary_widget.dart';
import 'package:oro_site_high_school/screens/parent/dialogs/report_export_dialog.dart';

/// Parent Grades Screen - View children's grades
/// UI only - interactive logic in ParentGradesLogic
class ParentGradesScreen extends StatefulWidget {
  const ParentGradesScreen({super.key});

  @override
  State<ParentGradesScreen> createState() => _ParentGradesScreenState();
}

class _ParentGradesScreenState extends State<ParentGradesScreen>
    with SingleTickerProviderStateMixin {
  final ParentGradesLogic _logic = ParentGradesLogic();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _logic.loadGrades('student123', 'Q1');
    _tabController = TabController(length: _logic.grades.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: 'Export Grades',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          if (_logic.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(),
              _buildQuarterSelector(),
              _buildOverallGradeCard(),
              Expanded(
                child: _buildSubjectTabs(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Academic Performance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Juan Dela Cruz - Grade 7 Diamond',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          const Text(
            'Quarter:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuarterChip('Q1'),
                  const SizedBox(width: 8),
                  _buildQuarterChip('Q2'),
                  const SizedBox(width: 8),
                  _buildQuarterChip('Q3'),
                  const SizedBox(width: 8),
                  _buildQuarterChip('Q4'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterChip(String quarter) {
    final isSelected = _logic.selectedQuarter == quarter;
    
    return FilterChip(
      label: Text(quarter),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _logic.setQuarter(quarter);
          _logic.loadGrades('student123', quarter);
        }
      },
      selectedColor: Colors.orange,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOverallGradeCard() {
    final overallGrade = _logic.calculateOverallGrade();
    final letterGrade = _logic.getLetterGrade(overallGrade);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    overallGrade.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    'Overall Grade',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 2,
                height: 60,
                color: Colors.orange.shade200,
              ),
              Column(
                children: [
                  Text(
                    letterGrade,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    'Letter Grade',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectTabs() {
    final grades = _logic.grades;
    
    if (grades.isEmpty) {
      return const Center(
        child: Text('No grades available for this quarter'),
      );
    }

    return DefaultTabController(
      length: grades.length,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: grades.map((grade) {
                return Tab(
                  child: Row(
                    children: [
                      Icon(
                        _getSubjectIcon(grade['subject']),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(grade['subject']),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: grades.map((grade) {
                return _buildSubjectDetail(grade);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDetail(Map<String, dynamic> subjectGrade) {
    final assignments = subjectGrade['assignments'] as List;
    final quarterGrade = subjectGrade['quarterGrade'];
    final letterGrade = subjectGrade['letterGrade'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradeSummaryWidget(gradeData: subjectGrade),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Assignments & Assessments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...assignments.map((assignment) => _buildAssignmentCard(assignment)),
          const SizedBox(height: 24),
          _buildGradeSummaryCard(quarterGrade, letterGrade),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final percentage = assignment['percentage'] as int;
    final color = percentage >= 90
        ? Colors.green
        : (percentage >= 75 ? Colors.orange : Colors.red);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    assignment['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      assignment['date'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${assignment['score']} / ${assignment['total']} points',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSummaryCard(double quarterGrade, String letterGrade) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Quarter Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      quarterGrade.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'Quarter Grade',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 2,
                  height: 50,
                  color: Colors.blue.shade200,
                ),
                Column(
                  children: [
                    Text(
                      letterGrade,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'Letter Grade',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    if (subject.contains('Math')) return Icons.calculate;
    if (subject.contains('Science')) return Icons.science;
    if (subject.contains('English')) return Icons.menu_book;
    if (subject.contains('Filipino')) return Icons.language;
    return Icons.school;
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ReportExportDialog(
        reportType: 'Grades Report',
        onExport: (format, options) {
          _logic.exportGradesAsPdf().then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Exporting grades as $format...'),
                backgroundColor: Colors.green,
              ),
            );
          });
        },
      ),
    );
  }
}
