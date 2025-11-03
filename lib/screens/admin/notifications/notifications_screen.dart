import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oro_site_high_school/flow/admin/notifications/notifications_state.dart';
import 'package:oro_site_high_school/models/notification.dart';

/// Admin Notifications Screen - Full-screen notification interface
/// Based on Teacher design but with admin-specific features
class AdminNotificationsScreen extends StatefulWidget {
  final String adminId;

  const AdminNotificationsScreen({super.key, required this.adminId});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late final NotificationsState state;

  @override
  void initState() {
    super.initState();
    state = NotificationsState();
    state.initNotifications(widget.adminId);
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [
            Consumer<NotificationsState>(
              builder: (context, state, _) {
                final unreadCount = state.getUnreadCount();
                if (unreadCount > 0) {
                  return TextButton.icon(
                    onPressed: () {
                      state.markAllAsRead(widget.adminId);
                    },
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Mark all read'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: _showNotificationSettings,
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilters(),
            _buildStatistics(),
            Expanded(child: _buildNotificationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<NotificationsState>(
      builder: (context, state, _) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.filters.length,
            itemBuilder: (context, index) {
              final filter = state.filters[index];
              final isSelected = state.selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    state.selectFilter(filter);
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.teal.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.teal.shade700 : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatistics() {
    return Consumer<NotificationsState>(
      builder: (context, state, _) {
        final unreadCount = state.getUnreadCount();
        final todoCount = state.getTodoNotifications().length;

        return Container(
          padding: const EdgeInsets.all(24),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  state.allNotifications.length.toString(),
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
                  'Action Required',
                  todoCount.toString(),
                  Icons.assignment_late,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Today',
                  state.allNotifications
                      .where((n) =>
                          n.createdAt.day == DateTime.now().day &&
                          n.createdAt.month == DateTime.now().month)
                      .length
                      .toString(),
                  Icons.today,
                  Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
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
    return Consumer<NotificationsState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.filteredNotifications.isEmpty) {
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
          itemCount: state.filteredNotifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(
                state, state.filteredNotifications[index]);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(
      NotificationsState state, AdminNotification notification) {
    final isUnread = !notification.isRead;
    final color = state.getColorForType(notification.type);
    final hasQuickAction = state.hasQuickAction(notification);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        state.deleteNotification(notification);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Card(
        elevation: isUnread ? 2 : 1,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _handleNotificationTap(state, notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Avatar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: notification.senderAvatar != null
                      ? Text(
                          notification.senderAvatar!,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : Icon(
                          state.getIconForType(notification.type),
                          color: color,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.senderName ?? 'System',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isUnread ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.content,
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
                              _getTypeLabel(notification.type),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            state.formatTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (hasQuickAction) ...[
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                _handleQuickAction(state, notification);
                              },
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: Text(
                                state.getQuickActionLabel(notification),
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(
      NotificationsState state, AdminNotification notification) {
    if (!notification.isRead) {
      state.markAsRead(notification);
    }

    // Handle navigation based on notification type
    if (notification.link != null) {
      // TODO: Navigate to the specific page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigate to: ${notification.link}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _handleQuickAction(
      NotificationsState state, AdminNotification notification) {
    state.markAsRead(notification);

    // Handle quick action based on notification type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${state.getQuickActionLabel(notification)} action triggered'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.enrollment:
        return 'Enrollment';
      case NotificationType.submission:
        return 'Submission';
      case NotificationType.message:
        return 'Message';
      case NotificationType.systemAlert:
        return 'System Alert';
      case NotificationType.courseCompletion:
        return 'Course Completion';
      case NotificationType.attendance:
        return 'Attendance';
      case NotificationType.gradeDispute:
        return 'Grade Dispute';
      case NotificationType.resourceRequest:
        return 'Resource Request';
      case NotificationType.assignmentCreated:
        return 'Assignment';
      case NotificationType.announcementPosted:
        return 'Announcement';
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose which notifications you want to receive:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enrollments'),
                subtitle: const Text('New student enrollments'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Submissions'),
                subtitle: const Text('Assignment submissions'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Messages'),
                subtitle: const Text('New messages and replies'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('System Alerts'),
                subtitle: const Text('Important system notifications'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Grade Disputes'),
                subtitle: const Text('Student grade disputes'),
                value: true,
                onChanged: (value) {},
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive notifications via email'),
                value: false,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive push notifications'),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings saved'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
