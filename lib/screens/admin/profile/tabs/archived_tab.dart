import 'package:flutter/material.dart';

class ArchivedTab extends StatelessWidget {
  const ArchivedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Archived',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildArchivedCoursesCard(),
          const SizedBox(height: 16),
          _buildArchivedAssignmentsCard(),
          const SizedBox(height: 16),
          _buildArchivedDataCard(),
        ],
      ),
    );
  }

  Widget _buildArchivedCoursesCard() {
    final courses = [
      {
        'name': 'Mathematics 7 (S.Y. 2023-2024)',
        'code': 'MATH-7-2023',
        'students': 32,
        'archivedDate': 'June 15, 2023',
        'status': 'Completed',
      },
      {
        'name': 'Science 8 (S.Y. 2022-2023)',
        'code': 'SCI-8-2022',
        'students': 35,
        'archivedDate': 'June 10, 2022',
        'status': 'Completed',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.archive, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Archived Courses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...courses.map((course) => _buildArchivedCourseItem(course)),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedCourseItem(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade50,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.book, color: Colors.grey.shade700),
        ),
        title: Text(
          course['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Code: ${course['code']} • ${course['students']} students'),
            Text('Archived: ${course['archivedDate']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () {},
              tooltip: 'View',
            ),
            IconButton(
              icon: const Icon(Icons.unarchive, size: 20),
              onPressed: () {},
              tooltip: 'Restore',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedAssignmentsCard() {
    final assignments = [
      {
        'title': 'Final Exam - Mathematics 7',
        'course': 'Mathematics 7',
        'dueDate': 'May 20, 2023',
        'submissions': 32,
        'archivedDate': 'June 15, 2023',
      },
      {
        'title': 'Science Project - Ecosystem',
        'course': 'Science 8',
        'dueDate': 'April 15, 2023',
        'submissions': 35,
        'archivedDate': 'June 10, 2023',
      },
      {
        'title': 'Essay: My Future Career',
        'course': 'English 9',
        'dueDate': 'March 30, 2023',
        'submissions': 30,
        'archivedDate': 'June 8, 2023',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Archived Assignments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...assignments.map((assignment) => _buildArchivedAssignmentItem(assignment)),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedAssignmentItem(Map<String, dynamic> assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade50,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.assignment_turned_in, color: Colors.grey.shade700),
        ),
        title: Text(
          assignment['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${assignment['course']} • Due: ${assignment['dueDate']}'),
            Text('${assignment['submissions']} submissions • Archived: ${assignment['archivedDate']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () {},
              tooltip: 'View',
            ),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () {},
              tooltip: 'Download',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Archived Data Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDataStatCard('Courses', '5', Icons.school, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDataStatCard('Assignments', '45', Icons.assignment, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDataStatCard('Resources', '120', Icons.library_books, Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDataStatCard('Reports', '28', Icons.insert_chart, Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Archived data is stored securely and can be restored at any time. Data older than 5 years may be permanently deleted.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
