import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:oro_site_high_school/services/classroom_permission_service.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/screens/teacher/assignments/create_assignment_screen_new.dart';
import 'package:oro_site_high_school/screens/teacher/assignments/assignment_submissions_screen.dart';

/// Reusable assignments tab widget for subject assignments
///
/// **Phase 3: Full Assignment Workspace Integration**
/// Displays assignments organized by quarter with full CRUD support for teachers.
///
/// **Features:**
/// - **Teacher**: Full CRUD (create, edit, delete, view submissions, grade)
/// - **Student**: View assignments and submit work
/// - **Quarter filtering**: Q1, Q2, Q3, Q4
/// - **Assignment details**: Title, description, due date, points, submissions
/// - **Real-time updates**: Assignments update automatically
///
/// **Usage:**
/// ```dart
/// SubjectAssignmentsTab(
///   subject: _selectedSubject!,
///   classroomId: _selectedClassroom!.id,
///   userRole: 'teacher',
///   userId: _teacherId!,
/// )
/// ```
class SubjectAssignmentsTab extends StatefulWidget {
  final ClassroomSubject subject;
  final String classroomId;
  final String? userRole;
  final String? userId;

  const SubjectAssignmentsTab({
    super.key,
    required this.subject,
    required this.classroomId,
    this.userRole,
    this.userId,
  });

  @override
  State<SubjectAssignmentsTab> createState() => _SubjectAssignmentsTabState();
}

class _SubjectAssignmentsTabState extends State<SubjectAssignmentsTab>
    with SingleTickerProviderStateMixin {
  final AssignmentService _assignmentService = AssignmentService();
  final ClassroomPermissionService _permissionService = ClassroomPermissionService();
  final ClassroomService _classroomService = ClassroomService();

  late TabController _quarterTabController;
  int _selectedQuarter = 1;
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  // Phase 3: Track selected assignment for details view
  Map<String, dynamic>? _selectedAssignment;

  @override
  void initState() {
    super.initState();
    _quarterTabController = TabController(length: 4, vsync: this);
    _quarterTabController.addListener(_onQuarterChanged);
    _loadAssignments();
  }

  @override
  void dispose() {
    _quarterTabController.removeListener(_onQuarterChanged);
    _quarterTabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SubjectAssignmentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject.id != widget.subject.id ||
        oldWidget.classroomId != widget.classroomId) {
      _loadAssignments();
    }
  }

  void _onQuarterChanged() {
    if (_quarterTabController.indexIsChanging) {
      setState(() {
        _selectedQuarter = _quarterTabController.index + 1;
      });
    }
  }

  bool get _isTeacher {
    final role = widget.userRole?.toLowerCase();
    return role == 'teacher' || role == 'admin' || role == 'ict_coordinator' || role == 'hybrid';
  }

  bool get _isStudent => widget.userRole?.toLowerCase() == 'student';

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);

    try {
      final assignments = await _assignmentService.getClassroomAssignments(
        widget.classroomId,
      );

      // Filter assignments for this subject
      final subjectAssignments = assignments.where((a) {
        // ✅ FIXED: Use subject_id (UUID) instead of course_id (bigint)
        // This links assignments to classroom_subjects table (new system)
        return a['subject_id']?.toString() == widget.subject.id;
      }).toList();

      setState(() {
        _assignments = subjectAssignments;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading assignments: $e');
      setState(() => _isLoading = false);
    }
  }

  bool get _canCreateAssignments {
    return _permissionService.canCreateAssignments(
      userRole: widget.userRole,
      userId: widget.userId,
      subjectTeacherId: widget.subject.teacherId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quarter sub-tabs with create button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _quarterTabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'Q1'),
                    Tab(text: 'Q2'),
                    Tab(text: 'Q3'),
                    Tab(text: 'Q4'),
                  ],
                ),
              ),
              // Phase 3: Create assignment button (teachers only)
              if (_canCreateAssignments) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: _handleCreateAssignment,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Assignment list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildAssignmentList(),
        ),
      ],
    );
  }

  Widget _buildAssignmentList() {
    final filtered = _assignments.where((a) {
      int? qInt;
      final q = a['quarter_no'];
      if (q != null) qInt = int.tryParse(q.toString());
      return qInt == _selectedQuarter;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildAssignmentCard(filtered[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No assignments for Q$_selectedQuarter',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final title = assignment['title'] ?? 'Untitled';
    final description = assignment['description'] ?? '';
    final dueDate = assignment['due_date'];
    final points = assignment['points'];
    final isOwned = assignment['teacher_id'] == widget.userId;

    // Format due date
    String dueDateStr = 'No due date';
    if (dueDate != null) {
      try {
        final date = DateTime.parse(dueDate.toString());
        dueDateStr = DateFormat('MMM d, y h:mm a').format(date);
      } catch (e) {
        dueDateStr = 'Invalid date';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleViewAssignment(assignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Phase 3: Edit/Delete buttons for owned assignments (teachers only)
                  if (_isTeacher && isOwned) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _handleEditAssignment(assignment),
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _handleDeleteAssignment(assignment),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),

              // Description
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Due date and points
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    dueDateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  if (points != null) ...[
                    Icon(Icons.grade, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '$points pts',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Phase 3: Assignment action handlers
  Future<void> _handleCreateAssignment() async {
    try {
      // Fetch classroom details
      final classroom = await _classroomService.getClassroomById(widget.classroomId);
      if (classroom == null || !mounted) return;

      // Navigate to create assignment screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAssignmentScreen(
            classroom: classroom,
            subjectId: widget.subject.id, // NEW: Pass subject ID to link assignment
          ),
        ),
      );

      // Reload assignments if created
      if (result == true && mounted) {
        _loadAssignments();
      }
    } catch (e) {
      print('❌ Error creating assignment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleEditAssignment(Map<String, dynamic> assignment) async {
    try {
      // Fetch classroom details
      final classroom = await _classroomService.getClassroomById(widget.classroomId);
      if (classroom == null || !mounted) return;

      // Navigate to edit assignment screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAssignmentScreen(
            classroom: classroom,
            existingAssignment: assignment,
          ),
        ),
      );

      // Reload assignments if updated
      if (result == true && mounted) {
        _loadAssignments();
      }
    } catch (e) {
      print('❌ Error editing assignment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error editing assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAssignment(Map<String, dynamic> assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text(
          'Are you sure you want to delete "${assignment['title']}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final assignmentId = assignment['id'].toString();

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting assignment...')),
      );

      // Delete assignment
      await _assignmentService.deleteAssignment(assignmentId);

      if (!mounted) return;

      // Reload assignments
      _loadAssignments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error deleting assignment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleViewAssignment(Map<String, dynamic> assignment) {
    // Phase 3: Navigate to assignment submissions screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentSubmissionsScreen(
          assignmentId: assignment['id'].toString(),
          classroomId: widget.classroomId,
        ),
      ),
    );
  }
}
