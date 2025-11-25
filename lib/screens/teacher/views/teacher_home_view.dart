import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/teacher/teacher_dashboard_logic.dart';
import 'package:oro_site_high_school/screens/teacher/widgets/teacher_course_card.dart';

class TeacherHomeView extends StatefulWidget {
  final TeacherDashboardLogic? logic;
  const TeacherHomeView({super.key, this.logic});

  @override
  State<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  @override
  Widget build(BuildContext context) {
    if (widget.logic == null) {
      return const Center(child: Text('Error: Logic not provided'));
    }

    return ListenableBuilder(
      listenable: widget.logic!,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildQuickStatsCards(),
              const SizedBox(height: 32),
              _buildMyCoursesSection(),
              const SizedBox(height: 32),
              _buildRecentActivitySection(),
              const SizedBox(height: 32),
              _buildUpcomingDeadlinesSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    final teacherData = widget.logic!.teacherData;
    final firstName = teacherData['firstName']?.toString() ?? 'Teacher';
    final role = teacherData['role']?.toString() ?? 'Teacher';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $firstName!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You have ${widget.logic!.dashboardData['pendingAssignments']} pending assignments to grade.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.school, size: 80, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    final data = widget.logic!.dashboardData;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'My Courses',
            '${data['activeCourses']}',
            Icons.school,
            Colors.blue,
            'Active courses',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'My Students',
            '${data['totalStudents']}',
            Icons.people,
            Colors.green,
            'Total students',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Assignments',
            '${data['pendingAssignments']}',
            Icons.assignment,
            Colors.orange,
            'Pending grading',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Attendance',
            '${data['attendanceRate']}',
            Icons.fact_check,
            Colors.purple,
            'Average rate',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCoursesSection() {
    // TODO: Use real courses from logic
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'My Courses',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.logic!.dashboardData['myCourses'].isEmpty)
          const Text('No active courses found.')
        else
          Column(
            children: (widget.logic!.dashboardData['myCourses'] as List).map((
              course,
            ) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TeacherCourseCard(
                  courseName: course['courseName'],
                  courseCode: course['courseCode'],
                  section: course['section'],
                  students: course['students'],
                  schedule: course['schedule'],
                  color: course['color'],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    final activities =
        widget.logic!.dashboardData['recentActivity'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent activity'),
                )
              else
                ...activities
                    .map(
                      (activity) => _buildActivityItem(
                        activity['title'],
                        activity['course'],
                        activity['time'],
                        Icons.info, // Default icon
                        Colors.blue, // Default color
                      ),
                    )
                    .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String course,
    String time,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(course, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        time,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildUpcomingDeadlinesSection() {
    final deadlines =
        widget.logic!.dashboardData['upcomingDeadlines'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Deadlines',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (deadlines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No upcoming deadlines'),
                )
              else
                ...deadlines
                    .map(
                      (deadline) => _buildDeadlineItem(
                        deadline['title'],
                        deadline['date'],
                        Colors.red, // Default color
                        deadline['status'],
                      ),
                    )
                    .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineItem(
    String title,
    String date,
    Color color,
    String status,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.event, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(date, style: const TextStyle(fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
