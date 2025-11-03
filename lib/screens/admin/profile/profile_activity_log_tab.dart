import 'package:flutter/material.dart';

class ProfileActivityLogTab extends StatefulWidget {
  const ProfileActivityLogTab({super.key});

  @override
  State<ProfileActivityLogTab> createState() => _ProfileActivityLogTabState();
}

class _ProfileActivityLogTabState extends State<ProfileActivityLogTab> {
  String? _selectedActivityType;
  String? _selectedDateRange;
  String _searchQuery = '';

  // Mock activity data
  final List<Map<String, dynamic>> _allActivities = [
    {
      'id': 1,
      'type': 'Login',
      'action': 'Logged in to the system',
      'timestamp': '2024-02-15 10:30:25',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
    {
      'id': 2,
      'type': 'User Management',
      'action': 'Created new user: Juan Dela Cruz',
      'timestamp': '2024-02-15 10:15:10',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
    {
      'id': 3,
      'type': 'Grade Management',
      'action': 'Updated grades for Mathematics 7 - Q3',
      'timestamp': '2024-02-15 09:45:30',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
    {
      'id': 4,
      'type': 'Settings',
      'action': 'Changed system settings: School Year to 2024-2025',
      'timestamp': '2024-02-15 09:30:15',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
    {
      'id': 5,
      'type': 'Course Management',
      'action': 'Created new course: Science 8',
      'timestamp': '2024-02-15 09:00:45',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
    {
      'id': 6,
      'type': 'Assignment',
      'action': 'Created assignment: Algebra Problem Set 1',
      'timestamp': '2024-02-14 16:20:00',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
    {
      'id': 7,
      'type': 'Resource',
      'action': 'Uploaded resource: Physics Lab Manual.pdf',
      'timestamp': '2024-02-14 15:45:30',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
    {
      'id': 8,
      'type': 'Login',
      'action': 'Failed login attempt',
      'timestamp': '2024-02-14 08:15:20',
      'ip': '203.177.xxx.xxx',
      'device': 'Unknown Device',
      'status': 'Failed',
    },
    {
      'id': 9,
      'type': 'Report',
      'action': 'Generated attendance report for January 2024',
      'timestamp': '2024-02-13 14:30:00',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
    {
      'id': 10,
      'type': 'Notification',
      'action': 'Sent notification to all Grade 7 students',
      'timestamp': '2024-02-13 11:00:00',
      'ip': '192.168.1.100',
      'device': 'Windows PC - Chrome',
      'status': 'Success',
    },
  ];

  List<Map<String, dynamic>> get _filteredActivities {
    var activities = List<Map<String, dynamic>>.from(_allActivities);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      activities = activities.where((activity) {
        final action = activity['action'].toString().toLowerCase();
        final type = activity['type'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return action.contains(query) || type.contains(query);
      }).toList();
    }

    // Apply activity type filter
    if (_selectedActivityType != null && _selectedActivityType != 'All Types') {
      activities = activities.where((a) => a['type'] == _selectedActivityType).toList();
    }

    return activities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportActivityLog,
            tooltip: 'Export Activity Log',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildStatisticsSection(),
          Expanded(child: _buildActivityList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search activities...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filters row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedActivityType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Type',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'Login', child: Text('Login')),
                    DropdownMenuItem(value: 'User Management', child: Text('User Management')),
                    DropdownMenuItem(value: 'Grade Management', child: Text('Grade Management')),
                    DropdownMenuItem(value: 'Course Management', child: Text('Course Management')),
                    DropdownMenuItem(value: 'Assignment', child: Text('Assignment')),
                    DropdownMenuItem(value: 'Resource', child: Text('Resource')),
                    DropdownMenuItem(value: 'Settings', child: Text('Settings')),
                    DropdownMenuItem(value: 'Report', child: Text('Report')),
                    DropdownMenuItem(value: 'Notification', child: Text('Notification')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedActivityType = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDateRange,
                  decoration: const InputDecoration(
                    labelText: 'Date Range',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Time')),
                    DropdownMenuItem(value: 'Today', child: Text('Today')),
                    DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                    DropdownMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
                    DropdownMenuItem(value: 'Last 90 Days', child: Text('Last 90 Days')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDateRange = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final activities = _filteredActivities;
    final successCount = activities.where((a) => a['status'] == 'Success').length;
    final failedCount = activities.where((a) => a['status'] == 'Failed').length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Activities',
              activities.length.toString(),
              Icons.list,
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Successful',
              successCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Failed',
              failedCount.toString(),
              Icons.error,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = _filteredActivities;

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No activities found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final isSuccess = activity['status'] == 'Success';
    final color = _getActivityTypeColor(activity['type'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActivityTypeIcon(activity['type'] as String),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          activity['action'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(activity['timestamp'] as String),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.devices, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(activity['device'] as String),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('IP: ${activity['ip']}'),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            activity['status'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type) {
      case 'Login':
        return Icons.login;
      case 'User Management':
        return Icons.people;
      case 'Grade Management':
        return Icons.grade;
      case 'Course Management':
        return Icons.school;
      case 'Assignment':
        return Icons.assignment;
      case 'Resource':
        return Icons.library_books;
      case 'Settings':
        return Icons.settings;
      case 'Report':
        return Icons.insert_chart;
      case 'Notification':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Color _getActivityTypeColor(String type) {
    switch (type) {
      case 'Login':
        return Colors.blue;
      case 'User Management':
        return Colors.purple;
      case 'Grade Management':
        return Colors.orange;
      case 'Course Management':
        return Colors.green;
      case 'Assignment':
        return Colors.teal;
      case 'Resource':
        return Colors.indigo;
      case 'Settings':
        return Colors.grey;
      case 'Report':
        return Colors.amber;
      case 'Notification':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _exportActivityLog() {
    // TODO: Export to Excel/PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting activity log...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
