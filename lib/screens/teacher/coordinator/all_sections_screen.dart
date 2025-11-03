import 'package:flutter/material.dart';
import 'package:oro_site_high_school/screens/teacher/coordinator/section_details_screen.dart';

class AllSectionsScreen extends StatefulWidget {
  const AllSectionsScreen({super.key});

  @override
  State<AllSectionsScreen> createState() => _AllSectionsScreenState();
}

class _AllSectionsScreenState extends State<AllSectionsScreen> {
  String _searchQuery = '';

  // Mock sections data for Grade 7
  final List<Map<String, dynamic>> _sections = [
    {
      'id': 'sec-1',
      'name': '7-Amethyst',
      'adviser': 'Maria Santos',
      'students': 35,
      'avgGrade': 87.5,
      'attendance': 92,
      'room': 'Room 101',
    },
    {
      'id': 'sec-2',
      'name': '7-Bronze',
      'adviser': 'Pedro Garcia',
      'students': 35,
      'avgGrade': 85.2,
      'attendance': 90,
      'room': 'Room 102',
    },
    {
      'id': 'sec-3',
      'name': '7-Copper',
      'adviser': 'Ana Reyes',
      'students': 35,
      'avgGrade': 88.1,
      'attendance': 93,
      'room': 'Room 103',
    },
    {
      'id': 'sec-4',
      'name': '7-Diamond',
      'adviser': 'Jose Rizal',
      'students': 35,
      'avgGrade': 89.3,
      'attendance': 94,
      'room': 'Room 104',
    },
    {
      'id': 'sec-5',
      'name': '7-Emerald',
      'adviser': 'Gabriela Silang',
      'students': 35,
      'avgGrade': 86.7,
      'attendance': 91,
      'room': 'Room 105',
    },
    {
      'id': 'sec-6',
      'name': '7-Feldspar',
      'adviser': 'Andres Bonifacio',
      'students': 35,
      'avgGrade': 84.9,
      'attendance': 89,
      'room': 'Room 106',
    },
  ];

  List<Map<String, dynamic>> get _filteredSections {
    return _sections.where((section) {
      return section['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          section['adviser']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Grade 7 Sections'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatistics(),
          Expanded(child: _buildSectionsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search sections or advisers...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatistics() {
    final totalStudents = _sections.fold(0, (sum, s) => sum + (s['students'] as int));
    final avgGrade = _sections.fold(0.0, (sum, s) => sum + (s['avgGrade'] as double)) /
        _sections.length;
    final avgAttendance =
        _sections.fold(0, (sum, s) => sum + (s['attendance'] as int)) /
            _sections.length;

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Sections',
              _sections.length.toString(),
              Icons.class_,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Students',
              totalStudents.toString(),
              Icons.people,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Grade',
              avgGrade.toStringAsFixed(1),
              Icons.grade,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Attendance',
              '${avgAttendance.toStringAsFixed(0)}%',
              Icons.fact_check,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsList() {
    if (_filteredSections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No sections found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _filteredSections.length,
      itemBuilder: (context, index) {
        return _buildSectionCard(_filteredSections[index]);
      },
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SectionDetailsScreen(section: section),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.class_, color: Colors.blue, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      section['room'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                section['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      section['adviser'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric(
                    Icons.people,
                    '${section['students']}',
                    Colors.blue,
                  ),
                  _buildMetric(
                    Icons.grade,
                    '${section['avgGrade']}',
                    Colors.orange,
                  ),
                  _buildMetric(
                    Icons.fact_check,
                    '${section['attendance']}%',
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
