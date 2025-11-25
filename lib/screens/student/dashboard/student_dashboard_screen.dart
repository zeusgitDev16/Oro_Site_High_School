import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_dashboard_logic.dart';
import 'package:oro_site_high_school/screens/student/views/student_home_view.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_assignments_screen.dart';
import 'package:oro_site_high_school/screens/student/grades/student_grades_screen.dart';
import 'package:oro_site_high_school/screens/student/attendance/student_attendance_screen.dart';
import 'package:oro_site_high_school/screens/student/messaging/student_messages_screen.dart';
import 'package:oro_site_high_school/screens/student/messaging/student_notifications_screen.dart';
import 'package:oro_site_high_school/screens/student/announcements/student_announcements_screen.dart';
import 'package:oro_site_high_school/screens/student/profile/student_profile_screen.dart';
import 'package:oro_site_high_school/screens/student/widgets/student_calendar_widget.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/logout_dialog.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/calendar_dialog.dart';
import 'package:oro_site_high_school/screens/student/help/student_help_screen.dart';
import 'package:oro_site_high_school/screens/student/classroom/student_classroom_screen.dart';

/// Student Dashboard Screen - Main entry point for student users
/// UI only - interactive logic in StudentDashboardLogic
/// Follows the same two-tier sidebar pattern as admin/teacher
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with TickerProviderStateMixin {
  late StudentDashboardLogic _logic;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _logic = StudentDashboardLogic();
    _tabController = TabController(length: 1, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _logic.setTabIndex(_tabController.index);
      }
    });

    // Load student profile immediately when dashboard is created
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _logic.loadStudentProfile();
    });
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
      body: Row(
        children: [
          _buildLeftNavigationRail(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(flex: 7, child: _buildCenterContent()),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(flex: 3, child: _buildRightSidebar()),
        ],
      ),
    );
  }

  Widget _buildLeftNavigationRail() {
    return Container(
      width: 200,
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/OroSiteLogo3.png', height: 30),
                const SizedBox(width: 8),
                const Text(
                  'OSHS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: _logic,
              builder: (context, _) {
                return ListView(
                  children: [
                    _buildNavItem(Icons.home, 'Home', 0),
                    _buildNavItem(Icons.class_outlined, 'My Classroom', 1),
                    _buildNavItem(Icons.assignment, 'Assignments', 2),
                    _buildNavItem(Icons.grade, 'Grades', 3),
                    _buildNavItem(Icons.fact_check, 'Attendance', 4),
                    // Removed: My Courses (accessible via My Classroom)
                    // Removed: Messages (accessible via top right icon)
                    // Removed: Announcements (accessible via notifications icon)
                    // Removed: Calendar (accessible via right sidebar)
                  ],
                );
              },
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          ListenableBuilder(
            listenable: _logic,
            builder: (context, _) {
              return Column(
                children: [
                  _buildNavItem(Icons.person, 'Profile', 7),
                  _buildNavItem(Icons.help_outline, 'Help', 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _logic.sideNavIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.grey.shade400,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey.shade400,
          ),
        ),
        onTap: () {
          _logic.setSideNavIndex(index);
          if (index == 0) {
            _tabController.animateTo(0);
          } else if (index == 1) {
            // My Classroom
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentClassroomScreen(),
              ),
            );
          } else if (index == 2) {
            // Assignments
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentAssignmentsScreen(),
              ),
            );
          } else if (index == 3) {
            // Grades
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentGradesScreen(),
              ),
            );
          } else if (index == 4) {
            // Attendance
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentAttendanceScreen(),
              ),
            );
          } else if (index == 5) {
            // Messages
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentMessagesScreen(),
              ),
            );
          } else if (index == 6) {
            // Announcements
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentAnnouncementsScreen(),
              ),
            );
          } else if (index == 7) {
            // Profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentProfileScreen(),
              ),
            );
          } else if (index == 8) {
            // Help
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHelpScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming in Phase 2+'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCenterContent() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [Tab(text: 'Dashboard')],
                ),
              ),
              Container(
                width: 300,
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [StudentHomeView(logic: _logic)],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ListenableBuilder(
                listenable: _logic,
                builder: (context, _) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StudentNotificationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_none),
                        tooltip: 'Notifications',
                      ),
                      if (_logic.notificationUnreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${_logic.notificationUnreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              ListenableBuilder(
                listenable: _logic,
                builder: (context, _) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StudentMessagesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.mail_outline),
                        tooltip: 'Messages',
                      ),
                      if (_logic.messageUnreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${_logic.messageUnreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              ListenableBuilder(
                listenable: _logic,
                builder: (context, _) {
                  final studentData = _logic.studentData;
                  final firstName = studentData['firstName']?.toString() ?? '';
                  final lastName = studentData['lastName']?.toString() ?? '';
                  final displayName = firstName.isEmpty && lastName.isEmpty
                      ? 'Student'
                      : '$firstName $lastName'.trim();
                  return Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildProfileAvatarWithDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildMiniCalendarCard(),
                const SizedBox(height: 16),
                _buildQuickActionsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarCard() {
    return const StudentCalendarWidget();
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildQuickActionButton(
              'View Courses',
              Icons.school,
              Colors.blue,
              () => _showComingSoonSnackbar('My Courses'),
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              'Submit Assignment',
              Icons.assignment_turned_in,
              Colors.green,
              () => _showComingSoonSnackbar('Assignments'),
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              'Check Grades',
              Icons.grade,
              Colors.purple,
              () => _showComingSoonSnackbar('Grades'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProfileAvatarWithDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              // Navigate to profile when avatar is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentProfileScreen(),
                ),
              );
            },
            child: ListenableBuilder(
              listenable: _logic,
              builder: (context, _) {
                final studentData = _logic.studentData;
                final initials = () {
                  final firstName = studentData['firstName']?.toString() ?? '';
                  final lastName = studentData['lastName']?.toString() ?? '';
                  if (firstName.isEmpty && lastName.isEmpty) {
                    return 'S'; // Default to 'S' for Student
                  }
                  final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
                  final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
                  return '$firstInitial$lastInitial'.toUpperCase();
                }();

                return CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green,
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Colors.grey.shade700,
            ),
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
            itemBuilder: (BuildContext context) => [
              // Only show Logout option
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              if (value == 'logout') {
                showLogoutDialog(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
