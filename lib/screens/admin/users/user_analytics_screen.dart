import 'package:flutter/material.dart';

class UserAnalyticsScreen extends StatefulWidget {
  const UserAnalyticsScreen({super.key});

  @override
  State<UserAnalyticsScreen> createState() => _UserAnalyticsScreenState();
}

class _UserAnalyticsScreenState extends State<UserAnalyticsScreen> {
  String _selectedTimeframe = 'This Month';

  // Mock analytics data - ready for backend connection
  final Map<String, dynamic> _analyticsData = {
    'totalUsers': 1245,
    'activeUsers': 1089,
    'newUsers': 45,
    'loginRate': 87.5,
    'usersByRole': [
      {'role': 'Students', 'count': 980, 'percentage': 78.7},
      {'role': 'Parents', 'count': 208, 'percentage': 16.7},
      {'role': 'Teachers', 'count': 45, 'percentage': 3.6},
      {'role': 'Admins', 'count': 12, 'percentage': 1.0},
    ],
    'activityTrends': [
      {'day': 'Mon', 'logins': 850},
      {'day': 'Tue', 'logins': 920},
      {'day': 'Wed', 'logins': 880},
      {'day': 'Thu', 'logins': 950},
      {'day': 'Fri', 'logins': 1020},
      {'day': 'Sat', 'logins': 450},
      {'day': 'Sun', 'logins': 380},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Analytics'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedTimeframe,
            onSelected: (value) {
              setState(() {
                _selectedTimeframe = value;
              });
              // TODO: Fetch data for selected timeframe
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(value: 'This Month', child: Text('This Month')),
              const PopupMenuItem(value: 'This Year', child: Text('This Year')),
              const PopupMenuItem(value: 'All Time', child: Text('All Time')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedTimeframe),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Export analytics report
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting analytics report...')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildUsersByRole(),
          const SizedBox(height: 24),
          _buildActivityTrends(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Users',
          '${_analyticsData['totalUsers']}',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Users',
          '${_analyticsData['activeUsers']}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'New Users',
          '+${_analyticsData['newUsers']}',
          Icons.person_add,
          Colors.orange,
        ),
        _buildStatCard(
          'Login Rate',
          '${_analyticsData['loginRate']}%',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersByRole() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Users by Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(_analyticsData['usersByRole'] as List).map((role) {
              return _buildRoleItem(role);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleItem(Map<String, dynamic> role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role['role'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${role['count']} (${role['percentage']}%)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: role['percentage'] / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getRoleColor(role['role']),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Students':
        return Colors.blue;
      case 'Teachers':
        return Colors.green;
      case 'Admins':
        return Colors.purple;
      case 'Parents':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActivityTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Login Activity (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: (_analyticsData['activityTrends'] as List).map((day) {
                  final maxLogins = 1100;
                  final height = (day['logins'] / maxLogins) * 150;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${day['logins']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day['day'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
