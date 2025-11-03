/// Example implementations for triggering admin notifications
/// from various parts of the system.
/// 
/// This file demonstrates how to integrate the notification system
/// with existing services and workflows.

import '../models/notification.dart';
import 'notification_service.dart';

class NotificationTriggerExamples {
  final NotificationService _notificationService = NotificationService();

  /// Generate a unique ID for notifications
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // ============================================================================
  // ENROLLMENT NOTIFICATIONS
  // ============================================================================

  /// Trigger when a student enrolls in a course
  Future<void> onStudentEnrollment({
    required String adminId,
    required String studentName,
    required String courseName,
    required String studentId,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'New Student Enrollment',
      content: '$studentName has enrolled in $courseName',
      isRead: false,
      type: NotificationType.enrollment,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      link: '/admin/users/$studentId',
      metadata: {
        'student_id': studentId,
        'course_name': courseName,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // SUBMISSION NOTIFICATIONS
  // ============================================================================

  /// Trigger when a student submits an assignment
  Future<void> onAssignmentSubmission({
    required String adminId,
    required String studentName,
    required String assignmentTitle,
    required String submissionId,
    required String assignmentId,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Assignment Submitted',
      content: '$studentName submitted $assignmentTitle',
      isRead: false,
      type: NotificationType.submission,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      link: '/admin/submissions/$submissionId',
      metadata: {
        'submission_id': submissionId,
        'assignment_id': assignmentId,
        'assignment_title': assignmentTitle,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  /// Trigger when a submission is late
  Future<void> onLateSubmission({
    required String adminId,
    required String studentName,
    required String assignmentTitle,
    required int daysLate,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Late Submission',
      content: '$studentName submitted $assignmentTitle ($daysLate days late)',
      isRead: false,
      type: NotificationType.submission,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      metadata: {
        'days_late': daysLate,
        'assignment_title': assignmentTitle,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // MESSAGE NOTIFICATIONS
  // ============================================================================

  /// Trigger when a student sends a message
  Future<void> onStudentMessage({
    required String adminId,
    required String studentName,
    required String messagePreview,
    required String messageId,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Student Query',
      content: '$studentName: $messagePreview',
      isRead: false,
      type: NotificationType.message,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      link: '/admin/messages/$messageId',
      metadata: {
        'message_id': messageId,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // COURSE COMPLETION NOTIFICATIONS
  // ============================================================================

  /// Trigger when a student completes a course
  Future<void> onCourseCompletion({
    required String adminId,
    required String studentName,
    required String courseName,
    required String courseId,
    required double finalGrade,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Course Completion',
      content: '$studentName completed $courseName with ${finalGrade.toStringAsFixed(1)}%',
      isRead: false,
      type: NotificationType.courseCompletion,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      link: '/admin/courses/$courseId',
      metadata: {
        'course_id': courseId,
        'course_name': courseName,
        'final_grade': finalGrade,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // ATTENDANCE NOTIFICATIONS
  // ============================================================================

  /// Trigger when a student has consecutive absences
  Future<void> onAttendanceAlert({
    required String adminId,
    required String studentName,
    required int consecutiveAbsences,
    required String studentId,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Attendance Alert',
      content: 'Low attendance: $studentName - $consecutiveAbsences consecutive absences',
      isRead: false,
      type: NotificationType.attendance,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      link: '/admin/attendance/$studentId',
      metadata: {
        'student_id': studentId,
        'consecutive_absences': consecutiveAbsences,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  /// Trigger when attendance falls below threshold
  Future<void> onLowAttendanceRate({
    required String adminId,
    required String studentName,
    required double attendanceRate,
    required String studentId,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Low Attendance Rate',
      content: '$studentName attendance rate: ${attendanceRate.toStringAsFixed(1)}%',
      isRead: false,
      type: NotificationType.attendance,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      link: '/admin/attendance/$studentId',
      metadata: {
        'student_id': studentId,
        'attendance_rate': attendanceRate,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // GRADE DISPUTE NOTIFICATIONS
  // ============================================================================

  /// Trigger when a student disputes a grade
  Future<void> onGradeDispute({
    required String adminId,
    required String studentName,
    required String assignmentTitle,
    required String disputeReason,
    required String disputeId,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Grade Dispute',
      content: '$studentName disputed grade for $assignmentTitle',
      isRead: false,
      type: NotificationType.gradeDispute,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      link: '/admin/grades/dispute/$disputeId',
      metadata: {
        'dispute_id': disputeId,
        'assignment_title': assignmentTitle,
        'reason': disputeReason,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // RESOURCE REQUEST NOTIFICATIONS
  // ============================================================================

  /// Trigger when a student requests resource access
  Future<void> onResourceRequest({
    required String adminId,
    required String studentName,
    required String resourceName,
    required String requestId,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Resource Request',
      content: '$studentName requested access to $resourceName',
      isRead: false,
      type: NotificationType.resourceRequest,
      senderName: studentName,
      senderAvatar: _getInitials(studentName),
      link: '/admin/resources/requests/$requestId',
      metadata: {
        'request_id': requestId,
        'resource_name': resourceName,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // SYSTEM ALERT NOTIFICATIONS
  // ============================================================================

  /// Trigger system-wide alerts
  Future<void> onSystemAlert({
    required String adminId,
    required String alertTitle,
    required String alertMessage,
    String? link,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: alertTitle,
      content: alertMessage,
      isRead: false,
      type: NotificationType.systemAlert,
      senderName: 'System',
      senderAvatar: 'SY',
      link: link,
    );

    await _notificationService.createAdminNotification(notification);
  }

  /// Trigger maintenance notification
  Future<void> onScheduledMaintenance({
    required String adminId,
    required DateTime maintenanceDate,
    required String duration,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'Scheduled Maintenance',
      content: 'System maintenance scheduled for ${_formatDate(maintenanceDate)} ($duration)',
      isRead: false,
      type: NotificationType.systemAlert,
      senderName: 'System',
      senderAvatar: 'SY',
      metadata: {
        'maintenance_date': maintenanceDate.toIso8601String(),
        'duration': duration,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // ASSIGNMENT NOTIFICATIONS
  // ============================================================================

  /// Trigger when a new assignment is created
  Future<void> onAssignmentCreated({
    required String adminId,
    required String teacherName,
    required String assignmentTitle,
    required String courseId,
    required DateTime dueDate,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'New Assignment Created',
      content: '$teacherName created "$assignmentTitle" (Due: ${_formatDate(dueDate)})',
      isRead: false,
      type: NotificationType.assignmentCreated,
      senderName: teacherName,
      senderAvatar: _getInitials(teacherName),
      link: '/admin/courses/$courseId/assignments',
      metadata: {
        'course_id': courseId,
        'assignment_title': assignmentTitle,
        'due_date': dueDate.toIso8601String(),
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // ANNOUNCEMENT NOTIFICATIONS
  // ============================================================================

  /// Trigger when a new announcement is posted
  Future<void> onAnnouncementPosted({
    required String adminId,
    required String authorName,
    required String announcementTitle,
    required String announcementId,
  }) async {
    final notification = AdminNotification(
      id: _generateId(),
      createdAt: DateTime.now(),
      recipientId: adminId,
      title: 'New Announcement',
      content: '$authorName posted: $announcementTitle',
      isRead: false,
      type: NotificationType.announcementPosted,
      senderName: authorName,
      senderAvatar: _getInitials(authorName),
      link: '/admin/announcements/$announcementId',
      metadata: {
        'announcement_id': announcementId,
        'announcement_title': announcementTitle,
      },
    );

    await _notificationService.createAdminNotification(notification);
  }

  // ============================================================================
  // BATCH NOTIFICATIONS
  // ============================================================================

  /// Send notifications to multiple admins
  Future<void> notifyAllAdmins({
    required List<String> adminIds,
    required String title,
    required String content,
    required NotificationType type,
    String? link,
  }) async {
    for (final adminId in adminIds) {
      final notification = AdminNotification(
        id: _generateId(),
        createdAt: DateTime.now(),
        recipientId: adminId,
        title: title,
        content: content,
        isRead: false,
        type: type,
        senderName: 'System',
        senderAvatar: 'SY',
        link: link,
      );

      await _notificationService.createAdminNotification(notification);
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get initials from a name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/// Example: Integrate with enrollment service
/// 
/// ```dart
/// class EnrollmentService {
///   final NotificationTriggerExamples _notificationTriggers = 
///     NotificationTriggerExamples();
///   
///   Future<void> enrollStudent(Student student, Course course) async {
///     // ... enrollment logic ...
///     
///     // Notify admin
///     await _notificationTriggers.onStudentEnrollment(
///       adminId: 'admin-1',
///       studentName: student.name,
///       courseName: course.name,
///       studentId: student.id,
///     );
///   }
/// }
/// ```

/// Example: Integrate with submission service
/// 
/// ```dart
/// class SubmissionService {
///   final NotificationTriggerExamples _notificationTriggers = 
///     NotificationTriggerExamples();
///   
///   Future<void> submitAssignment(Submission submission) async {
///     // ... submission logic ...
///     
///     // Notify admin
///     await _notificationTriggers.onAssignmentSubmission(
///       adminId: 'admin-1',
///       studentName: submission.studentName,
///       assignmentTitle: submission.assignmentTitle,
///       submissionId: submission.id,
///       assignmentId: submission.assignmentId,
///     );
///   }
/// }
/// ```

/// Example: Integrate with attendance service
/// 
/// ```dart
/// class AttendanceService {
///   final NotificationTriggerExamples _notificationTriggers = 
///     NotificationTriggerExamples();
///   
///   Future<void> checkAttendance(Student student) async {
///     final absences = await getConsecutiveAbsences(student.id);
///     
///     if (absences >= 3) {
///       await _notificationTriggers.onAttendanceAlert(
///         adminId: 'admin-1',
///         studentName: student.name,
///         consecutiveAbsences: absences,
///         studentId: student.id,
///       );
///     }
///   }
/// }
/// ```
