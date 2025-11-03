import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/teacher/views/teacher_home_view.dart';
import 'package:oro_site_high_school/screens/teacher/views/teacher_analytics_view.dart';
import 'package:oro_site_high_school/screens/teacher/views/teacher_calendar_view.dart';
import 'package:oro_site_high_school/screens/teacher/widgets/teacher_calendar_widget.dart';
import 'package:oro_site_high_school/screens/teacher/courses/my_courses_screen.dart';
import 'package:oro_site_high_school/screens/teacher/classroom/my_classroom_screen.dart';
import 'package:oro_site_high_school/screens/teacher/grades/grade_entry_screen.dart';
import 'package:oro_site_high_school/screens/teacher/attendance/attendance_main_screen.dart';
import 'package:oro_site_high_school/screens/teacher/assignments/my_assignments_screen.dart';
import 'package:oro_site_high_school/screens/teacher/messaging/messages_screen.dart';
import 'package:oro_site_high_school/screens/teacher/messaging/notifications_screen.dart';
import 'package:oro_site_high_school/screens/teacher/reports/reports_main_screen.dart';
import 'package:oro_site_high_school/screens/teacher/profile/teacher_profile_screen.dart';
import 'package:oro_site_high_school/screens/teacher/coordinator/coordinator_dashboard_screen.dart';
import 'package:oro_site_high_school/screens/teacher/help/teacher_help_screen.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/logout_dialog.dart';
import 'package:oro_site_high_school/screens/teacher/requests/my_requests_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with TickerProviderStateMixin {
  int _sideNavIndex = 0;
  late TabController _tabController;
  int _notificationUnreadCount = 5;
  int _messageUnreadCount = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            child: ListView(
              children: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.school, 'My Courses', 1),
                _buildNavItem(Icons.class_, 'My Classroom', 2),
                _buildNavItem(Icons.grade, 'Grades', 3),
                _buildNavItem(Icons.fact_check, 'Attendance', 4),
                _buildNavItem(Icons.assignment, 'Assignments', 5),
                _buildNavItem(Icons.inbox, 'My Requests', 6),
                _buildNavItem(Icons.insert_chart, 'Reports', 7),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildNavItem(Icons.person, 'Profile', 8),
          _buildNavItem(Icons.help_outline, 'Help', 9),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _sideNavIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
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
          setState(() {
            _sideNavIndex = index;
            if (index == 0) {
              _tabController.animateTo(0);
            }
          });
          
          // Handle navigation
          if (index == 1) {
            // My Courses
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyCoursesScreen(),
              ),
            );
          } else if (index == 2) {
            // My Classroom
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyClassroomScreen(),
              ),
            );
          } else if (index == 3) {
            // Grades
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GradeEntryScreen(),
              ),
            );
          } else if (index == 4) {
            // Attendance
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AttendanceMainScreen(),
              ),
            );
          } else if (index == 5) {
            // Assignments
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyAssignmentsScreen(),
              ),
            );
          } else if (index == 6) {
            // My Requests
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyRequestsScreen(),
              ),
            );
          } else if (index == 7) {
            // Reports
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsMainScreen(),
              ),
            );
          } else if (index == 8) {
            // Profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherProfileScreen(),
              ),
            );
          } else if (index == 9) {
            // Help
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherHelpScreen(),
              ),
            );
          }
        },
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
                  tabs: const [
                    Tab(text: 'Dashboard'),
                    Tab(text: 'Analytics'),
                    Tab(text: 'Schedule'),
                  ],
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
        children: const [
          TeacherHomeView(),
          TeacherAnalyticsView(),
          TeacherCalendarView(),
        ],
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
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_none),
                    tooltip: 'Notifications',
                  ),
                  if (_notificationUnreadCount > 0)
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
                          '$_notificationUnreadCount',
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
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessagesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mail_outline),
                    tooltip: 'Messages',
                  ),
                  if (_messageUnreadCount > 0)
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
                          '$_messageUnreadCount',
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
              ),
              const SizedBox(width: 16),
              const Text(
                'Maria Santos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _buildProfileAvatarWithDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                const TeacherCalendarWidget(),
                const SizedBox(height: 16),
                _buildQuickStatsCard(),
                const SizedBox(height: 16),
                _buildToDoCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
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
                Icon(Icons.analytics, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatRow('Courses', '2', Icons.school, Colors.blue),
            const SizedBox(height: 8),
            _buildStatRow('Students', '35', Icons.people, Colors.green),
            const SizedBox(height: 8),
            _buildStatRow('Assignments', '8', Icons.assignment, Colors.orange),
            const SizedBox(height: 8),
            _buildStatRow('Pending Grades', '12', Icons.grade, Colors.red),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CoordinatorDashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings, size: 16),
                label: const Text('Coordinator Mode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildToDoCard() {
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
                Icon(Icons.check_circle_outline, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                const Text(
                  'To-Do',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildToDoItem('Grade Math 7 Quiz 3'),
            _buildToDoItem('Upload Science 7 Module 4'),
            _buildToDoItem('Create attendance session'),
          ],
        ),
      ),
    );
  }

  Widget _buildToDoItem(String task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.circle_outlined, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(task, style: const TextStyle(fontSize: 13))),
        ],
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
          // Main avatar - click to go to profile
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherProfileScreen(),
              ),
            ),
            child: const CircleAvatar(
              radius: 16,
              child: Text('MS', style: TextStyle(fontSize: 12)),
            ),
          ),
          // Dropdown button beside avatar
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
