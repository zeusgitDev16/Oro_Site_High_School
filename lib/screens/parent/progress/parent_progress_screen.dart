import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/parent/parent_progress_logic.dart';
import 'package:oro_site_high_school/screens/parent/widgets/progress_chart_widget.dart';
import 'package:oro_site_high_school/screens/parent/dialogs/report_export_dialog.dart';

/// Parent Progress Screen - View children's progress reports and analytics
/// UI only - interactive logic in ParentProgressLogic
class ParentProgressScreen extends StatefulWidget {
  const ParentProgressScreen({super.key});

  @override
  State<ParentProgressScreen> createState() => _ParentProgressScreenState();
}

class _ParentProgressScreenState extends State<ParentProgressScreen> {
  final ParentProgressLogic _logic = ParentProgressLogic();

  @override
  void initState() {
    super.initState();
    _logic.loadProgressData('student123');
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Reports'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: 'Export Full Report',
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

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildComparisonCard(),
                _buildGradeTrendSection(),
                _buildAttendanceTrendSection(),
                _buildAssignmentCompletionSection(),
                _buildTeacherCommentsSection(),
              ],
            ),
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
                'Progress Analytics',
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

  Widget _buildComparisonCard() {
    final comparison = _logic.getComparisonData();
    final isImproving = comparison['trend'] == 'improving';
    final isStable = comparison['trend'] == 'stable';
    
    return Container(
      margin: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isImproving ? Colors.green.shade50 : (isStable ? Colors.blue.shade50 : Colors.orange.shade50),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isImproving ? Icons.trending_up : (isStable ? Icons.trending_flat : Icons.trending_down),
                    color: isImproving ? Colors.green.shade700 : (isStable ? Colors.blue.shade700 : Colors.orange.shade700),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isImproving ? 'Performance Improving!' : (isStable ? 'Performance Stable' : 'Needs Attention'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isImproving ? Colors.green.shade700 : (isStable ? Colors.blue.shade700 : Colors.orange.shade700),
                          ),
                        ),
                        Text(
                          'Current vs Previous Quarter',
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
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildComparisonItem(
                    'Current',
                    '${comparison['currentGrade']}%',
                    Colors.blue,
                  ),
                  Icon(
                    isImproving ? Icons.arrow_forward : Icons.arrow_back,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                  _buildComparisonItem(
                    'Previous',
                    '${comparison['previousGrade']}%',
                    Colors.grey,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isImproving ? Colors.green : (isStable ? Colors.blue : Colors.orange),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${comparison['difference'] > 0 ? '+' : ''}${comparison['difference'].toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  Widget _buildComparisonItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildGradeTrendSection() {
    final gradeTrends = _logic.getGradeTrends();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Grade Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ProgressChartWidget(
                title: 'Quarterly Performance',
                data: gradeTrends,
                type: 'grade',
              ),
              const SizedBox(height: 16),
              _buildGradeTrendList(gradeTrends),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeTrendList(List<Map<String, dynamic>> trends) {
    return Column(
      children: trends.map((trend) {
        final grade = trend['grade'] as double;
        final color = grade >= 90 ? Colors.green : (grade >= 75 ? Colors.orange : Colors.red);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend['quarter'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: grade / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${grade.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceTrendSection() {
    final attendanceTrends = _logic.getAttendanceTrends();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Attendance Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ProgressChartWidget(
                title: 'Monthly Attendance',
                data: attendanceTrends,
                type: 'attendance',
              ),
              const SizedBox(height: 16),
              _buildAttendanceTrendList(attendanceTrends),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTrendList(List<Map<String, dynamic>> trends) {
    return Column(
      children: trends.map((trend) {
        final percentage = trend['percentage'] as double;
        final color = percentage >= 95 ? Colors.green : (percentage >= 85 ? Colors.orange : Colors.red);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend['month'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAssignmentCompletionSection() {
    final stats = _logic.getAssignmentStats();
    final completionRate = _logic.calculateCompletionRate();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment_turned_in, color: Colors.purple.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Assignment Completion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: completionRate / 100,
                        strokeWidth: 20,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${completionRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Submitted', '${stats['submitted']}', Colors.green),
                  _buildStatItem('Pending', '${stats['pending']}', Colors.orange),
                  _buildStatItem('Late', '${stats['late']}', Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherCommentsSection() {
    final comments = _logic.getTeacherComments();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.comment, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Teacher Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...comments.map((comment) => _buildCommentCard(comment)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange,
                child: Text(
                  comment['teacher'].toString().split(' ')[0][0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['teacher'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      comment['subject'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                comment['date'],
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment['comment'],
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ReportExportDialog(
        reportType: 'Complete Progress Report',
        onExport: (format, options) {
          _logic.exportFullReport().then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Exporting full report as $format...'),
                backgroundColor: Colors.green,
              ),
            );
          });
        },
      ),
    );
  }
}
