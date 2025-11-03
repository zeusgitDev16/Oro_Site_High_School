
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import 'dart:async';

class NotificationService {
  final _supabase = Supabase.instance.client;
  
  // Stream controller for real-time notifications
  final _notificationController = StreamController<List<AdminNotification>>.broadcast();
  Stream<List<AdminNotification>> get notificationStream => _notificationController.stream;

  Future<List<Notification>> getNotificationsForUser(String userId) async {
    final response = await _supabase.from('notifications').select().eq('recipient_id', userId);
    return (response as List).map((item) => Notification.fromMap(item)).toList();
  }

  Future<Notification> createNotification(Notification notification) async {
    final response = await _supabase.from('notifications').insert({
      'recipient_id': notification.recipientId,
      'content': notification.content,
      'is_read': notification.isRead,
      'link': notification.link,
    }).select().single();
    return Notification.fromMap(response);
  }

  // Admin notification methods
  Future<List<AdminNotification>> getAdminNotifications(String adminId) async {
    try {
      final response = await _supabase
          .from('admin_notifications')
          .select()
          .eq('recipient_id', adminId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => AdminNotification.fromMap(item))
          .toList();
    } catch (e) {
      // Return mock data if database is not set up
      return _getMockAdminNotifications(adminId);
    }
  }

  Future<List<AdminNotification>> getUnreadAdminNotifications(String adminId) async {
    try {
      final response = await _supabase
          .from('admin_notifications')
          .select()
          .eq('recipient_id', adminId)
          .eq('is_read', false)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => AdminNotification.fromMap(item))
          .toList();
    } catch (e) {
      // Return mock data if database is not set up
      return _getMockAdminNotifications(adminId).where((n) => !n.isRead).toList();
    }
  }

  Future<int> getUnreadCount(String adminId) async {
    try {
      final response = await _supabase
          .from('admin_notifications')
          .select('id')
          .eq('recipient_id', adminId)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      // Return mock count if database is not set up
      return _getMockAdminNotifications(adminId).where((n) => !n.isRead).length;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      // Silently fail if database is not set up
    }
  }

  Future<void> markAllAsRead(String adminId) async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('recipient_id', adminId)
          .eq('is_read', false);
    } catch (e) {
      // Silently fail if database is not set up
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('admin_notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      // Silently fail if database is not set up
    }
  }

  Future<AdminNotification> createAdminNotification(AdminNotification notification) async {
    try {
      final response = await _supabase
          .from('admin_notifications')
          .insert(notification.toMap())
          .select()
          .single();
      
      return AdminNotification.fromMap(response);
    } catch (e) {
      // Return the notification as-is if database is not set up
      return notification;
    }
  }

  // Mock data for development/testing
  List<AdminNotification> _getMockAdminNotifications(String adminId) {
    final now = DateTime.now();
    return [
      AdminNotification(
        id: '0',
        createdAt: now.subtract(const Duration(minutes: 2)),
        recipientId: adminId,
        title: 'New Message',
        content: 'Ms. Cruz: Need help with student password reset',
        isRead: false,
        type: NotificationType.message,
        senderName: 'Ms. Cruz',
        senderAvatar: 'MC',
        link: '/admin/messages/th2',
        metadata: {'thread_id': 'th2', 'message_type': 'query'},
      ),
      AdminNotification(
        id: '1',
        createdAt: now.subtract(const Duration(minutes: 5)),
        recipientId: adminId,
        title: 'New Student Enrollment',
        content: 'John Smith has enrolled in Computer Science 101',
        isRead: false,
        type: NotificationType.enrollment,
        senderName: 'John Smith',
        senderAvatar: 'JS',
        link: '/admin/users/john-smith',
        metadata: {'student_id': 'john-smith', 'course': 'CS101'},
      ),
      AdminNotification(
        id: '2',
        createdAt: now.subtract(const Duration(minutes: 15)),
        recipientId: adminId,
        title: 'Assignment Submitted',
        content: 'Sarah Johnson submitted Assignment 05 - Data Structures',
        isRead: false,
        type: NotificationType.submission,
        senderName: 'Sarah Johnson',
        senderAvatar: 'SJ',
        link: '/admin/submissions/assignment-05',
      ),
      AdminNotification(
        id: '3',
        createdAt: now.subtract(const Duration(hours: 1)),
        recipientId: adminId,
        title: 'Student Query',
        content: 'Michael Brown: Question about final exam schedule',
        isRead: false,
        type: NotificationType.message,
        senderName: 'Michael Brown',
        senderAvatar: 'MB',
        link: '/admin/messages/michael-brown',
      ),
      AdminNotification(
        id: '4',
        createdAt: now.subtract(const Duration(hours: 2)),
        recipientId: adminId,
        title: 'Course Completion',
        content: 'Emily Davis completed Mathematics 201',
        isRead: false,
        type: NotificationType.courseCompletion,
        senderName: 'Emily Davis',
        senderAvatar: 'ED',
        link: '/admin/courses/math-201',
      ),
      AdminNotification(
        id: '5',
        createdAt: now.subtract(const Duration(hours: 3)),
        recipientId: adminId,
        title: 'Attendance Alert',
        content: 'Low attendance: David Wilson - 3 consecutive absences',
        isRead: true,
        type: NotificationType.attendance,
        senderName: 'System',
        senderAvatar: 'SY',
        link: '/admin/attendance/david-wilson',
      ),
      AdminNotification(
        id: '6',
        createdAt: now.subtract(const Duration(hours: 4)),
        recipientId: adminId,
        title: 'Grade Dispute',
        content: 'Lisa Anderson disputed grade for Assignment 03',
        isRead: true,
        type: NotificationType.gradeDispute,
        senderName: 'Lisa Anderson',
        senderAvatar: 'LA',
        link: '/admin/grades/dispute/assignment-03',
      ),
      AdminNotification(
        id: '7',
        createdAt: now.subtract(const Duration(hours: 5)),
        recipientId: adminId,
        title: 'Resource Request',
        content: 'James Taylor requested access to Advanced Physics Lab',
        isRead: true,
        type: NotificationType.resourceRequest,
        senderName: 'James Taylor',
        senderAvatar: 'JT',
        link: '/admin/resources/physics-lab',
      ),
      AdminNotification(
        id: '8',
        createdAt: now.subtract(const Duration(days: 1)),
        recipientId: adminId,
        title: 'System Alert',
        content: 'Server maintenance scheduled for this weekend',
        isRead: true,
        type: NotificationType.systemAlert,
        senderName: 'System',
        senderAvatar: 'SY',
      ),
    ];
  }

  void dispose() {
    _notificationController.close();
  }
}
