import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_profile_logic.dart';
import 'package:oro_site_high_school/screens/student/profile/edit_profile_screen.dart';
import 'package:oro_site_high_school/screens/student/profile/settings_screen.dart';
import 'package:oro_site_high_school/screens/student/messaging/student_messages_screen.dart';
import 'package:oro_site_high_school/screens/student/messaging/student_notifications_screen.dart';
import 'package:oro_site_high_school/screens/student/courses/student_courses_screen.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_assignments_screen.dart';
import 'package:oro_site_high_school/screens/student/grades/student_grades_screen.dart';
import 'package:oro_site_high_school/screens/student/attendance/student_attendance_screen.dart';
import 'package:oro_site_high_school/screens/student/announcements/student_announcements_screen.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/calendar_dialog.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/logout_dialog.dart';
import 'package:oro_site_high_school/screens/student/help/student_help_screen.dart';

/// Student Profile Screen - Main profile view for student users
/// UI only - interactive logic in StudentProfileLogic
/// Follows the same two-tier sidebar pattern as teacher/admin
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StudentProfileLogic _logic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _logic = StudentProfileLogic();

    // Load real student data (including LRN) from backend after first frame.
    // This keeps the existing UI design and simply swaps in live data when
    // available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logic.loadFromBackend();
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
                _buildIconNavItem(Icons.assignment, 2),
                _buildIconNavItem(Icons.grade, 3),
                _buildIconNavItem(Icons.fact_check, 4),
                _buildIconNavItem(Icons.mail, 5),
                _buildIconNavItem(Icons.campaign, 6),
                _buildIconNavItem(Icons.calendar_today, 7),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildIconNavItem(Icons.person, 8),
          _buildIconNavItem(Icons.help_outline, 9),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIconNavItem(IconData icon, int index) {
    final isSelected = index == 8; // Profile is selected

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
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
            // My Courses
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentCoursesScreen(),
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
            // Calendar
            showDialog(
              context: context,
              builder: (_) => const CalendarDialog(),
            );
          } else if (index == 9) {
            // Help
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHelpScreen(),
              ),
            );
          }
          // index == 8 is Profile (current page), do nothing
        },
      ),
    );
  }

  Widget _buildProfileSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildSidebarItem(Icons.person_outline, 'Profile', 0),
              _buildSidebarItem(Icons.settings_outlined, 'Settings', 1),
              _buildSidebarItem(Icons.lock_outline, 'Security', 2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int index) {
    final isSelected = _logic.sidebarSelectedIndex == index;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade600,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        onTap: () {
          _logic.setSidebarIndex(index);
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return ListenableBuilder(
      listenable: _logic,
      builder: (context, _) {
        // Show different content based on sidebar selection
        if (_logic.sidebarSelectedIndex == 1) {
          return StudentSettingsScreen(logic: _logic);
        } else if (_logic.sidebarSelectedIndex == 2) {
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
                        _buildStudentInfo(),
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
      },
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
                      builder: (context) => const StudentNotificationsScreen(),
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentMessagesScreen(),
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
                    '2',
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
                builder: (_) => const CalendarDialog(userRole: 'student'),
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
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green,
            child: Text(
              _logic.getInitials(),
              style: const TextStyle(fontSize: 12, color: Colors.white),
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

  Widget _buildHeroBanner() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1200',
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
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.green,
              child: Text(
                _logic.getInitials(),
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
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
                  Text(
                    _logic.getFullName(),
                    style: const TextStyle(
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
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Student',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _logic.getGradeAndSection(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Text(
            'LRN: ${_logic.studentData['lrn']}',
            style: TextStyle(
              color: Colors.green.shade700,
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
                  builder: (context) => EditProfileScreen(logic: _logic),
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
          Tab(text: 'Academic'),
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
        _buildAboutTab(),
        _buildInfoTab(),
        _buildAcademicTab(),
        _buildStatisticsTab(),
        _buildScheduleTab(),
      ],
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            _logic.studentData['bio'],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Interests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_logic.studentData['interests'] as List<String>)
                .map(
                  (interest) => Chip(
                    label: Text(interest),
                    backgroundColor: Colors.green.shade50,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Achievements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...(_logic.studentData['achievements'] as List<String>)
              .map(
                (achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(achievement),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
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
          _buildInfoRow('Student ID', _logic.studentData['studentId']),
          _buildInfoRow('LRN', _logic.studentData['lrn']),
          _buildInfoRow('Email', _logic.studentData['email']),
          _buildInfoRow('Phone', _logic.studentData['phone']),
          _buildInfoRow('Birth Date', _logic.studentData['birthDate']),
          _buildInfoRow('Age', '${_logic.studentData['age']} years old'),
          _buildInfoRow('Address', _logic.studentData['address']),
          const SizedBox(height: 24),
          const Text(
            'Guardian Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Guardian Name', _logic.studentData['guardian']),
          _buildInfoRow('Relation', _logic.studentData['guardianRelation']),
          _buildInfoRow('Guardian Phone', _logic.studentData['guardianPhone']),
          _buildInfoRow('Guardian Email', _logic.studentData['guardianEmail']),
        ],
      ),
    );
  }

  Widget _buildAcademicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Grade Level', _logic.studentData['gradeLevel']),
          _buildInfoRow('Section', _logic.studentData['section']),
          _buildInfoRow('Adviser', _logic.studentData['adviser']),
          _buildInfoRow(
            'Enrollment Date',
            _logic.studentData['enrollmentDate'],
          ),
          const SizedBox(height: 24),
          const Text(
            'Enrolled Courses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._logic.enrolledCourses.map(
            (course) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, color: Colors.green),
                ),
                title: Text(
                  course['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Teacher: ${course['teacher']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${course['grade']}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
            'Academic Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'GPA',
                  '${_logic.academicStats['gpa']}',
                  Icons.grade,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Attendance',
                  '${_logic.academicStats['attendanceRate']}%',
                  Icons.fact_check,
                  Colors.blue,
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
                  '${_logic.academicStats['assignmentsCompleted']}/${_logic.academicStats['totalAssignments']}',
                  Icons.assignment,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Courses',
                  '${_logic.academicStats['coursesEnrolled']}',
                  Icons.school,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Class Rank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_logic.academicStats['rank']} of ${_logic.academicStats['totalStudents']}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          ..._logic.weeklySchedule.map((daySchedule) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    daySchedule['day'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ...(daySchedule['schedule'] as List<Map<String, dynamic>>).map(
                  (schedule) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule, color: Colors.green),
                      ),
                      title: Text(
                        schedule['subject'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${schedule['time']} • ${schedule['room']}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
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
                fontSize: 28,
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
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parent access code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate a code you can share with your parent/guardian to link to your account.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _logic.parentAccessCode ?? 'No code generated yet',
                          style: const TextStyle(
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await _logic.generateParentAccessCode();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Parent access code generated'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Failed to generate parent access code',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Generate / Regenerate',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
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
                Icon(Icons.person, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRowSmall(
              Icons.calendar_today,
              'Enrolled',
              _logic.studentData['enrollmentDate'],
            ),
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
                    backgroundColor: Colors.green,
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
        Text(
          '$label:',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
