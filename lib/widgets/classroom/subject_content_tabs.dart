import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_modules_tab.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_assignments_tab.dart';
import 'package:oro_site_high_school/widgets/announcement_tab.dart';
import 'package:oro_site_high_school/widgets/attendance/attendance_tab_widget.dart';

/// Reusable tabbed content widget for subject details
///
/// **Role-Based Tab Display (Updated - Attendance for All):**
/// - **Students**: 3 tabs (Modules, Assignments, Attendance)
/// - **Teachers/Admin**: 5 tabs (Modules, Assignments, Announcements, Members, Attendance)
///
/// **Tab Contents:**
/// 1. **Modules** - Subject resources (modules only for students, includes assignment resources for teachers/admin)
/// 2. **Assignments** - Assignment list with submission tracking
/// 3. **Attendance** - Attendance tracking (read-only for students, editable for teachers/admin)
/// 4. **Announcements** - Subject announcements with replies (teachers/admin only)
/// 5. **Members** - Classroom members (teachers/admin only)
///
/// **Usage:**
/// ```dart
/// SubjectContentTabs(
///   subject: _selectedSubject!,
///   classroomId: _selectedClassroom!.id,
///   userRole: 'student', // 'student', 'teacher', 'admin', etc.
///   userId: _userId!,
/// )
/// ```
class SubjectContentTabs extends StatefulWidget {
  final ClassroomSubject subject;
  final String classroomId;
  final String? userRole;
  final String? userId;

  const SubjectContentTabs({
    super.key,
    required this.subject,
    required this.classroomId,
    this.userRole,
    this.userId,
  });

  @override
  State<SubjectContentTabs> createState() => _SubjectContentTabsState();
}

class _SubjectContentTabsState extends State<SubjectContentTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Check if current user is a student
  bool get _isStudent => widget.userRole?.toLowerCase() == 'student';

  /// Get number of tabs based on user role
  /// - Students: 3 tabs (Modules, Assignments, Attendance)
  /// - Teachers/Admin: 5 tabs (Modules, Assignments, Announcements, Members, Attendance)
  int get _tabCount => _isStudent ? 3 : 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SubjectContentTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if role changed (affects tab count)
    final oldIsStudent = oldWidget.userRole?.toLowerCase() == 'student';
    if (_isStudent != oldIsStudent) {
      // Role changed - recreate tab controller
      _tabController.dispose();
      _tabController = TabController(length: _tabCount, vsync: this);
    }

    // Reset to first tab when subject changes
    if (oldWidget.subject.id != widget.subject.id) {
      _tabController.index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.blue.shade700,
            tabs: _buildTabs(),
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _buildTabViews(),
          ),
        ),
      ],
    );
  }

  /// Build tabs based on user role
  /// Updated: Students now see Attendance tab (read-only)
  List<Widget> _buildTabs() {
    if (_isStudent) {
      // Students: Modules, Assignments, Attendance (read-only)
      return const [
        Tab(text: 'Modules'),
        Tab(text: 'Assignments'),
        Tab(text: 'Attendance'),
      ];
    } else {
      // Teachers/Admin: All tabs including Attendance (editable)
      return const [
        Tab(text: 'Modules'),
        Tab(text: 'Assignments'),
        Tab(text: 'Announcements'),
        Tab(text: 'Members'),
        Tab(text: 'Attendance'),
      ];
    }
  }

  /// Build tab views based on user role
  /// Updated: Students now see Attendance tab (read-only)
  List<Widget> _buildTabViews() {
    final commonTabs = [
      // Modules Tab
      SubjectModulesTab(
        subject: widget.subject,
        classroomId: widget.classroomId,
        userRole: widget.userRole,
        userId: widget.userId,
      ),

      // Assignments Tab
      SubjectAssignmentsTab(
        subject: widget.subject,
        classroomId: widget.classroomId,
        userRole: widget.userRole,
        userId: widget.userId,
      ),
    ];

    if (_isStudent) {
      // Students: Modules, Assignments, Attendance (read-only)
      return [
        ...commonTabs,
        // Attendance Tab (read-only for students)
        AttendanceTabWidget(
          subject: widget.subject,
          classroomId: widget.classroomId,
          userRole: widget.userRole,
          userId: widget.userId,
        ),
      ];
    } else {
      // Teachers/Admin: All tabs including Attendance (editable)
      return [
        ...commonTabs,
        // Announcements Tab
        AnnouncementTab(
          classroomId: widget.classroomId,
          courseId: widget.subject.id, // Use subject ID as course ID
          isTeacher: widget.userRole?.toLowerCase() != 'student',
          canManageAnnouncements: widget.userId == widget.subject.teacherId,
          canSoftDeleteReply: true,
          showDeletedPlaceholders: widget.userRole?.toLowerCase() != 'student',
        ),

        // Members Tab
        _buildMembersTab(),

        // Attendance Tab (editable for teachers/admin)
        AttendanceTabWidget(
          subject: widget.subject,
          classroomId: widget.classroomId,
          userRole: widget.userRole,
          userId: widget.userId,
        ),
      ];
    }
  }

  Widget _buildMembersTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View classroom members',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Show members dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Members dialog coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('View Members'),
            ),
          ],
        ),
      ),
    );
  }
}

