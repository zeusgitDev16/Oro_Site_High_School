import 'package:flutter/material.dart';

/// Parent Notifications Screen - View and manage notifications
/// Adapted from Teacher notifications system
class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Unread',
    'Grades',
    'Attendance',
    'Assignments',
    'School',
  ];

  late List<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      {
        'id': 'notif-1',
        'title': 'New Grade Posted',
        'message': 'Juan Dela Cruz received a grade for Quiz 3 - Mathematics',
        'type': 'Grades',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
        'read': false,
        'icon': Icons.grade,
        'color': Colors.blue,
      },
      {
        'id': 'notif-2',
        'title': 'Attendance Alert',
        'message': 'Juan Dela Cruz was marked late today',
        'type': 'Attendance',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'read': false,
        'icon': Icons.warning,
        'color': Colors.orange,
      },
      {
        'id': 'notif-3',
        'title': 'Assignment Due Soon',
        'message': 'Science Project due in 2 days',
        'type': 'Assignments',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
        'read': true,
        'icon': Icons.assignment,
        'color': Colors.purple,
      },
      {
        'id': 'notif-4',
        'title': 'School Announcement',
        'message': 'Parent-Teacher Conference scheduled for next week',
        'type': 'School',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'read': true,
        'icon': Icons.campaign,
        'color': Colors.green,
      },
      {
        'id': 'notif-5',
        'title': 'Progress Report Available',
        'message': 'Q1 Progress Report is now available for viewing',
        'type': 'Grades',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'read': true,
        'icon': Icons.assessment,
        'color': Colors.blue,
      },
      {
        'id': 'notif-6',
        'title': 'Attendance Summary',
        'message': 'Monthly attendance summary: 95% attendance rate',
        'type': 'Attendance',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'read': true,
        'icon': Icons.fact_check,
        'color': Colors.green,
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    return _notifications.where((notif) {
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Unread' && notif['read'] == false) ||
          notif['type'] == _selectedFilter;
      return matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18, color: Colors.white),
              label: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStatistics(unreadCount),
          Expanded(child: _buildNotificationsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.orange.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatistics(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              _notifications.length.toString(),
              Icons.notifications,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Unread',
              unreadCount.toString(),
              Icons.mark_email_unread,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Today',
              _notifications
                  .where((n) {
                    final diff = DateTime.now().difference(n['timestamp'] as DateTime);
                    return diff.inHours < 24;
                  })
                  .length
                  .toString(),
              Icons.today,
              Colors.green,
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
            Icon(icon, color: color, size: 24),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
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

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(_filteredNotifications[index]);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final timestamp = notification['timestamp'] as DateTime;
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    String timeAgo;
    if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inDays}d ago';
    }

    final isUnread = notification['read'] == false;
    final color = notification['color'] as Color;

    return Card(
      elevation: isUnread ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification['icon'],
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notification['type'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAsRead(Map<String, dynamic> notification) {
    setState(() {
      notification['read'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
