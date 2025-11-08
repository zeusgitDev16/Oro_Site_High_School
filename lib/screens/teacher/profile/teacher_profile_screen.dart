import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/teacher/profile/edit_profile_screen.dart';
import 'package:oro_site_high_school/screens/teacher/profile/settings_screen.dart';
import 'package:oro_site_high_school/screens/teacher/messaging/notifications_screen.dart';
import 'package:oro_site_high_school/screens/teacher/messaging/messages_screen.dart';
import 'package:oro_site_high_school/screens/teacher/courses/my_courses_screen.dart';
import 'package:oro_site_high_school/screens/teacher/students/my_students_screen.dart';
import 'package:oro_site_high_school/screens/teacher/grades/grade_entry_screen.dart';
import 'package:oro_site_high_school/screens/teacher/attendance/teacher_attendance_screen.dart';
import 'package:oro_site_high_school/screens/teacher/assignments/my_assignments_screen.dart';
import 'package:oro_site_high_school/screens/teacher/resources/my_resources_screen.dart';
import 'package:oro_site_high_school/screens/teacher/reports/reports_main_screen.dart';
import 'package:oro_site_high_school/screens/teacher/help/teacher_help_screen.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/calendar_dialog.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _sidebarSelectedIndex = 0; // 0=Profile, 1=Settings, 2=Security

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          _buildMainIconSidebar(),
          _buildProfileSidebar(),
          Expanded(child: _buildMainContent()),
          _buildRightSidebar(),
        ],
      ),
    );
  }

  Widget _buildMainIconSidebar() {
    return Container(
      width: 64,
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/OroSiteLogo3.png', height: 28),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildIconNavItem(Icons.home, 0),
                _buildIconNavItem(Icons.school, 1),
                _buildIconNavItem(Icons.people, 2),
                _buildIconNavItem(Icons.grade, 3),
                _buildIconNavItem(Icons.fact_check, 4),
                _buildIconNavItem(Icons.assignment, 5),
                _buildIconNavItem(Icons.library_books, 6),
                _buildIconNavItem(Icons.mail, 7),
                _buildIconNavItem(Icons.insert_chart, 8),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildIconNavItem(Icons.person, 9),
          _buildIconNavItem(Icons.help_outline, 10),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIconNavItem(IconData icon, int index) {
    final isSelected = index == 9; // Profile is selected

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade400,
          size: 20,
        ),
        onPressed: () {
          if (index == 0) {
            // Home - navigate back to dashboard
            Navigator.pop(context);
          } else if (index == 1) {
            // My Courses - pass 'profile' as origin
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyCoursesScreen(origin: 'profile'),
              ),
            );
          } else if (index == 2) {
            // My Students - TODO: add origin parameter
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyStudentsScreen()),
            );
          } else if (index == 3) {
            // Grades - TODO: add origin parameter
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GradeEntryScreen()),
            );
          } else if (index == 4) {
            // Attendance - TODO: add origin parameter
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherAttendanceScreen(),
              ),
            );
          } else if (index == 5) {
            // Assignments - TODO: add origin parameter
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyAssignmentsScreen(),
              ),
            );
          } else if (index == 6) {
            // Resources - TODO: add origin parameter
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyResourcesScreen(),
              ),
            );
          } else if (index == 7) {
            // Messages - TODO: add origin parameter
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagesScreen()),
            );
          } else if (index == 8) {
            // Reports - TODO: add origin parameter
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsMainScreen(),
              ),
            );
          } else if (index == 10) {
            // Help
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherHelpScreen(),
              ),
            );
          }
          // index == 9 is Profile (current page), do nothing
        },
      ),
    );
  }

  Widget _buildProfileSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildSidebarItem(Icons.person_outline, 'Profile', 0),
          _buildSidebarItem(Icons.settings_outlined, 'Settings', 1),
          _buildSidebarItem(Icons.lock_outline, 'Security', 2),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int index) {
    final isSelected = _sidebarSelectedIndex == index;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade600,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _sidebarSelectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMainContent() {
    // Show different content based on sidebar selection
    if (_sidebarSelectedIndex == 1) {
      return const SettingsScreen();
    } else if (_sidebarSelectedIndex == 2) {
      return _buildSecurityTab();
    }

    // Default: Show Profile tab (index 0)
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Column(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 16),
                    _buildSocialLinks(),
                    const SizedBox(height: 24),
                    _buildTabBar(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, size: 20, color: Colors.grey),
                  ),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                tooltip: 'Notifications',
              ),
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
                  child: const Text(
                    '5',
                    style: TextStyle(
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
                icon: const Icon(Icons.mail_outline, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MessagesScreen(),
                    ),
                  );
                },
                tooltip: 'Messages',
              ),
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
                  child: const Text(
                    '3',
                    style: TextStyle(
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
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CalendarDialog(),
              );
            },
            tooltip: 'Calendar',
          ),
          const SizedBox(width: 8),
          _buildProfileAvatarWithDropdown(),
          const SizedBox(width: 8),
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
          const CircleAvatar(
            radius: 16,
            child: Text('MS', style: TextStyle(fontSize: 12)),
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
                // Import logout dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back to login
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=1200',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: 40,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const CircleAvatar(
              radius: 60,
              child: Text('MS', style: TextStyle(fontSize: 32)),
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Maria Santos',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Teacher',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.link, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'https://orositehs.edu.ph/teacher/maria',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          const Text(
            'Mathematics & Science Department',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Info'),
          Tab(text: 'Teaching'),
          Tab(text: 'Statistics'),
          Tab(text: 'Schedule'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // About Tab
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'I am a dedicated educator at Oro Site High School, specializing in Mathematics and Science for Grade 7 students. With 4 years of teaching experience, I am passionate about making complex concepts accessible and engaging for young learners.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        // Info Tab
        _buildInfoTab(),
        // Teaching Tab
        _buildTeachingTab(),
        // Statistics Tab
        _buildStatisticsTab(),
        // Schedule Tab
        _buildScheduleTab(),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Employee ID', 'T-2024-001'),
          _buildInfoRow('Email', 'maria.santos@oshs.edu.ph'),
          _buildInfoRow('Phone', '+63 912 345 6789'),
          _buildInfoRow('Department', 'Mathematics & Science'),
          _buildInfoRow('Position', 'Senior Teacher'),
          _buildInfoRow('Employment Date', 'August 15, 2020'),
        ],
      ),
    );
  }

  Widget _buildTeachingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teaching Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Grade Level', 'Grade 7'),
          _buildInfoRow('Subjects', 'Mathematics 7, Science 7'),
          _buildInfoRow('Total Students', '35'),
          _buildInfoRow('Advisory Class', '7-A'),
          _buildInfoRow('Schedule', 'Monday - Friday, 8:00 AM - 5:00 PM'),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teaching Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Courses',
                  '2',
                  Icons.school,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Students',
                  '35',
                  Icons.people,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Assignments',
                  '8',
                  Icons.assignment,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Resources',
                  '5',
                  Icons.library_books,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildScheduleCard('Monday', 'Mathematics 7 (8:00 AM - 10:00 AM)'),
          _buildScheduleCard('Monday', 'Science 7 (10:30 AM - 12:30 PM)'),
          _buildScheduleCard('Tuesday', 'Mathematics 7 (8:00 AM - 10:00 AM)'),
          _buildScheduleCard('Tuesday', 'Science 7 (10:30 AM - 12:30 PM)'),
          _buildScheduleCard('Wednesday', 'Mathematics 7 (8:00 AM - 10:00 AM)'),
          _buildScheduleCard('Wednesday', 'Science 7 (10:30 AM - 12:30 PM)'),
          _buildScheduleCard('Thursday', 'Mathematics 7 (8:00 AM - 10:00 AM)'),
          _buildScheduleCard('Thursday', 'Science 7 (10:30 AM - 12:30 PM)'),
          _buildScheduleCard('Friday', 'Mathematics 7 (8:00 AM - 10:00 AM)'),
          _buildScheduleCard('Friday', 'Science 7 (10:30 AM - 12:30 PM)'),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(String day, String schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.schedule, color: Colors.blue),
        ),
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(schedule),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your account password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Change Password - Coming Soon'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      width: 300,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(24),
      child: ListView(children: [_buildAccountCard()]),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRowSmall(Icons.calendar_today, 'Joined', 'Aug 15, 2020'),
            const SizedBox(height: 12),
            _buildInfoRowSmall(
              Icons.access_time,
              'Last activity',
              'less than a minute ago',
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login Credentials - Coming Soon'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.vpn_key, size: 16),
              label: const Text('Login credentials'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowSmall(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
