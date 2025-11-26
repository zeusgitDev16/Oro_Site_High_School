import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/services/submission_service.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/screens/teacher/assignments/submission_detail_screen.dart';
import 'package:oro_site_high_school/widgets/assignment/assignment_analytics_widget.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  final String classroomId;
  final String assignmentId;
  final String? courseTitle;

  const AssignmentSubmissionsScreen({
    super.key,
    required this.classroomId,
    required this.assignmentId,
    this.courseTitle,
  });

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen>
    with SingleTickerProviderStateMixin {
  final SubmissionService _submissionService = SubmissionService();
  final ClassroomService _classroomService = ClassroomService();
  final AssignmentService _assignmentService = AssignmentService();

  bool _isLoading = true;
  Map<String, dynamic>? _assignment;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _submissions = [];
  late TabController _tabController;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Phase 5 Task 9: Added Analytics tab
    _loadData();
    _setupRealtime();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final students = await _classroomService.getClassroomStudents(
        widget.classroomId,
      );
      final submissions = await _submissionService.getSubmissionsForAssignment(
        widget.assignmentId,
      );
      final assignment = await _assignmentService.getAssignmentById(
        widget.assignmentId,
      );
      setState(() {
        _students = students;
        _submissions = submissions;
        _assignment = assignment;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading submissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic>? _findStudent(String studentId) {
    try {
      return _students.firstWhere(
        (s) => (s['student_id'] ?? s['id']).toString() == studentId,
      );
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _submitted {
    return _submissions
        .where((s) => (s['status'] ?? '') == 'submitted')
        .toList();
  }

  List<Map<String, dynamic>> get _notSubmitted {
    final submittedIds = _submitted
        .map((s) => s['student_id'].toString())
        .toSet();
    return _students
        .where(
          (st) =>
              !submittedIds.contains((st['student_id'] ?? st['id']).toString()),
        )
        .map(
          (st) => {
            'student_id': (st['student_id'] ?? st['id']).toString(),
            'full_name': st['full_name'] ?? 'Unknown Student',
            'email': st['email'] ?? '',
          },
        )
        .toList();
  }

  void _setupRealtime() {
    final supa = Supabase.instance.client;
    _channel = supa
        .channel('asubs:${widget.assignmentId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assignment_submissions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'assignment_id',
            value: widget.assignmentId,
          ),
          callback: (payload) {
            if (mounted) _loadData();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Submissions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: [
            Tab(text: 'Submitted (${_submitted.length})'),
            Tab(text: 'Not Submitted (${_notSubmitted.length})'),
            const Tab(text: 'Analytics'), // Phase 5 Task 9: Analytics tab
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildAssignmentHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubmittedList(),
                      _buildNotSubmittedList(),
                      // Phase 5 Task 9: Analytics tab
                      AssignmentAnalyticsWidget(
                        assignment: _assignment,
                        submissions: _submissions,
                        students: _students,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAssignmentHeader() {
    final a = _assignment;
    final title = (a != null
        ? (a['title']?.toString() ?? 'Assignment')
        : 'Assignment');
    final allowLate = (a != null
        ? ((a['allow_late_submissions'] ?? true) == true)
        : true);

    // NEW: Get timeline status
    final now = DateTime.now();
    final startTime = a?['start_time'] != null
        ? DateTime.tryParse(a!['start_time'].toString())
        : null;
    final dueDate = a?['due_date'] != null
        ? DateTime.tryParse(a!['due_date'].toString())
        : null;
    final endTime = a?['end_time'] != null
        ? DateTime.tryParse(a!['end_time'].toString())
        : null;

    String timelineStatus = 'active';
    if (startTime != null && now.isBefore(startTime)) {
      timelineStatus = 'scheduled';
    } else if (endTime != null && now.isAfter(endTime)) {
      timelineStatus = 'ended';
    } else if (dueDate != null && now.isAfter(dueDate)) {
      timelineStatus = allowLate ? 'late' : 'ended';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.courseTitle ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // NEW: Timeline status badge
              _buildTimelineStatusBadge(timelineStatus),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: allowLate ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: allowLate ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      allowLate ? Icons.check_circle : Icons.block,
                      size: 16,
                      color: allowLate ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      allowLate ? 'late allowed' : 'late not allowed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: allowLate
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // NEW: Timeline info row
          if (startTime != null || endTime != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (startTime != null)
                  _buildTimelineInfo(
                    'Start',
                    _formatDateTime(startTime),
                    Icons.play_circle,
                    Colors.green,
                  ),
                if (dueDate != null)
                  _buildTimelineInfo(
                    'Due',
                    _formatDateTime(dueDate),
                    Icons.event,
                    Colors.orange,
                  ),
                if (endTime != null)
                  _buildTimelineInfo(
                    'End',
                    _formatDateTime(endTime),
                    Icons.stop_circle,
                    Colors.red,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Build timeline status badge
  Widget _buildTimelineStatusBadge(String status) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'scheduled':
        icon = Icons.schedule;
        color = Colors.blue;
        label = 'Scheduled';
        break;
      case 'active':
        icon = Icons.play_circle;
        color = Colors.green;
        label = 'Active';
        break;
      case 'late':
        icon = Icons.warning;
        color = Colors.orange;
        label = 'Late';
        break;
      case 'ended':
        icon = Icons.stop_circle;
        color = Colors.red;
        label = 'Ended';
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Build timeline info chip
  Widget _buildTimelineInfo(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // NEW: Format date/time for display
  String _formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.month}/${dt.day}/${dt.year} $h:$m $ap';
  }

  Widget _buildSubmittedList() {
    if (_submitted.isEmpty) {
      return _empty('No submissions yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _submitted.length,
      itemBuilder: (context, index) {
        final s = _submitted[index];
        final student = _findStudent(s['student_id'].toString());
        final name = student?['full_name'] ?? s['student_id'];
        final email = student?['email'] ?? '';
        final submittedAt = s['submitted_at']?.toString();
        final isLate = (s['is_late'] ?? false) == true;
        final score = s['score'];
        final maxScore = s['max_score'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: const Icon(
                Icons.assignment_turned_in,
                color: Colors.green,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isLate ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLate
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    isLate ? 'late' : 'on time',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLate
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (submittedAt != null)
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        submittedAt.replaceFirst('T', ' ').split('.')[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                if (score != null && maxScore != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.grade, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Score: $score/$maxScore',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (email.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => SubmissionDetailScreen(
                    assignmentId: widget.assignmentId,
                    studentId: s['student_id'].toString(),
                    studentName: name,
                    studentEmail: email,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotSubmittedList() {
    final notList = _notSubmitted;
    if (notList.isEmpty) {
      return _empty('Everyone submitted');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notList.length,
      itemBuilder: (context, index) {
        final st = notList[index];
        final name = st['full_name'] ?? st['student_id'];
        final email = st['email'] ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: const Icon(Icons.hourglass_bottom, color: Colors.orange),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: email.toString().isNotEmpty
                ? Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _empty(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(msg, style: TextStyle(color: Colors.grey.shade600)),
    ),
  );
}
