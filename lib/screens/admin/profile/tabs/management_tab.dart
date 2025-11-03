import 'package:flutter/material.dart';

class ManagementTab extends StatelessWidget {
  const ManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildManagedCoursesCard(),
          const SizedBox(height: 16),
          _buildManagedSectionsCard(),
          const SizedBox(height: 16),
          _buildManagedUsersCard(),
        ],
      ),
    );
  }

  Widget _buildManagedCoursesCard() {
    final courses = [
      {
        'name': 'Mathematics 7',
        'code': 'MATH-7-2024',
        'students': 35,
        'status': 'Active',
      },
      {
        'name': 'Science 8',
        'code': 'SCI-8-2024',
        'students': 38,
        'status': 'Active',
      },
      {
        'name': 'English 9',
        'code': 'ENG-9-2024',
        'students': 32,
        'status': 'Active',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Managed Courses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${courses.length} Courses',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...courses.map((course) => _buildCourseItem(course)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.book, color: Colors.blue.shade700),
        ),
        title: Text(
          course['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Code: ${course['code']} • ${course['students']} students'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            course['status'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManagedSectionsCard() {
    final sections = [
      {
        'name': 'Grade 7 - Diamond',
        'students': 35,
        'adviser': 'Ms. Maria Santos',
        'room': 'Room 101',
      },
      {
        'name': 'Grade 8 - Sapphire',
        'students': 38,
        'adviser': 'Mr. Juan Dela Cruz',
        'room': 'Room 201',
      },
      {
        'name': 'Grade 9 - Emerald',
        'students': 32,
        'adviser': 'Mrs. Ana Reyes',
        'room': 'Room 301',
      },
      {
        'name': 'Grade 10 - Jade',
        'students': 30,
        'adviser': 'Mr. Pedro Garcia',
        'room': 'Room 401',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.class_, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Managed Sections',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sections.length} Sections',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sections.map((section) => _buildSectionItem(section)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem(Map<String, dynamic> section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.groups, color: Colors.green.shade700),
        ),
        title: Text(
          section['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${section['students']} students • ${section['room']}'),
            Text('Adviser: ${section['adviser']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildManagedUsersCard() {
    final userStats = [
      {'role': 'Teachers', 'count': 45, 'icon': Icons.person, 'color': Colors.blue},
      {'role': 'Students', 'count': 850, 'icon': Icons.school, 'color': Colors.green},
      {'role': 'Parents', 'count': 720, 'icon': Icons.family_restroom, 'color': Colors.orange},
      {'role': 'Staff', 'count': 12, 'icon': Icons.work, 'color': Colors.purple},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Managed Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildUserStatCard(
                    userStats[0]['role'] as String,
                    userStats[0]['count'] as int,
                    userStats[0]['icon'] as IconData,
                    userStats[0]['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUserStatCard(
                    userStats[1]['role'] as String,
                    userStats[1]['count'] as int,
                    userStats[1]['icon'] as IconData,
                    userStats[1]['color'] as Color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildUserStatCard(
                    userStats[2]['role'] as String,
                    userStats[2]['count'] as int,
                    userStats[2]['icon'] as IconData,
                    userStats[2]['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUserStatCard(
                    userStats[3]['role'] as String,
                    userStats[3]['count'] as int,
                    userStats[3]['icon'] as IconData,
                    userStats[3]['color'] as Color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatCard(String role, int count, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
