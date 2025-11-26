import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/widgets/gradebook/bulk_compute_grades_dialog.dart';
import 'package:oro_site_high_school/widgets/gradebook/score_edit_dialog.dart';
import 'package:oro_site_high_school/widgets/gradebook/class_list_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// **Phase 4: Gradebook Grid Panel (Right Panel)**
/// 
/// Displays gradebook grid with:
/// - Quarter selector (Q1-Q4)
/// - Student rows with assignment scores
/// - "Compute Grades" button
class GradebookGridPanel extends StatefulWidget {
  final Classroom classroom;
  final ClassroomSubject subject;
  final String teacherId;

  const GradebookGridPanel({
    super.key,
    required this.classroom,
    required this.subject,
    required this.teacherId,
  });

  @override
  State<GradebookGridPanel> createState() => _GradebookGridPanelState();
}

class _GradebookGridPanelState extends State<GradebookGridPanel> {
  final ClassroomService _classroomService = ClassroomService();
  final AssignmentService _assignmentService = AssignmentService();

  int _selectedQuarter = 1;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _assignments = [];
  Map<String, Map<String, dynamic>> _submissionMap = {}; // "studentId_assignmentId" -> submission

  bool _isLoading = true;
  bool _showClassList = false; // Toggle for class list panel

  @override
  void initState() {
    super.initState();
    _loadGradebookData();
  }

  @override
  void didUpdateWidget(GradebookGridPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classroom.id != widget.classroom.id ||
        oldWidget.subject.id != widget.subject.id) {
      _loadGradebookData();
    }
  }

  Future<void> _loadGradebookData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Load students (real users from database)
      final rawStudents = await _classroomService.getClassroomStudents(widget.classroom.id);

      // OPTIMIZATION: Normalize student data to use 'id' field consistently
      final students = rawStudents.map((s) {
        return {
          'id': s['student_id'] ?? s['id'], // Normalize to 'id'
          'full_name': s['full_name'] ?? 'Unknown',
          'email': s['email'] ?? '',
          'enrolled_at': s['enrolled_at'],
        };
      }).toList();

      // 2. Load assignments (filtered by quarter and subject)
      //    PHASE 5 INTEGRATION: Timeline assignments (with start_time/end_time)
      //    are included in the gradebook regardless of their timeline status.
      //    This allows teachers to see all assignments and their submissions,
      //    even if they're scheduled for the future or have ended.
      final allAssignments = await _assignmentService.getClassroomAssignments(widget.classroom.id);
      final filteredAssignments = allAssignments.where((a) {
        final quarterNo = a['quarter_no'];
        final courseId = a['course_id']?.toString();
        return quarterNo == _selectedQuarter && courseId == widget.subject.id;
      }).toList();

      // 3. Load submissions (bulk query with real student IDs)
      final submissionMap = await _loadSubmissions(
        students.map((s) => s['id'].toString()).toList(),
        filteredAssignments.map((a) => a['id'].toString()).toList(),
      );

      setState(() {
        _students = students;
        _assignments = filteredAssignments;
        _submissionMap = submissionMap;
        _isLoading = false;
      });

      print('✅ Gradebook loaded: ${students.length} students, ${filteredAssignments.length} assignments');
    } catch (e) {
      print('❌ Error loading gradebook data: $e');
      setState(() {
        _students = [];
        _assignments = [];
        _submissionMap = {};
        _isLoading = false;
      });
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadSubmissions(
    List<String> studentIds,
    List<String> assignmentIds,
  ) async {
    if (studentIds.isEmpty || assignmentIds.isEmpty) {
      return {};
    }

    try {
      final supabase = Supabase.instance.client;
      final submissions = await supabase
          .from('assignment_submissions')
          .select('*')
          .eq('classroom_id', widget.classroom.id)
          .inFilter('student_id', studentIds)
          .inFilter('assignment_id', assignmentIds);

      final map = <String, Map<String, dynamic>>{};
      for (final sub in submissions as List) {
        final key = '${sub['student_id']}_${sub['assignment_id']}';
        map[key] = Map<String, dynamic>.from(sub);
      }

      return map;
    } catch (e) {
      print('❌ Error loading submissions: $e');
      return {};
    }
  }

  void _handleQuarterChanged(int quarter) {
    setState(() => _selectedQuarter = quarter);
    _loadGradebookData();
  }

  Future<void> _handleComputeGrades() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to compute grades for')),
      );
      return;
    }

    final successCount = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BulkComputeGradesDialog(
        classroomId: widget.classroom.id,
        courseId: widget.subject.id,
        quarter: _selectedQuarter,
        students: _students,
      ),
    );

    if (successCount != null && successCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully computed $successCount grade(s)')),
      );

      // Refresh grid
      _loadGradebookData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main gradebook area
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Loading gradebook data...',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : _buildGradebookGrid(),
              ),
            ],
          ),
        ),

        // Class list panel (collapsible)
        if (_showClassList)
          ClassListPanel(
            students: _students,
            classroomTitle: widget.classroom.title,
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Gradebook',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Legend
                    _buildLegend(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.classroom.title} • ${widget.subject.subjectName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Quarter selector
          Wrap(
            spacing: 6,
            children: List.generate(4, (i) {
              final q = i + 1;
              final selected = _selectedQuarter == q;
              return ChoiceChip(
                label: Text('Q$q', style: const TextStyle(fontSize: 11)),
                selected: selected,
                onSelected: (_) => _handleQuarterChanged(q),
                selectedColor: Colors.blue.shade100,
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: selected ? Colors.blue.shade900 : Colors.grey.shade700,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }),
          ),

          const SizedBox(width: 12),

          // Compute Grades button
          Tooltip(
            message: 'Compute DepEd grades for selected students',
            child: ElevatedButton.icon(
              onPressed: _handleComputeGrades,
              icon: const Icon(Icons.calculate, size: 16),
              label: const Text('Compute Grades', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Class List toggle button
          Tooltip(
            message: _showClassList ? 'Hide class list' : 'Show class list',
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showClassList = !_showClassList;
                });
              },
              icon: Icon(
                _showClassList ? Icons.people : Icons.people_outline,
                size: 16,
              ),
              label: Text(
                'Class List',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _showClassList ? Colors.blue : Colors.grey.shade700,
                side: BorderSide(
                  color: _showClassList ? Colors.blue : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: Colors.red.shade400),
          const SizedBox(width: 4),
          Text('Missing', style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
          const SizedBox(width: 10),
          Icon(Icons.square, size: 10, color: Colors.orange.shade400),
          const SizedBox(width: 4),
          Text('Submitted', style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
          const SizedBox(width: 10),
          Text('##', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(width: 4),
          Text('Graded', style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildGradebookGrid() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No students enrolled',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Students must be enrolled in this classroom to appear here',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGradebookData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildDataTable(),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      headingRowHeight: 80,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 48,
      columnSpacing: 12,
      horizontalMargin: 12,
      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columns: [
        // Student column
        DataColumn(
          label: Container(
            width: 180,
            child: const Text(
              'Student',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Assignment columns
        ..._assignments.map((assignment) {
          final title = assignment['title'] ?? 'Untitled';
          final points = assignment['total_points'] ?? 0;
          final dueDate = assignment['due_date'];

          return DataColumn(
            label: Container(
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$points pts',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),

        // Overall column
        DataColumn(
          label: Container(
            width: 100,
            child: const Text(
              'Overall',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
      rows: _students.map((student) {
        return _buildStudentRow(student);
      }).toList(),
    );
  }

  DataRow _buildStudentRow(Map<String, dynamic> student) {
    final studentId = student['id'].toString();
    final fullName = student['full_name'] ?? 'Unknown';

    // Calculate overall score
    double totalScore = 0;
    double totalMax = 0;

    for (final assignment in _assignments) {
      final assignmentId = assignment['id'].toString();
      final key = '${studentId}_$assignmentId';
      final submission = _submissionMap[key];

      final score = (submission?['score'] as num?)?.toDouble() ?? 0;
      final maxScore = (assignment['total_points'] as num?)?.toDouble() ?? 0;

      totalScore += score;
      totalMax += maxScore;
    }

    final overallPercentage = totalMax > 0 ? (totalScore / totalMax) * 100 : 0;

    return DataRow(
      cells: [
        // Student name cell
        DataCell(
          Container(
            width: 180,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    fullName[0].toUpperCase(),
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade900),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Assignment score cells
        ..._assignments.map((assignment) {
          final assignmentId = assignment['id'].toString();
          final key = '${studentId}_$assignmentId';
          final submission = _submissionMap[key];

          return _buildScoreCell(studentId, assignmentId, submission, assignment);
        }).toList(),

        // Overall cell
        DataCell(
          Container(
            width: 100,
            child: Text(
              '${overallPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: overallPercentage >= 75 ? Colors.green.shade700 : Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  DataCell _buildScoreCell(
    String studentId,
    String assignmentId,
    Map<String, dynamic>? submission,
    Map<String, dynamic> assignment,
  ) {
    final status = submission?['status']?.toString() ?? 'missing';
    final score = (submission?['score'] as num?)?.toDouble();

    Widget content;
    String tooltipMessage;

    if (submission == null || status == 'draft') {
      // Missing
      content = Icon(Icons.circle, size: 12, color: Colors.red.shade400);
      tooltipMessage = 'Missing - No submission yet';
    } else if (status == 'submitted') {
      // Incomplete (submitted but not graded)
      content = Icon(Icons.square, size: 12, color: Colors.orange.shade400);
      tooltipMessage = 'Submitted - Waiting for grade';
    } else if (status == 'graded' && score != null) {
      // Graded
      content = Text(
        score.toStringAsFixed(0),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      );
      final maxScore = (assignment['total_points'] as num?)?.toDouble() ?? 0;
      tooltipMessage = 'Score: ${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)}';
    } else {
      // Unknown
      content = Text('-', style: TextStyle(fontSize: 11, color: Colors.grey.shade400));
      tooltipMessage = 'No data';
    }

    return DataCell(
      Tooltip(
        message: '$tooltipMessage\nClick to edit score',
        child: InkWell(
          onTap: () => _handleScoreEdit(studentId, assignmentId, submission, assignment),
          child: Container(
            width: 80,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: content,
          ),
        ),
      ),
    );
  }

  Future<void> _handleScoreEdit(
    String studentId,
    String assignmentId,
    Map<String, dynamic>? submission,
    Map<String, dynamic> assignment,
  ) async {
    // Find student data
    final student = _students.firstWhere(
      (s) => s['id'].toString() == studentId,
      orElse: () => {'id': studentId, 'full_name': 'Unknown'},
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => ScoreEditDialog(
        student: student,
        assignment: assignment,
        submission: submission,
      ),
    );

    if (saved == true && mounted) {
      // Refresh grid
      _loadGradebookData();
    }
  }
}

