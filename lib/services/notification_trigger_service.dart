import 'package:oro_site_high_school/services/notification_service.dart';
import 'package:oro_site_high_school/models/notification.dart';

/// Service for triggering notifications based on system events
/// Handles all notification triggers for Admin-Teacher interactions
/// Backend integration point: Supabase real-time subscriptions
class NotificationTriggerService {
  // Singleton pattern
  static final NotificationTriggerService _instance = NotificationTriggerService._internal();
  factory NotificationTriggerService() => _instance;
  NotificationTriggerService._internal();

  final NotificationService _notificationService = NotificationService();

  // ==================== ADMIN → TEACHER NOTIFICATIONS ====================

  /// Trigger notification when admin assigns teacher to course
  Future<void> triggerCourseAssignment({
    required String teacherId,
    required String teacherName,
    required String courseName,
    required String section,
    required String adminName,
  }) async {
    final notification = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      recipientId: teacherId,
      title: 'New Course Assignment',
      content: 'You have been assigned to teach $courseName for $section by $adminName',
      isRead: false,
      link: '/teacher/courses',
      type: NotificationType.assignmentCreated,
      senderName: adminName,
      metadata: {
        'courseName': courseName,
        'section': section,
        'adminName': adminName,
        'priority': 'high',
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  /// Trigger notification when admin responds to teacher request
  Future<void> triggerRequestResponse({
    required String teacherId,
    required String requestTitle,
    required String status,
    required String adminResponse,
    required String adminName,
  }) async {
    final notification = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      recipientId: teacherId,
      title: 'Request ${status == 'completed' ? 'Completed' : 'Updated'}',
      content: '$adminName responded to your request: "$requestTitle"',
      isRead: false,
      link: '/teacher/requests',
      type: NotificationType.systemAlert,
      senderName: adminName,
      metadata: {
        'requestTitle': requestTitle,
        'status': status,
        'adminResponse': adminResponse,
        'adminName': adminName,
        'priority': status == 'completed' ? 'high' : 'medium',
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  /// Trigger notification when admin assigns adviser to section
  Future<void> triggerAdviserAssignment({
    required String teacherId,
    required String sectionName,
    required String adminName,
  }) async {
    final notification = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      recipientId: teacherId,
      title: 'Adviser Assignment',
      content: 'You have been assigned as adviser for $sectionName by $adminName',
      isRead: false,
      link: '/teacher/sections',
      type: NotificationType.systemAlert,
      senderName: adminName,
      metadata: {
        'sectionName': sectionName,
        'adminName': adminName,
        'priority': 'high',
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ==================== TEACHER → ADMIN NOTIFICATIONS ====================

  /// Trigger notification when teacher submits request
  Future<void> triggerNewRequest({
    required String adminId,
    required String teacherName,
    required String requestType,
    required String requestTitle,
    required String priority,
  }) async {
    final notification = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'New Teacher Request',
      content: '$teacherName submitted a ${requestType.replaceAll('_', ' ')} request: "$requestTitle"',
      isRead: false,
      link: '/admin/requests',
      type: NotificationType.resourceRequest,
      senderName: teacherName,
      metadata: {
        'teacherName': teacherName,
        'requestType': requestType,
        'requestTitle': requestTitle,
        'priority': priority,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  /// Trigger notification when teacher submits grades
  Future<void> triggerGradeSubmission({
    required String adminId,
    required String teacherName,
    required String courseName,
    required String section,
    required int studentCount,
  }) async {
    final notification = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Grades Submitted',
      content: '$teacherName submitted grades for $studentCount students in $courseName ($section)',
      isRead: false,
      link: '/admin/grades',
      type: NotificationType.submission,
      senderName: teacherName,
      metadata: {
        'teacherName': teacherName,
        'courseName': courseName,
        'section': section,
        'studentCount': studentCount,
        'priority': 'low',
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  /// Trigger notification when coordinator submits bulk grades
  Future<void> triggerBulkGradeSubmission({
    required String adminId,
    required String coordinatorName,
    required String section,
    required String subject,
    required int studentCount,
  }) async {
    final notification = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Bulk Grades Submitted',
      content: '$coordinatorName submitted bulk grades for $studentCount students in $section - $subject',
      isRead: false,
      link: '/admin/grades',
      type: NotificationType.submission,
      senderName: coordinatorName,
      metadata: {
        'coordinatorName': coordinatorName,
        'section': section,
        'subject': subject,
        'studentCount': studentCount,
        'priority': 'low',
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ==================== SYSTEM NOTIFICATIONS ====================

  /// Trigger notification for deadline reminders
  Future<void> triggerDeadlineReminder({
    required String userId,
    required String userRole,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    final hoursUntil = deadline.difference(DateTime.now()).inHours;
    
    final notification = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      recipientId: userId,
      title: 'Deadline Reminder',
      content: '$taskTitle is due in $hoursUntil hours',
      isRead: false,
      link: userRole == 'teacher' ? '/teacher/assignments' : '/admin/tasks',
      type: NotificationType.systemAlert,
      metadata: {
        'taskTitle': taskTitle,
        'deadline': deadline.toIso8601String(),
        'hoursUntil': hoursUntil,
        'priority': hoursUntil <= 24 ? 'urgent' : 'medium',
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  /// Trigger notification for system announcements
  Future<void> triggerAnnouncement({
    required String userId,
    required String userRole,
    required String title,
    required String message,
  }) async {
    final notification = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      recipientId: userId,
      title: title,
      content: message,
      isRead: false,
      link: userRole == 'teacher' ? '/teacher/announcements' : '/admin/announcements',
      type: NotificationType.announcementPosted,
      metadata: {
        'priority': 'medium',
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ==================== BATCH NOTIFICATIONS ====================

  /// Trigger notifications for multiple users
  Future<void> triggerBatchNotifications({
    required List<String> userIds,
    required String userRole,
    required NotificationType type,
    required String title,
    required String message,
    String priority = 'medium',
    String? actionUrl,
  }) async {
    for (final userId in userIds) {
      final notification = AdminNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}-$userId',
        createdAt: DateTime.now(),
        recipientId: userId,
        title: title,
        content: message,
        isRead: false,
        link: actionUrl,
        type: type,
        metadata: {
          'priority': priority,
        },
      );

      await _notificationService.createAdminNotification(notification);
    }
  }

  // ==================== NOTIFICATION HELPERS ====================

  /// Get notification icon based on type
  static String getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.assignmentCreated:
        return '📚';
      case NotificationType.resourceRequest:
        return '📝';
      case NotificationType.submission:
        return '📊';
      case NotificationType.systemAlert:
        return '⏰';
      case NotificationType.announcementPosted:
        return '📢';
      case NotificationType.message:
        return '💬';
      case NotificationType.attendance:
        return '✅';
      case NotificationType.gradeDispute:
        return '⚠️';
      case NotificationType.enrollment:
        return '🎓';
      case NotificationType.courseCompletion:
        return '🏆';
    }
  }

  /// Get notification color based on priority from metadata
  static String getNotificationColor(String priority) {
    switch (priority) {
      case 'urgent':
        return '#FF0000';
      case 'high':
        return '#FF6B00';
      case 'medium':
        return '#0066FF';
      case 'low':
        return '#00CC66';
      default:
        return '#666666';
    }
  }
}
