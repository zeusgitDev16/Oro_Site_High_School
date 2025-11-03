import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import '../../../services/notification_service.dart';

/// Notifications domain state and interactive logic (no UI).
/// This ChangeNotifier manages notification filtering, marking as read,
/// and other interactive behaviors separate from the UI layer.
class NotificationsState extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  // Data
  final List<AdminNotification> allNotifications = [];
  List<AdminNotification> filteredNotifications = [];
  bool isLoading = true;
  String selectedFilter = 'All';

  // Filter options
  final List<String> filters = [
    'All',
    'Unread',
    'Enrollments',
    'Submissions',
    'Messages',
    'Alerts',
  ];

  /// Initialize notifications for a specific admin
  Future<void> initNotifications(String adminId) async {
    isLoading = true;
    notifyListeners();

    try {
      final notifications =
          await _notificationService.getAdminNotifications(adminId);
      allNotifications.clear();
      allNotifications.addAll(notifications);
      applyFilter();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Apply the current filter to notifications
  void applyFilter() {
    switch (selectedFilter) {
      case 'Unread':
        filteredNotifications =
            allNotifications.where((n) => !n.isRead).toList();
        break;
      case 'Enrollments':
        filteredNotifications = allNotifications
            .where((n) => n.type == NotificationType.enrollment)
            .toList();
        break;
      case 'Submissions':
        filteredNotifications = allNotifications
            .where((n) => n.type == NotificationType.submission)
            .toList();
        break;
      case 'Messages':
        filteredNotifications = allNotifications
            .where((n) => n.type == NotificationType.message)
            .toList();
        break;
      case 'Alerts':
        filteredNotifications = allNotifications
            .where((n) =>
                n.type == NotificationType.systemAlert ||
                n.type == NotificationType.attendance ||
                n.type == NotificationType.gradeDispute)
            .toList();
        break;
      default:
        filteredNotifications = allNotifications;
    }
    notifyListeners();
  }

  /// Change the active filter
  void selectFilter(String filterName) {
    selectedFilter = filterName;
    applyFilter();
  }

  /// Mark a single notification as read
  Future<void> markAsRead(AdminNotification notification) async {
    await _notificationService.markAsRead(notification.id);
    final index = allNotifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      allNotifications[index] = notification.copyWith(isRead: true);
    }
    applyFilter();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String adminId) async {
    await _notificationService.markAllAsRead(adminId);
    allNotifications.replaceRange(
      0,
      allNotifications.length,
      allNotifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
    applyFilter();
  }

  /// Delete a notification
  Future<void> deleteNotification(AdminNotification notification) async {
    await _notificationService.deleteNotification(notification.id);
    allNotifications.removeWhere((n) => n.id == notification.id);
    applyFilter();
  }

  /// Get unread notification count
  int getUnreadCount() {
    return allNotifications.where((n) => !n.isRead).length;
  }

  /// Get actionable notifications for To-do tab
  List<AdminNotification> getTodoNotifications() {
    return filteredNotifications
        .where((n) =>
            !n.isRead &&
            (n.type == NotificationType.submission ||
                n.type == NotificationType.gradeDispute ||
                n.type == NotificationType.resourceRequest ||
                n.type == NotificationType.message))
        .toList();
  }

  /// Get icon for notification type
  IconData getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.enrollment:
        return Icons.person_add;
      case NotificationType.submission:
        return Icons.assignment_turned_in;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.systemAlert:
        return Icons.warning;
      case NotificationType.courseCompletion:
        return Icons.school;
      case NotificationType.attendance:
        return Icons.event_busy;
      case NotificationType.gradeDispute:
        return Icons.gavel;
      case NotificationType.resourceRequest:
        return Icons.library_books;
      case NotificationType.assignmentCreated:
        return Icons.assignment;
      case NotificationType.announcementPosted:
        return Icons.campaign;
    }
  }

  /// Get color for notification type
  Color getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.enrollment:
        return Colors.green;
      case NotificationType.submission:
        return Colors.blue;
      case NotificationType.message:
        return Colors.purple;
      case NotificationType.systemAlert:
        return Colors.orange;
      case NotificationType.courseCompletion:
        return Colors.teal;
      case NotificationType.attendance:
        return Colors.red;
      case NotificationType.gradeDispute:
        return Colors.deepOrange;
      case NotificationType.resourceRequest:
        return Colors.indigo;
      case NotificationType.assignmentCreated:
        return Colors.cyan;
      case NotificationType.announcementPosted:
        return Colors.amber;
    }
  }

  /// Format time for display
  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'pm' : 'am'}';
    }
  }

  /// Check if notification has a quick action available
  bool hasQuickAction(AdminNotification notification) {
    return notification.type == NotificationType.message ||
        notification.type == NotificationType.submission ||
        notification.type == NotificationType.gradeDispute ||
        notification.type == NotificationType.resourceRequest ||
        notification.type == NotificationType.enrollment;
  }

  /// Get quick action label for notification
  String getQuickActionLabel(AdminNotification notification) {
    switch (notification.type) {
      case NotificationType.message:
        return 'Reply';
      case NotificationType.submission:
      case NotificationType.gradeDispute:
      case NotificationType.resourceRequest:
        return 'Review';
      case NotificationType.enrollment:
        return 'Send Welcome';
      default:
        return 'View';
    }
  }
}
