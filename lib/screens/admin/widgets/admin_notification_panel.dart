import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/notification.dart';
import '../../../flow/admin/notifications/notifications_state.dart';
import '../../../flow/admin/messages/messages_state.dart';
import '../dialogs/inbox_dialog.dart';
import '../dialogs/compose_message_dialog.dart';

class AdminNotificationPanel extends StatefulWidget {
  final String adminId;
  final MessagesState? messagesState;

  const AdminNotificationPanel({
    super.key,
    required this.adminId,
    this.messagesState,
  });

  @override
  State<AdminNotificationPanel> createState() => _AdminNotificationPanelState();
}

class _AdminNotificationPanelState extends State<AdminNotificationPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize notifications state
    Future.microtask(() {
      context.read<NotificationsState>().initNotifications(widget.adminId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(top: 60, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        height: 550,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            _buildFilterChips(),
            Expanded(
              child: _buildNotificationList(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<NotificationsState>(
      builder: (context, state, _) {
        final unreadCount = state.getUnreadCount();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                onPressed: () {
                  _showNotificationSettings();
                },
                tooltip: 'Configure',
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        tabs: const [
          Tab(
            icon: Icon(Icons.notifications_active, size: 18),
            text: 'Notifications',
          ),
          Tab(icon: Icon(Icons.check_circle_outline, size: 18), text: 'To-do'),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<NotificationsState>(
      builder: (context, state, _) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
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
                  selectedColor: Colors.blue.withValues(alpha: 0.2),
                  checkmarkColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationList() {
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
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildNotificationsTab(state),
            _buildTodoTab(state),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsTab(NotificationsState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = state.filteredNotifications[index];
        return _buildNotificationItem(state, notification);
      },
    );
  }

  Widget _buildTodoTab(NotificationsState state) {
    final todoNotifications = state.getTodoNotifications();

    if (todoNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: todoNotifications.length,
      itemBuilder: (context, index) {
        final notification = todoNotifications[index];
        return _buildNotificationItem(state, notification, showActions: true);
      },
    );
  }

  Widget _buildNotificationItem(
    NotificationsState state,
    AdminNotification notification, {
    bool showActions = false,
  }) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        state.deleteNotification(notification);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            state.markAsRead(notification);
          }
          if (notification.link != null) {
            Navigator.of(context).pop();
            // TODO: Implement navigation to the link
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : Colors.blue.withValues(alpha: 0.05),
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar or Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: state.getColorForType(notification.type)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: notification.senderAvatar != null
                    ? Center(
                        child: Text(
                          notification.senderAvatar!,
                          style: TextStyle(
                            color: state.getColorForType(notification.type),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Icon(
                        state.getIconForType(notification.type),
                        color: state.getColorForType(notification.type),
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          state.formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showActions) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              state.markAsRead(notification);
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text(
                              'Review',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              state.markAsRead(notification);
                            },
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text(
                              'Dismiss',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Consumer<NotificationsState>(
      builder: (context, state, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  // Show all notifications in a full page
                },
                icon: const Icon(Icons.list, size: 18),
                label: const Text('See all'),
              ),
              TextButton.icon(
                onPressed: () {
                  state.markAllAsRead(widget.adminId);
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark all read'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Enrollments'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Submissions'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Messages'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('System Alerts'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Email Notifications'),
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
